#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/common.sh"

BASE_URL="$(get_base_url)"
PORT="$(get_port)"

if curl -sf "${BASE_URL}/status" >/dev/null 2>&1; then
  info "Valhalla çalışıyor (port ${PORT})"
  curl -sf "${BASE_URL}/status" | (command -v jq >/dev/null && jq . || cat)
  exit 0
fi

error "Valhalla yanıt vermiyor (port ${PORT})"
docker_compose ps 2>/dev/null || true
exit 1
