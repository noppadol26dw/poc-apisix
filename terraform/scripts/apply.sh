#!/bin/bash
set -e

echo "Applying Terraform infrastructure..."

# Initialize
terraform init -backend-config=environments/prod/backend.tf

# Apply
terraform apply -auto-approve

# Save outputs for K8s deployment
terraform output -json > terraform-outputs.json

echo ""
echo "Infrastructure applied successfully!"
echo ""
echo "Outputs saved to terraform-outputs.json"
echo ""
echo "Next steps:"
echo "  1. Update kubeconfig: aws eks update-kubeconfig --name $(terraform output -raw cluster_name)"
echo "  2. Deploy K8s resources: cd ../k8s && ./scripts/deploy.sh"
echo "  3. Deploy CloudFront and WAF: terraform apply -target=module.cloudfront -target=module.waf"
