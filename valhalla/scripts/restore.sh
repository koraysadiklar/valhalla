#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/common.sh"

ARCHIVE="${1:-}"

if [[ -z "$ARCHIVE" ]]; then
  error "Kullanım: $0 <valhalla/backups/valhalla_YYYYMMDD_HHMMSS.tar.gz>"
  ls -1t "$BACKUP_DIR"/*.tar.gz 2>/dev/null || echo "(yedek yok)"
  exit 1
fi

if [[ ! -f "$ARCHIVE" ]]; then
  error "Dosya bulunamadı: $ARCHIVE"
  exit 1
fi

warn "Mevcut custom_files üzerine yazılacak."
read -r -p "Devam? [y/N] " confirm
[[ "$confirm" =~ ^[Yy]$ ]] || exit 0

info "Geri yükleniyor: $ARCHIVE"
tar -xzf "$ARCHIVE" -C "$VALHALLA_DIR"
info "Tamamlandı. Yeniden başlat: make restart"
