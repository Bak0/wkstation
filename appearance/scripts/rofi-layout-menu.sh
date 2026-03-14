#!/usr/bin/env bash
set -Eeuo pipefail

LAYOUT_DIR="${HOME}/wkstation/appearance/rofi-presets/layout"
ROFI_DIR="${HOME}/.config/rofi"
STATE_DIR="${HOME}/.config/wkstation-state"

choice="$(find "${LAYOUT_DIR}" -maxdepth 1 -type f -name '*.rasi' -printf '%f\n' | sed 's/\.rasi$//' | sort | rofi -dmenu -i -p 'Rofi layout')"
[[ -n "${choice:-}" ]] || exit 0

mkdir -p "${ROFI_DIR}" "${STATE_DIR}"
cp "${LAYOUT_DIR}/${choice}.rasi" "${ROFI_DIR}/layout.rasi"
printf '%s\n' "${choice}" > "${STATE_DIR}/current_rofi_layout"
