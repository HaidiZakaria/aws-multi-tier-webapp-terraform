resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "multi-tier-vpc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "multi-tier-igw"
  }
}

resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-west-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-1"
  }
}

resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "eu-west-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-2"
  }
}

resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "eu-west-1a"

  tags = {
    Name = "private-subnet-1"
  }
}

resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "eu-west-1b"

  tags = {
    Name = "private-subnet-2"
  }
}

# Elastic IP for NAT Gateway
resource "aws_eip" "nat_eip" {
  tags = {
    Name = "nat-eip"
  }
}


# NAT Gateway in public subnet
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_1.id

  tags = {
    Name = "nat-gateway"
  }

  depends_on = [aws_internet_gateway.igw]
}

# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-route-table"
  }
}

# Associate Public Subnets with Public Route Table
resource "aws_route_table_association" "public_1_assoc" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_2_assoc" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}

# Private Route Table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "private-route-table"
  }
}

# Associate Private Subnets with Private Route Table
resource "aws_route_table_association" "private_1_assoc" {
  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_2_assoc" {
  subnet_id      = aws_subnet.private_2.id
  route_table_id = aws_route_table.private.id
}

resource "aws_key_pair" "bastion_key" {
  key_name   = "bastion-key"
  public_key = file("${path.module}/bastion_key.pub")
}

# Security Group for Bastion Host
resource "aws_security_group" "bastion_sg" {
  name        = "bastion-sg"
  description = "Allow SSH from anywhere"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Replace with your IP if needed
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "db-subnet-group"
  subnet_ids = [aws_subnet.private_1.id, aws_subnet.private_2.id]

  tags = {
    Name = "db-subnet-group"
  }
}

# Security Group for Web EC2
resource "aws_security_group" "web_sg" {
  name        = "web-sg"
  description = "Allow traffic from Bastion only"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Later to be connected to ALB
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "db_sg" {
  name        = "db-sg"
  description = "Allow MySQL from web SG"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "db-sg"
  }
}

# Bastion EC2 in Public Subnet
resource "aws_instance" "bastion" {
  ami           = "ami-015b1e8e2a6899bdb" 
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public_1.id
  key_name      = aws_key_pair.bastion_key.key_name
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]

  tags = {
    Name = "bastion-host"
  }
}

# Web EC2 in Private Subnet
resource "aws_instance" "web" {
  ami           = "ami-015b1e8e2a6899bdb"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.private_1.id
  key_name      = aws_key_pair.bastion_key.key_name
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              yum install -y httpd
              echo "Hello from Web Server in Private Subnet!" > /var/www/html/index.html
              systemctl start httpd
              systemctl enable httpd
              EOF

  tags = {
    Name = "web-server"
  }
}


# ALB Security Group
resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "Allow HTTP traffic from the internet"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Target Group
resource "aws_lb_target_group" "web_tg" {
  name     = "web-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  target_type = "instance"
}

# Attach Web Instance to Target Group
resource "aws_lb_target_group_attachment" "web_attachment" {
  target_group_arn = aws_lb_target_group.web_tg.arn
  target_id        = aws_instance.web.id
  port             = 80
}

# Application Load Balancer
resource "aws_lb" "web_alb" {
  name               = "web-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [
    aws_subnet.public_1.id,
    aws_subnet.public_2.id
  ]

  tags = {
    Name = "web-alb"
  }
}

# Listener for ALB
resource "aws_lb_listener" "web_listener" {
  load_balancer_arn = aws_lb.web_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }
}

resource "aws_launch_template" "web_lt" {
  name_prefix   = "web-lt-"
  image_id      = "ami-015b1e8e2a6899bdb"  # same AMI you used before
  instance_type = "t2.micro"
  key_name      = aws_key_pair.bastion_key.key_name

  vpc_security_group_ids = [aws_security_group.web_sg.id]

  user_data = base64encode(<<-EOF
              #!/bin/bash
              yum install -y httpd
              echo "Hello from Auto Scaling Web Server!" > /var/www/html/index.html
              systemctl start httpd
              systemctl enable httpd
              EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "web-asg-instance"
    }
  }
}



resource "aws_autoscaling_group" "web_asg" {
  name                      = "web-asg"
  max_size                  = 2
  min_size                  = 1
  desired_capacity          = 1
  vpc_zone_identifier       = [aws_subnet.private_1.id, aws_subnet.private_2.id]
  target_group_arns         = [aws_lb_target_group.web_tg.arn]
  health_check_type         = "ELB"
  health_check_grace_period = 60

  launch_template {
    id      = aws_launch_template.web_lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "web-asg-instance"
    propagate_at_launch = true
  }

  depends_on = [aws_lb.web_alb]
}

resource "aws_db_instance" "web_db" {
  identifier              = "web-db"
  allocated_storage       = 20
  engine                  = "mysql"
  engine_version          = "8.0"
  instance_class          = "db.t3.micro"
  username                = "admin"
  password                = "HaidiSecure123!"  # you can move to variables.tf later
  db_subnet_group_name    = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids  = [aws_security_group.db_sg.id]
  multi_az                = false
  skip_final_snapshot     = true
  publicly_accessible     = false
  storage_encrypted       = false
  backup_retention_period = 0

  tags = {
    Name = "web-db"
  }
}

