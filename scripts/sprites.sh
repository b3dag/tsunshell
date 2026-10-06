#!/usr/bin/env bash
# Crops and resizes a sprite-sheet set into per-outfit, per-crop expression
# images for the WezTerm avatar (see wezterm/wezterm.lua, and tsun outfit /
# tsun crop in shell/tsundere.sh).
#
# Source files must be named <prefix>_<outfit>_<expression>.png, all the
# same canvas size, with no underscores inside <outfit> or <expression>
# themselves (e.g. shion_schoolwinter_angry.png).
#
# One expression per outfit (--ref, default "normal") is auto-trimmed to
# find where the art actually starts, and that exact box is then applied to
# every expression in the same outfit, so she never jumps position or size
# when her face changes. --show controls how much of her, from the top of
# that trimmed box, ends up in the final image, and can be a comma list or
# "all" (the default) to generate every crop level in one pass, so tsun
# crop has something to switch between without re-running this script.
#
# Usage  ./scripts/sprites.sh <source-dir> [--show full,waist,bust|all] [--width N] [--ref normal] [--dest DIR]
set -euo pipefail

usage() {
  sed -n '2,19p' "${BASH_SOURCE[0]}"
  exit "${1:-0}"
}

[[ $# -ge 1 ]] || usage 1
SRC=$1; shift
SHOW=all
WIDTH=400
REF=normal
DEST_BASE="$HOME/.config/tsundere/sprites"

while [[ $# -gt 0 ]]; do
  case $1 in
    --show) SHOW=$2; shift 2 ;;
    --width) WIDTH=$2; shift 2 ;;
    --ref) REF=$2; shift 2 ;;
    --dest) DEST_BASE=$2; shift 2 ;;
    -h|--help) usage 0 ;;
    *) echo "Unknown option $1" >&2; usage 1 ;;
  esac
done

[[ $SHOW == all ]] && SHOW=full,waist,bust
IFS=',' read -r -a SHOWS <<< "$SHOW"
declare -A FRAC=([full]=1.00 [waist]=0.60 [bust]=0.35)
for s in "${SHOWS[@]}"; do
  [[ -v FRAC[$s] ]] || { echo "Unknown --show value: $s (use full, waist, bust or all)" >&2; exit 1; }
done

command -v convert  >/dev/null 2>&1 || { echo "ImageMagick (convert) is required" >&2; exit 1; }
command -v identify >/dev/null 2>&1 || { echo "ImageMagick (identify) is required" >&2; exit 1; }
[[ -d $SRC ]] || { echo "Not a directory: $SRC" >&2; exit 1; }

shopt -s nullglob
files=("$SRC"/*_*_*.png)
shopt -u nullglob
((${#files[@]})) || { echo "No <prefix>_<outfit>_<expr>.png files found in $SRC" >&2; exit 1; }

declare -A outfits=()
for f in "${files[@]}"; do
  base=$(basename "$f" .png)
  outfit=${base%_*}    # drop _<expr>
  outfit=${outfit##*_} # keep only the field right before it
  outfits[$outfit]=1
done

# outfit/crop -> "width height", so wezterm.lua can size her without any
# hardcoded per-outfit table. Keep existing entries for outfits not touched
# by this run, so adding one outfit never drops the others.
declare -A ratios=()
if [[ -f "$DEST_BASE/ratios.txt" ]]; then
  while read -r key w h; do
    [[ -n $key ]] && ratios["$key"]="$w $h"
  done < "$DEST_BASE/ratios.txt"
fi

total=0
for outfit in "${!outfits[@]}"; do
  ref_file=""
  for f in "${files[@]}"; do
    if [[ $(basename "$f") == *"_${outfit}_${REF}.png" ]]; then
      ref_file=$f
      break
    fi
  done
  if [[ -z $ref_file ]]; then
    for f in "${files[@]}"; do
      [[ $(basename "$f") == *"_${outfit}_"* ]] && { ref_file=$f; break; }
    done
  fi

  box=$(identify -format '%@' "$ref_file")
  cw=${box%%x*}; rest=${box#*x}
  ch=${rest%%+*}; rest=${rest#*+}
  cx=${rest%%+*}; cy=${rest#*+}

  for show in "${SHOWS[@]}"; do
    vh=$(awk -v h="$ch" -v f="${FRAC[$show]}" 'BEGIN { printf "%d", h * f }')
    outdir="$DEST_BASE/$outfit/$show"
    mkdir -p "$outdir"

    for f in "${files[@]}"; do
      [[ $(basename "$f") == *"_${outfit}_"* ]] || continue
      expr=$(basename "$f" .png)
      expr=${expr##*_${outfit}_}
      convert "$f" -crop "${cw}x${ch}+${cx}+${cy}" +repage \
                    -crop "${cw}x${vh}+0+0" +repage \
                    -resize "${WIDTH}x" "$outdir/$expr.png"
      total=$((total + 1))
    done
    echo "$outfit/$show: $(ls "$outdir" | wc -l) sprites -> $outdir"

    # Record this outfit/crop's actual pixel size (any file in the set
    # works, they are all identical by construction)
    shopt -s nullglob
    outfiles=("$outdir"/*.png)
    shopt -u nullglob
    ratios["$outfit/$show"]=$(identify -format '%w %h' "${outfiles[0]}")
  done
done
{
  for k in "${!ratios[@]}"; do
    echo "$k ${ratios[$k]}"
  done
} | sort > "$DEST_BASE/ratios.txt"

echo "Done. $total sprites cropped (--show ${SHOW}, width ${WIDTH}px) into $DEST_BASE"
echo "Outfits: ${!outfits[*]}"
