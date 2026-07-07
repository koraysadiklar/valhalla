#!/usr/bin/env bash
# Volume hazırlık scripti — planet/kıta kurulumundan önce bir kez çalıştırın
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/common.sh"

if [[ $EUID -ne 0 ]]; then
  error "root olarak çalıştırın: sudo $0"
  exit 1
fi

echo ""
info "═══════════════════════════════════════"
info "  Volume Kontrolü"
info "═══════════════════════════════════════"
echo ""

echo "── Bağlı diskler ──"
lsblk -o NAME,SIZE,TYPE,MOUNTPOINT,FSTYPE
echo ""

echo "── Mount noktaları ──"
df -h | grep -E 'volume|Filesystem' || df -h
echo ""

if [[ -f "$ROOT_DIR/.env" ]]; then
  load_env
  info "Mevcut VALHALLA_DATA_DIR: ${VALHALLA_DATA_DIR:-tanımsız}"
else
  warn ".env yok — önce: make region REGION=world"
fi

echo ""
info "Volume mount yolu doğruysa devam edin."
info "Planet kurulum: make region REGION=world && make install"
echo ""

# VALHALLA_DATA_DIR tanımlıysa dizinleri oluştur
if [[ -n "${VALHALLA_DATA_DIR:-}" ]]; then
  CUSTOM_FILES="${VALHALLA_DATA_DIR}/custom_files"
  if [[ -d "$(dirname "$VALHALLA_DATA_DIR")" ]] || [[ -d "$VALHALLA_DATA_DIR" ]]; then
    mkdir -p "$CUSTOM_FILES" "${VALHALLA_DATA_DIR}/data" "${VALHALLA_DATA_DIR}/backups"
    info "Dizinler hazır: $VALHALLA_DATA_DIR"
    df -h "$(dirname "$VALHALLA_DATA_DIR")" 2>/dev/null || df -h "$VALHALLA_DATA_DIR"
  else
    warn "Mount yolu bulunamadı: $VALHALLA_DATA_DIR"
    warn "Önce volume'u mount edin (aşağıdaki adımlara bakın)."
  fi
fi
