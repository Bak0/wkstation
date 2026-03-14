#!/usr/bin/env bash
set -Eeuo pipefail

main_choice="$(printf 'Theme switch\nWaybar' | rofi -dmenu -i -p 'Appearance')"
[[ -n "${main_choice:-}" ]] || exit 0

case "${main_choice}" in
    "Theme switch")
        "${HOME}/wkstation/appearance/scripts/theme-menu.sh"
        ;;
    "Waybar")
        sub_choice="$(printf 'Position\nStyle' | rofi -dmenu -i -p 'Waybar')"
        [[ -n "${sub_choice:-}" ]] || exit 0

        case "${sub_choice}" in
            "Position")
                "${HOME}/wkstation/appearance/scripts/waybar-position-menu.sh"
                ;;
            "Style")
                "${HOME}/wkstation/appearance/scripts/waybar-style-menu.sh"
                ;;
        esac
        ;;
esac
