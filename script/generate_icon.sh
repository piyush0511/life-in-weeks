#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RES_DIR="$ROOT_DIR/Resources"
ICONSET="$RES_DIR/AppIcon.iconset"
ICNS_OUT="$RES_DIR/AppIcon.icns"
RENDERER="$ROOT_DIR/script/icon_render.swift"

mkdir -p "$ICONSET"
rm -f "$ICONSET"/*.png

declare -a SIZES=(
  "16:icon_16x16.png"
  "32:icon_16x16@2x.png"
  "32:icon_32x32.png"
  "64:icon_32x32@2x.png"
  "128:icon_128x128.png"
  "256:icon_128x128@2x.png"
  "256:icon_256x256.png"
  "512:icon_256x256@2x.png"
  "512:icon_512x512.png"
  "1024:icon_512x512@2x.png"
)

chmod +x "$RENDERER" 2>/dev/null || true

for spec in "${SIZES[@]}"; do
  px="${spec%%:*}"
  name="${spec##*:}"
  swift "$RENDERER" "$px" "$ICONSET/$name"
done

rm -f "$ICNS_OUT"
iconutil --convert icns --output "$ICNS_OUT" "$ICONSET"

echo "Generated: $ICNS_OUT"
