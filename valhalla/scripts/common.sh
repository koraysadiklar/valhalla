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

compose_v2_available() {
  docker compose version >/dev/null 2>&1
}

valhalla_docker_pull() {
  docker pull ghcr.io/valhalla/valhalla-scripted:latest
}

# docker-compose v1.29 ContainerConfig hatasını tamamen bypass eder
valhalla_docker_start() {
  docker rm -f valhalla 2>/dev/null || true

  # PBF host'ta indirildi — container tekrar indirmesin
  local tile_urls_env=""
  if ! compgen -G "$CUSTOM_FILES/*.pbf" >/dev/null && ! compgen -G "$CUSTOM_FILES/*.osm.pbf" >/dev/null; then
    tile_urls_env="${TILE_URLS:-}"
  fi

  docker run -d \
    --name valhalla \
    --restart unless-stopped \
    -p "${VALHALLA_PORT:-8002}:8002" \
    -v "${CUSTOM_FILES}:/custom_files" \
    -e "tile_urls=${tile_urls_env}" \
    -e "server_threads=${SERVER_THREADS:-1}" \
    -e "use_tiles_ignore_pbf=${USE_TILES_IGNORE_PBF:-False}" \
    -e "force_rebuild=${FORCE_REBUILD:-False}" \
    -e "build_elevation=${BUILD_ELEVATION:-False}" \
    -e "build_admins=${BUILD_ADMINS:-True}" \
    -e "build_time_zones=${BUILD_TIME_ZONES:-True}" \
    -e "build_transit=${BUILD_TRANSIT:-False}" \
    -e "build_tar=${BUILD_TAR:-True}" \
    -e "serve_tiles=${SERVE_TILES:-True}" \
    -e "update_existing_config=${UPDATE_EXISTING_CONFIG:-True}" \
    -e "use_default_speeds_config=${USE_DEFAULT_SPEEDS_CONFIG:-True}" \
    --memory 7g \
    --shm-size 256m \
    ghcr.io/valhalla/valhalla-scripted:latest
}

valhalla_pull() {
  valhalla_docker_pull
}

valhalla_start() {
  load_env
  valhalla_docker_start
}

docker_compose() {
  if compose_v2_available; then
    docker compose "$@"
  elif command -v docker-compose >/dev/null 2>&1; then
    docker-compose "$@"
  else
    error "docker compose v2 yok. Kurulum: apt install -y docker-compose-plugin"
    error "Alternatif: make install (docker run ile başlatır)"
    exit 1
  fi
}

docker_compose_fresh_up() {
  valhalla_start
}

require_docker() {
  require_cmd docker
  if compose_v2_available; then
    return 0
  fi
  warn "docker compose v2 yok — kurulum docker run ile yapılacak."
}

valhalla_pbf_min_bytes() {
  local name="$1"
  case "$name" in
    *andorra*)     echo $((2 * 1024 * 1024)) ;;
    *istanbul*)    echo $((10 * 1024 * 1024)) ;;
    *turkey*)      echo $((200 * 1024 * 1024)) ;;
    *)             echo $((5 * 1024 * 1024)) ;;
  esac
}

valhalla_verify_pbf() {
  local file="$1"
  local min_bytes size

  if [[ ! -f "$file" ]]; then
    error "PBF bulunamadı: $file"
    return 1
  fi

  size="$(stat -c%s "$file" 2>/dev/null || stat -f%z "$file")"
  min_bytes="$(valhalla_pbf_min_bytes "$(basename "$file")")"

  if head -c 64 "$file" 2>/dev/null | grep -qiE '<!DOCTYPE|<html|Error|Access'; then
    error "PBF geçersiz — HTML/hata sayfası indirilmiş: $file"
    return 1
  fi

  if (( size < min_bytes )); then
    error "PBF çok küçük veya yarım: $(basename "$file") ($(numfmt --to=iec "$size" 2>/dev/null || echo "${size} byte"), min ~$(numfmt --to=iec "$min_bytes" 2>/dev/null || echo "$min_bytes"))"
    return 1
  fi

  info "PBF OK: $(basename "$file") ($(numfmt --to=iec "$size" 2>/dev/null || echo "${size} byte"))"
  return 0
}

valhalla_normalize_url() {
  local url="$1"
  # Geofabrik: Turkey asia → europe taşındı
  url="${url//download.geofabrik.de\/asia\/turkey/download.geofabrik.de/europe/turkey}"
  echo "$url"
}

valhalla_resolve_url() {
  local url="$1"
  local final

  url="$(valhalla_normalize_url "$url")"
  final="$(curl -fsI -L -o /dev/null -w '%{url_effective}' "$url" 2>/dev/null || true)"

  if [[ -z "$final" ]]; then
    echo "$url"
    return 0
  fi

  if [[ "$final" =~ download\.geofabrik\.de/?$ ]]; then
    error "Geçersiz URL — Geofabrik ana sayfaya yönlendirdi: $url"
    error "Türkiye için doğru URL: https://download.geofabrik.de/europe/turkey-latest.osm.pbf"
    return 1
  fi

  if [[ "$final" != "$url" ]]; then
    info "Yönlendirme: $(basename "$final")" >&2
  fi
  echo "$url"
}

valhalla_download_pbf() {
  local url="${1:?URL gerekli}"
  local dest="${2:?Hedef dosya gerekli}"
  local tmp="${dest}.part"
  local resolved

  resolved="$(valhalla_resolve_url "$url")" || return 1

  mkdir -p "$(dirname "$dest")"
  rm -f "$tmp"
  info "İndiriliyor: $resolved"

  if command -v curl >/dev/null 2>&1; then
    curl -L --fail --retry 3 --retry-delay 5 --progress-bar -o "$tmp" "$resolved"
  elif command -v wget >/dev/null 2>&1; then
    wget --progress=dot:giga -O "$tmp" "$resolved"
  else
    error "curl veya wget gerekli."
    return 1
  fi

  mv "$tmp" "$dest"
  valhalla_verify_pbf "$dest"
}

valhalla_refresh_pbf() {
  load_env
  local url="${TILE_URLS%% *}"
  local filename dest

  if [[ -z "$url" ]]; then
    error "TILE_URLS .env içinde tanımlı değil. Önce: make region REGION=turkey"
    return 1
  fi

  filename="$(basename "$url")"
  dest="$CUSTOM_FILES/$filename"

  info "Eski PBF ve build dosyaları siliniyor..."
  docker rm -f valhalla 2>/dev/null || true

  shopt -s nullglob
  rm -f "$CUSTOM_FILES"/*.osm.pbf "$CUSTOM_FILES"/*.pbf "$DATA_DIR"/pbf/*.osm.pbf "$DATA_DIR"/pbf/*.pbf
  rm -f "$CUSTOM_FILES/.file_hashes.txt"
  rm -f "$CUSTOM_FILES/admins.sqlite" "$CUSTOM_FILES/timezones.sqlite"
  rm -f "$CUSTOM_FILES/valhalla_tiles.tar" "$CUSTOM_FILES/default_speeds.json"
  rm -rf "$CUSTOM_FILES/valhalla_tiles" 2>/dev/null || true

  valhalla_download_pbf "$url" "$dest"
  cp -f "$dest" "$DATA_DIR/pbf/$filename"
}

# Geriye dönük uyumluluk
valhalla_ensure_pbf() {
  valhalla_refresh_pbf
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
  [[ "$logs" == *"pbf_error"* ]] || \
  [[ "$logs" == *"invalid BlobHeader"* ]] || \
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
