# Kubernetes Deployment for APISIX on EKS

This guide explains how to deploy APISIX API Gateway and sample applications to EKS cluster.

## Prerequisites

- Terraform infrastructure deployed (see [TERRAFORM_SETUP.md](./TERRAFORM_SETUP.md))
- kubectl configured to EKS cluster
- helm installed

## Architecture

```
CloudFront -> WAF -> NLB (Internal) -> APISIX Gateway
                                            |
                                            v
                                    APISIX Ingress Controller
                                            |
                                            v
                                    web1 (70%) + web2 (30%)
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
- Deploy NLB Internal service
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

# Check NLB DNS name
kubectl get svc apisix-gateway -n apisix -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

Expected output:
- apisix namespace: APISIX pods, etcd pods, ingress controller, dashboard
- default namespace: web1, web2 pods
- NLB: LoadBalancer type with internal scheme

### 4. Test NLB Direct Access

```bash
# Get NLB DNS name
NLB_DNS=$(kubectl get svc apisix-gateway -n apisix -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

# Test routing
curl http://$NLB_DNS/web

# Test multiple times for canary
for i in {1..10}; do
  curl -s http://$NLB_DNS/web
done
```

Expected: 70% "web1", 30% "web2" responses.

### 5. Check Health Status

```bash
# APISIX control API
curl -s http://$NLB_DNS:9092/v1/healthcheck | jq .
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

### NLB Internal Service

Service type: LoadBalancer with internal scheme.

Annotations:
- `aws-load-balancer-type: nlb`
- `aws-load-balancer-nlb-target-type: ip`
- `aws-load-balancer-scheme: internal`
- `externalTrafficPolicy: Local` (preserve source IP)

Health checks:
- Protocol: HTTP
- Path: `/apisix/admin/upstream`
- Interval: 10s
- Timeout: 5s
- Thresholds: 3 healthy, 2 unhealthy

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
  curl -s http://$NLB_DNS/web
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
# Get NLB DNS
NLB_DNS=$(kubectl get svc apisix-gateway -n apisix -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

# Get health status
curl -s http://$NLB_DNS:9092/v1/healthcheck | jq .
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

### NLB Not Creating

```bash
# Check AWS Load Balancer Controller logs
kubectl logs -n kube-system deployment/aws-load-balancer-controller

# Check IAM role
aws iam get-role --role-name <role-name>

# Check security groups
aws ec2 describe-security-groups --group-ids <sg-id>
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
- NLB service
- APISIX Helm release

Note: Namespace `apisix` will not be deleted by default.

## Next Steps

After K8s deployment:
1. Deploy CloudFront distribution and WAF (via Terraform)
2. Configure DNS for CloudFront domain
3. Test end-to-end with CloudFront + WAF
4. Enable TLS for CloudFront

See [TERRAFORM_SETUP.md](./TERRAFORM_SETUP.md) for CloudFront and WAF deployment.
