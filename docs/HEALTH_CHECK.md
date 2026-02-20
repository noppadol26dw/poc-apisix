# Health Check

Use APISIX upstream health checks so traffic only goes to healthy nodes (web1, web2). When a node fails, APISIX marks it unhealthy and stops sending requests until it recovers.

Ref: [Health Check | Apache APISIX](https://apisix.apache.org/docs/apisix/tutorials/health-check/)

## Concepts

| Type | Description |
|------|-------------|
| **Active** | APISIX probes upstream periodically (HTTP/HTTPS/TCP). After N failed probes -> unhealthy; after M successful probes -> healthy again. |
| **Passive** | APISIX judges health from real request responses. After N failed responses -> unhealthy. Cannot recover to healthy by passive alone (use with active). |

## 1. Create route with health-checked upstream

This route sends traffic to **web1** and **web2** (our nginx containers). Both respond with 200 on `/`.

```bash
curl http://127.0.0.1:9180/apisix/admin/routes/2 \
-H "X-API-KEY: edd1c9f034335f136f87ad84b625c8f1" -X PUT -d '
{
  "uri": "/web",
  "upstream": {
    "type": "roundrobin",
    "nodes": {
      "web1:80": 1,
      "web2:80": 1
    },
    "retries": 2,
    "checks": {
      "active": {
        "type": "http",
        "timeout": 2,
        "http_path": "/",
        "healthy": {
          "interval": 2,
          "successes": 2
        },
        "unhealthy": {
          "interval": 1,
          "http_failures": 2
        }
      },
      "passive": {
        "healthy": {
          "http_statuses": [200],
          "successes": 3
        },
        "unhealthy": {
          "http_statuses": [500, 502, 503],
          "http_failures": 3
        }
      }
    }
  }
}'
```

| Setting | Meaning |
|---------|---------|
| `active.http_path` | Probe path (web1/web2 return 200 on `/`) |
| `active.healthy.interval` | Probe every 2s when node is healthy |
| `active.unhealthy.http_failures` | 2 failed probes -> mark unhealthy |
| `passive.unhealthy.http_statuses` | 500/502/503 from real requests count as failure |

## 2. Test

```bash
# Should return "web1" or "web2" (roundrobin)
curl http://127.0.0.1:9080/web
```

Call several times; you should see both responses.

## 3. Check health status (Control API)

APISIX exposes health check state on port **9092** (control API):

```bash
curl -s http://127.0.0.1:9092/v1/healthcheck | jq .
```

Example: list of upstreams with `nodes[].status` (`healthy` / `unhealthy`) and `counter` (success, http_failure, tcp_failure, timeout_failure).

## 4. See failure and recovery

**Make web1 fail:** stop the web1 container so it does not respond.

```bash
docker compose -f docker-compose-arm64.yml stop web1
```

- Call `curl http://127.0.0.1:9080/web` several times -> only **web2** responds.
- `curl -s http://127.0.0.1:9092/v1/healthcheck | jq .` -> web1 should show `unhealthy`.

**Restore web1:**

```bash
docker compose -f docker-compose-arm64.yml start web1
```

After a few active probes (within ~2–4 seconds), web1 becomes healthy again and receives traffic.

## Note

- Health checks **start only after the upstream is used** (at least one request to a route that uses it).
- If **no healthy nodes** remain, APISIX still forwards to the upstream (may get errors).
- Control API: [Control API](https://apisix.apache.org/docs/apisix/control-api/).
