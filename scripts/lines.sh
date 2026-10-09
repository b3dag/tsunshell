#!/usr/bin/env bash
# Copies every default phrase file from lines/ in this repo into
# ~/.config/tsundere/. Files that already exist are left alone, so your own
# additions and edits stay. Safe to run again any time, for example after
# updating the repo, it only ever creates what is missing.
#
# Each category is a folder of numbered files, one per affection level
# (lines/<category>/0.txt .. 4.txt, matching MY_LEVEL directly: 0 coldest,
# 4 warmest). To add a brand new category, just drop a new lines/<name>/
# folder with its own 0-4 files in this repo, nothing else to register.
# A category doesn't need every level filled in, my/pool in tsundere.sh
# falls back to the closest one that exists.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEST="$HOME/.config/tsundere"
mkdir -p "$DEST"

for dir in "$HERE"/lines/*/; do
  [[ -d $dir ]] || continue
  cat=$(basename "$dir")
  mkdir -p "$DEST/$cat"
  for src in "$dir"*.txt; do
    [[ -f $src ]] || continue
    dst="$DEST/$cat/$(basename "$src")"
    if [[ -f $dst ]]; then
      echo "kept     $dst"
    else
      cp "$src" "$dst"
      echo "created  $dst"
    fi
  done
done

echo "Done."
