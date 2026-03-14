#!/usr/bin/env bash
set -Eeuo pipefail

APP_DIR="${WK_APPEARANCE_DIR:-$HOME/wkstation/appearance}"

PRESETS_DIR="${APP_DIR}/presets"
WAYBAR_POS_DIR="${APP_DIR}/waybar/position"
WAYBAR_STYLE_DIR="${APP_DIR}/waybar/style"
ROFI_LAYOUT_DIR="${APP_DIR}/rofi/layout"
ROFI_STYLE_DIR="${APP_DIR}/rofi/style"
BG_STILL_DIR="${APP_DIR}/backgrounds/still"

HYPR_DIR="${HOME}/.config/hypr"
WAYBAR_DIR="${HOME}/.config/waybar"
ROFI_DIR="${HOME}/.config/rofi"
WALL_DIR="${HOME}/.local/share/wallpapers"
STATE_DIR="${HOME}/.config/wkstation-state"

ensure_dirs() {
    mkdir -p "${HYPR_DIR}" "${WAYBAR_DIR}" "${ROFI_DIR}" "${WALL_DIR}" "${STATE_DIR}"
}

state_set() {
    printf '%s\n' "$2" > "${STATE_DIR}/$1"
}

state_get() {
    local file="${STATE_DIR}/$1"
    local default="${2:-}"
    [[ -f "${file}" ]] && cat "${file}" || printf '%s\n' "${default}"
}

restart_waybar() {
    pkill waybar >/dev/null 2>&1 || true
    nohup waybar >/dev/null 2>&1 &
}

reload_hypr() {
    hyprctl reload >/dev/null 2>&1 || true
}

reload_wallpaper() {
    pkill hyprpaper >/dev/null 2>&1 || true
    nohup hyprpaper >/dev/null 2>&1 &
    sleep 0.4
    hyprctl hyprpaper unload all >/dev/null 2>&1 || true
    hyprctl hyprpaper preload "${WALL_DIR}/current.jpg" >/dev/null 2>&1 || true
    hyprctl hyprpaper wallpaper ",${WALL_DIR}/current.jpg" >/dev/null 2>&1 || true
}

default_background_for_preset() {
    local preset="$1"
    local ext

    for ext in jpg jpeg png webp; do
        if [[ -f "${BG_STILL_DIR}/${preset}.${ext}" ]]; then
            printf '%s\n' "${preset}.${ext}"
            return
        fi
    done
}

apply_preset_only() {
    local preset="$1"
    local dir="${PRESETS_DIR}/${preset}"

    [[ -d "${dir}" ]] || { echo "Preset not found: ${preset}"; exit 1; }
    [[ -f "${dir}/hypr.conf" ]] || { echo "Missing ${dir}/hypr.conf"; exit 1; }
    [[ -f "${dir}/waybar.css" ]] || { echo "Missing ${dir}/waybar.css"; exit 1; }
    [[ -f "${dir}/rofi.rasi" ]] || { echo "Missing ${dir}/rofi.rasi"; exit 1; }

    cp "${dir}/hypr.conf" "${HYPR_DIR}/theme.conf"
    cp "${dir}/waybar.css" "${WAYBAR_DIR}/theme.css"
    cp "${dir}/rofi.rasi" "${ROFI_DIR}/theme.rasi"

    state_set current_preset "${preset}"

    local bg
    bg="$(default_background_for_preset "${preset}")"
    if [[ -n "${bg}" ]]; then
        cp "${BG_STILL_DIR}/${bg}" "${WALL_DIR}/current.jpg"
        state_set current_background "${bg}"
    fi
}

apply_waybar_position_only() {
    local name="$1"
    local src="${WAYBAR_POS_DIR}/${name}.jsonc"
    [[ -f "${src}" ]] || { echo "Waybar position not found: ${name}"; exit 1; }
    cp "${src}" "${WAYBAR_DIR}/config.jsonc"
    state_set current_waybar_position "${name}"
}

apply_waybar_style_only() {
    local name="$1"
    local src="${WAYBAR_STYLE_DIR}/${name}.css"
    [[ -f "${src}" ]] || { echo "Waybar style not found: ${name}"; exit 1; }
    cp "${src}" "${WAYBAR_DIR}/variant.css"
    state_set current_waybar_style "${name}"
}

apply_rofi_layout_only() {
    local name="$1"
    local src="${ROFI_LAYOUT_DIR}/${name}.rasi"
    [[ -f "${src}" ]] || { echo "Rofi layout not found: ${name}"; exit 1; }
    cp "${src}" "${ROFI_DIR}/layout.rasi"
    state_set current_rofi_layout "${name}"
}

apply_rofi_style_only() {
    local name="$1"
    local src="${ROFI_STYLE_DIR}/${name}.rasi"
    [[ -f "${src}" ]] || { echo "Rofi style not found: ${name}"; exit 1; }
    cp "${src}" "${ROFI_DIR}/variant.rasi"
    state_set current_rofi_style "${name}"
}

list_presets() {
    find "${PRESETS_DIR}" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort
}

list_current_preset_backgrounds() {
    find "${BG_STILL_DIR}" -maxdepth 1 -type f \
        \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) \
        -printf '%f\n' | sort
}

apply_background_from_current_preset() {
    local name="$1"
    local src="${BG_STILL_DIR}/${name}"

    [[ -f "${src}" ]] || { echo "Background not found: ${name}"; exit 1; }

    cp "${src}" "${WALL_DIR}/current.jpg"
    state_set current_background "${name}"
    reload_wallpaper
}

load_preset() {
    local preset="$1"
    apply_preset_only "${preset}"
    reload_hypr
    restart_waybar
    reload_wallpaper
}

save_preset() {
    local name="$1"
    [[ -n "${name}" ]] || { echo "Preset name required"; exit 1; }

    local dest="${PRESETS_DIR}/${name}"
    mkdir -p "${dest}" "${BG_STILL_DIR}"

    cp "${HYPR_DIR}/theme.conf" "${dest}/hypr.conf"
    cp "${WAYBAR_DIR}/theme.css" "${dest}/waybar.css"
    cp "${ROFI_DIR}/theme.rasi" "${dest}/rofi.rasi"

    if [[ -f "${WALL_DIR}/current.jpg" ]]; then
        cp "${WALL_DIR}/current.jpg" "${BG_STILL_DIR}/${name}.jpg"
        state_set current_background "${name}.jpg"
    fi
    state_set current_preset "${name}"
}

cycle_preset() {
    mapfile -t presets < <(list_presets)
    [[ ${#presets[@]} -gt 0 ]] || exit 1

    local current
    current="$(state_get current_preset "")"

    local next_index=0
    local i
    for i in "${!presets[@]}"; do
        if [[ "${presets[$i]}" == "${current}" ]]; then
            next_index=$(( (i + 1) % ${#presets[@]} ))
            break
        fi
    done

    load_preset "${presets[$next_index]}"
}

usage() {
    cat <<'EOF'
appearance-controller.sh list-presets
appearance-controller.sh load-preset NAME
appearance-controller.sh save-preset NAME
appearance-controller.sh cycle-preset
appearance-controller.sh list-backgrounds
appearance-controller.sh apply-background NAME
appearance-controller.sh apply-waybar-position NAME
appearance-controller.sh apply-waybar-style NAME
appearance-controller.sh apply-rofi-layout NAME
appearance-controller.sh apply-rofi-style NAME
EOF
}

main() {
    ensure_dirs

    case "${1:-}" in
        list-presets) list_presets ;;
        load-preset) [[ -n "${2:-}" ]] || { usage; exit 1; }; load_preset "$2" ;;
        save-preset) [[ -n "${2:-}" ]] || { usage; exit 1; }; save_preset "$2" ;;
        cycle-preset) cycle_preset ;;
        list-backgrounds) list_current_preset_backgrounds ;;
        apply-background) [[ -n "${2:-}" ]] || { usage; exit 1; }; apply_background_from_current_preset "$2" ;;
        apply-waybar-position) [[ -n "${2:-}" ]] || { usage; exit 1; }; apply_waybar_position_only "$2"; restart_waybar ;;
        apply-waybar-style) [[ -n "${2:-}" ]] || { usage; exit 1; }; apply_waybar_style_only "$2"; restart_waybar ;;
        apply-rofi-layout) [[ -n "${2:-}" ]] || { usage; exit 1; }; apply_rofi_layout_only "$2" ;;
        apply-rofi-style) [[ -n "${2:-}" ]] || { usage; exit 1; }; apply_rofi_style_only "$2" ;;
        *) usage; exit 1 ;;
    esac
}

main "$@"
