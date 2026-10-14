# Zellij, Niri, and Waybar

These Stow packages capture Hassan's desktop configuration. Paths under
`/home/hassan`, monitor names, network interface, and local application paths
are intentional machine-specific settings; review them on another machine.

```sh
stow --no-folding -v -t "$HOME" zellij niri waybar
systemctl --user daemon-reload
systemctl --user enable primary-to-clipboard.service waybar-waifu.service
```

The bootstrap installer also stows these packages. If real files already exist
at the destination, back them up and remove only the files being replaced before
running Stow. Do not use `--adopt` unless you intend to overwrite the repository
copies. Enabling the services attaches them to graphical-session and Waybar
startup; it does not launch a new desktop session.

## Requirements

Install Zellij 0.45 or newer, Niri compatible with this config, and Waybar with
Niri module support separately. The existing bootstrap dependency list is not a
complete installer for this Wayland desktop.

- Zellij's **Ctrl+t, f** tab picker requires `fzf` and Python 3.
- Desktop helpers use Alacritty, Fuzzel, swaybg, swaylock, wlsunset, jq,
  wl-clipboard, libnotify tools, brightnessctl, playerctl, PipeWire/WirePlumber,
  NetworkManager (`nmcli`/`nmtui`), Flameshot, Swappy, slurp, and wf-recorder.
- Wallpaper selection needs Python GObject bindings and GTK 4.
- The Waybar character needs Python GObject, Cairo and GI Cairo bindings,
  GTK 3, and `libgtk-layer-shell.so.0`. Use matching system packages; the local
  machine's vendored Python binary extension is deliberately not included.
- Spotify's heart indicator needs Python D-Bus bindings and Spotify's
  accessibility interface. The launcher expects Spotify at `/snap/bin/spotify`.
- The bar uses Noto Sans and FontAwesome fonts. Optional launchers expect btop,
  bluetui, LazySSH, and the Easy Effects Flatpak.

## External local dependencies

Application binaries are installed separately: Clipse/Clipse GUI, Zen,
Mattermost, and the local Swappy launcher/build are referenced by the config.
Wallpaper images live in `~/wallpapers`; the selected wallpaper is
`~/.config/current-wallpaper`. Neither wallpaper images nor clipboard history
are included.

The VPN button expects an existing `openvpn-client@sageteck.service` and its
local sudo policy. VPN credentials and profiles are not included. The staging
dashboard launcher points to the separately maintained
`~/ringba/staging-monitor/open-dashboard.sh`.

The Niri package includes the Fuzzel window-search settings and primary-selection
clipboard service. The Waybar package includes Spotify/VPN/network helpers,
menus, character sprites and their upstream source/license information.
Runtime state, caches, backups, installed binaries, and unrelated application
configs are not part of these packages.
