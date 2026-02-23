# Kubernetes Deployment for APISIX on EKS

This guide explains how to deploy APISIX API Gateway and sample applications to EKS cluster.

## Prerequisites

- Terraform infrastructure deployed (see [TERRAFORM_SETUP.md](./TERRAFORM_SETUP.md))
- kubectl configured to EKS cluster
- helm installed

```

## Setup Steps

### 1. Validate K8s Manifests

```bash
cd k8s
./scripts/validate.sh
```

This validates all manifests without applying:
- Helm values rendering
- K8s resource validation with dry-run

### 2. Deploy APISIX and Applications

```bash
cd k8s
./scripts/deploy.sh
```

This will:
- Create apisix namespace
- Deploy APISIX via Helm (gateway, etcd, ingress controller, dashboard)
- Deploy gateway Service (ClusterIP) and Ingress (internet-facing ALB)
- Deploy sample applications (web1, web2)
- Deploy ApisixRoute with canary (70:30)

Wait 5-10 minutes for all pods to be ready.

### 3. Verify Deployment

```bash
# Check pods
kubectl get pods -n apisix
kubectl get pods -n default

# Check services
kubectl get svc -n apisix
kubectl get svc -n default

# Check ALB DNS name (from Ingress)
kubectl get ingress apisix-gateway -n apisix -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

Expected output:
- apisix namespace: APISIX pods, etcd pods, ingress controller, dashboard
- default namespace: web1, web2 pods
- Ingress: ADDRESS set to ALB DNS (internet-facing)

### 4. Test ALB or CloudFront Access

```bash
# Get ALB DNS name
ALB_DNS=$(kubectl get ingress apisix-gateway -n apisix -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

# Test routing (via ALB)
curl http://$ALB_DNS/web

# Or test via CloudFront (after terraform apply)
# curl https://<cloudfront-domain>/web

# Test multiple times for canary
for i in {1..10}; do
  curl -s http://$ALB_DNS/web
done
```

Expected: 70% "web1", 30% "web2" responses.

### 5. Check Health Status

```bash
# APISIX control API
curl -s http://$ALB_DNS:9092/v1/healthcheck | jq .
```

Should show health status for upstreams (web1, web2).

### 6. Access Dashboard (ClusterIP + Port Forward)

```bash
# Port forward to dashboard
kubectl port-forward svc/apisix-dashboard 9000:9000 -n apisix

# Access at http://localhost:9000
# Login: admin / admin
```

Note: Dashboard is ClusterIP only, requires port forward or VPN.

## Components

### APISIX Gateway

Deployed via Helm chart `apisix/apisix`.

Configuration:
- Gateway pods: 2 replicas
- etcd: 3 replicas, EBS gp3 storage
- Ingress controller: enabled
- Dashboard: enabled (ClusterIP)
- Prometheus plugin: enabled (port 9091)
- Admin API: enabled (port 9180)

### Gateway Service (ClusterIP) + Ingress (ALB)

- **Service** `apisix-gateway`: ClusterIP, ports 80→9080, 443→9443, admin 9180, control 9092.
- **Ingress** `apisix-gateway`: Uses IngressClass `alb`; AWS Load Balancer Controller creates an **internet-facing ALB**.
  - Annotations: `alb.ingress.kubernetes.io/scheme: internet-facing`, `alb.ingress.kubernetes.io/target-type: ip`
  - Backend: service `apisix-gateway`, port 80.
- Terraform discovers the ALB by tag `ingress.k8s.aws/resource = apisix/apisix-gateway` and sets it as CloudFront origin.

### Sample Applications

**web1**: nginx container returning "web1"
- Deployment: 2 replicas
- Service: ClusterIP, port 80

**web2**: nginx container returning "web2"
- Deployment: 2 replicas
- Service: ClusterIP, port 80

### ApisixRoute

Route: `/web`

Backends:
- web1-svc: 70% weight
- web2-svc: 30% weight (canary)

Health checks:
- Active: HTTP, path `/`, interval 2s, 2 successes -> healthy
- Passive: HTTP statuses [200, 201], 3 successes -> healthy
- Passive: HTTP statuses [500, 502, 503], 3 failures -> unhealthy

Plugins:
- prometheus: enabled (metrics export)

## Canary Deployment

The ApisixRoute uses 70:30 weight split for canary deployment.

To test:
```bash
# Call multiple times
for i in {1..20}; do
  curl -s http://$ALB_DNS/web
done | sort | uniq -c
```

Expected output:
```
  14 web1
   6 web2
```

To adjust canary weights:
```bash
kubectl edit apisixeroute web-route -n default
# Adjust weights in backends section
```

## Health Checks

APISIX performs active and passive health checks on upstreams.

### Active Health Checks

- Probes every 2 seconds (healthy) or 1 second (unhealthy)
- HTTP request to `/` on each upstream
- After 2 successes -> mark healthy
- After 2 failures -> mark unhealthy

### Passive Health Checks

- Monitors actual request responses
- 200/201 responses count as healthy
- 500/502/503 responses count as unhealthy
- After 3 successes -> mark healthy
- After 3 failures -> mark unhealthy

### Check Health Status

```bash
# Get ALB DNS (from Ingress)
ALB_DNS=$(kubectl get ingress apisix-gateway -n apisix -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

# Get health status
curl -s http://$ALB_DNS:9092/v1/healthcheck | jq .
```

## Troubleshooting

### Pods Not Ready

```bash
kubectl describe pod <pod-name> -n <namespace>

# Common issues:
# - Image pull errors: Check ECR access, IAM permissions
# - Resource limits: Check node capacity
# - CrashLoopBackOff: Check logs, verify config
```

### ALB / Ingress Not Creating

```bash
# Check AWS Load Balancer Controller logs
kubectl logs -n kube-system deployment/aws-load-balancer-controller

# Check Ingress status and events
kubectl describe ingress apisix-gateway -n apisix

# Check IAM role and security groups (controller needs ec2:CreateSecurityGroup, elasticloadbalancing:CreateLoadBalancer, etc.)
```

### Routing Not Working

```bash
# Check ApisixRoute
kubectl get apisixeroute -n default -o yaml

# Check backend services
kubectl get svc -n default

# Check service endpoints
kubectl get endpoints web1-svc -n default

# Test backend directly
kubectl run curl --rm -it --image=curlimages/curl -- sh
curl web1-svc:80
```

### Health Check Failing

```bash
# Check ApisixRoute health check config
kubectl get apisixeroute web-route -n default -o yaml

# Check if upstream services are responding
kubectl run curl --rm -it --image=curlimages/curl -- sh
curl web1-svc:80
```

## Cleanup

```bash
cd k8s
./scripts/cleanup.sh
```

This will remove:
- ApisixRoute
- Sample applications (web1, web2)
- Ingress (ALB) and gateway Service
- APISIX Helm release

Note: Namespace `apisix` will not be deleted by default.

## Next Steps

After K8s deployment:
1. Deploy CloudFront distribution and WAF (via Terraform)
2. Configure DNS for CloudFront domain
3. Test end-to-end with CloudFront + WAF
4. Enable TLS for CloudFront

See [TERRAFORM_SETUP.md](./TERRAFORM_SETUP.md) for CloudFront and WAF deployment.
