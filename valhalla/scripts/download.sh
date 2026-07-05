#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/common.sh"

cd "$ROOT_DIR"
load_env
ensure_dirs

DEFAULT_URL="https://download.geofabrik.de/asia/turkey-latest.osm.pbf"
URL="${1:-${TILE_URLS:-$DEFAULT_URL}}"
URL="${URL%% *}"

FILENAME="$(basename "$URL")"
OUTPUT_PBF="$DATA_DIR/pbf/$FILENAME"
OUTPUT_CF="$CUSTOM_FILES/$FILENAME"

if [[ -f "$OUTPUT_PBF" ]]; then
  info "Dosya zaten mevcut: $OUTPUT_PBF"
else
  info "İndiriliyor: $URL"
  if command -v wget >/dev/null 2>&1; then
    wget -O "$OUTPUT_PBF" "$URL"
  elif command -v curl >/dev/null 2>&1; then
    curl -L --progress-bar -o "$OUTPUT_PBF" "$URL"
  else
    error "wget veya curl gerekli."
    exit 1
  fi
fi

cp -f "$OUTPUT_PBF" "$OUTPUT_CF"
info "Hazır: $OUTPUT_CF"
info "Başlat: make up  |  Yeniden build: make rebuild"
