#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/common.sh"

info "Sistem bağımlılıkları kontrol ediliyor..."

if [[ $EUID -eq 0 ]]; then
  APT="apt-get"
else
  APT="sudo apt-get"
fi

apt_install() {
  local pkg=$1
  if ! dpkg -s "$pkg" >/dev/null 2>&1; then
    info "$pkg kuruluyor..."
    $APT update -qq
    DEBIAN_FRONTEND=noninteractive $APT install -y "$pkg"
  fi
}

if ! command -v make >/dev/null 2>&1; then
  apt_install make
fi

if ! command -v curl >/dev/null 2>&1; then
  apt_install curl
fi

if ! command -v wget >/dev/null 2>&1; then
  apt_install wget
fi

require_cmd docker
info "Bağımlılıklar hazır (docker run modu)."
