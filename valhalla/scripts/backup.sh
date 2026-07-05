#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/common.sh"

ensure_dirs
STAMP="$(date +%Y%m%d_%H%M%S)"
ARCHIVE="$BACKUP_DIR/valhalla_${STAMP}.tar.gz"

info "Yedek alınıyor: $ARCHIVE"
tar -czf "$ARCHIVE" -C "$VALHALLA_DIR" custom_files
info "Tamamlandı ($(du -h "$ARCHIVE" | cut -f1))"
