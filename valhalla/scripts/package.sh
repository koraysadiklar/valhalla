#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/common.sh"

OUT="${1:-valhalla-stack-export.tar.gz}"
STAMP="$(date +%Y%m%d)"

info "Taşınabilir paket oluşturuluyor: $OUT"
tar -czf "$OUT" \
  --exclude='valhalla/backups/*' \
  --exclude='.idea' \
  --exclude='.git' \
  -C "$ROOT_DIR" \
  docker-compose.yml .env.example Makefile README.md LICENSE \
  valhalla/custom_files valhalla/config valhalla/examples valhalla/regions valhalla/scripts valhalla/docs

info "Paket hazır: $OUT"
info "Hedef sunucuda: tar -xzf $OUT && cp .env.example .env && make install"
