locals {
  azs = ["ap-southeast-1a", "ap-southeast-1b", "ap-southeast-1c"]
}

module "vpc" {
  source = "./modules/vpc"

  vpc_cidr             = var.vpc_cidr
  availability_zones   = local.azs
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  project_name         = var.project_name
  environment          = var.environment
  cluster_name         = var.cluster_name
}

module "eks" {
  source = "./modules/eks"

  cluster_name                = var.cluster_name
  cluster_version             = var.cluster_version
  vpc_id                      = module.vpc.vpc_id
  private_subnet_ids          = module.vpc.private_subnet_ids
  node_instance_types         = var.node_instance_types
  node_desired_size           = var.node_desired_size
  node_max_size               = var.node_max_size
  node_min_size               = var.node_min_size
  eks_nodes_security_group_id = module.vpc.eks_nodes_security_group_id
  project_name                = var.project_name
  environment                 = var.environment
}

module "vpc_endpoints" {
  source = "./modules/vpc-endpoints"

  vpc_id                          = module.vpc.vpc_id
  private_subnet_ids              = module.vpc.private_subnet_ids
  route_table_ids                 = module.vpc.private_route_table_ids
  vpc_endpoints_security_group_id = module.vpc.vpc_endpoints_security_group_id
  project_name                    = var.project_name
  environment                     = var.environment
  aws_region                      = var.aws_region
}

data "aws_eks_cluster" "main" {
  name = module.eks.cluster_name

  depends_on = [
    module.eks
  ]
}

# ALB created by Ingress (AWS LB controller). Tags: elbv2.k8s.aws/cluster, ingress.k8s.aws/resource
data "aws_lbs" "apisix_alb" {
  tags = {
    "elbv2.k8s.aws/cluster"     = var.cluster_name
    "ingress.k8s.aws/resource"  = "${var.k8s_gateway_namespace}/${var.k8s_gateway_service_name}"
  }
}

data "aws_lb" "apisix_alb" {
  for_each = toset(data.aws_lbs.apisix_alb.arns)
  arn      = each.value
}

locals {
  # Use ALB DNS when found; otherwise fallback to var.alb_dns_name (e.g. placeholder)
  cloudfront_origin_dns = length(data.aws_lbs.apisix_alb.arns) > 0 ? values(data.aws_lb.apisix_alb)[0].dns_name : var.alb_dns_name
}

module "cloudfront" {
  source = "./modules/cloudfront"

  origin_dns_name     = local.cloudfront_origin_dns
  domain_name         = var.domain_name
  acm_certificate_arn = var.domain_name != "" ? aws_acm_certificate.main[0].arn : null
  waf_web_acl_id      = module.waf.web_acl_id

  project_name = var.project_name
  environment  = var.environment
}

module "waf" {
  source = "./modules/waf"

  project_name = var.project_name
  environment  = var.environment

  providers = {
    aws = aws.us_east_1
  }
}

# ACM certificate for CloudFront (only when using custom domain; must be in us-east-1)
resource "aws_acm_certificate" "main" {
  count             = var.domain_name != "" ? 1 : 0
  provider          = aws.us_east_1
  domain_name       = var.domain_name
  validation_method = "DNS"

  subject_alternative_names = [
    "*.${var.domain_name}",
    "www.${var.domain_name}"
  ]

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name        = "${var.project_name}-${var.domain_name}"
    Project     = var.project_name
    Environment = var.environment
  }
}


data "aws_eks_cluster_auth" "main" {
  name = module.eks.cluster_name

  depends_on = [module.eks]
}

module "lb_controller" {
  source = "./modules/lb-controller"

  cluster_name           = module.eks.cluster_name
  cluster_endpoint       = module.eks.cluster_endpoint
  cluster_ca_certificate = module.eks.cluster_ca_certificate
  oidc_provider_arn      = module.eks.oidc_provider_arn
  vpc_id                 = module.vpc.vpc_id
  project_name           = var.project_name
  environment            = var.environment
}

# WAF is attached to CloudFront via distribution's web_acl_id (in cloudfront module), not via aws_wafv2_web_acl_association.
# aws_wafv2_web_acl_association is only for regional resources (ALB, API Gateway, etc.), not CloudFront.

# resource "aws_s3_bucket" "terraform_state" {
#   bucket = "${var.project_name}-terraform-state"

#   versioning {
#     enabled = true
#   }

#   server_side_encryption_configuration {
#     rule {
#       apply_server_side_encryption_by_default = true
#     }
#   }

#   tags = {
#     Name        = "${var.project_name}-terraform-state"
#     Project     = var.project_name
#     Environment = var.environment
#   }
# }

# resource "aws_dynamodb_table" "terraform_locks" {
#   name         = "${var.project_name}-terraform-locks"
#   billing_mode = "PAY_PER_REQUEST"
#   hash_key     = "LockID"
#   attribute {
#     name = "LockID"
#     type = "S"
#   }

#   tags = {
#     Project     = var.project_name
#     Environment = var.environment
#   }
# }
