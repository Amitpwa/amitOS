#!/usr/bin/env bash
# ============================================================================
# amitOS — System Installer
# ============================================================================
# Transforms a fresh Debian Bookworm installation into amitOS.
#
# Usage:
#   sudo bash install.sh [--skip-packages] [--skip-docker] [--skip-nvidia]
#
# This script:
#   1. Validates prerequisites (Debian, root, architecture)
#   2. Installs system packages
#   3. Creates amitOS filesystem layout
#   4. Deploys configuration files
#   5. Installs systemd services
#   6. Applies kernel tuning
#   7. Optionally installs Docker and NVIDIA CUDA
#   8. Runs health check
# ============================================================================
set -euo pipefail
IFS=$'\n\t'

# --- Constants ---
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly VERSION="$(cat "${SCRIPT_DIR}/VERSION" 2>/dev/null || echo '0.3.0-dev')"

# --- Defaults ---
SKIP_PACKAGES=false
SKIP_DOCKER=false
SKIP_NVIDIA=false
NONINTERACTIVE=false
INSTALL_DESKTOP=false

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

log_info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
log_step()  { echo -e "\n${BLUE}${BOLD}[$((++STEP_NUM))/8]${NC} ${BOLD}$*${NC}"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }
STEP_NUM=0

# --- Parse Arguments ---
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --skip-packages) SKIP_PACKAGES=true; shift ;;
            --skip-docker)   SKIP_DOCKER=true; shift ;;
            --skip-nvidia)   SKIP_NVIDIA=true; shift ;;
            --desktop)       INSTALL_DESKTOP=true; shift ;;
            --noninteractive|-y) NONINTERACTIVE=true; shift ;;
            --help|-h)
                cat <<EOF
Usage: sudo bash install.sh [OPTIONS]

Transform a Debian Bookworm system into amitOS.

OPTIONS:
  --skip-packages      Skip APT package installation
  --skip-docker        Skip Docker Engine installation
  --skip-nvidia        Skip NVIDIA CUDA toolkit installation
  --desktop            Install post-installation GUI (XFCE4 Desktop Environment)
  --noninteractive     Run without prompting for confirmation
  -h, --help           Show this help

EXAMPLES:
  sudo bash install.sh                        # Full install
  sudo bash install.sh --skip-nvidia          # Install without CUDA
  sudo bash install.sh --skip-packages -y     # Skip packages, no prompts
EOF
                exit 0
                ;;
            *) log_error "Unknown option: $1"; exit 1 ;;
        esac
    done
}

# --- Step 1: Validate Prerequisites ---
step_validate() {
    log_step "Validating prerequisites..."

    # Must be root
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root. Use: sudo bash install.sh"
        exit 1
    fi

    # Must be Debian
    if [[ ! -f /etc/debian_version ]]; then
        log_error "amitOS requires Debian Linux. This system is not Debian."
        exit 1
    fi

    local debian_ver
    debian_ver="$(cat /etc/debian_version)"
    log_info "Debian version: ${debian_ver}"

    # Check architecture
    local arch
    arch="$(uname -m)"
    if [[ "${arch}" != "x86_64" && "${arch}" != "aarch64" ]]; then
        log_error "Unsupported architecture: ${arch}. amitOS supports x86_64 and aarch64."
        exit 1
    fi
    log_info "Architecture: ${arch}"

    # Confirmation prompt
    if [[ "${NONINTERACTIVE}" == false ]]; then
        echo ""
        echo -e "  ${YELLOW}This will transform your Debian system into amitOS ${VERSION}.${NC}"
        echo -e "  ${YELLOW}It will install packages, create directories, and modify system configs.${NC}"
        echo ""
        read -rp "  Continue? [y/N] " confirm
        if [[ "${confirm}" != "y" && "${confirm}" != "Y" ]]; then
            log_info "Installation cancelled."
            exit 0
        fi
    fi

    log_info "Prerequisites validated."
}

# --- Step 2: Install Packages ---
step_packages() {
    log_step "Installing system packages..."

    if [[ "${SKIP_PACKAGES}" == true ]]; then
        log_info "Skipping package installation (--skip-packages)."
        return
    fi

    apt-get update -qq

    # Read packages from packages.list
    local packages_file="${SCRIPT_DIR}/build/packages.list"
    if [[ -f "${packages_file}" ]]; then
        local packages
        packages="$(grep -v '^\s*#' "${packages_file}" | grep -v '^\s*$' | tr '\n' ' ')"
        log_info "Installing packages from packages.list..."
        # shellcheck disable=SC2086
        apt-get install -y -qq ${packages} || log_warn "Some packages may have failed to install."
    else
        log_warn "packages.list not found. Installing minimal set..."
        apt-get install -y -qq \
            curl wget gnupg ca-certificates \
            python3 python3-pip python3-venv python3-yaml \
            nginx nftables netplan.io \
            openssh-server htop jq tmux
    fi

    log_info "Packages installed."
}

# --- Step 3: Create Filesystem Layout ---
step_filesystem() {
    log_step "Creating amitOS filesystem layout..."

    # Configuration directories
    mkdir -p /etc/amitos/adapters
    mkdir -p /etc/amitos/opcua/certs/trusted
    mkdir -p /etc/amitos/opcua/certs/rejected
    mkdir -p /etc/amitos/nginx/certs

    # Application directories
    mkdir -p /opt/amitos/adapters
    mkdir -p /opt/amitos/opcua
    mkdir -p /opt/amitos/ai
    mkdir -p /opt/amitos/scripts
    mkdir -p /opt/amitos/dashboard

    # Runtime directories
    mkdir -p /var/log/amitos
    mkdir -p /run/amitos

    # Version file
    echo "${VERSION}" > /etc/amitos/version

    log_info "Filesystem layout created."
}

# --- Step 4: Deploy Configurations ---
step_configs() {
    log_step "Deploying configuration files..."

    local configs_dir="${SCRIPT_DIR}/system/configs"

    # Adapter configs
    if [[ -d "${configs_dir}/adapters" ]]; then
        cp -n "${configs_dir}/adapters/"*.yaml /etc/amitos/adapters/ 2>/dev/null || true
        log_info "Adapter configs deployed to /etc/amitos/adapters/"
    fi

    # OPC UA config
    if [[ -f "${configs_dir}/opcua/server.xml" ]]; then
        cp -n "${configs_dir}/opcua/server.xml" /etc/amitos/opcua/
        log_info "OPC UA config deployed."
    fi

    # Nginx config
    if [[ -f "${configs_dir}/nginx/amitos-dashboard.conf" ]]; then
        cp -n "${configs_dir}/nginx/amitos-dashboard.conf" /etc/amitos/nginx/
        # Symlink to nginx sites if available
        if [[ -d /etc/nginx/sites-available ]]; then
            ln -sf /etc/amitos/nginx/amitos-dashboard.conf /etc/nginx/sites-available/amitos-dashboard.conf
            ln -sf /etc/nginx/sites-available/amitos-dashboard.conf /etc/nginx/sites-enabled/amitos-dashboard.conf 2>/dev/null || true
        fi
        log_info "Nginx config deployed."
    fi

    # Netplan default (don't overwrite existing)
    if [[ ! -f /etc/netplan/01-amitos.yaml ]]; then
        mkdir -p /etc/netplan
        cat > /etc/netplan/01-amitos.yaml <<EOF
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      dhcp4: true
EOF
        log_info "Default Netplan config deployed."
    fi

    log_info "Configurations deployed."
}

# --- Step 5: Install Services ---
step_services() {
    log_step "Installing systemd services..."

    local services_dir="${SCRIPT_DIR}/system/services"

    if [[ -d "${services_dir}" ]]; then
        # Copy service files
        cp "${services_dir}/"*.service /etc/systemd/system/ 2>/dev/null || true
        cp "${services_dir}/"*.target /etc/systemd/system/ 2>/dev/null || true
        cp "${services_dir}/"*.timer /etc/systemd/system/ 2>/dev/null || true

        # Reload systemd
        systemctl daemon-reload

        # Enable core services
        systemctl enable amitos-health.timer 2>/dev/null || true
        systemctl enable amitos-adapters.target 2>/dev/null || true

        log_info "systemd services installed."
        log_info "Note: Adapter services are not enabled by default. Use 'amitos-adapter enable <name>'."
    else
        log_warn "Services directory not found."
    fi
}

# --- Step 6: Install Scripts ---
step_scripts() {
    log_step "Installing utility scripts..."

    local scripts_dir="${SCRIPT_DIR}/system/scripts"

    if [[ -d "${scripts_dir}" ]]; then
        cp "${scripts_dir}/"*.sh /opt/amitos/scripts/
        chmod +x /opt/amitos/scripts/*.sh

        # Create symlinks in /usr/local/bin for easy access
        ln -sf /opt/amitos/scripts/amitos-info.sh /usr/local/bin/amitos-info
        ln -sf /opt/amitos/scripts/amitos-check.sh /usr/local/bin/amitos-check
        ln -sf /opt/amitos/scripts/amitos-adapter.sh /usr/local/bin/amitos-adapter

        log_info "Scripts installed. Available commands: amitos-info, amitos-check, amitos-adapter"
    else
        log_warn "Scripts directory not found."
    fi
}

# --- Step 7: Apply Kernel Tuning ---
step_kernel() {
    log_step "Applying kernel tuning..."

    local kernel_dir="${SCRIPT_DIR}/kernel"

    # sysctl tuning
    if [[ -f "${kernel_dir}/sysctl-amitos.conf" ]]; then
        cp "${kernel_dir}/sysctl-amitos.conf" /etc/sysctl.d/99-amitos.conf
        sysctl --system --quiet 2>/dev/null || log_warn "Some sysctl parameters could not be applied."
        log_info "Kernel sysctl parameters applied."
    fi

    # Module auto-loading
    if [[ -f "${kernel_dir}/modules-load.conf" ]]; then
        cp "${kernel_dir}/modules-load.conf" /etc/modules-load.d/amitos.conf
        # Load essential modules now
        modprobe overlay 2>/dev/null || true
        modprobe br_netfilter 2>/dev/null || true
        log_info "Kernel module configuration applied."
    fi

    # Install custom kernel if .deb packages are available
    local kernel_debs="${SCRIPT_DIR}/build/output"
    if ls "${kernel_debs}"/linux-image-*amitos*.deb 1>/dev/null 2>&1; then
        log_info "Custom amitOS kernel packages found. Installing..."
        dpkg -i "${kernel_debs}"/linux-image-*amitos*.deb || true
        dpkg -i "${kernel_debs}"/linux-headers-*amitos*.deb 2>/dev/null || true
        update-grub 2>/dev/null || true
        log_info "Custom kernel installed. A reboot is required to use it."
    else
        log_info "No custom kernel packages found. Using stock Debian kernel."
    fi
}

# --- Step 8: Optional — Docker & NVIDIA ---
step_optional() {
    log_step "Installing optional components..."

    # Docker
    if [[ "${SKIP_DOCKER}" == false ]]; then
        if command -v docker &>/dev/null; then
            log_info "Docker is already installed."
        else
            log_info "Installing Docker Engine..."
            install -m 0755 -d /etc/apt/keyrings
            curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc 2>/dev/null || true
            chmod a+r /etc/apt/keyrings/docker.asc 2>/dev/null || true

            echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian $(lsb_release -cs 2>/dev/null || echo bookworm) stable" \
                > /etc/apt/sources.list.d/docker.list

            apt-get update -qq
            apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin 2>/dev/null || \
                log_warn "Docker installation failed. Install manually: https://docs.docker.com/engine/install/debian/"

            # Add amitos user to docker group
            usermod -aG docker amitos 2>/dev/null || true

            systemctl enable docker 2>/dev/null || true
            log_info "Docker installed."
        fi
    else
        log_info "Skipping Docker installation (--skip-docker)."
    fi

    # Desktop Environment
    if [[ "${INSTALL_DESKTOP}" == true ]]; then
        log_info "Installing XFCE4 Desktop Environment..."
        export DEBIAN_FRONTEND=noninteractive
        apt-get install -y -qq xorg xfce4 xfce4-goodies lightdm network-manager-gnome 2>/dev/null || \
            log_warn "Desktop installation failed."
        systemctl enable lightdm 2>/dev/null || true
        systemctl set-default graphical.target 2>/dev/null || true
        log_info "Desktop Environment installed."
    else
        log_info "Skipping Desktop Environment (--desktop not specified)."
    fi

    # NVIDIA CUDA
    if [[ "${SKIP_NVIDIA}" == false ]]; then
        if command -v nvidia-smi &>/dev/null; then
            log_info "NVIDIA drivers already installed."
        else
            local arch
            arch="$(uname -m)"
            if [[ "${arch}" == "x86_64" ]]; then
                log_info "Setting up NVIDIA CUDA repository..."
                curl -fsSL https://developer.download.nvidia.com/compute/cuda/repos/debian12/x86_64/cuda-keyring_1.1-1_all.deb -o /tmp/cuda-keyring.deb 2>/dev/null || true
                dpkg -i /tmp/cuda-keyring.deb 2>/dev/null || true
                rm -f /tmp/cuda-keyring.deb
                apt-get update -qq
                log_info "NVIDIA CUDA repository configured. Install drivers with: apt install cuda-toolkit-12-3"
            else
                log_info "ARM64 detected. Use NVIDIA JetPack for Jetson platforms."
            fi
        fi
    else
        log_info "Skipping NVIDIA setup (--skip-nvidia)."
    fi
}

# --- Summary ---
print_summary() {
    echo ""
    echo "  ╔══════════════════════════════════════════════════════════╗"
    echo "  ║          amitOS Installation Complete                    ║"
    echo "  ╚══════════════════════════════════════════════════════════╝"
    echo ""
    echo -e "  ${BOLD}Version:${NC}     ${VERSION}"
    echo -e "  ${BOLD}Kernel:${NC}      $(uname -r)"
    echo -e "  ${BOLD}Config:${NC}      /etc/amitos/"
    echo -e "  ${BOLD}Scripts:${NC}     /opt/amitos/scripts/"
    echo -e "  ${BOLD}Logs:${NC}        /var/log/amitos/"
    echo ""
    echo -e "  ${BOLD}Quick Commands:${NC}"
    echo "    amitos-info              Show system information"
    echo "    amitos-check --full      Run full health check"
    echo "    amitos-adapter list      List all adapters"
    echo "    amitos-adapter enable    Enable an adapter"
    echo ""
    echo -e "  ${BOLD}Documentation:${NC}"
    echo "    docs/GETTING_STARTED.md  Getting started guide"
    echo "    docs/ARCHITECTURE.md     Architecture overview"
    echo "    docs/ADAPTERS.md         Adapter framework guide"
    echo "    docs/KERNEL.md           Kernel configuration guide"
    echo ""

    if ls /tmp/cuda-keyring.deb 1>/dev/null 2>&1 || command -v nvidia-smi &>/dev/null; then
        echo -e "  ${YELLOW}⚠  GPU:${NC} Don't forget to install NVIDIA drivers if not already present."
    fi

    echo -e "  ${GREEN}✓ amitOS ${VERSION} is ready.${NC}"
    echo ""
}

# --- Main ---
main() {
    echo ""
    echo -e "\033[0;36m"
    cat << 'LOGO'
        ╭──────────────────────────╮
        │  ██                      │
        │ ████       ╭──────╮     │
        │ ████       │ ╭──╮ │     │
        │  ██        │ ╰──╯ │     │
        │            ╰──────╯     │
        ╰──────────────────────────╯
LOGO
    echo -e "\033[1;37m"
    cat << 'TEXT'
       ██████╗ ███╗   ███╗██╗████████╗ ██████╗ ███████╗
      ██╔══██╗████╗ ████║██║╚══██╔══╝██╔═══██╗██╔════╝
      ███████║██╔████╔██║██║   ██║   ██║   ██║███████╗
      ██╔══██║██║╚██╔╝██║██║   ██║   ██║   ██║╚════██║
      ██║  ██║██║ ╚═╝ ██║██║   ██║   ╚██████╔╝███████║
      ╚═╝  ╚═╝╚═╝     ╚═╝╚═╝   ╚═╝    ╚═════╝ ╚══════╝
TEXT
    echo -e "\033[0m"
    echo -e "\033[2m  Installer v${VERSION}\033[0m"
    echo ""

    parse_args "$@"
    step_validate
    step_packages
    step_filesystem
    step_configs
    step_services
    step_scripts
    step_kernel
    step_optional
    print_summary
}

main "$@"
