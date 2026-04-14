#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

mkdir -p output

# Concatenate all chapters in order
cd src
cat $(grep '.md' SUMMARY.md | sed 's/.*(\(.*\))/\1/' | tr '\n' ' ') > /tmp/full-book.md
cd ..

pandoc /tmp/full-book.md \
  -o output/book.pdf \
  --pdf-engine=xelatex \
  -V mainfont="PingFang SC" \
  -V monofont="Menlo" \
  -V geometry:margin=2.5cm \
  -V CJKmainfont="PingFang SC" \
  --toc --toc-depth=2 \
  --highlight-style=tango \
  -V title="Agent Skill 高质量设计指南" \
  -V author="手工川" \
  -V date="2026"

echo "✓ PDF output: output/book.pdf"
