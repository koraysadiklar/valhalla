#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../scripts/common.sh"

BASE_URL="$(get_base_url)"
curl -sf "${BASE_URL}/status" | (command -v jq >/dev/null && jq . || cat)
