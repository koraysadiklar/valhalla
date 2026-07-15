#!/usr/bin/env bash
# Swap dosyası oluşturur (volume üzerinde)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/common.sh"

if [[ $EUID -ne 0 ]]; then
  error "root olarak çalıştırın: sudo $0"
  exit 1
fi

load_env

SWAP_SIZE="${SWAP_SIZE:-16G}"
SWAP_FILE="${SWAP_FILE:-/mnt/volume_valhalla/swapfile}"
VOLUME_ROOT="$(dirname "$SWAP_FILE")"

info "Swap kurulumu: ${SWAP_SIZE} → ${SWAP_FILE}"

if [[ ! -d "$VOLUME_ROOT" ]]; then
  error "Volume dizini yok: $VOLUME_ROOT"
  error "Önce volume'u mount edin: /mnt/volume-valhalla"
  exit 1
fi

if swapon --show 2>/dev/null | grep -qF "$SWAP_FILE"; then
  info "Swap zaten aktif: $SWAP_FILE"
  swapon --show
  free -h
  exit 0
fi

if [[ -f "$SWAP_FILE" ]]; then
  warn "Swap dosyası mevcut, yeniden etkinleştiriliyor..."
  chmod 600 "$SWAP_FILE"
  mkswap "$SWAP_FILE" >/dev/null
  swapon "$SWAP_FILE"
else
  info "Swap dosyası oluşturuluyor (${SWAP_SIZE})..."
  mkdir -p "$VOLUME_ROOT"
  if fallocate -l "$SWAP_SIZE" "$SWAP_FILE" 2>/dev/null; then
    :
  else
    warn "fallocate başarısız, dd kullanılıyor (yavaş)..."
    dd if=/dev/zero of="$SWAP_FILE" bs=1M count=$(( ${SWAP_SIZE%G} * 1024 )) status=progress
  fi
  chmod 600 "$SWAP_FILE"
  mkswap "$SWAP_FILE"
  swapon "$SWAP_FILE"
fi

if ! grep -qF "$SWAP_FILE" /etc/fstab 2>/dev/null; then
  echo "$SWAP_FILE none swap sw 0 0" >> /etc/fstab
  info "fstab güncellendi"
fi

sysctl -w vm.swappiness=60 >/dev/null
grep -q '^vm.swappiness' /etc/sysctl.conf 2>/dev/null || echo 'vm.swappiness=60' >> /etc/sysctl.conf

echo ""
info "Swap hazır:"
swapon --show
free -h
