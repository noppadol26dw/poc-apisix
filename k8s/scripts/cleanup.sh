#!/bin/bash
set -e

read -p "Are you sure you want to clean up all K8s resources? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
  echo "Cleanup cancelled."
  exit 0
fi

echo "Cleaning up Kubernetes resources..."

# Delete ApisixRoute
echo "Deleting ApisixRoute..."
kubectl delete -f routes/web-route.yaml --ignore-not-found=true

# Delete sample applications
echo "Deleting sample applications..."
kubectl delete -f apps/web1-deployment.yaml --ignore-not-found=true
kubectl delete -f apps/web2-deployment.yaml --ignore-not-found=true
kubectl delete -f apps/services.yaml --ignore-not-found=true
kubectl delete -f apps/configmaps.yaml --ignore-not-found=true

# Delete NLB service
echo "Deleting NLB service..."
kubectl delete -f base/apisix-gateway-svc.yaml --ignore-not-found=true

# Uninstall APISIX Helm release
echo "Uninstalling APISIX..."
helm uninstall apisix -n apisix --ignore-not-found

# Delete namespace (optional - comment out to keep namespace)
# kubectl delete namespace apisix --ignore-not-found=true

echo "Cleanup complete!"
