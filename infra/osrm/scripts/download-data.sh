#!/usr/bin/env bash
# Downloads the configured region's OSM extract from Geofabrik (the
# reputable, standard country-extract provider used throughout the OSM/OSRM
# ecosystem — see README.md "Data source"). Never overwrites a previous
# download in place: each run is saved under its own date, so
# scripts/preprocess.sh always has a clear, reproducible input to point at
# and nothing is silently replaced.
#
# Usage: ./scripts/download-data.sh [path-to-.env]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OSRM_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE="${1:-$OSRM_DIR/.env}"

if [[ -f "$ENV_FILE" ]]; then
  # shellcheck disable=SC1090
  set -a; source "$ENV_FILE"; set +a
elif [[ -f "$OSRM_DIR/.env.example" ]]; then
  echo "No .env found at $ENV_FILE — using .env.example defaults." >&2
  set -a; source "$OSRM_DIR/.env.example"; set +a
fi

OSRM_REGION="${OSRM_REGION:-algeria}"
OSRM_DATA_DIR="${OSRM_DATA_DIR:-$OSRM_DIR/data}"
OSRM_PBF_URL="${OSRM_PBF_URL:-https://download.geofabrik.de/africa/algeria-latest.osm.pbf}"

RAW_DIR="$OSRM_DATA_DIR/raw"
DATE_STAMP="$(date -u +%Y%m%d)"
DEST="$RAW_DIR/${OSRM_REGION}-${DATE_STAMP}.osm.pbf"

mkdir -p "$RAW_DIR"

if [[ -f "$DEST" ]]; then
  echo "Already downloaded today: $DEST (delete it to force a re-download)."
  exit 0
fi

echo "Downloading $OSRM_PBF_URL"
echo "       -> $DEST"
TMP="$DEST.part"
curl --fail --location --show-error --progress-bar "$OSRM_PBF_URL" -o "$TMP"

# Lightweight integrity check — a real .osm.pbf is a sequence of length-
# prefixed protobuf "fileblocks", and every valid one starts with an
# OSMHeader block, so this string appears near the very start of the file.
# This won't catch subtle corruption, but reliably catches "downloaded an
# HTML error page" or "connection cut off after a few bytes" without
# needing osmium/any extra tool beyond `grep` (see README.md "Data source"
# for the fuller verification procedure using osmium if you have it).
if ! head -c 64 "$TMP" | grep -aq "OSMHeader"; then
  echo "ERROR: downloaded file does not look like a valid .osm.pbf (missing OSMHeader block). Aborting." >&2
  rm -f "$TMP"
  exit 1
fi

SIZE_BYTES=$(wc -c < "$TMP")
if (( SIZE_BYTES < 10000000 )); then
  echo "ERROR: downloaded file is suspiciously small (${SIZE_BYTES} bytes) for a country extract. Aborting." >&2
  rm -f "$TMP"
  exit 1
fi

mv "$TMP" "$DEST"
echo "OK: $DEST ($(( SIZE_BYTES / 1024 / 1024 )) MB)"
echo "Next: ./scripts/preprocess.sh $DEST"
