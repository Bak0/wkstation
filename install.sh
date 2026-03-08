#!/usr/bin/env bash
# wkstation/install.sh
# One-time Arch + Hyprland base install
#
# Repo layout expected:
#   config/
#     hypr/
#     waybar/
#     rofi/
#   packages/
#     pacman.txt
#     aur-packages.txt
#   themes/
#     dark/
#     cyberpunk/
#
# Core design:
# - copy base behavior config from repo -> ~/.config
# - apply active theme from repo themes -> runtime theme files
# - configure greetd + ReGreet for graphical login
# - use hyprlock/hypridle/hyprpaper from your base config
# - install AUR packages as the real user, never as root

set -Eeuo pipefail

log()  { printf '\n==> %s\n' "$*"; }
warn() { printf '\n[WARN] %s\n' "$*" >&2; }
die()  { printf '\n[ERROR] %s\n' "$*" >&2; exit 1; }

[[ "${EUID}" -eq 0 ]] || die "Run this with sudo."
[[ -n "${SUDO_USER:-}" && "${SUDO_USER}" != "root" ]] || die "Run this with sudo from your normal user account, not directly as root."

USER_NAME="${SUDO_USER}"
USER_HOME="$(getent passwd "${USER_NAME}" | cut -d: -f6)"
[[ -n "${USER_HOME}" && -d "${USER_HOME}" ]] || die "Could not resolve home directory for user: ${USER_NAME}"

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_SOURCE_DIR="${REPO_DIR}/config"
PACKAGES_DIR="${REPO_DIR}/packages"
THEMES_DIR="${REPO_DIR}/themes"

PACMAN_FILE="${PACKAGES_DIR}/pacman.txt"
AUR_FILE="${PACKAGES_DIR}/aur-packages.txt"

DEFAULT_THEME="${DEFAULT_THEME:-dark}"

USER_CONFIG_DIR="${USER_HOME}/.config"
USER_HYPR_DIR="${USER_CONFIG_DIR}/hypr"
USER_WAYBAR_DIR="${USER_CONFIG_DIR}/waybar"
USER_ROFI_DIR="${USER_CONFIG_DIR}/rofi"
USER_LOCAL_SHARE="${USER_HOME}/.local/share"
USER_WALL_DIR="${USER_LOCAL_SHARE}/wallpapers"
AUR_BUILD_ROOT="${USER_HOME}/.cache/wkstation-aur"

require_file() {
    local file="$1"
    [[ -f "${file}" ]] || die "Required file not found: ${file}"
}

parse_pkg_file() {
    local file="$1"
    sed -E 's/[[:space:]]*#.*$//' "${file}" | sed '/^[[:space:]]*$/d'
}

enable_multilib() {
    if grep -Eq '^[[:space:]]*\[multilib\][[:space:]]*$' /etc/pacman.conf; then
        log "Multilib already enabled"
        return
    fi

    log "Enabling multilib in /etc/pacman.conf"
    sed -i '/^[[:space:]]*#\s*\[multilib\][[:space:]]*$/,/^[[:space:]]*#\s*Include = \/etc\/pacman.d\/mirrorlist[[:space:]]*$/ s/^[[:space:]]*#\s*//' /etc/pacman.conf
}

install_pacman_packages() {
    require_file "${PACMAN_FILE}"

    mapfile -t pkgs < <(parse_pkg_file "${PACMAN_FILE}")
    if (( ${#pkgs[@]} == 0 )); then
        warn "No pacman packages found in ${PACMAN_FILE}"
        return
    fi

    log "Installing pacman packages"
    pacman -S --noconfirm --needed "${pkgs[@]}"
}

build_and_install_aur_pkg() {
    local pkg="$1"
    local build_dir="${AUR_BUILD_ROOT}/${pkg}"

    if pacman -Q "${pkg}" >/dev/null 2>&1; then
        log "AUR package already installed: ${pkg}"
        return
    fi

    log "Building AUR package: ${pkg}"

    rm -rf "${build_dir}"
    sudo -u "${USER_NAME}" mkdir -p "${AUR_BUILD_ROOT}"
    sudo -u "${USER_NAME}" git clone --depth 1 "https://aur.archlinux.org/${pkg}.git" "${build_dir}"

    sudo -u "${USER_NAME}" bash -lc "
        set -Eeuo pipefail
        cd '${build_dir}'
        makepkg -s --noconfirm
    "

    local built_pkg
    built_pkg="$(find "${build_dir}" -maxdepth 1 -type f -name '*.pkg.tar.*' ! -name '*.sig' | sort | tail -n 1)"
    [[ -n "${built_pkg}" ]] || die "Failed to find built package for ${pkg}"

    pacman -U --noconfirm "${built_pkg}"
}

install_aur_packages() {
    require_file "${AUR_FILE}"

    mapfile -t pkgs < <(parse_pkg_file "${AUR_FILE}")
    if (( ${#pkgs[@]} == 0 )); then
        log "No AUR packages listed"
        return
    fi

    log "Installing base-devel + git for AUR builds"
    pacman -S --noconfirm --needed base-devel git

    for pkg in "${pkgs[@]}"; do
        build_and_install_aur_pkg "${pkg}"
    done
}

copy_base_config() {
    [[ -d "${CONFIG_SOURCE_DIR}" ]] || die "Missing config directory: ${CONFIG_SOURCE_DIR}"

    log "Copying base config from repo"
    install -d -m 0755 -o "${USER_NAME}" -g "${USER_NAME}" "${USER_CONFIG_DIR}"

    for dir in "${CONFIG_SOURCE_DIR}"/*; do
        [[ -d "${dir}" ]] || continue
        name="$(basename "${dir}")"
        rm -rf "${USER_CONFIG_DIR:?}/${name}"
        cp -a "${dir}" "${USER_CONFIG_DIR}/"
    done

    find "${USER_CONFIG_DIR}" -type f -name '.keep' -delete || true
    chown -R "${USER_NAME}:${USER_NAME}" "${USER_CONFIG_DIR}"
}

apply_theme() {
    local theme="$1"
    local theme_dir="${THEMES_DIR}/${theme}"

    [[ -d "${theme_dir}" ]] || die "Theme not found: ${theme_dir}"
    require_file "${theme_dir}/hypr.conf"
    require_file "${theme_dir}/waybar.css"
    require_file "${theme_dir}/rofi.rasi"
    require_file "${theme_dir}/wallpaper.jpg"

    log "Applying theme: ${theme}"

    install -d -m 0755 -o "${USER_NAME}" -g "${USER_NAME}" \
        "${USER_HYPR_DIR}" \
        "${USER_WAYBAR_DIR}" \
        "${USER_ROFI_DIR}" \
        "${USER_WALL_DIR}"

    install -m 0644 -o "${USER_NAME}" -g "${USER_NAME}" \
        "${theme_dir}/hypr.conf" "${USER_HYPR_DIR}/theme.conf"

    install -m 0644 -o "${USER_NAME}" -g "${USER_NAME}" \
        "${theme_dir}/waybar.css" "${USER_WAYBAR_DIR}/theme.css"

    install -m 0644 -o "${USER_NAME}" -g "${USER_NAME}" \
        "${theme_dir}/rofi.rasi" "${USER_ROFI_DIR}/theme.rasi"

    install -m 0644 -o "${USER_NAME}" -g "${USER_NAME}" \
        "${theme_dir}/wallpaper.jpg" "${USER_WALL_DIR}/current.jpg"

    ln -sfn "${theme_dir}" "${USER_CONFIG_DIR}/current_theme"
    chown -h "${USER_NAME}:${USER_NAME}" "${USER_CONFIG_DIR}/current_theme"
}

configure_greetd() {
    if ! command -v greetd >/dev/null 2>&1; then
        warn "greetd is not installed yet. Add greetd to packages/pacman.txt."
        return
    fi

    if ! command -v regreet >/dev/null 2>&1; then
        warn "greetd-regreet is not installed yet. Add greetd-regreet to packages/pacman.txt."
        return
    fi

    if ! command -v cage >/dev/null 2>&1; then
        warn "cage is not installed yet. Add cage to packages/pacman.txt."
        return
    fi

    log "Configuring greetd + ReGreet"
    install -d -m 0755 /etc/greetd

    cat > /etc/greetd/config.toml <<'EOF'
[terminal]
vt = 1

[default_session]
command = "cage -s -- regreet"
user = "greeter"
EOF

    systemctl enable greetd.service
}

enable_services() {
    log "Enabling essential services"
    systemctl enable --now NetworkManager.service
    systemctl enable --now bluetooth.service

    if systemctl list-unit-files | grep -q '^libvirtd\.service'; then
        systemctl enable libvirtd.service
        if getent group libvirt >/dev/null 2>&1; then
            usermod -aG libvirt "${USER_NAME}" || true
        fi
    fi
}

create_timeshift_snapshot() {
    if ! command -v timeshift >/dev/null 2>&1; then
        warn "timeshift is not installed yet. Add timeshift to packages/pacman.txt."
        return
    fi

    local root_fstype
    root_fstype="$(findmnt -nro FSTYPE / || true)"
    if [[ "${root_fstype}" != "btrfs" ]]; then
        warn "Root filesystem is ${root_fstype:-unknown}, not btrfs. Snapshot will still be attempted, but this is not your intended Btrfs-first layout."
    fi

    local root_source
    root_source="$(findmnt -nro SOURCE / | sed 's/\[[^]]*\]$//' || true)"
    [[ -n "${root_source}" ]] || die "Could not determine root device for Timeshift."

    log "Creating initial Timeshift snapshot"
    timeshift --create \
        --comments "wkstation: initial base install" \
        --tags D \
        --snapshot-device "${root_source}" \
        || warn "Timeshift snapshot creation failed. Check Timeshift after first boot."
}

final_notes() {
    printf '\n'
    printf 'Done.\n'
    printf 'User: %s\n' "${USER_NAME}"
    printf 'Default theme applied: %s\n' "${DEFAULT_THEME}"
    printf 'Repo dir: %s\n' "${REPO_DIR}"
    printf '\n'
    printf 'Important:\n'
    printf ' - Base behavior was copied from config/ into ~/.config\n'
    printf ' - Active theme was copied from themes/%s into runtime theme files\n' "${DEFAULT_THEME}"
    printf ' - greetd was configured only if greetd + greetd-regreet + cage were installed\n'
    printf ' - Timeshift snapshot was attempted, but Timeshift is still primarily system rollback, not a full home-data backup\n'
    printf '\n'
}

main() {
    require_file "${PACMAN_FILE}"
    require_file "${AUR_FILE}"
    [[ -d "${CONFIG_SOURCE_DIR}" ]] || die "Missing config directory: ${CONFIG_SOURCE_DIR}"
    [[ -d "${THEMES_DIR}" ]] || die "Missing themes directory: ${THEMES_DIR}"

    enable_multilib

    log "Refreshing package databases and upgrading system"
    pacman -Syu --noconfirm

    install_pacman_packages
    install_aur_packages

    copy_base_config
    apply_theme "${DEFAULT_THEME}"

    configure_greetd
    enable_services
    create_timeshift_snapshot
    final_notes
}

main "$@"
