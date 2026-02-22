#!/bin/bash
set -e

read -p "Are you sure you want to destroy all infrastructure? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
  echo "Destroy cancelled."
  exit 0
fi

echo "Destroying Terraform infrastructure..."

terraform init -backend-config=environments/prod/backend.tf
terraform destroy -auto-approve

echo "Infrastructure destroyed successfully!"
