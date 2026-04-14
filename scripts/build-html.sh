#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mdbook build
echo "✓ HTML output: book/"
