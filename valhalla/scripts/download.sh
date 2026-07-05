#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/common.sh"

cd "$ROOT_DIR"
load_env
ensure_dirs

URL="${1:-${TILE_URLS:-https://download.geofabrik.de/asia/turkey-latest.osm.pbf}}"
URL="${URL%% *}"
FILENAME="$(basename "$URL")"
OUTPUT_CF="$CUSTOM_FILES/$FILENAME"
OUTPUT_PBF="$DATA_DIR/pbf/$FILENAME"

warn "Mevcut PBF silinip yeniden indirilecek (bozuk dosya düzeltme)."
docker rm -f valhalla 2>/dev/null || true
rm -f "$OUTPUT_CF" "$OUTPUT_PBF" "$CUSTOM_FILES/.file_hashes.txt" \
      "$CUSTOM_FILES/admins.sqlite" "$CUSTOM_FILES/timezones.sqlite" \
      "$CUSTOM_FILES/valhalla_tiles.tar"

valhalla_download_pbf "$URL" "$OUTPUT_CF"
cp -f "$OUTPUT_CF" "$OUTPUT_PBF"
info "Hazır: $OUTPUT_CF"
info "Devam: make install"
