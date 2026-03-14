#!/usr/bin/env bash
set -Eeuo pipefail

BG_DIR="${HOME}/wkstation/appearance/backgrounds/still"

choice="$(find "${BG_DIR}" -maxdepth 1 -type f -name '*.jpg' -printf '%f\n' | sort | rofi -dmenu -i -p 'Still background')"
[[ -n "${choice:-}" ]] || exit 0

"${HOME}/wkstation/appearance/scripts/background-switch.sh" still "${choice}"
