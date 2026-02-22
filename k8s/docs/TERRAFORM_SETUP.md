# Terraform Infrastructure Setup

This guide explains how to deploy APISIX infrastructure on AWS EKS using Terraform.

## Prerequisites

- AWS CLI configured with credentials
- Terraform >= 1.0 installed
- kubectl installed
- helm installed
- AWS Route53 (for DNS validation)

## Architecture

```
Internet -> CloudFront -> WAF -> NLB (Internal) -> APISIX -> Apps
```

## Setup Steps

### 1. Configure Variables

Edit `terraform/environments/prod/terraform.tfvars`:

```hcl
aws_region        = "ap-southeast-1"
project_name       = "apisix"
environment        = "prod"
vpc_cidr          = "10.0.0.0/16"
cluster_name       = "apisix-cluster"
cluster_version    = "1.28"
node_instance_types = ["t3.medium"]
node_desired_size = 3
node_max_size     = 5
node_min_size     = 3
domain_name       = "api.example.com"  # Change to your domain
```

### 2. Configure S3 Backend

Edit `terraform/environments/prod/backend.tf` if needed:

```hcl
terraform {
  backend "s3" {
    bucket         = "apisix-terraform-state"  # Create this bucket first
    key            = "prod/terraform.tfstate"
    region         = "ap-southeast-1"
    encrypt        = true
    dynamodb_table = "apisix-terraform-locks"  # Create this table first
  }
}
```

### 3. Create S3 Bucket and DynamoDB Table (One-time)

```bash
aws s3 mb s3://apisix-terraform-state --region ap-southeast-1
aws dynamodb create-table \
  --table-name apisix-terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region ap-southeast-1
```

### 4. Validate Terraform Code

```bash
cd terraform
./scripts/validate.sh
```

This will:
- Check Terraform format
- Validate syntax
- Generate plan without applying

### 5. Review Terraform Plan

```bash
terraform show tfplan
```

Review resources that will be created:
- VPC, subnets, NAT gateways
- EKS cluster and node groups
- IAM roles and policies
- AWS Load Balancer Controller
- VPC Interface Endpoints
- ACM certificate (for DNS validation)

### 6. Deploy Infrastructure

```bash
./scripts/apply.sh
```

Wait 10-15 minutes for EKS cluster to be ready.

### 7. Validate ACM Certificate

Terraform will output DNS validation records:

```bash
terraform output -json acm_dns_validation
```

Add these CNAME records to your DNS provider (Route53):

```text
_d852b3f1234567890.api.example.com CNAME _d852b3f1234567890.abcdefghijklmnopqrstuvw.acm-validations.aws.
```

Wait for ACM certificate status to change to `ISSUED`:

```bash
aws acm describe-certificate --certificate-arn <CERT-ARN> --query 'Certificate.Status'
```

### 8. Update kubeconfig

```bash
aws eks update-kubeconfig --name apisix-cluster --region ap-southeast-1
kubectl get nodes
```

### 9. Deploy K8s Resources

See [K8S_DEPLOYMENT.md](./K8S_DEPLOYMENT.md).

## Resources Created

| Resource | Description |
|-----------|-------------|
| VPC | 10.0.0.0/16 network |
| Public Subnets (3) | For VPC endpoints, NAT gateways |
| Private Subnets (3) | For EKS nodes, APISIX pods |
| NAT Gateways (2) | EKS nodes internet access |
| Internet Gateway | Public internet access |
| Route Tables | Routing for public/private subnets |
| Security Groups | EKS nodes, NLB, VPC endpoints |
| EKS Cluster | Kubernetes control plane |
| Managed Node Groups | 3 x t3.medium nodes |
| IAM Roles | EKS cluster, nodes, LB controller |
| AWS Load Balancer Controller | Helm release in kube-system |
| VPC Interface Endpoints | CloudFront, S3, ECR |
| ACM Certificate | TLS certificate (DNS validation required) |

## Troubleshooting

### EKS Cluster Not Ready

```bash
kubectl get nodes
# If nodes are NotReady, check:
kubectl describe node <node-name>
# Check IAM roles and security groups
```

### ACM Certificate Pending Validation

- Add DNS validation records to Route53
- Wait 10-30 minutes for certificate to issue
- Verify with: `aws acm describe-certificate --certificate-arn <ARN>`

### Terraform State Lock

If Terraform fails with state lock:
```bash
# Force unlock (only if no other terraform apply is running)
aws dynamodb delete-item --table-name apisix-terraform-locks --key '{"LockID":{"S":"prod"}}'
```

### Module Not Found

```bash
# Ensure you're in terraform directory
cd terraform
terraform init -backend-config=environments/prod/backend.tf
```

## Cleanup

```bash
cd terraform
./scripts/destroy.sh
```

This will:
- Remove all AWS resources
- Delete S3 bucket (manual, must be empty first)
- Delete DynamoDB table

## Cost Considerations

Estimated monthly costs:
- EKS Cluster: $73
- EKS Nodes (3 x t3.medium): ~$50
- NAT Gateways (2): ~$64
- VPC Endpoints: ~$0.01/hour each
- S3 Storage: ~$0.023/GB
- DynamoDB: $0.25/GB stored + request fees

Total: ~$200/month (before CloudFront, WAF, NLB)
