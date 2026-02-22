variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for VPC endpoints"
  type        = list(string)
}

variable "vpc_endpoints_security_group_id" {
  description = "Security group ID for VPC endpoints"
  type        = string
}

variable "project_name" {
  description = "Project name for tagging"
  type        = string
}

variable "environment" {
  description = "Environment for tagging"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}
