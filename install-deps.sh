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
    volumeicon-alsa \
    fonts-jetbrains-mono \
    stow \
    playerctl

cd "$(dirname "$(readlink -f "$0")")"
for pkg in i3 i3status hypr screenlayouts tmux; do
    if [ "$pkg" = tmux ]; then
        # Keep ~/.tmux and ~/.config/nvim-treemux as real directories so TPM,
        # compiled plugins, and Neovim runtime files do not land in this repo.
        stow --no-folding -v -t "$HOME" "$pkg"
    elif [ -d "$pkg" ]; then
        stow -v -t "$HOME" "$pkg"
    fi
done

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
