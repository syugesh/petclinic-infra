variable "project_name" {
  description = "Name prefix for AWS resources."
  type        = string
  default     = "petclinic"
}

variable "aws_region" {
  description = "AWS region."
  type        = string
  default     = "us-east-1"
}

variable "key_name" {
  description = "Existing AWS EC2 key pair name for SSH."
  type        = string
}

variable "ssh_allowed_cidr" {
  description = "CIDR allowed to SSH into the app VM."
  type        = string
}

variable "app_instance_type" {
  description = "EC2 instance size for the app VM."
  type        = string
  default     = "t3.micro"
}

variable "db_instance_class" {
  description = "RDS instance size."
  type        = string
  default     = "db.t3.micro"
}

variable "db_name" {
  description = "Application database name."
  type        = string
  default     = "petclinic"
}

variable "db_username" {
  description = "Application database username."
  type        = string
  default     = "petclinic"
}

variable "db_password" {
  description = "Application database password."
  type        = string
  sensitive   = true
}

