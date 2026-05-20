#!/usr/bin/env bash
set -euo pipefail

APP_URL="${APP_URL:-http://localhost:3000}"
MAX_RETRIES="${MAX_RETRIES:-5}"
RETRY_DELAY="${RETRY_DELAY:-10}"
RESPONSE_TIME_THRESHOLD="${RESPONSE_TIME_THRESHOLD:-2000}"

PASSED=0
FAILED=0

print_header() {
  echo ""
  echo "=== $1 ==="
  echo ""
}

check_endpoint() {
  local name="$1"
  local endpoint="$2"
  local expected_status="${3:-200}"
  local required_field="${4:-}"

  echo -n "  $name ($endpoint) ... "

  for attempt in $(seq 1 "$MAX_RETRIES"); do
    HTTP_RESPONSE=$(curl -s -o /tmp/smoke_response.json -w "%{http_code}:%{time_total}" \
      --connect-timeout 10 \
      --max-time 30 \
      "$APP_URL$endpoint" 2>/dev/null) || true

    HTTP_STATUS=$(echo "$HTTP_RESPONSE" | cut -d: -f1)
    RESPONSE_TIME=$(echo "$HTTP_RESPONSE" | cut -d: -f2)
    RESPONSE_TIME_MS=$(echo "$RESPONSE_TIME * 1000" | bc 2>/dev/null | cut -d. -f1 || echo "0")

    if [ "$HTTP_STATUS" = "$expected_status" ]; then
      if [ -n "$required_field" ]; then
        if grep -q "\"$required_field\"" /tmp/smoke_response.json 2>/dev/null; then
          echo "PASSED (${RESPONSE_TIME_MS}ms)"
          PASSED=$((PASSED + 1))

          if [ "$RESPONSE_TIME_MS" -gt "$RESPONSE_TIME_THRESHOLD" ]; then
            echo "    WARNING: Response time ${RESPONSE_TIME_MS}ms exceeds ${RESPONSE_TIME_THRESHOLD}ms threshold"
          fi
          return 0
        fi
      else
        echo "PASSED (${RESPONSE_TIME_MS}ms)"
        PASSED=$((PASSED + 1))
        return 0
      fi
    fi

    if [ "$attempt" -lt "$MAX_RETRIES" ]; then
      echo ""
      echo "    Retry $attempt/$MAX_RETRIES in ${RETRY_DELAY}s (got HTTP $HTTP_STATUS)"
      sleep "$RETRY_DELAY"
  echo -n "  $name ($endpoint) ... "
    fi
  done

  echo "FAILED (expected $expected_status, got $HTTP_STATUS)"
  FAILED=$((FAILED + 1))
  return 1
}

print_header "Smoke Tests — $APP_URL"

echo "  Configuration:"
echo "    Max retries:     $MAX_RETRIES"
echo "    Retry delay:     ${RETRY_DELAY}s"
echo "    Response limit:  ${RESPONSE_TIME_THRESHOLD}ms"
echo ""

check_endpoint "Health Check (Liveness)" "/health" "200" "status" || true
check_endpoint "Readiness Check" "/ready" "200" "status" || true
check_endpoint "API Info" "/api/info" "200" "version" || true
check_endpoint "Metrics" "/api/metrics" "200" "uptime" || true
check_endpoint "Root" "/" "200" "name" || true
check_endpoint "404 Handling" "/nonexistent" "404" "error" || true

print_header "Results"

TOTAL=$((PASSED + FAILED))
echo "  Total:  $TOTAL"
echo "  Passed: $PASSED"
echo "  Failed: $FAILED"
echo ""

if [ "$FAILED" -gt 0 ]; then
  echo "  SMOKE TESTS FAILED — triggering rollback"
  exit 1
else
  echo "  ALL SMOKE TESTS PASSED"
  exit 0
fi
