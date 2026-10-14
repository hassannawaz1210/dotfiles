#!/bin/sh

choice=$(printf '%s\n' "Logout" "Restart" "Shutdown" "Cancel" | fuzzel --dmenu --prompt="Power: ")

case "$choice" in
  Logout)
    niri msg action quit --skip-confirmation
    ;;
  Restart)
    systemctl reboot
    ;;
  Shutdown)
    systemctl poweroff
    ;;
esac
