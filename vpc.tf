resource "aws_subnet" "public" {
  ...
  availability_zone = "eu-west-1a"
  ...
}

resource "aws_subnet" "private" {
  ...
  availability_zone = "eu-west-1a"
  ...
}
