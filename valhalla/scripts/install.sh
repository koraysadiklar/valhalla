#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/common.sh"

cd "$ROOT_DIR"
require_cmd curl
require_docker
ensure_dirs

echo ""
info "═══════════════════════════════════════"
info "  Valhalla Stack — Kurulum"
info "═══════════════════════════════════════"
echo ""

# ── Aşama 1: Ortam ──
info "[1/5] Ortam dosyaları kontrol ediliyor..."
if [[ ! -f .env ]]; then
  cp .env.example .env
  info "      .env oluşturuldu (.env.example)"
  warn "      Bölge: make region REGION=turkey"
else
  info "      .env mevcut"
fi

load_env
REGION_NAME="${TILE_URLS%% *}"
REGION_NAME="$(basename "$REGION_NAME" 2>/dev/null || echo "özel")"
info "      Harita: ${REGION_NAME}"
info "      Thread: ${SERVER_THREADS:-4}"

shopt -s nullglob
pbf_files=("$DATA_DIR"/pbf/*.osm.pbf "$DATA_DIR"/pbf/*.pbf)
if ((${#pbf_files[@]})); then
  info "      Yerel PBF dosyaları custom_files'a kopyalanıyor..."
  cp -f "${pbf_files[@]}" "$CUSTOM_FILES/"
fi

# ── Aşama 2: Docker imaj ──
echo ""
info "[2/5] Docker imajı çekiliyor..."
docker_compose pull
info "      İmaj hazır"

# ── Aşama 3: Container başlat ──
echo ""
info "[3/5] Container başlatılıyor..."
docker_compose up -d
sleep 3
info "      Container ID: $(docker ps -aq --filter name=^valhalla$ | head -1)"

PORT="$(get_port)"

# ── Aşama 4: Build izleme ──
echo ""
info "[4/5] Tile build & servis bekleniyor"
warn "      Türkiye haritası 30-90 dk sürebilir. İlerleme aşağıda görünür."
echo ""

attempt=0
max_attempts=360   # 360 × 15s = 90 dk
last_stage=""
dots=0

while (( attempt < max_attempts )); do
  if curl -sf "http://localhost:${PORT}/status" >/dev/null 2>&1; then
    echo ""
    echo ""
    info "[5/5] Servis hazır!"
    info "      URL: http://localhost:${PORT}/status"
    info "      Test: make test"
    exit 0
  fi

  status="$(valhalla_container_status)"

  if [[ "$status" == "exited" || "$status" == "dead" ]]; then
    echo ""
    valhalla_diagnose_failure
    exit 1
  fi

  if [[ "$status" == "missing" ]]; then
    echo ""
    error "Container bulunamadı."
    exit 1
  fi

  stage="$(valhalla_detect_stage)"
  elapsed=$((attempt * 15))
  mins=$((elapsed / 60))
  secs=$((elapsed % 60))

  if [[ "$stage" != "$last_stage" ]]; then
    [[ -n "$last_stage" ]] && echo ""
    info "      → ${stage}"
    last_stage="$stage"
    dots=0
  else
    dots=$((dots + 1))
    printf "."
    if (( dots % 40 == 0 )); then
      echo ""
      info "      … ${mins}dk ${secs}sn geçti — hâlâ: ${stage}"
    fi
  fi

  # Her ~2 dakikada son log satırını göster
  if (( attempt > 0 && attempt % 8 == 0 )); then
    log_line="$(valhalla_log_tail 1)"
    if [[ -n "$log_line" ]]; then
      echo ""
      info "      log: ${log_line:0:120}"
    fi
  fi

  attempt=$((attempt + 1))
  sleep 15
done

echo ""
warn "Zaman aşımı (90 dk) — build hâlâ devam ediyor olabilir."
warn "Container çalışıyorsa endişelenmeyin: make logs"
valhalla_diagnose_failure
exit 0
