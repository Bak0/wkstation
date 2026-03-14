#!/usr/bin/env bash
set -Eeuo pipefail

APPEARANCE_DIR="${WK_APPEARANCE_DIR:-$HOME/wkstation/appearance}"
STYLE_DIR="${APPEARANCE_DIR}/waybar-presets/style"

WAYBAR_DIR="${HOME}/.config/waybar"
STATE_DIR="${HOME}/.config/wkstation-state"

choice="$(find "${STYLE_DIR}" -maxdepth 1 -type f -name '*.css' -printf '%f\n' | sed 's/\.css$//' | sort | rofi -dmenu -i -p 'Waybar style')"
[[ -n "${choice:-}" ]] || exit 0

mkdir -p "${WAYBAR_DIR}" "${STATE_DIR}"
cp "${STYLE_DIR}/${choice}.css" "${WAYBAR_DIR}/variant.css"
printf '%s\n' "${choice}" > "${STATE_DIR}/current_waybar_style"

pkill waybar >/dev/null 2>&1 || true
nohup waybar >/dev/null 2>&1 &
