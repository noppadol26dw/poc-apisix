output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_ca_certificate" {
  description = "EKS cluster CA certificate"
  value       = module.eks.cluster_ca_certificate
}

output "alb_dns_name" {
  description = "ALB DNS name (CloudFront origin; from Ingress when present)"
  value       = local.cloudfront_origin_dns
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  value       = module.cloudfront.distribution_id
}

output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name"
  value       = module.cloudfront.domain_name
}

output "waf_web_acl_id" {
  description = "WAF Web ACL ID"
  value       = module.waf.web_acl_id
}

output "acm_certificate_arn" {
  description = "ACM certificate ARN (only set when domain_name is set)"
  value       = length(aws_acm_certificate.main) > 0 ? aws_acm_certificate.main[0].arn : null
}

output "acm_dns_validation" {
  description = "ACM DNS validation records (only set when domain_name is set)"
  value = length(aws_acm_certificate.main) > 0 ? {
    for record in aws_acm_certificate.main[0].domain_validation_options : record.domain_name => {
      name   = record.resource_record_name
      record = record.resource_record_value
      type   = record.resource_record_type
    }
  } : null
}
