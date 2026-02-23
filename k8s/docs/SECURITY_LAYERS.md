# Security Layers for APISIX on AWS EKS

This document explains the multi-layer security architecture for APISIX API Gateway on AWS EKS.

## Architecture Overview

```
Internet Users
    │
    ▼ Layer 1
CloudFront (Global CDN)
    │
    ├─► DDoS Protection (L3/L4)
    ├─► Geographic Distribution
    └─► Static Content Caching
    │
    ▼ Layer 2
AWS WAF (Web Application Firewall)
    │
    ├─► OWASP Top 10
    ├─► SQL Injection Protection
    ├─► XSS Protection
    ├─► CSRF Protection
    ├─► Rate Limiting (per IP)
    └─► Bot Protection
    │
    ▼ Layer 3
AWS ALB (CloudFront Origin)
    │
    ├─► Internet-facing (WAF in front)
    ├─► L7 Load Balancing
    └─► Ingress → APISIX Service
    │
    ▼ Layer 4
APISIX Gateway Pods (Private Subnets)
    │
    ├─► Per-API Rate Limiting
    ├─► Authentication (JWT, API Keys)
    ├─► Authorization
    ├─► Request/Response Plugins
    └─► Canary Deployments
    │
    ▼ Layer 5
Application Services (Private Network)
    │
    └─► No Direct Internet Access
```

## Layer 1: CloudFront

### Purpose

Global CDN and DDoS protection at edge.

### Security Features

- **L3/L4 DDoS Protection**: Shields against volumetric attacks
- **Geographic Distribution**: 400+ edge locations worldwide
- **Static Content Caching**: Reduces origin load
- **TLS Termination**: End-to-end encryption from users
- **Origin Failover**: Automatic failover to backup origins

### Configuration

- Distribution: Global edge locations
- Cache Behavior: GET cached, POST/PUT/DELETE forwarded
- Price Class: All edge locations (no restriction)
- TLS: ACM certificate (us-east-1 required)
- Origin Access: VPC Interface Endpoint (private)

### Benefits

- Reduced latency (global edge locations)
- DDoS mitigation (AWS shield standard)
- Cost savings (cached requests)
- Scalability (handles millions of requests)

## Layer 2: AWS WAF

### Purpose

Application-level security and request filtering.

### Security Features

**OWASP Top 10 Rule Group:**
- SQL Injection (SQLi)
- Cross-Site Scripting (XSS)
- Cross-Site Request Forgery (CSRF)
- Remote File Inclusion (RFI)
- Local File Inclusion (LFI)
- Command Injection
- Insecure Deserialization
- XML External Entities (XXE)
- Broken Access Control
- Security Misconfiguration

**Rate Limiting Rule:**
- 2000 requests per 5 minutes per IP
- Block suspicious IP addresses
- Mitigate DDoS at application layer

**Managed Rule Groups:**
- Common rule set: Core attack patterns
- Known bad inputs: Malformed requests
- Linux rule set: OS-specific exploits (if applicable)

### Configuration

- Association: Linked to CloudFront distribution
- Capacity: 600 WAF capacity units
- Rate Limit: 2000 req/5min per IP
- Metrics: CloudWatch integration enabled

### Benefits

- OWASP compliance
- Application-level DDoS protection
- Fine-grained request filtering
- Real-time threat detection

## Layer 3: AWS ALB (CloudFront Origin)

### Purpose

Application Load Balancer as CloudFront origin; WAF sits in front. Created by AWS Load Balancer Controller from Ingress.

### Security Features

- **Internet-facing**: CloudFront and WAF terminate first; ALB receives filtered traffic
- **Target Type: IP**: Direct to APISIX pod IPs
- **Ingress-driven**: Single Ingress (e.g. apisix-gateway) provisions ALB
- **Health Checks**: ALB health checks to APISIX pods

### Configuration

```yaml
# Ingress (alb ingress class)
annotations:
  alb.ingress.kubernetes.io/scheme: internet-facing
  alb.ingress.kubernetes.io/target-type: ip
spec:
  ingressClassName: alb
```

### Benefits

- L7 routing and health checks
- Single ALB for APISIX (Ingress)
- CloudFront + WAF in front reduce direct exposure

## Layer 4: APISIX Gateway

### Purpose

API gateway with per-API security and traffic management.

### Security Features

**Rate Limiting:**
- Per-route rate limits (limit-count plugin)
- Per-IP, per-API-key, per-consumer
- Configurable time windows (second, minute, hour)

**Authentication & Authorization:**
- JWT authentication (jwt-auth plugin)
- API key authentication (key-auth plugin)
- Consumer-based access control

**Plugins:**
- CORS: Cross-origin resource sharing
- Request/Response headers: Custom headers
- Proxy rewrite: URL/path transformation
- IP restriction: Allow/deny by IP
- Referer restriction: Prevent hotlinking

**Health Checks:**
- Active: Periodic probes to upstreams
- Passive: Monitor actual request responses
- Automatic failover: Remove unhealthy backends

### Configuration

```yaml
plugins:
  - name: limit-req
    enable: true
    config:
      rate: 100
      burst: 50
      key_type: "var"
      rejected_code: 429
      rejected_msg: "Too many requests"
```

### Benefits

- Fine-grained API security
- Per-route rate limiting
- Authentication and authorization
- Real-time traffic monitoring
- Automatic upstream failover

## Layer 5: Application Services

### Purpose

Backend services running in private network.

### Security Features

- **Private Subnets**: No direct internet access
- **ClusterIP Services**: Services only accessible within cluster
- **Network Policies**: Kubernetes network policies (if enabled)
- **Service Mesh**: Optional service mesh integration

### Configuration

```yaml
apiVersion: v1
kind: Service
spec:
  type: ClusterIP  # Only accessible within cluster
  selector:
    app: web1
```

### Benefits

- No direct internet access
- Cluster-level isolation
- Service-level segmentation
- Network policy enforcement

## Defense in Depth

### Layer Responsibility

| Layer | Threats Mitigated | Protection Mechanism |
|--------|------------------|---------------------|
| CloudFront | Volumetric DDoS, latency | Shield Standard, caching |
| WAF | SQLi, XSS, CSRF, bot attacks | OWASP rules, rate limiting |
| ALB | Origin exposure | WAF in front, L7 health checks |
| APISIX | API abuse, unauthorized access | Rate limiting, auth, plugins |
| Applications | Data breaches, injection | Private network, service isolation |

### Attack Path Analysis

```
Attacker -> CloudFront
  └─► Blocked by DDoS protection
       └─► Allowed -> WAF
          └─► Blocked by OWASP rules
               └─► Blocked by rate limiting
                    └─► Allowed -> ALB (CloudFront origin)
                          └─► APISIX Gateway
                             └─► Blocked by rate limiting
                                  └─► Blocked by auth
                                       └─► Allowed -> Private Apps
                                          └─► Private network only
```

## Monitoring & Logging

### CloudWatch Metrics

- EKS metrics: CPU, memory, network
- ALB metrics: Active connections, request count, target response time
- CloudFront metrics: Requests, errors, latency
- WAF metrics: Blocked requests, allowed requests, rate limit exceeded

### Logging

- **CloudFront Access Logs**: S3 bucket (all requests)
- **WAF Logs**: S3 bucket (blocked/allowed requests)
- **EKS Logs**: CloudWatch Logs (pod logs)
- **APISIX Metrics**: Prometheus plugin (port 9091) -> CloudWatch

### Alerts

- High error rate (CloudFront)
- WAF block rate exceeds threshold
- ALB unhealthy target count
- APISIX rate limit exceeded
- EKS node resource exhaustion

## Compliance

### SOC 2 Compliance

- Access logging and retention
- Monitoring and alerting
- Network segmentation
- Least privilege IAM roles

### PCI DSS

- TLS encryption in transit
- No cardholder data exposure
- Regular security updates
- Access control and authentication

### GDPR

- Data encryption at rest and in transit
- Access logging and audit trails
- Data minimization
- Right to be forgotten (data retention policies)

## Best Practices

### 1. Defense in Depth

Multiple security layers (not single point of failure).

### 2. Least Privilege

IAM roles with minimal required permissions.

### 3. Network Segmentation

Private subnets for workloads, VPC endpoints for AWS services.

### 4. Monitoring & Alerting

Comprehensive logging and real-time alerts.

### 5. Regular Updates

Keep APISIX, EKS, and AWS services updated.

### 6. Security Testing

- Penetration testing
- Vulnerability scanning
- Red team exercises

### 7. Incident Response

- Playbooks for common attacks
- Automated blocking (WAF, APISIX)
- Post-incident analysis

## Cost vs Security

| Security Feature | Monthly Cost | Protection Level |
|------------------|---------------|------------------|
| CloudFront (Shield Standard) | Included | DDoS protection |
| WAF | $5 + $0.60M reqs | OWASP, rate limiting |
| ALB | ~$22 | Load balancing (CloudFront origin) |
| Private Subnets | No extra cost | Network isolation |
| VPC Endpoints | ~$0.01/hour | Private access |

**Total:** ~$30-50/month for enhanced security

## Summary

This architecture provides defense in depth with 5 security layers:

1. **CloudFront**: Global CDN + DDoS protection
2. **WAF**: OWASP compliance + rate limiting
3. **ALB**: CloudFront origin, L7 load balancing to APISIX
4. **APISIX**: Per-API security (rate limit, auth)
5. **Private Apps**: Network isolation

Each layer provides different protection mechanisms, creating a robust security posture for production API deployments.
