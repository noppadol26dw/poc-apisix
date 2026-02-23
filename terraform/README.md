# Terraform Infrastructure for APISIX on AWS EKS

This directory contains Terraform modules and configuration for deploying APISIX API Gateway on AWS EKS with production-grade security.

## Architecture

```
Internet -> CloudFront -> WAF -> ALB -> APISIX -> Apps
```

## Directory Structure

```
terraform/
├── modules/              # Reusable Terraform modules
│   ├── vpc/           # VPC, subnets, NAT gateways
│   ├── eks/           # EKS cluster and node groups
│   ├── cloudfront/     # CloudFront distribution
│   ├── waf/          # WAF Web ACL
│   ├── vpc-endpoints/  # VPC Interface Endpoints
│   └── lb-controller/ # AWS Load Balancer Controller
├── main.tf             # Root module entry point
├── providers.tf        # Provider configuration
├── variables.tf        # Input variables
├── outputs.tf         # Output values
├── acm.tf            # ACM certificate
├── environments/      # Environment-specific configs
│   └── prod/
│       ├── backend.tf   # S3 backend for state
│       └── terraform.tfvars
└── scripts/          # Deployment scripts
    ├── validate.sh   # Validate Terraform code
    ├── apply.sh      # Apply infrastructure
    └── destroy.sh    # Destroy infrastructure
```

## Usage

### 1. Validate (Dry Run)

```bash
cd terraform
terraform init -backend-config=environments/prod/backend.tf
./scripts/validate.sh
```

This will:
- Check Terraform format
- Validate syntax
- Generate plan without applying

### 2. Deploy Infrastructure

```bash
./scripts/apply.sh
```

### 3. Destroy Infrastructure

```bash
./scripts/destroy.sh
```

## Modules

Each module is self-contained and can be used independently or as part of the full stack.

### VPC Module
Creates VPC with public and private subnets.

### EKS Module
Creates EKS cluster and managed node groups.

### CloudFront Module
Creates CloudFront distribution with WAF.

### WAF Module
Creates WAF Web ACL with OWASP rules.

### VPC Endpoints Module
Creates VPC Interface Endpoints for private CloudFront access.

### Load Balancer Controller Module
Installs AWS Load Balancer Controller via Helm.

## Security

- All EKS nodes and APISIX pods run in private subnets
- ALB is internet-facing as CloudFront origin
- VPC Interface Endpoints for private CloudFront access
- IAM roles follow least privilege principle
