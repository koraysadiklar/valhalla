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

require_cmd docker

if ! docker compose version >/dev/null 2>&1 && ! command -v docker-compose >/dev/null 2>&1; then
  info "Docker Compose kuruluyor..."
  if $APT update -qq && DEBIAN_FRONTEND=noninteractive $APT install -y docker-compose-plugin 2>/dev/null; then
    :
  else
    apt_install docker-compose
  fi
fi

require_docker
info "Bağımlılıklar hazır."
