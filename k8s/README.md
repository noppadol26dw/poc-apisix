# Kubernetes Manifests for APISIX on EKS

This directory contains Kubernetes manifests for deploying APISIX API Gateway and sample applications on EKS.

## Directory Structure

```
k8s/
├── base/                   # Base configurations
│   ├── apisix-values.yaml           # Helm values for APISIX
│   ├── apisix-gateway-svc.yaml      # Gateway Service (ClusterIP)
│   ├── apisix-gateway-ingress.yaml  # Ingress for internet-facing ALB
│   └── ingressclass-alb.yaml       # IngressClass for ALB
├── apps/                    # Sample applications
│   ├── web1-deployment.yaml
│   ├── web2-deployment.yaml
│   └── services.yaml
├── routes/                  # ApisixRoute definitions
│   └── web-route.yaml
└── scripts/                 # Deployment scripts
    ├── validate.sh       # Validate manifests
    ├── deploy.sh         # Deploy resources
    └── cleanup.sh       # Cleanup resources
```

## Prerequisites

- kubectl configured to connect to EKS cluster
- helm installed
- Terraform infrastructure deployed (from `../terraform/`)

## Usage

### 1. Validate (Dry Run)

```bash
cd k8s
./scripts/validate.sh
```

This validates all manifests without applying.

### 2. Deploy

```bash
cd k8s
./scripts/deploy.sh
```

### 3. Cleanup

```bash
cd k8s
./scripts/cleanup.sh
```

## Components

### APISIX Gateway
Deployed via Helm chart from `apisix/apisix`. Includes:
- Gateway pods in private subnets
- Gateway Service (ClusterIP) + Ingress (internet-facing ALB) for CloudFront origin
- etcd storage (EBS gp3)
- Ingress controller
- Dashboard (ClusterIP only)

### Sample Applications
- web1: Returns "web1" (70% traffic)
- web2: Returns "web2" (30% traffic - Canary)

### ApisixRoute
- Route: `/web`
- Backends: web1 (70%), web2 (30%)
- Health checks: Active + passive
- Prometheus metrics enabled
