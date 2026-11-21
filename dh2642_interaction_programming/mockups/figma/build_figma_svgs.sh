#!/bin/bash
# Regenerate the Figma-ready SVGs from the authored (class-based) wireframes.
# Run from anywhere:  bash build_figma_svgs.sh
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
MOCKUPS="$(dirname "$HERE")"

for name in Mobile_390 TabletPortrait_834 Desktop_1280; do
  src="$MOCKUPS/CatchUp_${name}.svg"
  out="$HERE/CatchUp_${name}.figma.svg"
  python3 "$HERE/flatten_for_figma.py" "$src" "$out"
done

echo
echo "Figma-ready files:"
ls -la "$HERE"/*.figma.svg
