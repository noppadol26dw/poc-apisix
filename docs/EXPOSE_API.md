# Expose API

Create upstream and route so APISIX proxies requests to httpbin.org.

Ref: [Expose API | Apache APISIX](https://apisix.apache.org/docs/apisix/tutorials/expose-api/)

## 1. Add upstream

```bash
curl "http://127.0.0.1:9180/apisix/admin/upstreams/1" \
-H "X-API-KEY: edd1c9f034335f136f87ad84b625c8f1" -X PUT -d '
{
  "type": "roundrobin",
  "nodes": {
    "httpbin.org:80": 1
  }
}'
```

| field | meaning |
|-------|---------|
| `roundrobin` | load balancing type |
| `nodes` | backend targets (host:port : weight) |

## 2. Add route (with upstream_id)

```bash
curl "http://127.0.0.1:9180/apisix/admin/routes/1" \
-H "X-API-KEY: edd1c9f034335f136f87ad84b625c8f1" -X PUT -d '
{
  "methods": ["GET"],
  "host": "example.com",
  "uri": "/anything/*",
  "upstream_id": "1"
}'
```

## 3. Add route with inline upstream (alternative)

```bash
curl "http://127.0.0.1:9180/apisix/admin/routes/1" \
-H "X-API-KEY: edd1c9f034335f136f87ad84b625c8f1" -X PUT -d '
{
  "methods": ["GET"],
  "host": "example.com",
  "uri": "/anything/*",
  "upstream": {
    "type": "roundrobin",
    "nodes": {
      "httpbin.org:80": 1
    }
  }
}'
```

Same as step 2 but upstream is embedded in the route. Use when you don't need to reuse the upstream.

## 4. Test

```bash
curl -i -X GET "http://127.0.0.1:9080/anything/get?foo1=bar1&foo2=bar2" -H "Host: example.com"
```

Note: `Host: example.com` must match the route. Without it, the route won't match.

## 5. Result

Response header:

```text
HTTP/1.1 200 OK
Content-Type: application/json
Content-Length: 460
Connection: keep-alive
Date: Tue, 17 Feb 2026 08:06:47 GMT
Access-Control-Allow-Origin: *
Access-Control-Allow-Credentials: true
Server: APISIX/3.15.0
```

Response body (httpbin echo):

```json
{
  "args": {
    "foo1": "bar1", 
    "foo2": "bar2"
  }, 
  "data": "", 
  "files": {}, 
  "form": {}, 
  "headers": {
    "Accept": "*/*", 
    "Host": "example.com", 
    "User-Agent": "curl/8.7.1", 
    "X-Amzn-Trace-Id": "Root=1-69942197-2454c58873c174bc47996b6d", 
    "X-Forwarded-Host": "example.com"
  }, 
  "json": null, 
  "method": "GET", 
  "origin": "192.168.65.1, 58.8.154.18", 
  "url": "http://example.com/anything/get?foo1=bar1&foo2=bar2"
}
```
