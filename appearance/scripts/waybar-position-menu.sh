#!/usr/bin/env bash
set -Eeuo pipefail

APPEARANCE_DIR="${WK_APPEARANCE_DIR:-$HOME/wkstation/appearance}"
POS_DIR="${APPEARANCE_DIR}/waybar-presets/position"

WAYBAR_DIR="${HOME}/.config/waybar"
STATE_DIR="${HOME}/.config/wkstation-state"

choice="$(find "${POS_DIR}" -maxdepth 1 -type f -name '*.jsonc' -printf '%f\n' | sed 's/\.jsonc$//' | sort | rofi -dmenu -i -p 'Waybar position')"
[[ -n "${choice:-}" ]] || exit 0

mkdir -p "${WAYBAR_DIR}" "${STATE_DIR}"
cp "${POS_DIR}/${choice}.jsonc" "${WAYBAR_DIR}/config.jsonc"
printf '%s\n' "${choice}" > "${STATE_DIR}/current_waybar_position"

pkill waybar >/dev/null 2>&1 || true
nohup waybar >/dev/null 2>&1 &
