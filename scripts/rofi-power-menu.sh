#!/usr/bin/env bash
set -euo pipefail

chosen=$(printf "Shutdown\nReboot\nSuspend\nExit i3" | rofi -dmenu -i -p "Power")
case "$chosen" in
  Shutdown) systemctl poweroff ;;
  Reboot) systemctl reboot ;;
  Suspend) systemctl suspend ;;
  "Exit i3") i3-msg exit ;;
esac
