variable "project_name" {
  description = "Project name for tagging"
  type        = string
}

variable "environment" {
  description = "Environment for tagging"
  type        = string
}

variable "cloudfront_distribution_id" {
  description = "CloudFront distribution ID to associate WAF with"
  type        = string
}
