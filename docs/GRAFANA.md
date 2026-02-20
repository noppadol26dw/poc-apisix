# Grafana

Grafana is in the arm64 stack. Prometheus is pre-configured as a datasource.

## Prerequisites

- Stack running with Prometheus (see [README](../README.md)).
- At least one route with the **prometheus** plugin enabled and some traffic (see [OBSERVE_API.md](OBSERVE_API.md) -> Metrics).

## Start

```bash
docker compose -f docker-compose-arm64.yml up -d
```

- **URL:** http://localhost:3000  
- **Login:** `admin` / `admin` (first time you may be asked to set a new password; you can skip or set one)

## First chart

1. **Explore** (compass icon in the left menu) -> choose datasource **Prometheus** (already set).
2. In **Query**, enter:
   ```promql
   sum(rate(apisix_http_status{route="1"}[5m]))
   ```
3. Click **Run query**. You should see a graph (send some requests to `http://127.0.0.1:9080/get` first so there is data).

## Import APISIX dashboard (recommended)

Use the community dashboard that already has panels for APISIX metrics:

1. **Dashboards** (grid icon) -> **New** -> **Import**.
2. Enter dashboard ID: **11719**.
3. Click **Load** -> choose **Prometheus** as datasource -> **Import**.

Source: [Grafana.com – Apache APISIX (11719)](https://grafana.com/grafana/dashboards/11719-apache-apisix/).

## Create your own dashboard

1. **Dashboards** -> **New** -> **New dashboard** -> **Add visualization**.
2. Choose **Prometheus** and add panels. Example panels:

| Panel title      | Query |
|------------------|--------|
| Request rate     | `sum(rate(apisix_http_status[5m]))` |
| Status 200 rate  | `sum(rate(apisix_http_status{code="200"}[5m]))` |
| Requests by code | `sum(increase(apisix_http_status[1h])) by (code)` |
| Latency (if available) | `histogram_quantile(0.99, sum(rate(apisix_http_latency_bucket[5m])) by (le, route))` |

3. **Apply** -> **Save dashboard**.

## Useful queries

| Query | Meaning |
|-------|---------|
| `sum(rate(apisix_http_status[5m]))` | Total request rate (all routes) |
| `sum(rate(apisix_http_status{code="200"}[5m]))` | Rate of 200 responses |
| `sum(apisix_http_status) by (code)` | Total requests by status code |

## Troubleshooting

| Issue | Check |
|-------|--------|
| No data in panels | 1) Route has prometheus plugin. 2) Send traffic to that route (e.g. `curl http://127.0.0.1:9080/get` or run `./scripts/send-traffic.sh`). 3) Set time range (top right) to **Last 15 minutes** or **Last 5 minutes**. |
| "No data" in Explore | Same as above; confirm Prometheus has data at http://localhost:9090 (query `apisix_http_status`). |
| Datasource error | Ensure Prometheus is up: `docker compose -f docker-compose-arm64.yml ps` and check http://localhost:9090. |

## Generate traffic (for more graph data)

Run the script to send requests for a few minutes so the dashboard fills with data:

```bash
./scripts/send-traffic.sh    # default: 5 minutes
./scripts/send-traffic.sh 60 # 1 minute
```

Override URL: `APISIX_URL=http://127.0.0.1:9080/get ./scripts/send-traffic.sh 120`

---

Ref: [Observe APIs](https://apisix.apache.org/docs/apisix/tutorials/observe-your-api/) (Metrics section).
