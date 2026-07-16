output "app_public_ip" {
  description = "Public IP address of the app VM."
  value       = aws_instance.app.public_ip
}

output "alb_dns_name" {
  description = "Load balancer DNS name."
  value       = aws_lb.app.dns_name
}

output "rds_endpoint" {
  description = "RDS MySQL endpoint without port."
  value       = aws_db_instance.mysql.address
}

output "ecr_repository_url" {
  description = "ECR repository URL for Docker images."
  value       = aws_ecr_repository.app.repository_url
}

