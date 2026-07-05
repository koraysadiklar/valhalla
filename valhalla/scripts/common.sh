#!/usr/bin/env bash
# Ortak yardımcılar — diğer scriptler tarafından source edilir

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
VALHALLA_DIR="$ROOT_DIR/valhalla"
CUSTOM_FILES="$VALHALLA_DIR/custom_files"
DATA_DIR="$VALHALLA_DIR/data"
BACKUP_DIR="$VALHALLA_DIR/backups"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

load_env() {
  if [[ -f "$ROOT_DIR/.env" ]]; then
    # shellcheck disable=SC1091
    set -a
    source "$ROOT_DIR/.env"
    set +a
  fi
}

get_port() {
  load_env
  echo "${VALHALLA_PORT:-8002}"
}

get_base_url() {
  echo "http://localhost:$(get_port)"
}

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    error "$1 bulunamadı."
    exit 1
  fi
}

require_docker() {
  require_cmd docker
  if ! docker compose version >/dev/null 2>&1; then
    error "docker compose v2 gerekli."
    exit 1
  fi
}

ensure_dirs() {
  mkdir -p \
    "$CUSTOM_FILES" \
    "$CUSTOM_FILES/elevation_data" \
    "$DATA_DIR/pbf" \
    "$DATA_DIR/tiles" \
    "$DATA_DIR/elevation" \
    "$DATA_DIR/admin" \
    "$DATA_DIR/timezone" \
    "$DATA_DIR/transit" \
    "$BACKUP_DIR"
}
