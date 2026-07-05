#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/common.sh"

cd "$ROOT_DIR"
require_docker

info "Tile'lar zorla yeniden üretilecek..."
load_env
export FORCE_REBUILD=True
valhalla_docker_start
info "Log: make logs"
