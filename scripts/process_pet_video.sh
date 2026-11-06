#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "Usage: scripts/process_pet_video.sh <input-video> <output-dir> [fps] [size]" >&2
  echo "Example: scripts/process_pet_video.sh pet/leafbuds/1777280828806.mp4 pet/leafbuds/generated/leafbuds_happy 16 512" >&2
  exit 1
fi

INPUT="$1"
OUT_DIR="$2"
FPS="${3:-16}"
SIZE="${4:-512}"

if [[ ! -f "$INPUT" ]]; then
  echo "Input video not found: $INPUT" >&2
  exit 1
fi

if ! command -v ffmpeg >/dev/null 2>&1; then
  echo "ffmpeg was not found. Install it with: brew install ffmpeg" >&2
  exit 1
fi

if ! command -v magick >/dev/null 2>&1; then
  echo "ImageMagick 'magick' was not found. Install it with: brew install imagemagick" >&2
  exit 1
fi

RAW_DIR="$OUT_DIR/raw_${FPS}fps_${SIZE}px"
FRAME_DIR="$OUT_DIR/frames_${FPS}fps_${SIZE}px_clean"
PREVIEW_GIF="$OUT_DIR/preview_${FPS}fps_${SIZE}px.gif"
SHEET_PNG="$OUT_DIR/sheet_${FPS}fps_${SIZE}px.png"

rm -rf "$RAW_DIR" "$FRAME_DIR"
mkdir -p "$RAW_DIR" "$FRAME_DIR" "$OUT_DIR"

echo "Extracting frames..."
ffmpeg -hide_banner -y \
  -i "$INPUT" \
  -an \
  -vf "fps=${FPS},scale=${SIZE}:${SIZE}:flags=lanczos" \
  "$RAW_DIR/frame_%04d.png"

MAX=$((SIZE - 1))
TOP_CLEAR_W=$((SIZE * 34 / 100))
TOP_CLEAR_H=$((SIZE * 15 / 100))
BOTTOM_CLEAR_X=$((SIZE * 77 / 100))
BOTTOM_CLEAR_Y=$((SIZE * 91 / 100))

echo "Removing background, clearing watermarks, and brightening foreground..."
count=0
for raw in "$RAW_DIR"/frame_*.png; do
  name="$(basename "$raw")"
  out="$FRAME_DIR/$name"
  magick "$raw" \
    -alpha set \
    -fuzz 5% \
    -fill none \
    -draw "color 0,0 floodfill" \
    -draw "color ${MAX},0 floodfill" \
    -draw "color 0,${MAX} floodfill" \
    -draw "color ${MAX},${MAX} floodfill" \
    -compose Clear \
    -draw "rectangle 0,0 ${TOP_CLEAR_W},${TOP_CLEAR_H}" \
    -draw "rectangle ${BOTTOM_CLEAR_X},${BOTTOM_CLEAR_Y} ${MAX},${MAX}" \
    -compose Over \
    -modulate 110,114,100 \
    -brightness-contrast 3x2 \
    \( +clone -alpha extract -threshold 5% \) \
    -alpha off \
    -compose CopyOpacity \
    -composite \
    -compose Clear \
    -draw "rectangle 0,0 ${TOP_CLEAR_W},${TOP_CLEAR_H}" \
    -draw "rectangle ${BOTTOM_CLEAR_X},${BOTTOM_CLEAR_Y} ${MAX},${MAX}" \
    -compose Over \
    -define png:color-type=6 \
    "$out"
  count=$((count + 1))
done

DELAY=$((100 / FPS))
if (( DELAY < 2 )); then
  DELAY=2
fi

echo "Creating preview GIF..."
magick -delay "$DELAY" -loop 0 "$FRAME_DIR"/frame_*.png "$PREVIEW_GIF"

echo "Creating sprite sheet..."
magick montage "$FRAME_DIR"/frame_*.png \
  -tile 18x \
  -geometry "${SIZE}x${SIZE}+0+0" \
  -background none \
  "$SHEET_PNG"

echo "Input:        $INPUT"
echo "Output dir:   $OUT_DIR"
echo "Raw frames:   $RAW_DIR"
echo "Clean frames: $FRAME_DIR"
echo "Preview GIF:  $PREVIEW_GIF"
echo "Sprite sheet: $SHEET_PNG"
echo "FPS:          $FPS"
echo "Frame size:   ${SIZE}x${SIZE}"
echo "Frame count:  $count"
