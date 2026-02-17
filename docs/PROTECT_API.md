# Protect API

Use the `limit-count` plugin to limit requests per client (aka. rate limiting).

Ref: [Protect API | Apache APISIX](https://apisix.apache.org/docs/apisix/tutorials/protect-api/)

## Prerequisites

Complete [EXPOSE_API.md](./EXPOSE_API.md) first (upstream 1 + route).

## 1. Add route with limit-count plugin

```bash
curl -i http://127.0.0.1:9180/apisix/admin/routes/1 \
-H "X-API-KEY: edd1c9f034335f136f87ad84b625c8f1" -X PUT -d '
{
    "uri": "/index.html",
    "plugins": {
        "limit-count": {
            "count": 2,
            "time_window": 60,
            "rejected_code": 503,
            "key_type": "var",
            "key": "remote_addr"
        }
    },
    "upstream_id": "1"
}'
```

| field | meaning |
|-------|---------|
| `count: 2` | max 2 requests |
| `time_window: 60` | within 60 seconds |
| `rejected_code: 503` | return 503 when over quota |
| `key: "remote_addr"` | count per client IP |

## 2. Test

```bash
curl http://127.0.0.1:9080/index.html
```

Call 3 times — the 3rd returns 503:

```html
<html>
<head><title>503 Service Temporarily Unavailable</title></head>
<body>
<center><h1>503 Service Temporarily Unavailable</h1></center>
<hr><center>openresty</center>
</body>
</html>
```

## Other rate limiting plugins

| Plugin | description |
|--------|-------------|
| limit-conn | limit concurrent requests |
| limit-req | limit using leaky bucket |
| limit-count | limit requests per time window (used in this tutorial) |
