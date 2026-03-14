#!/usr/bin/env bash
set -Eeuo pipefail

BG_DIR="${HOME}/wkstation/appearance/backgrounds/animated"

choice="$(find "${BG_DIR}" -maxdepth 1 -type f \( -name '*.mp4' -o -name '*.webm' -o -name '*.gif' \) -printf '%f\n' | sort | rofi -dmenu -i -p 'Animated background')"
[[ -n "${choice:-}" ]] || exit 0

"${HOME}/wkstation/appearance/scripts/background-switch.sh" animated "${choice}"
