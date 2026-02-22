#!/bin/bash
set -e

echo "Deploying APISIX and applications to Kubernetes..."

# Create namespace
kubectl create namespace apisix --dry-run=client 2>/dev/null || true

# Deploy APISIX via Helm
echo "Deploying APISIX..."
helm upgrade --install apisix apisix/apisix \
  -n apisix \
  -f base/apisix-values.yaml \
  --wait \
  --timeout 10m

# Deploy NLB service
echo "Deploying NLB service..."
kubectl apply -f base/apisix-gateway-svc.yaml

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

# Print NLB DNS name
echo ""
echo "Deployment complete!"
echo ""
echo "NLB DNS name:"
kubectl get svc apisix-gateway -n apisix -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
echo ""
echo "To test the route:"
echo "  curl http://<NLB-DNS-NAME>/web"
echo ""
echo "Note: Replace <NLB-DNS-NAME> with the actual DNS name above"
