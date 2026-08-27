#!/usr/bin/env bash
# Orchestrates the full, safe data-refresh cycle documented in README.md
# "Data update strategy" (download -> preprocess -> test-route -> switch),
# intended to be invoked unattended (cron/systemd timer) on a production
# host. Every step that can abort safely does: if anything fails, the
# currently-serving dataset (data/current) is left completely untouched —
# this script never activates a release it has not itself just validated.
#
# This is intentionally a thin wrapper around the existing individual
# scripts (no new logic duplicated) — see each of them for what a step
# actually does.
#
# Usage: ./scripts/refresh.sh
# Exit code 0 only if a new dataset was downloaded, processed, validated,
# AND switched in. Exit code 1 (with the current dataset still active) for
# any failure — safe to run this on a schedule and only alert on non-zero.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OSRM_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$OSRM_DIR/.env"
[[ -f "$ENV_FILE" ]] || { echo "ERROR: $ENV_FILE not found — copy .env.example first." >&2; exit 1; }
# shellcheck disable=SC1090
set -a; source "$ENV_FILE"; set +a

OSRM_REGION="${OSRM_REGION:-algeria}"
OSRM_DATA_DIR="${OSRM_DATA_DIR:-$OSRM_DIR/data}"
LOG_PREFIX="[refresh $(date -u +%Y-%m-%dT%H:%M:%SZ)]"

log() { echo "$LOG_PREFIX $*"; }

fail() {
  log "FAILED: $*"
  log "The currently-serving dataset (data/current) was NOT touched."
  exit 1
}

log "Starting scheduled refresh for region '$OSRM_REGION'."

# 1. Download (idempotent — download-data.sh no-ops if today's file already exists).
"$SCRIPT_DIR/download-data.sh" "$ENV_FILE" || fail "download-data.sh"
TODAY="$(date -u +%Y%m%d)"
PBF="$OSRM_DATA_DIR/raw/${OSRM_REGION}-${TODAY}.osm.pbf"
[[ -f "$PBF" ]] || fail "expected $PBF after download-data.sh, not found"

# 2. Compare against the currently-active dataset's source date, if known —
#    skip the (expensive) preprocessing entirely when there is nothing new.
CURRENT_LINK="$OSRM_DATA_DIR/current"
if [[ -L "$CURRENT_LINK" || -d "$CURRENT_LINK" ]]; then
  CURRENT_TARGET="$(readlink -f "$CURRENT_LINK" 2>/dev/null || true)"
  if [[ -n "$CURRENT_TARGET" && "$(basename "$CURRENT_TARGET")" == *"$TODAY"* ]]; then
    log "Current dataset's release directory already matches today's date ($TODAY) — nothing to do."
    exit 0
  fi
fi

# 3. Preprocess into a new, isolated release directory (never touches data/current).
log "Preprocessing $PBF (this is the slow step — see README.md Resource requirements)..."
PREPROCESS_OUTPUT="$("$SCRIPT_DIR/preprocess.sh" "$PBF")" || fail "preprocess.sh"
echo "$PREPROCESS_OUTPUT"
# preprocess.sh prints exactly one unambiguous "RELEASE_DIR=<path>" line for
# this purpose (see its own final lines) — never parse its human-facing
# instructional text, which is quoted/wrapped differently.
RELEASE_DIR="$(echo "$PREPROCESS_OUTPUT" | sed -n 's/^RELEASE_DIR=//p' | tail -1)"
[[ -n "$RELEASE_DIR" && -d "$RELEASE_DIR" ]] || fail "could not determine the release directory preprocess.sh just created"

# 4. Validate the new release BEFORE it ever serves real traffic.
log "Validating new release: $RELEASE_DIR"
"$SCRIPT_DIR/test-route.sh" --release "$RELEASE_DIR" || fail "test-route.sh rejected the new release — it will NOT be activated"

# 5. Only now, atomically switch and reload.
log "Validation passed — activating $RELEASE_DIR"
"$SCRIPT_DIR/switch-dataset.sh" "$RELEASE_DIR" --restart || fail "switch-dataset.sh"

# 6. Confirm the live service actually came back healthy on the new data.
sleep 5
"$SCRIPT_DIR/healthcheck.sh" || fail "post-switch healthcheck — consider rolling back (README.md Backup/rollback)"

log "Refresh complete. Active dataset: $RELEASE_DIR"
