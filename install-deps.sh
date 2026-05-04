#!/bin/bash
# Bootstrap: install dependencies and stow dotfiles into $HOME.
set -e

sudo apt update && sudo apt install -y \
    feh \
    brightnessctl \
    i3lock \
    rofi \
    maim \
    xclip \
    xdotool \
    xinput \
    volumeicon-alsa \
    fonts-jetbrains-mono \
    stow \
    playerctl

cd "$(dirname "$(readlink -f "$0")")"
for pkg in i3 i3status hypr screenlayouts; do
    [ -d "$pkg" ] && stow -v -t "$HOME" "$pkg"
done

echo
echo "Done. bashrc intentionally not stowed — review bashrc/.bashrc and stow manually if desired:"
echo "  stow -v -t \"\$HOME\" bashrc"
