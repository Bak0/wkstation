#!/usr/bin/env bash
set -Eeuo pipefail

APPEARANCE_DIR="${WK_APPEARANCE_DIR:-$HOME/wkstation/appearance}"
CONTROLLER="${APPEARANCE_DIR}/scripts/appearance-controller.sh"

main_choice="$(printf 'Presets\nWaybar\nRofi\nBackgrounds' | rofi -dmenu -i -p 'Appearance')"
[[ -n "${main_choice:-}" ]] || exit 0

case "${main_choice}" in
    "Presets")
        sub_choice="$(printf 'List presets\nSave preset' | rofi -dmenu -i -p 'Presets')"
        [[ -n "${sub_choice:-}" ]] || exit 0

        case "${sub_choice}" in
            "List presets")
                preset="$("${CONTROLLER}" list-presets | rofi -dmenu -i -p 'Load preset')"
                [[ -n "${preset:-}" ]] || exit 0
                "${CONTROLLER}" load-preset "${preset}"
                ;;
            "Save preset")
                name="$(printf '' | rofi -dmenu -p 'Save preset as')"
                [[ -n "${name:-}" ]] || exit 0
                "${CONTROLLER}" save-preset "${name}"
                ;;
        esac
        ;;
    "Waybar")
        sub_choice="$(printf 'Position\nStyle' | rofi -dmenu -i -p 'Waybar')"
        [[ -n "${sub_choice:-}" ]] || exit 0

        case "${sub_choice}" in
            "Position")
                choice="$(find "${APPEARANCE_DIR}/waybar-presets/position" -maxdepth 1 -type f -name '*.jsonc' -printf '%f\n' | sed 's/\.jsonc$//' | sort | rofi -dmenu -i -p 'Waybar position')"
                [[ -n "${choice:-}" ]] || exit 0
                "${CONTROLLER}" apply-waybar-position "${choice}"
                ;;
            "Style")
                choice="$(find "${APPEARANCE_DIR}/waybar-presets/style" -maxdepth 1 -type f -name '*.css' -printf '%f\n' | sed 's/\.css$//' | sort | rofi -dmenu -i -p 'Waybar style')"
                [[ -n "${choice:-}" ]] || exit 0
                "${CONTROLLER}" apply-waybar-style "${choice}"
                ;;
        esac
        ;;
    "Rofi")
        sub_choice="$(printf 'Layout\nStyle' | rofi -dmenu -i -p 'Rofi')"
        [[ -n "${sub_choice:-}" ]] || exit 0

        case "${sub_choice}" in
            "Layout")
                choice="$(find "${APPEARANCE_DIR}/rofi-presets/layout" -maxdepth 1 -type f -name '*.rasi' -printf '%f\n' | sed 's/\.rasi$//' | sort | rofi -dmenu -i -p 'Rofi layout')"
                [[ -n "${choice:-}" ]] || exit 0
                "${CONTROLLER}" apply-rofi-layout "${choice}"
                ;;
            "Style")
                choice="$(find "${APPEARANCE_DIR}/rofi-presets/style" -maxdepth 1 -type f -name '*.rasi' -printf '%f\n' | sed 's/\.rasi$//' | sort | rofi -dmenu -i -p 'Rofi style')"
                [[ -n "${choice:-}" ]] || exit 0
                "${CONTROLLER}" apply-rofi-style "${choice}"
                ;;
        esac
        ;;
    "Backgrounds")
        sub_choice="$(printf 'Still\nAnimated' | rofi -dmenu -i -p 'Backgrounds')"
        [[ -n "${sub_choice:-}" ]] || exit 0

        case "${sub_choice}" in
            "Still")
                choice="$(find "${APPEARANCE_DIR}/backgrounds/still" -maxdepth 1 -type f \( -name '*.jpg' -o -name '*.jpeg' -o -name '*.png' -o -name '*.webp' \) -printf '%f\n' | sort | rofi -dmenu -i -p 'Still background')"
                [[ -n "${choice:-}" ]] || exit 0
                "${CONTROLLER}" apply-background still "${choice}"
                ;;
            "Animated")
                choice="$(find "${APPEARANCE_DIR}/backgrounds/animated" -maxdepth 1 -type f \( -name '*.mp4' -o -name '*.webm' -o -name '*.gif' \) -printf '%f\n' | sort | rofi -dmenu -i -p 'Animated background')"
                [[ -n "${choice:-}" ]] || exit 0
                "${CONTROLLER}" apply-background animated "${choice}"
                ;;
        esac
        ;;
esac