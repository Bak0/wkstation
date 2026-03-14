#!/usr/bin/env bash
set -Eeuo pipefail

STYLE_DIR="${HOME}/wkstation/appearance/rofi-presets/style"
ROFI_DIR="${HOME}/.config/rofi"
STATE_DIR="${HOME}/.config/wkstation-state"

choice="$(find "${STYLE_DIR}" -maxdepth 1 -type f -name '*.rasi' -printf '%f\n' | sed 's/\.rasi$//' | sort | rofi -dmenu -i -p 'Rofi style')"
[[ -n "${choice:-}" ]] || exit 0

mkdir -p "${ROFI_DIR}" "${STATE_DIR}"
cp "${STYLE_DIR}/${choice}.rasi" "${ROFI_DIR}/variant.rasi"
printf '%s\n' "${choice}" > "${STATE_DIR}/current_rofi_style"
