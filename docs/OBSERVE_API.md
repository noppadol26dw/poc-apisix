# Observe APIs

Use APISIX plugins for the three pillars of observability: **logs**, **metrics**, and **tracing**.

Ref: [Observe APIs | Apache APISIX](https://apisix.apache.org/docs/apisix/tutorials/observe-your-api/)

## Prerequisites

Complete [EXPOSE_API.md](./EXPOSE_API.md) first (upstream 1 + route).

---

## 1. Logs — http-logger

Send API log data to an HTTP endpoint (e.g. webhook.site, monitoring tool).

1. Open [webhook.site](https://webhook.site) and copy your unique URL.
2. Enable the plugin:

```bash
curl http://127.0.0.1:9180/apisix/admin/routes/1 \
-H "X-API-KEY: edd1c9f034335f136f87ad84b625c8f1" -X PUT -d '
{
  "plugins": {
    "http-logger": {
      "uri": "https://webhook.site/YOUR-UNIQUE-ID"
    }
  },
  "upstream_id": "1",
  "uri": "/get"
}'
```

Replace `YOUR-UNIQUE-ID` with the ID from your webhook.site URL. Then:

```bash
curl -i http://127.0.0.1:9080/get
```

View incoming log requests on the webhook.site page.

### Sample log payload

http-logger sends a JSON array. Main fields: `route_id`, `server`, `client_ip`, `request`, `response`, `upstream`, `upstream_latency`, `apisix_latency`, `latency`.

### Other logger plugins

tcp-logger, kafka-logger, udp-logger, error-logger — see [PluginHub](https://apisix.apache.org/docs/apisix/plugins/http-logger/).

---

## 2. Metrics — Prometheus

APISIX exposes metrics on port 9091. Enable the prometheus plugin on a route, then scrape with Prometheus.

### Enable prometheus plugin

```bash
curl http://127.0.0.1:9180/apisix/admin/routes/1 \
-H "X-API-KEY: edd1c9f034335f136f87ad84b625c8f1" -X PUT -d '
{
  "uri": "/get",
  "plugins": { "prometheus": {} },
  "upstream_id": "1"
}'
```

Send traffic so metrics appear:

```bash
curl http://127.0.0.1:9080/get
```

### Prometheus in this POC

With `docker-compose-arm64.yml`, Prometheus is included. Config: `prometheus_conf/prometheus.yml` (scrapes `apisix:9091`, path `/apisix/prometheus/metrics`).

- **Prometheus UI:** http://localhost:9090  
- **Targets:** http://localhost:9090/targets (job `apisix` should be UP)  
- **Raw metrics:** `curl http://127.0.0.1:9091/apisix/prometheus/metrics` (from host)

### Useful queries

`apisix_http_status` is a **counter**. Use `rate()` or `increase()` to see activity.

| Query | Meaning |
|-------|---------|
| `apisix_http_status` | Raw counter (Table view) |
| `rate(apisix_http_status[5m])` | Requests per second |
| `increase(apisix_http_status[5m])` | Total requests in last 5m |
| `sum(apisix_http_status{route="1"})` | Total for route 1 (all nodes) |

### Labels on `apisix_http_status`

| Label | Meaning |
|-------|---------|
| `code` | HTTP status (e.g. 200) |
| `matched_uri` | Route URI that matched |
| `node` | Upstream backend IP |
| `route` | Route ID |

Multiple upstream nodes produce multiple series; use `sum(...)` to aggregate.

---

## 3. Tracing — Zipkin

Send distributed traces to Zipkin. Zipkin is included in `docker-compose-arm64.yml` (port 9411).

Enable zipkin plugin (APISIX and Zipkin share the same Docker network, so use `http://zipkin:9411`):

```bash
curl http://127.0.0.1:9180/apisix/admin/routes/1 \
-H "X-API-KEY: edd1c9f034335f136f87ad84b625c8f1" -X PUT -d '
{
  "methods": ["GET"],
  "uri": "/get",
  "plugins": {
    "zipkin": {
      "endpoint": "http://zipkin:9411/api/v2/spans",
      "sample_ratio": 1
    }
  },
  "upstream_id": "1"
}'
```

Test:

```bash
curl -i http://127.0.0.1:9080/get
```

Response headers include `X-B3-Traceid`, `X-B3-Spanid`. View traces at http://localhost:9411/zipkin (Zipkin runs in the same stack).

### Viewing traces in Zipkin

- **By Trace ID:** Copy `X-B3-Traceid` from the response header, paste into the "Trace ID" field, click **Run Query**.
- **By service:** Set **Service Name** to `apisix`, choose a time range (e.g. Last 15 minutes), click **Run Query**.

### Trace spans (what APISIX sends)

| Span name | Meaning |
|-----------|---------|
| `apisix.request` | Request received from client (method, URI, status, duration) |
| `apisix.proxy` | APISIX forwarding to upstream |
| `apisix.response_span` | Sending response back to client |

All spans have `localEndpoint.serviceName`: `apisix`.

### Zipkin not showing traces?

1. Confirm the route has the zipkin plugin: `curl -s http://127.0.0.1:9180/apisix/admin/routes/1 -H "X-API-KEY: edd1c9f034335f136f87ad84b625c8f1" | jq '.value.plugins.zipkin'`
2. Send a request and check for `X-B3-Traceid` in the response headers. If missing, the plugin is not active for that request.
3. In Zipkin, set the time range to **Last 1 hour** or **All** and run the query again.

---

## Summary

| Pillar | Plugin | Where to see it |
|--------|--------|-----------------|
| Logs | http-logger | webhook.site (or your endpoint) |
| Metrics | prometheus | http://localhost:9090 (Prometheus) |
| Tracing | zipkin | http://localhost:9411/zipkin |

### One route with all three

```bash
curl http://127.0.0.1:9180/apisix/admin/routes/1 \
-H "X-API-KEY: edd1c9f034335f136f87ad84b625c8f1" -X PUT -d '
{
  "methods": ["GET"],
  "uri": "/get",
  "plugins": {
    "http-logger": { "uri": "https://webhook.site/YOUR-UNIQUE-ID" },
    "prometheus": {},
    "zipkin": {
      "endpoint": "http://zipkin:9411/api/v2/spans",
      "sample_ratio": 1
    }
  },
  "upstream_id": "1"
}'
```

Replace `YOUR-UNIQUE-ID`. Zipkin is in the same stack (`docker-compose-arm64.yml`).

---

Next: [Manage API Consumers](https://apisix.apache.org/docs/apisix/tutorials/manage-api-consumers/), [Health Check](https://apisix.apache.org/docs/apisix/tutorials/health-check/).
