#!/usr/bin/env bash
# Removes the tsundere terminal files from your home folder.
# Your .bashrc is not touched, remove the source line yourself.

set -euo pipefail

read -r -p "Remove ~/.config/tsundere (shell logic, phrases, images) and saved stats? [y/N] " a
[[ $a == [yY]* ]] || { echo "Cancelled."; exit 0; }

rm -rf "$HOME/.config/tsundere"
rm -rf "${XDG_CACHE_HOME:-$HOME/.cache}/tsundere"

echo "Done. Remove the four lines from ~/.bashrc."
echo "If you want the old WezTerm config back, restore ~/.config/wezterm/wezterm.lua.bak if it exists."
