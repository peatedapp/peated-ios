#!/bin/bash
set -euo pipefail

# Script to generate the iOS app icon with optional padding (inset)
# Uses sips (built-in on macOS). No ImageMagick required.

# Defaults (can be overridden via env or flags)
SOURCE_IMAGE_DEFAULT="/Users/dcramer/src/peated/apps/web/src/assets/glyph.png"
OUTPUT_DIR_DEFAULT="/Users/dcramer/src/peated-ios/Peated/Peated/Resources/Assets.xcassets/AppIcon.appiconset"
INSET_PERCENT_DEFAULT="12"   # percent of canvas on each side (e.g., 12 => 12%)
PAD_COLOR_DEFAULT="000000"    # default to black background for contrast

usage() {
  cat <<USAGE
Usage: $(basename "$0") [--source <path>] [--output <appiconset_dir>] [--inset <percent>] [--pad-color <hex>] [--recolor-to <hex>] [--allow-fallback]

  --source      Path to source image (PNG/SVG->rasterized elsewhere). Default: $SOURCE_IMAGE_DEFAULT
  --output      Path to .appiconset directory. Default: $OUTPUT_DIR_DEFAULT
  --inset       Padding per-side as percent (0-50). Default: $INSET_PERCENT_DEFAULT
  --pad-color   Hex background color used when padding. Default: $PAD_COLOR_DEFAULT
  --recolor-to  Recolor non-transparent pixels to this hex (e.g., F59E0B)
  --allow-fallback  Permit using existing AppIcon(.png) if source not found. Default: disabled (script exits if missing)

Environment overrides: SOURCE_IMAGE, OUTPUT_DIR, INSET_PERCENT, PAD_COLOR
USAGE
}

# Parse flags
SOURCE_IMAGE="${SOURCE_IMAGE:-$SOURCE_IMAGE_DEFAULT}"
OUTPUT_DIR="${OUTPUT_DIR:-$OUTPUT_DIR_DEFAULT}"
INSET_PERCENT="${INSET_PERCENT:-$INSET_PERCENT_DEFAULT}"
PAD_COLOR="${PAD_COLOR:-$PAD_COLOR_DEFAULT}"
ALLOW_FALLBACK=false
RECOLOR_TO=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --source)
      SOURCE_IMAGE="$2"; shift 2;;
    --output)
      OUTPUT_DIR="$2"; shift 2;;
    --inset)
      INSET_PERCENT="$2"; shift 2;;
    --pad-color)
      PAD_COLOR="${2#\#}"; shift 2;;
    --recolor-to)
      RECOLOR_TO="${2#\#}"; shift 2;;
    --allow-fallback)
      ALLOW_FALLBACK=true; shift 1;;
    -h|--help)
      usage; exit 0;;
    *)
      echo "Unknown option: $1" >&2; usage; exit 1;;
  esac
done

mkdir -p "$OUTPUT_DIR"

# Normalize inset to fraction (support values like 12 or 0.12)
if [[ "$INSET_PERCENT" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
  if (( $(echo "$INSET_PERCENT > 1" | bc -l) )); then
    INSET_FRAC=$(echo "scale=6; $INSET_PERCENT/100" | bc -l)
  else
    INSET_FRAC="$INSET_PERCENT"
  fi
else
  echo "Invalid --inset value: $INSET_PERCENT" >&2
  exit 1
fi

if (( $(echo "$INSET_FRAC < 0 || $INSET_FRAC >= 0.5" | bc -l) )); then
  echo "--inset must be between 0 and < 50%" >&2
  exit 1
fi

# Choose a usable source: prefer provided, else fallback to backup or current
PREFERRED_SOURCE="$SOURCE_IMAGE"
if [ ! -f "$PREFERRED_SOURCE" ]; then
  if [ "$ALLOW_FALLBACK" = true ]; then
    if [ -f "$OUTPUT_DIR/AppIcon_backup.png" ]; then
      PREFERRED_SOURCE="$OUTPUT_DIR/AppIcon_backup.png"
    elif [ -f "$OUTPUT_DIR/AppIcon.png" ]; then
      echo "Using existing AppIcon.png as source (will be inset/padded)."
      PREFERRED_SOURCE="$OUTPUT_DIR/AppIcon.png"
    else
      echo "Error: no source image found. Tried: $SOURCE_IMAGE, AppIcon_backup.png, AppIcon.png" >&2
      exit 1
    fi
  else
    echo "Error: source image not found: $SOURCE_IMAGE" >&2
    echo "Provide --source <path-to-amber glyph PNG/SVG->PNG> or use --allow-fallback to permit existing AppIcon.*" >&2
    exit 1
  fi
fi

PCT=$(python - <<PY
f=$INSET_FRAC
print(f"{f*100:.2f}")
PY
)
echo "🔧 Generating 1024×1024 AppIcon with inset ${PCT}% and pad color #$PAD_COLOR"

TMP_IMG=$(mktemp -t appicon-src).png
trap 'rm -f "$TMP_IMG"' EXIT

# Compute inner max dimension after inset per-side
INNER=$(python - <<PY
import math
f=$INSET_FRAC
print(int(round(1024*(1-2*f))))
PY
)

if [ "$INNER" -le 0 ]; then
  echo "Computed inner size invalid: $INNER" >&2
  exit 1
fi

# 1) Optional recolor of non-transparent pixels (requires ImageMagick 'magick')
WORK_IMG="$PREFERRED_SOURCE"
if [ -n "$RECOLOR_TO" ]; then
  if command -v magick >/dev/null 2>&1; then
    TMP_ALPHA=$(mktemp -t appicon-alpha).png
    trap 'rm -f "$TMP_IMG" "$TMP_ALPHA"' EXIT
    # Extract alpha, colorize to target, reapply original alpha
    magick "$PREFERRED_SOURCE" -alpha extract "$TMP_ALPHA"
    magick "$PREFERRED_SOURCE" -fill "#${RECOLOR_TO}" -colorize 100 -alpha off -compose copyopacity "$TMP_ALPHA" -composite "$TMP_IMG"
    WORK_IMG="$TMP_IMG"
    echo "🎨 Recolored non-transparent pixels to #$RECOLOR_TO"
  else
    echo "Warning: ImageMagick 'magick' not found; skipping recolor." >&2
  fi
fi

# 2) Scale the (possibly recolored) source to fit within INNER (preserve aspect)
sips -Z "$INNER" "$WORK_IMG" --out "$TMP_IMG" >/dev/null

# 3) Pad to exactly 1024×1024 using pad color
sips -p 1024 1024 --padColor "$PAD_COLOR" "$TMP_IMG" --out "$OUTPUT_DIR/AppIcon.png" >/dev/null

# 4) Update Contents.json
cat > "$OUTPUT_DIR/Contents.json" << 'EOF'
{
  "images" : [
    {
      "filename" : "AppIcon.png",
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOF

echo "✅ App icon generated at: $OUTPUT_DIR/AppIcon.png"
echo "   Inset: ${PCT}% per side | Pad color: #$PAD_COLOR"
