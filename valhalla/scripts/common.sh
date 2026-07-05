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

docker_compose() {
  if docker compose version >/dev/null 2>&1; then
    docker compose "$@"
  elif command -v docker-compose >/dev/null 2>&1; then
    docker-compose "$@"
  else
    error "docker compose (v2) veya docker-compose kurulu değil."
    error "Kurulum: apt install -y docker-compose-plugin  veya  apt install -y docker-compose"
    exit 1
  fi
}

require_docker() {
  require_cmd docker
  if docker compose version >/dev/null 2>&1; then
    return 0
  fi
  if command -v docker-compose >/dev/null 2>&1; then
    warn "docker compose v2 yok; docker-compose (v1) kullanılıyor."
    return 0
  fi
  error "docker compose veya docker-compose bulunamadı."
  error "Kurulum: apt install -y docker-compose-plugin  veya  apt install -y docker-compose"
  exit 1
}

valhalla_container_status() {
  docker inspect -f '{{.State.Status}}' valhalla 2>/dev/null || echo "missing"
}

valhalla_alive() {
  local status
  status="$(valhalla_container_status)"
  [[ "$status" == "running" || "$status" == "restarting" || "$status" == "created" ]]
}

valhalla_log_tail() {
  docker logs valhalla 2>&1 | tail -n "${1:-1}" | sed 's/^[[:space:]]*//' | tr -d '\r'
}

valhalla_detect_stage() {
  local logs
  logs="$(docker logs valhalla 2>&1 | tail -30)"

  if curl -sf "http://localhost:$(get_port)/status" >/dev/null 2>&1; then
    echo "Servis hazır"
  elif [[ "$logs" == *"Starting valhalla service"* ]]; then
    echo "HTTP servisi başlatılıyor"
  elif [[ "$logs" == *"Enhancing the initial graph"* ]]; then
    echo "Graph iyileştiriliyor (son aşama)"
  elif [[ "$logs" == *"Build the initial graph"* ]] || [[ "$logs" == *"valhalla_build_tiles"* ]]; then
    echo "Routing tile'ları üretiliyor"
  elif [[ "$logs" == *"Building timezone"* ]]; then
    echo "Timezone veritabanı oluşturuluyor"
  elif [[ "$logs" == *"Building admin"* ]]; then
    echo "Admin veritabanı oluşturuluyor"
  elif [[ "$logs" == *"Downloading links"* ]] || [[ "$logs" == *"download"* ]]; then
    echo "OSM harita dosyası (PBF) indiriliyor"
  elif compgen -G "$CUSTOM_FILES/*.osm.pbf" >/dev/null 2>&1; then
    echo "PBF indirildi, yapılandırma hazırlanıyor"
  else
    echo "Container başlatılıyor"
  fi
}

valhalla_diagnose_failure() {
  local status exit_code oom
  status="$(valhalla_container_status)"
  exit_code="$(docker inspect -f '{{.State.ExitCode}}' valhalla 2>/dev/null || echo "?")"
  oom="$(docker inspect -f '{{.State.OOMKilled}}' valhalla 2>/dev/null || echo "false")"

  echo ""
  error "Kurulum tamamlanamadı (container: ${status}, exit: ${exit_code})"
  if [[ "$oom" == "true" ]]; then
    warn "Bellek yetersiz (OOM). .env içinde SERVER_THREADS=2 yapın veya make region REGION=istanbul deneyin."
  fi
  echo ""
  echo "────────── Container ──────────"
  docker ps -a --filter "name=^valhalla$" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
  echo ""
  echo "────────── Son loglar ──────────"
  docker logs valhalla 2>&1 | tail -50
  echo ""
  warn "Canlı izleme: make logs"
  warn "Yeniden deneme: make rebuild"
}

valhalla_running() {
  docker ps --filter "name=^valhalla$" --filter "status=running" --format '{{.Names}}' 2>/dev/null | grep -qx valhalla
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
