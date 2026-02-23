#!/bin/bash
set -e

echo "Validating Kubernetes manifests..."

# Validate Helm values
echo "Validating APISIX Helm values..."
helm template apisix apisix/apisix -f base/apisix-values.yaml > /dev/null

# Validate K8s manifests with dry-run
echo "Validating IngressClass alb..."
kubectl apply --dry-run=server -f base/ingressclass-alb.yaml
echo "Validating APISIX gateway Service and Ingress..."
kubectl apply --dry-run=server -f base/apisix-gateway-svc.yaml
kubectl apply --dry-run=server -f base/apisix-gateway-ingress.yaml

echo "Validating sample applications..."
kubectl apply --dry-run=server -f apps/configmaps.yaml
kubectl apply --dry-run=server -f apps/services.yaml
kubectl apply --dry-run=server -f apps/web1-deployment.yaml
kubectl apply --dry-run=server -f apps/web2-deployment.yaml

echo "Validating ApisixRoute..."
kubectl apply --dry-run=server -f routes/web-route.yaml

echo ""
echo "Validation passed! All manifests are valid."
echo ""
echo "To deploy:"
echo "  ./scripts/deploy.sh"
