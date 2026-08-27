#!/usr/bin/env bash
# The documented functional test required before activating any new
# dataset (README.md "Data update strategy" step 6 — "validate"). Uses the
# same general route shape (~1.9km, Constantine) that exposed the original
# RAHATI defect: a 1.9km route reported as a 3-minute ("33 km/h") walk. This
# test proves a *self-hosted* OSRM instance does not reproduce that.
#
# Walking-speed bounds mirror
# apps/backend/src/modules/routing/domain/walking-route-plausibility.ts
# (10 km/h ceiling) plus a floor here to catch nonsense at the other extreme
# — that floor is a test-script sanity net only, not something RAHATI's
# backend itself enforces (a very slow but real walk is still valid to
# RAHATI; here it would instead suggest OSRM's *own* profile/data is broken).
#
# Usage: ./scripts/test-route.sh [--release /path/to/release-dir] [base-url]
#   --release runs OSRM in a disposable one-off container against that
#   release directory instead of hitting an already-running service —
#   exactly what preprocess.sh's own printed instructions use.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OSRM_DIR="$(dirname "$SCRIPT_DIR")"
OSRM_IMAGE="ghcr.io/project-osrm/osrm-backend:v5.27.1"

MAX_WALKING_KMH=10     # keep in sync with walking-route-plausibility.ts
MIN_WALKING_KMH=0.5    # sanity floor for this test only, see header comment

RELEASE=""
BASE_URL="http://127.0.0.1:${OSRM_HOST_PORT:-5000}"
CONTAINER_NAME=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --release) RELEASE="$2"; shift 2 ;;
    *) BASE_URL="$1"; shift ;;
  esac
done

cleanup() {
  if [[ -n "$CONTAINER_NAME" ]]; then
    docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

if [[ -n "$RELEASE" ]]; then
  [[ -d "$RELEASE" ]] || { echo "ERROR: release dir not found: $RELEASE" >&2; exit 1; }
  OSRM_REGION="${OSRM_REGION:-algeria}"
  CONTAINER_NAME="rahati-osrm-test-route-$$"
  ONE_OFF_PORT="${OSRM_TEST_PORT:-5099}"
  BASE_URL="http://127.0.0.1:$ONE_OFF_PORT"
  echo "Starting a disposable OSRM container against $RELEASE on port $ONE_OFF_PORT..."
  docker run -d --rm --name "$CONTAINER_NAME" \
    -p "127.0.0.1:$ONE_OFF_PORT:5000" \
    -v "$RELEASE:/data:ro" \
    "$OSRM_IMAGE" osrm-routed --algorithm mld "/data/${OSRM_REGION}-latest.osrm" >/dev/null
  echo -n "Waiting for it to become ready"
  for _ in $(seq 1 30); do
    if curl --fail --silent --max-time 2 "$BASE_URL/route/v1/foot/3.05,36.75;3.06,36.76" >/dev/null 2>&1; then
      echo " ready."
      break
    fi
    echo -n "."
    sleep 2
  done
fi

# Constantine, Algeria — the exact route shape (~1.9km) from the original
# RAHATI defect report (real-device QA, 2026-08-27): Mosquée Hassan Bey area.
ORIGIN="6.6147,36.365002"
DEST="6.6118017,36.3672728"
URL="$BASE_URL/route/v1/foot/$ORIGIN;$DEST?overview=false"

echo "Requesting: $URL"
HTTP_CODE=$(curl --silent --output /tmp/osrm-test-route-response.json --write-out "%{http_code}" --max-time 15 "$URL")
BODY="$(cat /tmp/osrm-test-route-response.json)"
rm -f /tmp/osrm-test-route-response.json

echo "HTTP status: $HTTP_CODE"
[[ "$HTTP_CODE" == "200" ]] || { echo "FAIL: expected HTTP 200, got $HTTP_CODE. Body: $BODY" >&2; exit 1; }

node -e "
const body = process.argv[1];
const maxKmh = Number(process.argv[2]);
const minKmh = Number(process.argv[3]);

let json;
try {
  json = JSON.parse(body);
} catch (e) {
  console.error('FAIL: response is not valid JSON:', e.message);
  process.exit(1);
}

if (json.code !== 'Ok' || !Array.isArray(json.routes) || json.routes.length === 0) {
  console.error('FAIL: no route in response:', JSON.stringify(json));
  process.exit(1);
}

const route = json.routes[0];
const distanceMeters = route.distance;
const durationSeconds = route.duration;

if (!(distanceMeters > 0)) {
  console.error('FAIL: distance is not > 0:', distanceMeters);
  process.exit(1);
}
if (!(durationSeconds > 0)) {
  console.error('FAIL: duration is not > 0:', durationSeconds);
  process.exit(1);
}

const speedKmh = (distanceMeters / durationSeconds) * 3.6;
console.log(\`distance = \${distanceMeters.toFixed(1)} m\`);
console.log(\`duration = \${durationSeconds.toFixed(1)} s\`);
console.log(\`implied speed = \${speedKmh.toFixed(2)} km/h\`);

if (speedKmh > maxKmh) {
  console.error(\`FAIL: \${speedKmh.toFixed(2)} km/h exceeds the \${maxKmh} km/h walking ceiling — this is the exact defect this infrastructure exists to prevent.\`);
  process.exit(1);
}
if (speedKmh < minKmh) {
  console.error(\`FAIL: \${speedKmh.toFixed(2)} km/h is below the \${minKmh} km/h sanity floor — OSRM/profile data likely broken.\`);
  process.exit(1);
}

console.log('PASS: plausible walking route.');
" "$BODY" "$MAX_WALKING_KMH" "$MIN_WALKING_KMH"
