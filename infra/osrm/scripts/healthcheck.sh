#!/usr/bin/env bash
# Host-runnable equivalent of docker-compose.yml's HEALTHCHECK (which can
# only use bash's /dev/tcp builtin — no curl/wget in the official image).
# This version uses curl since it runs from the host/CI shell, not inside
# the container. Exits 0/healthy only if OSRM actually returned a route,
# not merely "the port accepted a connection".
#
# Usage: ./scripts/healthcheck.sh [base-url]   (default: http://127.0.0.1:5000)
set -euo pipefail

BASE_URL="${1:-http://127.0.0.1:${OSRM_HOST_PORT:-5000}}"
# Two points a few hundred meters apart in central Algiers — well inside
# Algeria, on streets any Algeria extract will have routable data for.
URL="$BASE_URL/route/v1/foot/3.0588,36.7538;3.0610,36.7580?overview=false"

BODY="$(curl --fail --silent --show-error --max-time 10 "$URL")" || {
  echo "UNHEALTHY: could not reach OSRM at $BASE_URL" >&2
  exit 1
}

if ! grep -q '"code":"Ok"' <<<"$BODY"; then
  echo "UNHEALTHY: OSRM responded but did not return a valid route: $BODY" >&2
  exit 1
fi

echo "HEALTHY: $BASE_URL is serving real foot routes."
