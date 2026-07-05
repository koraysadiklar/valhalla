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

# docker-compose v1.29 + yeni Docker Engine → KeyError: 'ContainerConfig'
# Eski container'ı silip sıfırdan oluşturur.
docker_compose_fresh_up() {
  if docker ps -a --format '{{.Names}}' 2>/dev/null | grep -qx valhalla; then
    warn "Eski valhalla container'ı temizleniyor (ContainerConfig hatası önlemi)..."
    docker rm -f valhalla 2>/dev/null || true
  fi
  docker_compose up -d "$@"
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

valhalla_pbf_info() {
  local f size
  shopt -s nullglob
  local files=("$CUSTOM_FILES"/*.osm.pbf "$CUSTOM_FILES"/*.pbf)
  if ((${#files[@]} == 0)); then
    echo "PBF henüz yok"
    return
  fi
  for f in "${files[@]}"; do
    size="$(du -h "$f" 2>/dev/null | cut -f1)"
    echo "$(basename "$f") (${size})"
  done
}

valhalla_fatal_in_logs() {
  local logs
  logs="$(docker logs valhalla 2>&1 | tail -80)"
  [[ "$logs" == *"Aborted"* ]] || \
  [[ "$logs" == *"core dumped"* ]] || \
  [[ "$logs" == *"Killed"* ]] || \
  [[ "$logs" == *"Cannot allocate memory"* ]] || \
  [[ "$logs" == *"valhalla_build_admins"* && "$logs" == *"ERROR"* ]]
}

valhalla_detect_stage() {
  local logs
  logs="$(docker logs valhalla 2>&1 | tail -40)"

  if valhalla_fatal_in_logs; then
    echo "HATA: build çöktü (admin/tile aşaması)"
  elif curl -sf "http://localhost:$(get_port)/status" >/dev/null 2>&1; then
    echo "Servis hazır"
  elif [[ "$logs" == *"Starting valhalla service"* ]]; then
    echo "HTTP servisi başlatılıyor"
  elif [[ "$logs" == *"Enhancing the initial graph"* ]]; then
    echo "Graph iyileştiriliyor (son aşama)"
  elif [[ "$logs" == *"Build the initial graph"* ]] || [[ "$logs" == *"valhalla_build_tiles"* ]]; then
    echo "Routing tile'ları üretiliyor"
  elif [[ "$logs" == *"Building timezone"* ]]; then
    echo "Timezone veritabanı oluşturuluyor"
  elif [[ "$logs" == *"Building admin"* ]] || [[ "$logs" == *"valhalla_build_admins"* ]]; then
    echo "Admin veritabanı oluşturuluyor (SQLite)"
  elif [[ "$logs" == *"Downloading links"* ]] || [[ "$logs" == *"Download"* ]] || [[ "$logs" == *"wget"* ]] || [[ "$logs" == *"curl"* ]]; then
    echo "OSM harita dosyası (PBF) indiriliyor"
  elif compgen -G "$CUSTOM_FILES/*.osm.pbf" >/dev/null 2>&1 || compgen -G "$CUSTOM_FILES/*.pbf" >/dev/null 2>&1; then
    echo "PBF mevcut ($(valhalla_pbf_info)), yapılandırma hazırlanıyor"
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
  if [[ "$oom" == "true" ]] || docker logs valhalla 2>&1 | tail -80 | grep -qE 'Aborted|core dumped|Killed|Cannot allocate memory'; then
    warn "Bellek yetersiz veya build çöktü."
    warn "Çözüm: .env → SERVER_THREADS=1, sonra make clean && make rebuild"
    warn "Hızlı test: make region REGION=istanbul"
  fi
  if docker logs valhalla 2>&1 | tail -80 | grep -q "valhalla_build_admins"; then
    warn "Admin DB build başarısız. PBF dosyası eksik/bozuk olabilir:"
    warn "  ls -lh valhalla/custom_files/*.pbf   (Türkiye ~500MB olmalı)"
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
