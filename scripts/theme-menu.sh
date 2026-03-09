#!/usr/bin/env bash
set -Eeuo pipefail

REPO_DIR="${HOME}/wkstation"
THEMES_DIR="${REPO_DIR}/themes"

theme="$(find "${THEMES_DIR}" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort | rofi -dmenu -i -p 'Theme')"

[[ -n "${theme:-}" ]] || exit 0

"${HOME}/.local/bin/theme-switch.sh" "${theme}"
