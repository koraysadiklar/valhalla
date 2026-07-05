#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/common.sh"

cd "$ROOT_DIR"
require_docker

info "Güncel imaj çekiliyor..."
docker_compose pull

info "Container yeniden oluşturuluyor..."
docker rm -f valhalla 2>/dev/null || true
docker_compose up -d

info "Tamamlandı."
