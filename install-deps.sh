#!/bin/bash
# Bootstrap: install dependencies and stow dotfiles into $HOME.
set -e

sudo apt update && sudo apt install -y \
    feh \
    brightnessctl \
    curl \
    fzf \
    git \
    i3lock \
    lsof \
    neovim \
    python3-venv \
    rofi \
    maim \
    tmux \
    xclip \
    xdotool \
    xinput \
    autocutsel \
    picom \
    xfce4-clipman-plugin \
    fonts-font-awesome \
    volumeicon-alsa \
    fonts-jetbrains-mono \
    stow \
    playerctl

cd "$(dirname "$(readlink -f "$0")")"
# --no-folding links individual files rather than whole directories, so shared
# dirs like ~/.local/bin and ~/.tmux stay real and their other contents (TPM
# plugins, Neovim runtime files, unrelated binaries) never land in this repo.
for pkg in i3 i3status hypr screenlayouts xprofile git rofi; do
    [ -d "$pkg" ] && stow -v -t "$HOME" "$pkg"
done
for pkg in tmux battery-monitor zellij niri waybar; do
    [ -d "$pkg" ] && stow --no-folding -v -t "$HOME" "$pkg"
done

systemctl --user daemon-reload
systemctl --user enable --now battery-monitor.service

treemux_venv="$HOME/.local/share/treemux/venv"
if [ ! -x "$treemux_venv/bin/python" ]; then
    python3 -m venv "$treemux_venv"
fi
if ! "$treemux_venv/bin/python" -c 'import pynvim' 2>/dev/null; then
    "$treemux_venv/bin/pip" install pynvim
fi

tpm_dir="$HOME/.tmux/plugins/tpm"
if [ ! -d "$tpm_dir/.git" ]; then
    git clone https://github.com/tmux-plugins/tpm "$tpm_dir"
fi
"$tpm_dir/bin/install_plugins"

echo
echo "Done. bashrc intentionally not stowed — review bashrc/.bashrc and stow manually if desired:"
echo "  stow -v -t \"\$HOME\" bashrc"
echo
echo "Root-owned configs (keyd keymaps, logind lid/power drop-ins) are separate:"
echo "  sudo ./system/install-system.sh"
