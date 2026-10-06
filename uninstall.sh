#!/usr/bin/env bash
# Removes the tsundere terminal files from your home folder.
# Your .bashrc, starship.toml and sudoers are not touched, remove those lines yourself.

set -euo pipefail

read -r -p "Remove ~/.tsundere.sh, the phrase files, the images and saved stats? [y/N] " a
[[ $a == [yY]* ]] || { echo "Cancelled."; exit 0; }

rm -f "$HOME/.tsundere.sh"
rm -f "$HOME/.config/tsundere-phrases.txt" "$HOME/.config/tsundere-insults.txt" "$HOME/.config/tsundere-praise.txt"
rm -rf "$HOME/.config/tsundere"
rm -rf "${XDG_CACHE_HOME:-$HOME/.cache}/tsundere"
rm -f "${XDG_CACHE_HOME:-$HOME/.cache}/tsundere-meter"

echo "Done. Remove the four lines from ~/.bashrc and the custom.tsundere block from starship.toml."
echo "If you want the old WezTerm config back, restore ~/.config/wezterm/wezterm.lua.bak if it exists."
