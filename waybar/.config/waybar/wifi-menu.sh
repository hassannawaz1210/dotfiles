#!/bin/sh
#
# Wi-Fi picker for waybar's network module (left click).
#
# The menu is built from NetworkManager's AP cache and shown immediately; a
# rescan is kicked off in the background instead of blocking the menu. This
# matters because NM runs wpa_supplicant with bgscan=simple:30:-70:86400, so
# while connected above -70 dBm nothing refreshes the cache on its own -- but a
# blocking "--rescan yes" costs several seconds before anything appears on
# screen, which reads as a dead click.

LOCK="${XDG_RUNTIME_DIR:-/tmp}/waybar-wifi-menu.lock"

# fuzzel is single-instance. Without this guard a second click while the menu
# is opening spawns a fuzzel that dies on fuzzel's own lock, which looks like
# the click did nothing. Exit quietly instead: the menu is already coming.
exec 9>"$LOCK" || exit 1
if ! flock -n 9; then
  exit 0
fi

notify_error() {
  notify-send "Wi-Fi" "$1"
}

wifi_state=$(nmcli -t -f WIFI general 2>/dev/null) || {
  notify_error "NetworkManager is unavailable"
  exit 1
}

if [ "$wifi_state" != "enabled" ]; then
  choice=$(printf '%s\n' "Enable Wi-Fi" "Cancel" | fuzzel --dmenu --prompt="Wi-Fi: ")
  [ "$choice" = "Enable Wi-Fi" ] && {
    nmcli radio wifi on || notify_error "Could not enable Wi-Fi"
  }
  exit
fi

# Refresh the cache for the *next* open without making this one wait. Errors
# here are non-fatal: the menu still works off the existing cache.
nmcli device wifi rescan >/dev/null 2>&1 &

active_ssid=$(nmcli -t -f ACTIVE,SSID device wifi list --rescan no 2>/dev/null |
  awk -F: '$1 == "yes" { sub(/^yes:/, ""); print; exit }')

menu_items="Disable Wi-Fi
Rescan"

if [ -n "$active_ssid" ]; then
  menu_items="$menu_items
Disconnect: $active_ssid"
fi

networks=$(nmcli -t -f SSID,SECURITY,SIGNAL device wifi list --rescan no 2>/dev/null |
  awk -F: '
    $1 != "" && !seen[$1]++ {
      security = ($2 == "" || $2 == "--") ? "Open" : $2
      printf "%s  •  %s  •  %s%%\n", $1, security, $3
    }')

if [ -n "$networks" ]; then
  menu_items="$menu_items
$networks"
fi

choice=$(printf '%s\n' "$menu_items" | fuzzel --dmenu --prompt="Wi-Fi: ")

case "$choice" in
  ""|Cancel)
    exit
    ;;
  "Disable Wi-Fi")
    nmcli radio wifi off || notify_error "Could not disable Wi-Fi"
    ;;
  Rescan)
    # Explicit request, so waiting for results is what the user asked for.
    if ! nmcli device wifi list --rescan yes >/dev/null 2>&1; then
      notify_error "Rescan failed"
      exit 1
    fi
    flock -u 9
    exec "$0"
    ;;
  "Disconnect: "*)
    nmcli connection down id "${choice#Disconnect: }" || notify_error "Could not disconnect"
    ;;
  *)
    ssid=${choice%%  •  *}

    if nmcli connection up id "$ssid" >/dev/null 2>&1; then
      exit
    fi

    if nmcli device wifi connect "$ssid" >/dev/null 2>&1; then
      exit
    fi

    password=$(zenity --password --title="Connect to $ssid" 2>/dev/null) || exit
    if ! nmcli device wifi connect "$ssid" password "$password" >/dev/null 2>&1; then
      notify_error "Could not connect to $ssid"
    fi
    ;;
esac
