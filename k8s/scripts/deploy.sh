#!/bin/bash
set -e

# Run from k8s/ so paths base/, apps/, routes/ resolve correctly
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR/.."

echo "Deploying APISIX and applications to Kubernetes..."

# Wait for AWS Load Balancer Controller webhook (required for ALB Ingress)
echo "Waiting for AWS Load Balancer Controller webhook..."
if ! kubectl get deployment aws-load-balancer-controller -n kube-system &>/dev/null; then
  echo "Error: AWS Load Balancer Controller not found. Run Terraform apply first (terraform apply), then retry."
  exit 1
fi
kubectl wait deployment/aws-load-balancer-controller -n kube-system --for=condition=available --timeout=120s
echo "AWS Load Balancer Controller is ready."

# Create namespace (ignore if already exists)
kubectl create namespace apisix 2>/dev/null || true

# Deploy APISIX via Helm (only when not yet installed; avoids StatefulSet conflict after manual patch)
if ! helm list -n apisix -q 2>/dev/null | grep -qx apisix; then
  echo "Deploying APISIX (first install)..."
  helm repo add apisix https://apache.github.io/apisix-helm-chart 2>/dev/null || true
  helm repo update
  helm upgrade --install apisix apisix/apisix \
    -n apisix \
    -f base/apisix-values.yaml \
    --no-hooks
else
  echo "APISIX release exists, skipping Helm (use 'helm upgrade' manually to update chart)."
fi

# Ensure IngressClass alb exists (for ALB Ingress)
kubectl apply -f base/ingressclass-alb.yaml

# Deploy gateway Service (ClusterIP) and Ingress (ALB)
echo "Deploying gateway Service and Ingress (ALB)..."
kubectl apply -f base/apisix-gateway-svc.yaml
kubectl apply -f base/apisix-gateway-ingress.yaml

# Deploy sample applications
echo "Deploying sample applications..."
kubectl apply -f apps/configmaps.yaml
kubectl apply -f apps/services.yaml
kubectl apply -f apps/web1-deployment.yaml
kubectl apply -f apps/web2-deployment.yaml

# Wait for pods to be ready
echo "Waiting for pods to be ready..."
kubectl wait --for=condition=ready pod -l app=web1 -n default --timeout=2m
kubectl wait --for=condition=ready pod -l app=web2 -n default --timeout=2m
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=apisix -n apisix --timeout=5m

# Deploy ApisixRoute
echo "Deploying ApisixRoute..."
kubectl apply -f routes/web-route.yaml

# Print ALB DNS name (from Ingress)
echo ""
echo "Deployment complete!"
echo ""
echo "ALB DNS name (Ingress):"
kubectl get ingress apisix-gateway -n apisix -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
echo ""
echo "To test the route (via ALB or CloudFront):"
echo "  curl http://<ALB-DNS-NAME>/web"
echo ""
echo "Note: Run 'terraform apply' to update CloudFront origin to this ALB, then test via CloudFront URL."
