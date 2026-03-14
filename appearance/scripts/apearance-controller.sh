#!/usr/bin/env bash
set -Eeuo pipefail

APPEARANCE_DIR="${WK_APPEARANCE_DIR:-$HOME/wkstation/appearance}"

PRESETS_DIR="${APPEARANCE_DIR}/presets"
PRESET_CONFS_DIR="${APPEARANCE_DIR}/preset-confs"

WAYBAR_POS_DIR="${APPEARANCE_DIR}/waybar-presets/position"
WAYBAR_STYLE_DIR="${APPEARANCE_DIR}/waybar-presets/style"

ROFI_LAYOUT_DIR="${APPEARANCE_DIR}/rofi-presets/layout"
ROFI_STYLE_DIR="${APPEARANCE_DIR}/rofi-presets/style"

BG_STILL_DIR="${APPEARANCE_DIR}/backgrounds/still"
BG_ANIM_DIR="${APPEARANCE_DIR}/backgrounds/animated"

HYPR_DIR="${HOME}/.config/hypr"
WAYBAR_DIR="${HOME}/.config/waybar"
ROFI_DIR="${HOME}/.config/rofi"
WALL_DIR="${HOME}/.local/share/wallpapers"
STATE_DIR="${HOME}/.config/wkstation-state"

log() {
    printf '%s\n' "$*"
}

ensure_dirs() {
    mkdir -p "${HYPR_DIR}" "${WAYBAR_DIR}" "${ROFI_DIR}" "${WALL_DIR}" "${STATE_DIR}"
}

state_set() {
    local key="$1"
    local value="$2"
    printf '%s\n' "${value}" > "${STATE_DIR}/${key}"
}

state_get() {
    local key="$1"
    local default="${2:-}"
    if [[ -f "${STATE_DIR}/${key}" ]]; then
        cat "${STATE_DIR}/${key}"
    else
        printf '%s\n' "${default}"
    fi
}

restart_waybar() {
    pkill waybar >/dev/null 2>&1 || true
    nohup waybar >/dev/null 2>&1 &
}

reload_hypr() {
    hyprctl reload >/dev/null 2>&1 || true
}

reload_still_wallpaper() {
    pkill hyprpaper >/dev/null 2>&1 || true
    nohup hyprpaper >/dev/null 2>&1 &
    sleep 0.5
    hyprctl hyprpaper unload all >/dev/null 2>&1 || true
    hyprctl hyprpaper preload "${WALL_DIR}/current.jpg" >/dev/null 2>&1 || true
    hyprctl hyprpaper wallpaper ",${WALL_DIR}/current.jpg" >/dev/null 2>&1 || true
}

apply_preset_asset_only() {
    local preset="$1"
    local preset_dir="${PRESETS_DIR}/${preset}"

    [[ -d "${preset_dir}" ]] || {
        echo "Preset asset not found: ${preset}"
        exit 1
    }

    cp "${preset_dir}/hypr.conf" "${HYPR_DIR}/theme.conf"
    cp "${preset_dir}/waybar.css" "${WAYBAR_DIR}/theme.css"
    cp "${preset_dir}/rofi.rasi" "${ROFI_DIR}/theme.rasi"
    cp "${preset_dir}/wallpaper.jpg" "${WALL_DIR}/current.jpg"

    state_set current_preset_asset "${preset}"
    state_set current_background_mode "preset"
    state_set current_background_name "${preset}"
}

apply_waybar_position_only() {
    local name="$1"
    local src="${WAYBAR_POS_DIR}/${name}.jsonc"

    [[ -f "${src}" ]] || {
        echo "Waybar position preset not found: ${name}"
        exit 1
    }

    cp "${src}" "${WAYBAR_DIR}/config.jsonc"
    state_set current_waybar_position "${name}"
}

apply_waybar_style_only() {
    local name="$1"
    local src="${WAYBAR_STYLE_DIR}/${name}.css"

    [[ -f "${src}" ]] || {
        echo "Waybar style preset not found: ${name}"
        exit 1
    }

    cp "${src}" "${WAYBAR_DIR}/variant.css"
    state_set current_waybar_style "${name}"
}

apply_rofi_layout_only() {
    local name="$1"
    local src="${ROFI_LAYOUT_DIR}/${name}.rasi"

    [[ -f "${src}" ]] || {
        echo "Rofi layout preset not found: ${name}"
        exit 1
    }

    cp "${src}" "${ROFI_DIR}/layout.rasi"
    state_set current_rofi_layout "${name}"
}

apply_rofi_style_only() {
    local name="$1"
    local src="${ROFI_STYLE_DIR}/${name}.rasi"

    [[ -f "${src}" ]] || {
        echo "Rofi style preset not found: ${name}"
        exit 1
    }

    cp "${src}" "${ROFI_DIR}/variant.rasi"
    state_set current_rofi_style "${name}"
}

apply_background_only() {
    local mode="$1"
    local name="$2"

    case "${mode}" in
        preset)
            local preset_name
            preset_name="$(state_get current_preset_asset "")"
            [[ -n "${preset_name}" ]] || {
                echo "No current preset asset set."
                exit 1
            }
            local src="${PRESETS_DIR}/${preset_name}/wallpaper.jpg"
            [[ -f "${src}" ]] || {
                echo "Preset wallpaper not found for ${preset_name}"
                exit 1
            }
            cp "${src}" "${WALL_DIR}/current.jpg"
            state_set current_background_mode "preset"
            state_set current_background_name "${preset_name}"
            ;;
        still)
            local src="${BG_STILL_DIR}/${name}"
            [[ -f "${src}" ]] || {
                echo "Still background not found: ${name}"
                exit 1
            }
            cp "${src}" "${WALL_DIR}/current.jpg"
            state_set current_background_mode "still"
            state_set current_background_name "${name}"
            ;;
        animated)
            local src="${BG_ANIM_DIR}/${name}"
            [[ -f "${src}" ]] || {
                echo "Animated background not found: ${name}"
                exit 1
            }
            state_set current_background_mode "animated"
            state_set current_background_name "${name}"
            rofi -e "Animated backgrounds are wired but backend is not implemented yet."
            ;;
        *)
            echo "Invalid background mode: ${mode}"
            exit 1
            ;;
    esac
}

refresh_runtime() {
    reload_hypr
    restart_waybar

    local bg_mode
    bg_mode="$(state_get current_background_mode preset)"

    case "${bg_mode}" in
        preset|still)
            reload_still_wallpaper
            ;;
        animated)
            # placeholder until animated backend is added
            ;;
    esac
}

list_preset_confs() {
    find "${PRESET_CONFS_DIR}" -maxdepth 1 -type f -name '*.conf' -printf '%f\n' | sed 's/\.conf$//' | sort
}

load_preset() {
    local name="$1"
    local file="${PRESET_CONFS_DIR}/${name}.conf"

    [[ -f "${file}" ]] || {
        echo "Preset conf not found: ${name}"
        exit 1
    }

    local preset=""
    local waybar_position=""
    local waybar_style=""
    local rofi_layout=""
    local rofi_style=""
    local background_mode=""
    local background_name=""

    while IFS='=' read -r key value; do
        key="${key%%#*}"
        key="$(printf '%s' "${key}" | xargs)"
        value="$(printf '%s' "${value}" | xargs)"

        [[ -z "${key}" ]] && continue

        case "${key}" in
            preset) preset="${value}" ;;
            waybar_position) waybar_position="${value}" ;;
            waybar_style) waybar_style="${value}" ;;
            rofi_layout) rofi_layout="${value}" ;;
            rofi_style) rofi_style="${value}" ;;
            background_mode) background_mode="${value}" ;;
            background_name) background_name="${value}" ;;
        esac
    done < "${file}"

    ensure_dirs

    [[ -n "${preset}" ]] && apply_preset_asset_only "${preset}"
    [[ -n "${waybar_position}" ]] && apply_waybar_position_only "${waybar_position}"
    [[ -n "${waybar_style}" ]] && apply_waybar_style_only "${waybar_style}"
    [[ -n "${rofi_layout}" ]] && apply_rofi_layout_only "${rofi_layout}"
    [[ -n "${rofi_style}" ]] && apply_rofi_style_only "${rofi_style}"

    if [[ -n "${background_mode}" ]]; then
        case "${background_mode}" in
            preset)
                apply_background_only preset "${background_name:-}"
                ;;
            still|animated)
                [[ -n "${background_name}" ]] && apply_background_only "${background_mode}" "${background_name}"
                ;;
        esac
    fi

    state_set current_preset "${name}"
    refresh_runtime
}

save_preset() {
    local name="$1"
    [[ -n "${name}" ]] || {
        echo "Preset name required."
        exit 1
    }

    ensure_dirs
    mkdir -p "${PRESET_CONFS_DIR}"

    cat > "${PRESET_CONFS_DIR}/${name}.conf" <<EOF
preset=$(state_get current_preset_asset dark)
waybar_position=$(state_get current_waybar_position top)
waybar_style=$(state_get current_waybar_style rounded)
rofi_layout=$(state_get current_rofi_layout compact)
rofi_style=$(state_get current_rofi_style rounded)
background_mode=$(state_get current_background_mode preset)
background_name=$(state_get current_background_name "$(state_get current_preset_asset dark)")
EOF

    state_set current_preset "${name}"
}

cycle_preset() {
    mapfile -t presets < <(list_preset_confs)
    [[ ${#presets[@]} -gt 0 ]] || exit 1

    local current
    current="$(state_get current_preset "")"

    local i next_index=0
    for i in "${!presets[@]}"; do
        if [[ "${presets[$i]}" == "${current}" ]]; then
            next_index=$(( (i + 1) % ${#presets[@]} ))
            break
        fi
    done

    load_preset "${presets[$next_index]}"
}

usage() {
    cat <<EOF
Usage:
  appearance-controller.sh list-presets
  appearance-controller.sh load-preset NAME
  appearance-controller.sh save-preset NAME
  appearance-controller.sh cycle-preset

  appearance-controller.sh apply-waybar-position NAME
  appearance-controller.sh apply-waybar-style NAME
  appearance-controller.sh apply-rofi-layout NAME
  appearance-controller.sh apply-rofi-style NAME
  appearance-controller.sh apply-background MODE NAME
EOF
}

main() {
    ensure_dirs

    case "${1:-}" in
        list-presets)
            list_preset_confs
            ;;
        load-preset)
            [[ -n "${2:-}" ]] || { usage; exit 1; }
            load_preset "${2}"
            ;;
        save-preset)
            [[ -n "${2:-}" ]] || { usage; exit 1; }
            save_preset "${2}"
            ;;
        cycle-preset)
            cycle_preset
            ;;
        apply-waybar-position)
            [[ -n "${2:-}" ]] || { usage; exit 1; }
            apply_waybar_position_only "${2}"
            refresh_runtime
            ;;
        apply-waybar-style)
            [[ -n "${2:-}" ]] || { usage; exit 1; }
            apply_waybar_style_only "${2}"
            refresh_runtime
            ;;
        apply-rofi-layout)
            [[ -n "${2:-}" ]] || { usage; exit 1; }
            apply_rofi_layout_only "${2}"
            ;;
        apply-rofi-style)
            [[ -n "${2:-}" ]] || { usage; exit 1; }
            apply_rofi_style_only "${2}"
            ;;
        apply-background)
            [[ -n "${2:-}" && -n "${3:-}" ]] || { usage; exit 1; }
            apply_background_only "${2}" "${3}"
            refresh_runtime
            ;;
        *)
            usage
            exit 1
            ;;
    esac
}

main "$@"