#!/bin/bash
while true; do
  level=$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null)
  if [ -n "$level" ] && [ "$level" -le 15 ]; then
    notify-send -u critical "Battery Low" "Battery is at ${level}%"
    sleep 300  # wait 5 min before checking again after alerting
  else
    sleep 60
  fi
done
