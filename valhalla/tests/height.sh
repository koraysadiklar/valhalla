#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../scripts/common.sh"

BASE_URL="$(get_base_url)"
EXAMPLES="$SCRIPT_DIR/../examples"

curl -sf "${BASE_URL}/height" \
  -H "Content-Type: application/json" \
  -d @"$EXAMPLES/height.json" | (command -v jq >/dev/null && jq . || cat)
