#!/usr/bin/env bash
# Runs the full osrm-extract -> osrm-partition -> osrm-customize pipeline
# (the MLD algorithm's pipeline — see README.md "Why MLD") against a raw
# .osm.pbf, using the FOOT profile, entirely inside the same pinned official
# OSRM image the routing container itself runs — the profile is the
# project's own unmodified `foot.lua`, never a fork/copy of it.
#
# Output goes into its own dated release directory under
# data/releases/<region>-<timestamp>/ — the currently-serving dataset
# (data/current, a symlink) is never touched. Run scripts/switch-dataset.sh
# to activate the result after validating it with scripts/test-route.sh.
#
# Usage: ./scripts/preprocess.sh /path/to/algeria-YYYYMMDD.osm.pbf
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OSRM_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$OSRM_DIR/.env"
[[ -f "$ENV_FILE" ]] || ENV_FILE="$OSRM_DIR/.env.example"
# shellcheck disable=SC1090
set -a; source "$ENV_FILE"; set +a

OSRM_IMAGE="ghcr.io/project-osrm/osrm-backend:v5.27.1" # keep in sync with docker-compose.yml
OSRM_REGION="${OSRM_REGION:-algeria}"
OSRM_DATA_DIR="${OSRM_DATA_DIR:-$OSRM_DIR/data}"

PBF_PATH="${1:?Usage: preprocess.sh /path/to/region-YYYYMMDD.osm.pbf}"
[[ -f "$PBF_PATH" ]] || { echo "ERROR: $PBF_PATH not found." >&2; exit 1; }
PBF_ABS="$(cd "$(dirname "$PBF_PATH")" && pwd)/$(basename "$PBF_PATH")"
PBF_DIR="$(dirname "$PBF_ABS")"
PBF_FILE="$(basename "$PBF_ABS")"

TIMESTAMP="$(date -u +%Y%m%dT%H%M%SZ)"
RELEASE_DIR="$OSRM_DATA_DIR/releases/${OSRM_REGION}-${TIMESTAMP}"
mkdir -p "$RELEASE_DIR"

# Named exactly `<region>-latest.osm.pbf` so osrm-extract's own "strip
# .osm.pbf, append .osrm" convention produces `<region>-latest.osrm` with no
# renaming logic needed here.
INPUT_PBF="${OSRM_REGION}-latest.osm.pbf"
WORK_FILE="${OSRM_REGION}-latest.osrm"
echo "== Copying $PBF_FILE into release directory (osrm-extract writes many"
echo "   sibling files next to its input, so it must run on a private copy) =="
cp "$PBF_ABS" "$RELEASE_DIR/$INPUT_PBF"

run_osrm() {
  echo "== docker run: $* =="
  # MSYS_NO_PATHCONV: when this script runs under Git Bash on Windows,
  # MSYS silently rewrites POSIX-looking arguments (e.g. the in-container
  # `/usr/local/share/osrm/profiles/foot.lua` path below) into a Windows
  # path before `docker run` ever sees them — breaking the in-container
  # path. This env var is a no-op on real Linux/macOS shells. See
  # https://github.com/docker/for-win/issues/1509 (the standard workaround).
  MSYS_NO_PATHCONV=1 docker run --rm \
    -v "$RELEASE_DIR:/data" \
    "$OSRM_IMAGE" "$@"
}

START_TIME=$(date +%s)

run_osrm osrm-extract -p /usr/local/share/osrm/profiles/foot.lua "/data/$INPUT_PBF"
# osrm-extract never writes a bare "$WORK_FILE" itself — it writes
# "$WORK_FILE.<suffix>" siblings (.properties, .ebg, .timestamp, etc.) that
# osrm-partition/osrm-customize/osrm-routed address via the "$WORK_FILE"
# prefix. .properties is one of the first files extract writes, so its
# presence is a reliable "extract actually completed" signal.
[[ -f "$RELEASE_DIR/$WORK_FILE.properties" ]] || { echo "ERROR: expected $RELEASE_DIR/$WORK_FILE.properties after osrm-extract, not found." >&2; exit 1; }

run_osrm osrm-partition "/data/$WORK_FILE"
run_osrm osrm-customize "/data/$WORK_FILE"

END_TIME=$(date +%s)
echo "== Done in $(( (END_TIME - START_TIME) / 60 )) min $(( (END_TIME - START_TIME) % 60 ))s =="

# The raw .osm.pbf copy isn't needed by osrm-routed at serve time — drop it
# so the release directory only holds what's actually required (keeps
# rollback storage cost down, README.md "Resource requirements").
rm -f "$RELEASE_DIR/$INPUT_PBF"

echo
echo "Release ready (NOT yet active): $RELEASE_DIR"
echo "Validate it, then activate with:"
echo "  ./scripts/test-route.sh --release '$RELEASE_DIR'"
echo "  ./scripts/switch-dataset.sh '$RELEASE_DIR'"
# Single unambiguous machine-parseable line for scripts/refresh.sh (or any
# other caller) to extract — deliberately printed last, on its own line,
# with no quoting/wrapping, unlike the human-facing instructions above.
echo "RELEASE_DIR=$RELEASE_DIR"
