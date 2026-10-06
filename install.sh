#!/usr/bin/env bash
# Installs the tsundere terminal into your home folder.
# Usage  ./install.sh [--no-wezterm] [--no-images]
# Existing files are backed up with a .bak suffix before they are replaced.

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DO_WEZTERM=1
DO_IMAGES=1

for arg in "$@"; do
  case $arg in
    --no-wezterm) DO_WEZTERM=0 ;;
    --no-images) DO_IMAGES=0 ;;
    -h|--help)
      sed -n '2,4p' "${BASH_SOURCE[0]}"
      exit 0
      ;;
    *)
      echo "Unknown option $arg"
      exit 1
      ;;
  esac
done

# Copy a file, keeping a backup if the target exists and is different
install_file() {
  local src=$1 dst=$2
  mkdir -p "$(dirname "$dst")"
  if [[ -f $dst ]] && ! cmp -s "$src" "$dst"; then
    cp "$dst" "$dst.bak"
    echo "backup   $dst.bak"
  fi
  cp "$src" "$dst"
  echo "installed $dst"
}

echo "== Shell logic"
install_file "$HERE/shell/tsundere.sh" "$HOME/.config/tsundere/tsundere.sh"
install_file "$HERE/shell/ai.sh" "$HOME/.config/tsundere/ai.sh"

echo "== Phrase files"
bash "$HERE/scripts/lines.sh"

if ((DO_IMAGES)) && [[ -d "$HERE/images/sprites" ]]; then
  echo "== Images"
  mkdir -p "$HOME/.config/tsundere/sprites"
  cp -r "$HERE/images/sprites/." "$HOME/.config/tsundere/sprites/"
  outfits=$(cd "$HERE/images/sprites" && for d in */; do echo "${d%/}"; done)
  echo "installed $HOME/.config/tsundere/sprites (outfits: ${outfits//$'\n'/ })"
  echo "Pick one with: tsun outfit <name>"
fi

if ((DO_WEZTERM)); then
  echo "== WezTerm"
  install_file "$HERE/wezterm/wezterm.lua" "$HOME/.config/wezterm/wezterm.lua"
fi

cat << 'EOF'

== One manual step
Add this line anywhere in ~/.bashrc (the end is fine).

  [[ -f ~/.config/tsundere/tsundere.sh ]] && source ~/.config/tsundere/tsundere.sh

If you have older ble.sh or starship init lines from a previous setup,
neither is required anymore, remove them if you like. Then open a new
terminal.
EOF
