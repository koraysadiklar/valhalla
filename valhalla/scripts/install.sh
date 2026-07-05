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

# ── [1/6] Ortam ──
info "[1/6] Ortam dosyaları"
if [[ ! -f .env ]]; then
  cp valhalla/regions/turkey.env .env
  info "      .env oluşturuldu (varsayılan: turkey)"
else
  info "      .env mevcut"
fi

load_env
info "      Harita: $(basename "${TILE_URLS%% *}")"
info "      Thread: ${SERVER_THREADS:-1}"

# ── [2/6] PBF sil + yeniden indir ──
echo ""
info "[2/6] PBF indiriliyor (eski dosya silinip yeniden yüklenir)"
valhalla_refresh_pbf

# ── [3/6] Docker imaj ──
echo ""
info "[3/6] Docker imajı çekiliyor..."
valhalla_pull
info "      İmaj hazır"

# ── [4/6] Container ──
echo ""
info "[4/6] Container başlatılıyor..."
valhalla_start
sleep 3
info "      Container: $(docker ps -aq --filter name=^valhalla$ | head -1)"

PORT="$(get_port)"

# ── [5/6] Build izleme ──
echo ""
info "[5/6] Tile build & servis bekleniyor"
warn "      Türkiye haritası 30-90 dk sürebilir."
echo ""

attempt=0
max_attempts=360
last_stage=""
dots=0
fatal_count=0

while (( attempt < max_attempts )); do
  if curl -sf "http://localhost:${PORT}/status" >/dev/null 2>&1; then
    echo ""
    echo ""
    info "[6/6] Servis hazır!"
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

  if valhalla_fatal_in_logs; then
    fatal_count=$((fatal_count + 1))
    if (( fatal_count >= 3 )); then
      echo ""
      error "Build tekrar tekrar çöküyor."
      valhalla_diagnose_failure
      exit 1
    fi
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
      info "      … ${mins}dk ${secs}sn — ${stage}"
    fi
  fi

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
warn "Zaman aşımı — build devam ediyor olabilir: make logs"
exit 0
