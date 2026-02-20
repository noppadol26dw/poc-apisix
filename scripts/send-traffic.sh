#!/usr/bin/env bash
# Send requests to APISIX so Prometheus/Grafana show more data.
# Usage: ./scripts/send-traffic.sh [duration_seconds]
# Default: 300 (5 minutes). Ctrl+C to stop early.

DURATION=${1:-300}
URL="${APISIX_URL:-http://127.0.0.1:9080/get}"
end=$(($(date +%s) + DURATION))
count=0

echo "Sending requests to $URL for ${DURATION}s (Ctrl+C to stop)"
while [ "$(date +%s)" -lt "$end" ]; do
  curl -s -o /dev/null "$URL"
  count=$((count + 1))
  sleep "0.$((1 + RANDOM % 4))"
done
echo "Done. Sent $count requests."
