#!/usr/bin/env bash
# Copies every default phrase file from lines/ in this repo into
# ~/.config/tsundere/. Files that already exist are left alone, so your own
# additions and edits stay. Safe to run again any time, for example after
# updating the repo, it only ever creates what is missing.
#
# To add a new phrase file, just drop a new lines/<name>.txt in this repo,
# nothing else to register.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEST="$HOME/.config/tsundere"
mkdir -p "$DEST"

for src in "$HERE"/lines/*.txt; do
  [[ -f $src ]] || continue
  dst="$DEST/$(basename "$src")"
  if [[ -f $dst ]]; then
    echo "kept     $dst"
  else
    cp "$src" "$dst"
    echo "created  $dst"
  fi
done

echo "Done."
