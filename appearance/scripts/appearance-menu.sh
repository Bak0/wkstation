#!/usr/bin/env bash
set -Eeuo pipefail

APP_DIR="${WK_APPEARANCE_DIR:-$HOME/wkstation/appearance}"
CTL="${APP_DIR}/scripts/appearance-controller.sh"

main_choice="$(printf 'Themes\nWaybar\nRofi' | rofi -dmenu -i -p 'Appearance')"
[[ -n "${main_choice:-}" ]] || exit 0

case "${main_choice}" in
    "Themes")
        sub="$(printf 'Load preset\nSave as preset' | rofi -dmenu -i -p 'Themes')"
        [[ -n "${sub:-}" ]] || exit 0
        case "${sub}" in
            "Load preset")
                choice="$("${CTL}" list-presets | rofi -dmenu -i -p 'Load preset')"
                [[ -n "${choice:-}" ]] || exit 0
                "${CTL}" load-preset "${choice}"
                ;;
            "Save as preset")
                name="$(printf '' | rofi -dmenu -p 'Save preset as')"
                [[ -n "${name:-}" ]] || exit 0
                "${CTL}" save-preset "${name}"
                ;;
        esac
        ;;
    "Waybar")
        sub="$(printf 'Position\nStyle' | rofi -dmenu -i -p 'Waybar')"
        [[ -n "${sub:-}" ]] || exit 0
        case "${sub}" in
            "Position")
                choice="$(find "${APP_DIR}/waybar/position" -maxdepth 1 -type f -name '*.jsonc' -printf '%f\n' | sed 's/\.jsonc$//' | sort | rofi -dmenu -i -p 'Waybar position')"
                [[ -n "${choice:-}" ]] || exit 0
                "${CTL}" apply-waybar-position "${choice}"
                ;;
            "Style")
                choice="$(find "${APP_DIR}/waybar/style" -maxdepth 1 -type f -name '*.css' -printf '%f\n' | sed 's/\.css$//' | sort | rofi -dmenu -i -p 'Waybar style')"
                [[ -n "${choice:-}" ]] || exit 0
                "${CTL}" apply-waybar-style "${choice}"
                ;;
        esac
        ;;
    "Rofi")
        sub="$(printf 'Layout\nStyle' | rofi -dmenu -i -p 'Rofi')"
        [[ -n "${sub:-}" ]] || exit 0
        case "${sub}" in
            "Layout")
                choice="$(find "${APP_DIR}/rofi/layout" -maxdepth 1 -type f -name '*.rasi' -printf '%f\n' | sed 's/\.rasi$//' | sort | rofi -dmenu -i -p 'Rofi layout')"
                [[ -n "${choice:-}" ]] || exit 0
                "${CTL}" apply-rofi-layout "${choice}"
                ;;
            "Style")
                choice="$(find "${APP_DIR}/rofi/style" -maxdepth 1 -type f -name '*.rasi' -printf '%f\n' | sed 's/\.rasi$//' | sort | rofi -dmenu -i -p 'Rofi style')"
                [[ -n "${choice:-}" ]] || exit 0
                "${CTL}" apply-rofi-style "${choice}"
                ;;
        esac
        ;;
esac
