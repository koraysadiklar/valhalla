#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== status ==="
"$SCRIPT_DIR/status.sh"
echo ""

echo "=== route ==="
"$SCRIPT_DIR/route.sh"
echo ""

echo "=== height ==="
"$SCRIPT_DIR/height.sh"
