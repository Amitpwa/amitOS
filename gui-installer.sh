#!/usr/bin/env bash
# ============================================================================
# amitOS — GUI Installer Wizard (Whiptail)
# ============================================================================
# This is an interactive curses-based GUI for the amitOS installation.
# It acts as a wrapper around install.sh
# ============================================================================
set -euo pipefail

# Check for whiptail
if ! command -v whiptail &>/dev/null; then
    echo "Installing whiptail for GUI installer..."
    apt-get update -qq && apt-get install -y -qq whiptail
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_SCRIPT="${SCRIPT_DIR}/install.sh"

if [[ $EUID -ne 0 ]]; then
    whiptail --title "Permission Error" --msgbox "This installer must be run as root. Please run with sudo." 8 78
    exit 1
fi

whiptail --title "amitOS Installer" --msgbox "Welcome to the amitOS GUI Installer Wizard!\n\nThis will configure your Debian system into amitOS, complete with Industrial Edge capabilities, AI/GPU acceleration, and the amitFS unified filesystem." 12 78

# Ask for Desktop Environment
if whiptail --title "Desktop Environment" --yesno "Would you like to install the amitOS Post-Install Desktop GUI (XFCE4)?\n\nChoose 'Yes' for a graphical desktop, or 'No' to keep the system headless (CLI-only)." 10 78; then
    DESKTOP_FLAG="--desktop"
else
    DESKTOP_FLAG=""
fi

# Ask for Docker
if whiptail --title "Container Runtime" --yesno "Would you like to install Docker Engine?\n\nDocker is recommended for running containerized AI models and edge applications." 10 78; then
    DOCKER_FLAG=""
else
    DOCKER_FLAG="--skip-docker"
fi

# Ask for NVIDIA
if whiptail --title "NVIDIA GPU Support" --yesno "Would you like to configure the NVIDIA CUDA repository?\n\nChoose 'Yes' if this device has an NVIDIA GPU." 10 78; then
    NVIDIA_FLAG=""
else
    NVIDIA_FLAG="--skip-nvidia"
fi

whiptail --title "Ready to Install" --msgbox "amitOS is ready to install with your selected options.\n\nThe installation process will now begin in the terminal." 10 78

# Run the actual installer silently (or let it output to terminal)
clear
echo "Starting amitOS Installation..."

bash "${INSTALL_SCRIPT}" ${DESKTOP_FLAG} ${DOCKER_FLAG} ${NVIDIA_FLAG} -y

if [ $? -eq 0 ]; then
    whiptail --title "Installation Complete" --msgbox "amitOS has been successfully installed!\n\nPlease restart your system or start using the new amitos commands." 8 78
else
    whiptail --title "Installation Failed" --msgbox "An error occurred during installation. Please check the terminal output for details." 8 78
fi
clear
