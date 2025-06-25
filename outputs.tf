output "alb_dns_name" {
  value = aws_lb.web_alb.dns_name
}

output "db_endpoint" {
  value = aws_db_instance.web_db.endpoint
}

 
