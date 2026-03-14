#!/usr/bin/env bash
set -Eeuo pipefail

main_choice="$(printf 'Theme switch\nWaybar\nRofi\nBackgrounds' | rofi -dmenu -i -p 'Appearance')"
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
    "Rofi")
        sub_choice="$(printf 'Style\nLayout' | rofi -dmenu -i -p 'Rofi')"
        [[ -n "${sub_choice:-}" ]] || exit 0

        case "${sub_choice}" in
            "Style")
                "${HOME}/wkstation/appearance/scripts/rofi-style-menu.sh"
                ;;
            "Layout")
                "${HOME}/wkstation/appearance/scripts/rofi-layout-menu.sh"
                ;;
        esac
        ;;
    "Backgrounds")
        sub_choice="$(printf 'Still\nAnimated' | rofi -dmenu -i -p 'Backgrounds')"
        [[ -n "${sub_choice:-}" ]] || exit 0

        case "${sub_choice}" in
            "Still")
                "${HOME}/wkstation/appearance/scripts/background-still-menu.sh"
                ;;
            "Animated")
                "${HOME}/wkstation/appearance/scripts/background-animated-menu.sh"
                ;;
        esac
        ;;
esac
