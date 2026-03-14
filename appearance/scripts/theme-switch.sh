#!/usr/bin/env bash
set -Eeuo pipefail

APPEARANCE_DIR="${WK_APPEARANCE_DIR:-$HOME/wkstation/appearance}"
THEMES_DIR="${APPEARANCE_DIR}/themes"

HYPR_DIR="${HOME}/.config/hypr"
WAYBAR_DIR="${HOME}/.config/waybar"
ROFI_DIR="${HOME}/.config/rofi"
WALL_DIR="${HOME}/.local/share/wallpapers"
STATE_DIR="${HOME}/.config/wkstation-state"

CURRENT_THEME_FILE="${STATE_DIR}/current_theme"

restart_waybar() {
    pkill waybar >/dev/null 2>&1 || true
    nohup waybar >/dev/null 2>&1 &
}

reload_wallpaper() {
    pkill hyprpaper >/dev/null 2>&1 || true
    nohup hyprpaper >/dev/null 2>&1 &
    sleep 0.5
    hyprctl hyprpaper unload all >/dev/null 2>&1 || true
    hyprctl hyprpaper preload "${WALL_DIR}/current.jpg" >/dev/null 2>&1 || true
    hyprctl hyprpaper wallpaper ",${WALL_DIR}/current.jpg" >/dev/null 2>&1 || true
}

apply_theme() {
    local theme="$1"
    local theme_dir="${THEMES_DIR}/${theme}"

    [[ -d "${theme_dir}" ]] || {
        echo "Theme not found: ${theme}"
        exit 1
    }

    mkdir -p "${HYPR_DIR}" "${WAYBAR_DIR}" "${ROFI_DIR}" "${WALL_DIR}" "${STATE_DIR}"

    cp "${theme_dir}/hypr.conf" "${HYPR_DIR}/theme.conf"
    cp "${theme_dir}/waybar.css" "${WAYBAR_DIR}/theme.css"
    cp "${theme_dir}/rofi.rasi" "${ROFI_DIR}/theme.rasi"
    cp "${theme_dir}/wallpaper.jpg" "${WALL_DIR}/current.jpg"

    printf '%s\n' "${theme}" > "${CURRENT_THEME_FILE}"

    hyprctl reload >/dev/null 2>&1 || true
    restart_waybar
    reload_wallpaper
}

cycle_next() {
    mapfile -t themes < <(find "${THEMES_DIR}" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort)
    [[ ${#themes[@]} -gt 0 ]] || exit 1

    local current=""
    [[ -f "${CURRENT_THEME_FILE}" ]] && current="$(cat "${CURRENT_THEME_FILE}")"

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
