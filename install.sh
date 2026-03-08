#!/bin/bash
# install.sh - Arch + Hyprland base setup
# Fully automated, 1-time setup
# Root placement: repo root
# Flow:
# 1. Update system
# 2. Install pacman packages
# 3. Install AUR packages
# 4. Copy configs
# 5. Enable essential services (NetworkManager, Bluetooth)
# 6. Create full Timeshift snapshot
# 7. Generate Hyprlock systemd service dynamically

set -e

# ----------------------------------------
# 0️⃣ Ensure running as root
# ----------------------------------------
if [[ $EUID -ne 0 ]]; then
    echo "Please run this script as root using sudo"
    exit 1
fi

# ----------------------------------------
# 1️⃣ Update system
# ----------------------------------------
echo "Updating system..."
pacman -Syu --noconfirm

# ----------------------------------------
# 2️⃣ Install pacman packages
# ----------------------------------------
echo "Installing pacman packages..."
PACMAN_FILE="$(dirname "$0")/packages/pacman.txt"
while read -r pkg; do
    [[ -z "$pkg" || "$pkg" =~ ^# ]] && continue
    echo "Installing $pkg..."
    pacman -S --noconfirm --needed "$pkg"
done < "$PACMAN_FILE"
echo "Pacman packages installed."

# ----------------------------------------
# 3️⃣ Install AUR packages via yay
# ----------------------------------------
echo "Installing AUR packages..."
if ! command -v yay &>/dev/null; then
    echo "Installing yay from AUR..."
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    cd /tmp/yay || exit
    makepkg -si --noconfirm
    cd - || exit
    rm -rf /tmp/yay
fi

AUR_FILE="$(dirname "$0")/packages/aur-packages.txt"
while read -r pkg; do
    [[ -z "$pkg" || "$pkg" =~ ^# ]] && continue
    echo "Installing $pkg..."
    yay -S --noconfirm --needed "$pkg"
done < "$AUR_FILE"
echo "AUR packages installed."

# ----------------------------------------
# 4️⃣ Copy configs
# ----------------------------------------
echo "Copying configuration files..."
CONFIGS_DIR="$(dirname "$0")/configs"
for folder in "$CONFIGS_DIR"/*; do
    if [ -d "$folder" ]; then
        folder_name=$(basename "$folder")
        echo "Copying $folder_name..."
        rm -rf "/home/$SUDO_USER/.config/$folder_name"
        cp -r "$folder" "/home/$SUDO_USER/.config/"
    fi
done
echo "Configs copied."

# ----------------------------------------
# 5️⃣ Enable essential services
# ----------------------------------------
echo "Enabling essential services..."
systemctl enable NetworkManager
systemctl enable bluetooth
echo "Services enabled."

# ----------------------------------------
# 6️⃣ Install Timeshift and create full snapshot
# ----------------------------------------
echo "Creating full initial Timeshift snapshot..."
if ! command -v timeshift &>/dev/null; then
    pacman -S --noconfirm timeshift
fi

# Detect root device for snapshot
ROOT_DEVICE=$(findmnt -n -o SOURCE /)
timeshift --create --comments "Super First Install Snapshot" --tags D --snapshot-device "$ROOT_DEVICE"
echo "Full initial snapshot created."

# ----------------------------------------
# 7️⃣ Generate Hyprlock systemd service dynamically
# ----------------------------------------
echo "Creating Hyprlock systemd service..."

SERVICE_FILE="/etc/systemd/system/hyprlock@.service"
cat > "$SERVICE_FILE" << EOF
[Unit]
Description=Hyprlock Login Screen
After=systemd-user-sessions.service
After=graphical.target
Wants=graphical.target

[Service]
Type=simple
User=%i
PAMName=login
Environment=DISPLAY=:0
Environment=XDG_RUNTIME_DIR=/run/user/%U
ExecStart=/usr/bin/hyprlock
Restart=always
RestartSec=1

[Install]
WantedBy=graphical.target
EOF

# Enable for the detected first user
FIRST_USER=$(ls /home | head -n1)
systemctl enable hyprlock@$FIRST_USER.service
echo "Hyprlock service enabled for user: $FIRST_USER"

# ----------------------------------------
# ✅ Installation complete
# ----------------------------------------
echo "Install script completed! System ready with Hyprland login, configs applied, packages installed, and snapshot created."
