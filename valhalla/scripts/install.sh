#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/common.sh"

cd "$ROOT_DIR"
require_cmd curl
require_docker
ensure_dirs

if [[ ! -f .env ]]; then
  cp .env.example .env
  info ".env dosyası oluşturuldu."
  warn "Bölge seçmek için: cp valhalla/regions/turkey.env .env"
else
  info ".env mevcut, korunuyor."
fi

load_env

# data/pbf içindeki dosyaları custom_files köküne kopyala (Valhalla burada arar)
shopt -s nullglob
pbf_files=("$DATA_DIR"/pbf/*.osm.pbf "$DATA_DIR"/pbf/*.pbf)
if ((${#pbf_files[@]})); then
  info "PBF dosyaları custom_files dizinine kopyalanıyor..."
  cp -f "${pbf_files[@]}" "$CUSTOM_FILES/"
fi

info "Docker imajı çekiliyor..."
docker_compose pull

info "Valhalla başlatılıyor..."
docker_compose up -d

PORT="$(get_port)"
info "Tile üretimi harita boyutuna göre uzun sürebilir."
info "Loglar: make logs"

attempt=0
max_attempts=240
info "Servis bekleniyor (http://localhost:${PORT}/status)..."

while (( attempt < max_attempts )); do
  if curl -sf "http://localhost:${PORT}/status" >/dev/null 2>&1; then
    echo ""
    info "Valhalla hazır!"
    info "Test: make test"
    exit 0
  fi

  if ! docker_compose ps --status running --services 2>/dev/null | grep -q valhalla; then
    error "Container çalışmıyor. Log: docker compose logs valhalla"
    exit 1
  fi

  attempt=$((attempt + 1))
  printf "."
  sleep 15
done

echo ""
warn "Zaman aşımı — tile build devam ediyor olabilir."
warn "Log: docker compose logs -f valhalla"
