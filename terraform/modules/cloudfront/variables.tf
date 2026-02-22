variable "nlb_dns_name" {
  description = "NLB DNS name as CloudFront origin"
  type        = string
}

variable "domain_name" {
  description = "Domain name for CloudFront distribution"
  type        = string
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN"
  type        = string
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
