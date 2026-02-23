variable "origin_dns_name" {
  description = "ALB DNS name as CloudFront origin"
  type        = string
}

variable "domain_name" {
  description = "Custom domain for CloudFront (optional)"
  type        = string
  default     = ""
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN for custom domain. Null = use CloudFront default cert (xxx.cloudfront.net)."
  type        = string
  default     = null
}

variable "waf_web_acl_id" {
  description = "WAF Web ACL ID to associate"
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
