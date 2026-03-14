#!/usr/bin/env bash
set -Eeuo pipefail

MODE="${1:-}"
NAME="${2:-}"

STILL_DIR="${HOME}/wkstation/appearance/backgrounds/still"
ANIM_DIR="${HOME}/wkstation/appearance/backgrounds/animated"

WALL_DIR="${HOME}/.local/share/wallpapers"
STATE_DIR="${HOME}/.config/wkstation-state"

mkdir -p "${WALL_DIR}" "${STATE_DIR}"

case "${MODE}" in
    still)
        SRC="${STILL_DIR}/${NAME}"
        [[ -f "${SRC}" ]] || {
            rofi -e "Still background not found: ${NAME}"
            exit 1
        }

        cp "${SRC}" "${WALL_DIR}/current.jpg"
        printf '%s\n' "${NAME}" > "${STATE_DIR}/current_background"

        pkill hyprpaper >/dev/null 2>&1 || true
        nohup hyprpaper >/dev/null 2>&1 &
        sleep 0.5
        hyprctl hyprpaper unload all >/dev/null 2>&1 || true
        hyprctl hyprpaper preload "${WALL_DIR}/current.jpg" >/dev/null 2>&1 || true
        hyprctl hyprpaper wallpaper ",${WALL_DIR}/current.jpg" >/dev/null 2>&1 || true
        ;;
    animated)
        SRC="${ANIM_DIR}/${NAME}"
        [[ -f "${SRC}" ]] || {
            rofi -e "Animated background not found: ${NAME}"
            exit 1
        }

        rofi -e "Animated backgrounds menu is wired. Video playback backend will be added next."
        ;;
    *)
        rofi -e "Usage: background-switch.sh still|animated FILE"
        exit 1
        ;;
esac
