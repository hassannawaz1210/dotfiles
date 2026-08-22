#!/usr/bin/env bash
# Install the root-owned configs that stow cannot symlink: keyd keymaps and the
# systemd-logind power drop-ins. Run with sudo.
#
# WARNING: reloading systemd-logind can terminate the running graphical session.
# This script therefore installs the logind drop-ins but does NOT restart
# logind; the settings take effect on the next boot.
set -euo pipefail

cd "$(dirname "$(readlink -f "$0")")"

if [ "$(id -u)" -ne 0 ]; then
    echo "Run with sudo: sudo $0" >&2
    exit 1
fi

# keyd: tap-vs-hold remap of the backtick key. keyd itself is built from source
# (https://github.com/rvaiya/keyd) and lives at /usr/local/bin/keyd.
if command -v keyd >/dev/null; then
    install -Dm644 keyd/default.conf /etc/keyd/default.conf
    # x85.conf targets the Apple keyboard 05ac:024f only; default.conf already
    # covers every keyboard, so keep it disabled unless the two need to differ.
    install -Dm644 keyd/x85.conf /etc/keyd/x85.conf.disabled
    keyd check /etc/keyd/default.conf
    keyd reload
    echo "keyd: reloaded"
else
    echo "keyd not installed, skipping keymaps. Build it from source first:" >&2
    echo "  git clone https://github.com/rvaiya/keyd && cd keyd && sudo make install" >&2
fi

# logind: suspend on lid close in every power state, ignore the power button.
install -Dm644 logind.conf.d/lid.conf /etc/systemd/logind.conf.d/lid.conf
install -Dm644 logind.conf.d/power-button.conf /etc/systemd/logind.conf.d/power-button.conf
echo "logind drop-ins installed. They apply on next boot."
echo "To apply now (WILL likely end your session): systemctl restart systemd-logind"

# Ubuntu grants backlight writes to the video group. Add the invoking desktop
# user so brightnessctl works from i3bar after their next login.
desktop_user="${SUDO_USER:-}"
if [ -n "$desktop_user" ] && ! id -nG "$desktop_user" | grep -qw video; then
    usermod -aG video "$desktop_user"
    echo "brightness: added $desktop_user to video; log out and back in to apply"
fi
