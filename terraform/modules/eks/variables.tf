variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "cluster_version" {
  description = "EKS Kubernetes version"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for EKS nodes"
  type        = list(string)
}

variable "node_instance_types" {
  description = "EC2 instance types for EKS nodes"
  type        = list(string)
}

variable "node_desired_size" {
  description = "Desired number of EKS nodes"
  type        = number
}

variable "node_max_size" {
  description = "Maximum number of EKS nodes"
  type        = number
}

variable "node_min_size" {
  description = "Minimum number of EKS nodes"
  type        = number
}

variable "eks_nodes_security_group_id" {
  description = "Security group ID for EKS nodes"
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
