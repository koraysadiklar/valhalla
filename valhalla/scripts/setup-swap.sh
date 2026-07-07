#!/usr/bin/env bash
# 32 GB swap dosyası oluşturur (volume üzerinde)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/common.sh"

if [[ $EUID -ne 0 ]]; then
  error "root olarak çalıştırın: sudo $0"
  exit 1
fi

load_env

SWAP_SIZE="${SWAP_SIZE:-32G}"
SWAP_FILE="${SWAP_FILE:-/mnt/volume_ams3_1782933520272/swapfile}"

info "Swap kurulumu: ${SWAP_SIZE} → ${SWAP_FILE}"

# Volume dosya sistemi genişletilmiş mi?
if [[ -b /dev/sda ]]; then
  fs_size="$(df -BG --output=size /mnt/volume_ams3_1782933520272 2>/dev/null | tail -1 | tr -d 'G ' || echo 0)"
  if [[ "$fs_size" =~ ^[0-9]+$ ]] && (( fs_size < 1000 )); then
    warn "Volume hâlâ küçük görünüyor (${fs_size}G). Önce:"
    warn "  sudo resize2fs /dev/sda"
    warn "  df -h /mnt/volume_ams3_1782933520272"
  fi
fi

if swapon --show | grep -q "$SWAP_FILE"; then
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
  mkdir -p "$(dirname "$SWAP_FILE")"
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

# fstab'a ekle (yoksa)
if ! grep -qF "$SWAP_FILE" /etc/fstab 2>/dev/null; then
  echo "$SWAP_FILE none swap sw 0 0" >> /etc/fstab
  info "fstab güncellendi"
fi

# Swap kullanımını teşvik et (build sırasında RAM dolunca swap'a geçsin)
sysctl -w vm.swappiness=60
grep -q '^vm.swappiness' /etc/sysctl.conf 2>/dev/null || echo 'vm.swappiness=60' >> /etc/sysctl.conf

echo ""
info "Swap hazır:"
swapon --show
free -h
