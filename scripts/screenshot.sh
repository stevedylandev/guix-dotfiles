#!/usr/bin/env bash

# wayshot — screenshot on Wayland using grim
# deps: grim (capture); optional: slurp (region select), wl-clipboard, libnotify

set -euo pipefail

DIR="${SCREENSHOT_DIR:-$HOME/Pictures/screenshots}"
mkdir -p "$DIR"
FILE="$DIR/screenshot_$(date +%Y%m%d_%H%M%S).png"

# Pass "-r" or "-f" for full screen, default is region-select
GEO=()
if [[ "${1:-}" != "-f" ]]; then
    GEO=(-g "$(slurp)")   # Ctrl+C or Esc to cancel
fi

grim -t png "${GEO[@]}" "$FILE"

# Optional: copy to clipboard + notify
command -v wl-copy   >/dev/null && wl-copy < "$FILE"
command -v notify-send >/dev/null && notify-send "Screenshot saved" "$FILE"

echo "$FILE"
