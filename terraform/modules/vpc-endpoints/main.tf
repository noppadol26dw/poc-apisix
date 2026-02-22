resource "aws_vpc_endpoint" "cloudfront" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${var.aws_region}.cloudfront"
  vpc_endpoint_type = "Interface"
  subnet_ids        = [var.private_subnet_ids[0]]

  security_group_ids = [var.vpc_endpoints_security_group_id]

  private_dns_enabled = true

  tags = {
    Name        = "${var.project_name}-${var.environment}-cloudfront-endpoint"
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"

  tags = {
    Name        = "${var.project_name}-${var.environment}-s3-endpoint"
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${var.aws_region}.ecr.dkr"
  vpc_endpoint_type = "Interface"
  subnet_ids        = var.private_subnet_ids

  security_group_ids = [var.vpc_endpoints_security_group_id]

  private_dns_enabled = true

  tags = {
    Name        = "${var.project_name}-${var.environment}-ecr-dkr-endpoint"
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${var.aws_region}.ecr.api"
  vpc_endpoint_type = "Interface"
  subnet_ids        = var.private_subnet_ids

  security_group_ids = [var.vpc_endpoints_security_group_id]

  private_dns_enabled = true

  tags = {
    Name        = "${var.project_name}-${var.environment}-ecr-api-endpoint"
    Project     = var.project_name
    Environment = var.environment
  }
}
