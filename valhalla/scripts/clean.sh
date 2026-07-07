#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/common.sh"

cd "$ROOT_DIR"
load_env

warn "Üretilmiş tile, config ve hash dosyaları silinecek (PBF korunur)."
read -r -p "Devam? [y/N] " confirm
[[ "$confirm" =~ ^[Yy]$ ]] || exit 0

shopt -s nullglob
for f in "$CUSTOM_FILES"/valhalla_tiles.tar \
         "$CUSTOM_FILES"/valhalla.json \
         "$CUSTOM_FILES"/file_hashes.txt \
         "$CUSTOM_FILES"/admins.sqlite \
         "$CUSTOM_FILES"/timezones.sqlite \
         "$CUSTOM_FILES"/default_speeds.json; do
  [[ -f "$f" ]] && rm -f "$f" && info "Silindi: $f"
done

rm -rf "$CUSTOM_FILES"/valhalla_tiles 2>/dev/null || true
rm -rf "$DATA_DIR"/tiles/* 2>/dev/null || true

info "Temizlik tamam. Yeniden build: make rebuild"
