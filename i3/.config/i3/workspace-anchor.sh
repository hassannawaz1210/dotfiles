#!/usr/bin/env bash
set -euo pipefail

ANCHOR_FILE="$HOME/.cache/i3-anchor-workspace"

current_ws() {
  i3-msg -t get_workspaces | jq -r '.[] | select(.focused) | .name'
}

notify() {
  command -v notify-send >/dev/null && notify-send -t 1500 "i3 anchor" "$1" || true
}

case "${1:-}" in
  mark)
    cur=$(current_ws)
    mkdir -p "$(dirname "$ANCHOR_FILE")"
    printf '%s' "$cur" > "$ANCHOR_FILE"
    notify "Marked workspace: $cur"
    ;;
  toggle)
    if [ ! -s "$ANCHOR_FILE" ]; then
      notify "No marked workspace — use mark binding first"
      exit 0
    fi
    anchor=$(cat "$ANCHOR_FILE")
    cur=$(current_ws)
    if [ "$cur" = "$anchor" ]; then
      i3-msg workspace back_and_forth >/dev/null
    else
      i3-msg workspace "$anchor" >/dev/null
    fi
    ;;
  *)
    echo "usage: $0 {mark|toggle}" >&2
    exit 1
    ;;
esac
