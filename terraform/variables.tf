variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "ap-southeast-1"
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "apisix"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets (must be within vpc_cidr)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets (must be within vpc_cidr)"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"]
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "apisix-cluster"
}

variable "cluster_version" {
  description = "EKS Kubernetes version"
  type        = string
  default     = "1.28"
}

variable "node_instance_types" {
  description = "EC2 instance types for EKS nodes"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_desired_size" {
  description = "Desired number of EKS nodes"
  type        = number
  default     = 3
}

variable "node_max_size" {
  description = "Maximum number of EKS nodes"
  type        = number
  default     = 5
}

variable "node_min_size" {
  description = "Minimum number of EKS nodes"
  type        = number
  default     = 3
}

variable "domain_name" {
  description = "Custom domain for CloudFront (optional). Leave empty to use default CloudFront URL (xxx.cloudfront.net)."
  type        = string
  default     = ""
}

variable "alb_dns_name" {
  description = "Fallback DNS for CloudFront origin when ALB from K8s Ingress is not found by data source."
  type        = string
  default     = "placeholder.invalid"
}

variable "k8s_gateway_namespace" {
  description = "K8s namespace of apisix-gateway Ingress (for ALB lookup by tag ingress.k8s.aws/resource)."
  type        = string
  default     = "apisix"
}

variable "k8s_gateway_service_name" {
  description = "K8s Ingress name (e.g. apisix-gateway) used for ALB lookup by tag ingress.k8s.aws/resource."
  type        = string
  default     = "apisix-gateway"
}
