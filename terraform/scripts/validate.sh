#!/bin/bash
set -e

echo "Validating Terraform configuration..."

# Check format
echo "Checking Terraform format..."
terraform fmt -check -recursive

# Validate syntax
echo "Validating Terraform syntax..."
terraform init -backend-config=environments/prod/backend.tf
terraform validate

# Generate plan for review
echo "Generating Terraform plan..."
terraform plan -out=tfplan

echo ""
echo "Validation passed! Review the plan file:"
echo "  terraform show tfplan"
echo ""
echo "To apply infrastructure:"
echo "  ./scripts/apply.sh"
