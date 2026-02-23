output "s3_endpoint_id" {
  description = "VPC endpoint ID for S3"
  value       = aws_vpc_endpoint.s3.id
}
