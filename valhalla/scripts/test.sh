#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/common.sh"

BASE_URL="$(get_base_url)"
EXAMPLES="$VALHALLA_DIR/examples"

require_cmd curl

echo "=== Status ==="
"$SCRIPT_DIR/../tests/status.sh"
echo ""

echo "=== Route ==="
curl -sf "${BASE_URL}/route" \
  -H "Content-Type: application/json" \
  -d @"$EXAMPLES/route.json" | (command -v jq >/dev/null && jq '{trip: .trip.summary, legs: (.trip.legs | length)}' || cat)
echo ""

echo "=== Height ==="
curl -sf "${BASE_URL}/height" \
  -H "Content-Type: application/json" \
  -d @"$EXAMPLES/height.json" | (command -v jq >/dev/null && jq . || cat)
echo ""

info "Tüm testler tamamlandı."
