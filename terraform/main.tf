locals {
  azs           = ["ap-southeast-1a", "ap-southeast-1b", "ap-southeast-1c"]
  public_cidrs  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_cidrs = ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"]
}

module "vpc" {
  source = "./modules/vpc"

  vpc_cidr             = var.vpc_cidr
  availability_zones   = local.azs
  public_subnet_cidrs  = local.public_cidrs
  private_subnet_cidrs = local.private_cidrs
  project_name         = var.project_name
  environment          = var.environment
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

module "cloudfront" {
  source = "./modules/cloudfront"

  domain_name         = var.domain_name
  acm_certificate_arn = aws_acm_certificate.main.arn
  waf_web_acl_id      = module.waf.web_acl_id

  project_name = var.project_name
  environment  = var.environment
}

module "waf" {
  source = "./modules/waf"

  cloudfront_distribution_id = aws_cloudfront_distribution.main.id

  project_name = var.project_name
  environment  = var.environment
}

resource "aws_acm_certificate" "main" {
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

data "aws_cloudfront_distribution" "main" {
  id = aws_cloudfront_distribution.main.id
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
  project_name           = var.project_name
  environment            = var.environment
}

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
