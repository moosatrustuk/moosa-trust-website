#!/usr/bin/env bash
#
# convert-images.sh
# -----------------
# Converts the large hero/cause JPEGs into responsive WebP plus matching JPG
# fallbacks at three widths (480 / 960 / 1600). The HTML uses <picture> with
# srcset to pick the smallest variant a browser can use. Originals stay
# untouched.
#
# Requirements:
#   - cwebp (libwebp). Install:
#       macOS:    brew install webp
#       Ubuntu:   sudo apt install webp
#       Windows:  https://developers.google.com/speed/webp/download
#   - ImageMagick "convert" (optional, for the JPG fallback variants):
#       macOS:    brew install imagemagick
#       Ubuntu:   sudo apt install imagemagick
#
# Usage:
#   bash scripts/convert-images.sh

set -euo pipefail

cd "$(dirname "$0")/.."

if ! command -v cwebp >/dev/null 2>&1; then
  echo "ERROR: cwebp not found. Install libwebp (see header of this script)." >&2
  exit 1
fi
HAVE_CONVERT=0
command -v convert >/dev/null 2>&1 && HAVE_CONVERT=1

# Hero/cause/blog photographs. Add new entries here as more large images are
# introduced.
SOURCES=(
  "about-main.jpg"
  "about-water.jpg"
  "water.jpg"
  "education.jpg"
  "relief.jpg"
  "blog/hajj-qurbani-and-trust/livestock.jpg"
  "blog/hajj-qurbani-and-trust/cow.jpg"
)

WIDTHS=(480 960 1600)
QUALITY=80

for src in "${SOURCES[@]}"; do
  if [[ ! -f "$src" ]]; then
    echo "Skipping $src (not found)"
    continue
  fi
  base="${src%.jpg}"
  echo "Processing $src..."
  for w in "${WIDTHS[@]}"; do
    cwebp -q "$QUALITY" -resize "$w" 0 "$src" -o "${base}-${w}.webp" 2>/dev/null
    echo "  -> ${base}-${w}.webp"
    if [[ $HAVE_CONVERT -eq 1 ]]; then
      convert "$src" -resize "${w}x>" -strip -interlace Plane -quality 82 "${base}-${w}.jpg"
      echo "  -> ${base}-${w}.jpg"
    fi
  done
  cwebp -q "$QUALITY" "$src" -o "${base}.webp" 2>/dev/null
  echo "  -> ${base}.webp"
done

# Trustee / founder portraits. Used at 84x84 (and 72x72 in author cards). A
# single 168px square covers retina up to 84px display.
PORTRAITS=("minhaz.jpg" "faizel.jpg" "zubair.jpg")
for src in "${PORTRAITS[@]}"; do
  [[ -f "$src" ]] || { echo "Skipping $src (not found)"; continue; }
  base="${src%.jpg}"
  cwebp -q 82 -resize 168 168 "$src" -o "${base}-168.webp" 2>/dev/null
  echo "Portrait $src -> ${base}-168.webp"
  if [[ $HAVE_CONVERT -eq 1 ]]; then
    convert "$src" -resize "168x168^" -gravity center -extent 168x168 -strip -quality 85 "${base}-168.jpg"
    echo "  -> ${base}-168.jpg"
  fi
done

echo
echo "Done. Commit the new *.webp / *.jpg variants and push."
