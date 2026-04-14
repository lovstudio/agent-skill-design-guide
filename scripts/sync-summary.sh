#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
echo "src/SUMMARY.md is maintained manually — edit it directly or regenerate from OUTLINE.md"
echo "Current chapters:"
grep -c '\.md)' src/SUMMARY.md
echo "chapter links found in src/SUMMARY.md"
