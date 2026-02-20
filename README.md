# poc-apisix

APISIX API gateway with etcd, two nginx upstreams, Prometheus, and Zipkin.

## Prerequisites

- Docker and Docker Compose

## Quick start

**arm64 (Apple Silicon):**

```bash
docker compose -f docker-compose-arm64.yml up -d
```

**amd64 (x86):**

```bash
docker compose up -d
```

## Services

| Service    | Port  | Description              |
|-----------|-------|--------------------------|
| APISIX    | 9080, 9180, 9091, 9443 | API gateway              |
| etcd      | 2379  | Config store             |
| web1      | 9081  | Upstream nginx           |
| web2      | 9082  | Upstream nginx           |
| Prometheus| 9090  | Metrics (arm64 stack)    |
| Zipkin    | 9411  | Tracing (arm64 stack)    |
| Grafana   | 3000  | Dashboards (arm64 stack) |

## Config

| Path | Purpose |
|------|---------|
| `apisix_conf/config.yaml` | APISIX (etcd, admin keys) |
| `upstream/web1.conf`, `web2.conf` | nginx upstreams |
| `prometheus_conf/prometheus.yml` | Prometheus scrape (APISIX 9091) |

## Docs

| Doc | Content |
|-----|---------|
| [docs/EXPOSE_API.md](docs/EXPOSE_API.md) | Upstream, route, proxy to httpbin |
| [docs/PROTECT_API.md](docs/PROTECT_API.md) | Rate limit (limit-count) |
| [docs/OBSERVE_API.md](docs/OBSERVE_API.md) | Logs, Prometheus metrics, Zipkin tracing |
| [docs/GRAFANA.md](docs/GRAFANA.md) | Grafana login, first chart, dashboards |

## Full stack (amd64)

`docker-compose.yml` adds Prometheus (9090) and Grafana (3000). Needs `prometheus_conf/` and `grafana_conf/` in place.
