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
install_file "$HERE/shell/tsundere.sh" "$HOME/.tsundere.sh"

echo "== Phrase files"
bash "$HERE/scripts/lines.sh"

if ((DO_IMAGES)); then
  echo "== Images"
  mkdir -p "$HOME/.config/tsundere"
  for img in "$HERE"/images/*.png; do
    [[ -f $img ]] || continue
    install_file "$img" "$HOME/.config/tsundere/$(basename "$img")"
  done
fi

if ((DO_WEZTERM)); then
  echo "== WezTerm"
  install_file "$HERE/wezterm/wezterm.lua" "$HOME/.config/wezterm/wezterm.lua"
fi

echo "== Starship"
if [[ -f $HOME/.config/starship.toml ]]; then
  echo "You already have ~/.config/starship.toml, so it was left alone."
  echo "Merge the custom.tsundere block and the \${custom.tsundere} part of the format from"
  echo "  $HERE/starship/starship.toml"
else
  install_file "$HERE/starship/starship.toml" "$HOME/.config/starship.toml"
fi

cat << 'EOF'

== One manual step
Put these four lines at the very end of ~/.bashrc, in this order.

  source ~/.local/share/blesh/ble.sh --noattach
  eval "$(starship init bash)"
  [[ -f ~/.tsundere.sh ]] && source ~/.tsundere.sh
  [[ ${BLE_VERSION-} ]] && ble-attach

Then open a new terminal. The sudo messages and the goodbye line are optional,
see docs/SETUP.md, parts 6 and 7.
EOF
