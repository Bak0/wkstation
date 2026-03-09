#!/usr/bin/env bash
set -Eeuo pipefail

REPO_DIR="${HOME}/wkstation"
THEMES_DIR="${REPO_DIR}/themes"

HYPR_DIR="${HOME}/.config/hypr"
WAYBAR_DIR="${HOME}/.config/waybar"
ROFI_DIR="${HOME}/.config/rofi"
WALL_DIR="${HOME}/.local/share/wallpapers"

CURRENT_LINK="${HOME}/.config/current_theme"

apply_theme() {
    local theme="$1"
    local theme_dir="${THEMES_DIR}/${theme}"

    [[ -d "${theme_dir}" ]] || {
        echo "Theme not found: ${theme}"
        exit 1
    }

    mkdir -p "${HYPR_DIR}" "${WAYBAR_DIR}" "${ROFI_DIR}" "${WALL_DIR}"

    cp "${theme_dir}/hypr.conf" "${HYPR_DIR}/theme.conf"
    cp "${theme_dir}/waybar.css" "${WAYBAR_DIR}/theme.css"
    cp "${theme_dir}/rofi.rasi" "${ROFI_DIR}/theme.rasi"
    cp "${theme_dir}/wallpaper.jpg" "${WALL_DIR}/current.jpg"

    ln -sfn "${theme_dir}" "${CURRENT_LINK}"

    hyprctl reload >/dev/null 2>&1 || true

    pkill waybar >/dev/null 2>&1 || true
    nohup waybar >/dev/null 2>&1 &

    pkill hyprpaper >/dev/null 2>&1 || true
    nohup hyprpaper >/dev/null 2>&1 &
}

cycle_next() {
    mapfile -t themes < <(find "${THEMES_DIR}" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort)
    [[ ${#themes[@]} -gt 0 ]] || exit 1

    local current=""
    if [[ -L "${CURRENT_LINK}" ]]; then
        current="$(basename "$(readlink "${CURRENT_LINK}")")"
    fi

    local i next_index=0
    for i in "${!themes[@]}"; do
        if [[ "${themes[$i]}" == "${current}" ]]; then
            next_index=$(( (i + 1) % ${#themes[@]} ))
            break
        fi
    done

    apply_theme "${themes[$next_index]}"
}

case "${1:-}" in
    --next)
        cycle_next
        ;;
    "")
        echo "Usage: theme-switch.sh THEME_NAME | --next"
        exit 1
        ;;
    *)
        apply_theme "$1"
        ;;
esac
