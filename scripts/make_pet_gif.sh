#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "Usage: scripts/make_pet_gif.sh <sprite-sheet.png> <output.gif> [cols] [rows] [delay_cs]" >&2
  echo "Example: scripts/make_pet_gif.sh pet/leafbuds/leafbuds_happy_sheet_12.png outputs/pet_previews/leafbuds_happy.gif 4 3 8" >&2
  exit 1
fi

INPUT="$1"
OUTPUT="$2"
COLS="${3:-4}"
ROWS="${4:-3}"
DELAY_CS="${5:-8}"

if ! command -v magick >/dev/null 2>&1; then
  echo "ImageMagick 'magick' was not found. Install it with: brew install imagemagick" >&2
  exit 1
fi

if [[ ! -f "$INPUT" ]]; then
  echo "Input file not found: $INPUT" >&2
  exit 1
fi

WIDTH="$(magick identify -format '%w' "$INPUT")"
HEIGHT="$(magick identify -format '%h' "$INPUT")"
CHANNELS="$(magick identify -format '%[channels]' "$INPUT")"
FRAME_W=$((WIDTH / COLS))
FRAME_H=$((HEIGHT / ROWS))

if (( WIDTH % COLS != 0 || HEIGHT % ROWS != 0 )); then
  echo "Image size ${WIDTH}x${HEIGHT} is not divisible by ${COLS}x${ROWS}." >&2
  exit 1
fi

if [[ "$CHANNELS" != *a* && "$CHANNELS" != *A* ]]; then
  echo "Warning: input does not appear to have an alpha channel. The checkerboard may be baked into the image." >&2
fi

mkdir -p "$(dirname "$OUTPUT")"
TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/pacekit_pet_frames.XXXXXX")"
trap 'rm -rf "$TMP_DIR"' EXIT

magick "$INPUT" -crop "${FRAME_W}x${FRAME_H}" +repage "$TMP_DIR/frame_%03d.png"
magick -delay "$DELAY_CS" -loop 0 "$TMP_DIR"/frame_*.png "$OUTPUT"

echo "Input:  $INPUT"
echo "Size:   ${WIDTH}x${HEIGHT}"
echo "Grid:   ${COLS}x${ROWS}"
echo "Frame:  ${FRAME_W}x${FRAME_H}"
echo "Delay:  ${DELAY_CS}cs per frame"
echo "Output: $OUTPUT"
