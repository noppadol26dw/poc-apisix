output "cloudfront_endpoint_id" {
  description = "VPC endpoint ID for CloudFront"
  value       = aws_vpc_endpoint.cloudfront.id
}

output "s3_endpoint_id" {
  description = "VPC endpoint ID for S3"
  value       = aws_vpc_endpoint.s3.id
}
