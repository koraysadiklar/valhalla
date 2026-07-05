#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/common.sh"

load_env
BASE_URL="$(get_base_url)"
PORT="$(get_port)"
ID="$(valhalla_container_id || true)"
STATUS="$(valhalla_container_status)"

if curl -sf "${BASE_URL}/status" >/dev/null 2>&1; then
  info "Valhalla çalışıyor (port ${PORT})"
  curl -sf "${BASE_URL}/status" | (command -v jq >/dev/null && jq . || cat)
  exit 0
fi

error "Valhalla yanıt vermiyor (port ${PORT})"
echo ""
echo "────────── Container ──────────"
docker ps -a --filter "name=valhalla" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo ""

if [[ -n "$ID" ]]; then
  warn "Durum: ${STATUS} | Container: ${ID}"
  echo ""
  echo "────────── Son loglar ──────────"
  valhalla_docker_logs 2>/dev/null | tail -30 || true
  echo ""
  if [[ "$STATUS" == "exited" || "$STATUS" == "dead" ]]; then
    warn "Container çökmüş. Temizleyip yeniden başlatın:"
    warn "  make down && make up"
    warn "  veya: make install  (PBF varsa atlar, yoksa indirir)"
  fi
else
  warn "Valhalla container bulunamadı. Kurulum: make install"
fi

exit 1
