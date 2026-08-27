#!/usr/bin/env bash
# Atomically points data/current at a validated release directory, without
# ever deleting the previously-active one — that's the whole rollback
# strategy (see README.md "Backup / rollback"): the old release is left on
# disk exactly as it was, so rolling back is just re-running this script
# with the old release's path.
#
# Usage:
#   ./scripts/switch-dataset.sh /path/to/data/releases/algeria-20260827T120000Z
#   ./scripts/switch-dataset.sh --restart   # also restart the compose service to load it
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OSRM_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$OSRM_DIR/.env"
[[ -f "$ENV_FILE" ]] || ENV_FILE="$OSRM_DIR/.env.example"
# shellcheck disable=SC1090
set -a; source "$ENV_FILE"; set +a

OSRM_REGION="${OSRM_REGION:-algeria}"
OSRM_DATA_DIR="${OSRM_DATA_DIR:-$OSRM_DIR/data}"
RESTART=false
TARGET=""

for arg in "$@"; do
  case "$arg" in
    --restart) RESTART=true ;;
    *) TARGET="$arg" ;;
  esac
done

[[ -n "$TARGET" ]] || { echo "Usage: switch-dataset.sh [--restart] /path/to/release-dir" >&2; exit 1; }
[[ -d "$TARGET" ]] || { echo "ERROR: $TARGET is not a directory." >&2; exit 1; }

EXPECTED="$TARGET/${OSRM_REGION}-latest.osrm.properties"
[[ -f "$EXPECTED" ]] || { echo "ERROR: $EXPECTED not found — this doesn't look like a completed release. Aborting." >&2; exit 1; }
# osrm-extract/osrm-partition/osrm-customize never write a bare "<region>-
# latest.osrm" file — only "<region>-latest.osrm.<suffix>" siblings (.ebg,
# .properties, .mldgr, etc., ~20 in total; exact set varies by OSRM version,
# not hardcoded here). A release with only the handful of files osrm-extract
# alone produces means partition/customize never completed; this generic
# count catches that without asserting version-specific filenames.
SIBLING_COUNT=$(find "$TARGET" -maxdepth 1 -name "${OSRM_REGION}-latest.osrm*" | wc -l)
if (( SIBLING_COUNT < 15 )); then
  echo "WARNING: only $SIBLING_COUNT ${OSRM_REGION}-latest.osrm* file(s) in $TARGET — a complete" >&2
  echo "         extract+partition+customize run normally produces ~20. This release may be incomplete." >&2
fi

CURRENT_LINK="$OSRM_DATA_DIR/current"
mkdir -p "$OSRM_DATA_DIR"

if [[ -e "$CURRENT_LINK" ]]; then
  PREVIOUS_TARGET="$(readlink -f "$CURRENT_LINK" 2>/dev/null || true)"
  echo "Previous dataset (kept on disk, not deleted): ${PREVIOUS_TARGET:-<none>}"
fi

# `ln -sfn` + rename-into-place is the standard atomic-symlink-swap pattern:
# the new symlink is built next to the old one and then atomically renamed
# over it, so osrm-routed (or anything else reading `current`) never
# observes a half-updated/missing path.
TMP_LINK="$OSRM_DATA_DIR/.current.tmp"
ln -sfn "$TARGET" "$TMP_LINK"
mv -Tf "$TMP_LINK" "$CURRENT_LINK"

echo "OK: data/current -> $TARGET"

if $RESTART; then
  echo "Restarting osrm-routed to load the new dataset..."
  (cd "$OSRM_DIR" && docker compose restart osrm)
  echo "Restarted. Run ./scripts/healthcheck.sh to confirm it came back up healthy."
else
  echo "Not restarted (pass --restart to also reload osrm-routed now)."
fi
