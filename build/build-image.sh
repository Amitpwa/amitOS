#!/usr/bin/env bash
# ============================================================================
# amitOS — OS Image Builder
# ============================================================================
# Builds a minimal amitOS root filesystem using debootstrap, then layers
# amitOS components (kernel config, services, adapters, scripts).
#
# Usage:
#   sudo ./build/build-image.sh [--arch amd64|arm64] [--output NAME]
#
# Output:
#   build/output/amitOS-<version>-<arch>.tar.gz   (rootfs tarball)
#   build/output/amitOS-<version>-<arch>.img       (raw disk image)
#
# Prerequisites:
#   apt install debootstrap qemu-user-static binfmt-support dosfstools
# ============================================================================
set -euo pipefail
IFS=$'\n\t'

# --- Constants ---
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
readonly OUTPUT_DIR="${PROJECT_ROOT}/build/output"
readonly ROOTFS_DIR="${PROJECT_ROOT}/build/rootfs"
readonly PACKAGES_FILE="${SCRIPT_DIR}/packages.list"
readonly HOOKS_DIR="${SCRIPT_DIR}/hooks"

# --- Defaults ---
ARCH="amd64"
SUITE="bookworm"
MIRROR="http://deb.debian.org/debian"
IMAGE_SIZE="4G"
AMITOS_VERSION="$(cat "${PROJECT_ROOT}/VERSION" 2>/dev/null || echo '0.3.0-dev')"
OUTPUT_NAME=""

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
log_step()  { echo -e "${BLUE}[STEP]${NC}  $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

# --- Parse Arguments ---
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --arch)    ARCH="$2"; shift 2 ;;
            --output)  OUTPUT_NAME="$2"; shift 2 ;;
            --suite)   SUITE="$2"; shift 2 ;;
            --mirror)  MIRROR="$2"; shift 2 ;;
            --size)    IMAGE_SIZE="$2"; shift 2 ;;
            --help|-h)
                echo "Usage: $(basename "$0") [--arch amd64|arm64] [--output NAME] [--suite bookworm] [--size 4G]"
                exit 0
                ;;
            *) log_error "Unknown option: $1"; exit 1 ;;
        esac
    done

    OUTPUT_NAME="${OUTPUT_NAME:-amitOS-${AMITOS_VERSION}-${ARCH}}"

    if [[ "${ARCH}" == "arm64" ]]; then
        DEBOOTSTRAP_ARCH="arm64"
    else
        DEBOOTSTRAP_ARCH="amd64"
    fi
}

check_prerequisites() {
    log_step "Checking prerequisites..."

    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root."
        exit 1
    fi

    local deps=(debootstrap)
    if [[ "${ARCH}" == "arm64" && "$(uname -m)" != "aarch64" ]]; then
        deps+=(qemu-user-static binfmt-support)
    fi

    for cmd in "${deps[@]}"; do
        if ! command -v "${cmd}" &>/dev/null && ! dpkg -l "${cmd}" &>/dev/null; then
            log_info "Installing ${cmd}..."
            apt-get install -y -qq "${cmd}"
        fi
    done

    log_info "Prerequisites OK."
}

bootstrap_rootfs() {
    log_step "Bootstrapping Debian ${SUITE} (${DEBOOTSTRAP_ARCH})..."

    if [[ -d "${ROOTFS_DIR}" ]]; then
        log_warn "Removing existing rootfs..."
        rm -rf "${ROOTFS_DIR}"
    fi

    mkdir -p "${ROOTFS_DIR}"

    # Read packages from packages.list (skip comments and blank lines)
    local packages
    packages="$(grep -v '^\s*#' "${PACKAGES_FILE}" | grep -v '^\s*$' | tr '\n' ',' | sed 's/,$//')"

    debootstrap \
        --arch="${DEBOOTSTRAP_ARCH}" \
        --variant=minbase \
        --include="${packages}" \
        "${SUITE}" \
        "${ROOTFS_DIR}" \
        "${MIRROR}"

    log_info "Base system bootstrapped."
}

configure_rootfs() {
    log_step "Configuring amitOS rootfs..."

    # --- Hostname ---
    echo "amitos" > "${ROOTFS_DIR}/etc/hostname"
    cat > "${ROOTFS_DIR}/etc/hosts" <<EOF
127.0.0.1   localhost
127.0.1.1   amitos

::1         localhost ip6-localhost ip6-loopback
ff02::1     ip6-allnodes
ff02::2     ip6-allrouters
EOF

    # --- Version File ---
    echo "${AMITOS_VERSION}" > "${ROOTFS_DIR}/etc/amitos/version"

    # --- Filesystem structure ---
    mkdir -p "${ROOTFS_DIR}/etc/amitos/adapters"
    mkdir -p "${ROOTFS_DIR}/etc/amitos/opcua/certs/trusted"
    mkdir -p "${ROOTFS_DIR}/etc/amitos/opcua/certs/rejected"
    mkdir -p "${ROOTFS_DIR}/etc/amitos/nginx/certs"
    mkdir -p "${ROOTFS_DIR}/opt/amitos/adapters"
    mkdir -p "${ROOTFS_DIR}/opt/amitos/opcua"
    mkdir -p "${ROOTFS_DIR}/opt/amitos/ai"
    mkdir -p "${ROOTFS_DIR}/opt/amitos/scripts"
    mkdir -p "${ROOTFS_DIR}/opt/amitos/dashboard"
    mkdir -p "${ROOTFS_DIR}/var/log/amitos"
    mkdir -p "${ROOTFS_DIR}/run/amitos"

    # --- Copy adapter configs ---
    cp "${PROJECT_ROOT}/system/configs/adapters/"*.yaml "${ROOTFS_DIR}/etc/amitos/adapters/"

    # --- Copy OPC UA config ---
    cp "${PROJECT_ROOT}/system/configs/opcua/server.xml" "${ROOTFS_DIR}/etc/amitos/opcua/"

    # --- Copy Nginx config ---
    cp "${PROJECT_ROOT}/system/configs/nginx/amitos-dashboard.conf" "${ROOTFS_DIR}/etc/amitos/nginx/"

    # --- Copy systemd services ---
    cp "${PROJECT_ROOT}/system/services/"*.service "${ROOTFS_DIR}/etc/systemd/system/" 2>/dev/null || true
    cp "${PROJECT_ROOT}/system/services/"*.target "${ROOTFS_DIR}/etc/systemd/system/" 2>/dev/null || true
    cp "${PROJECT_ROOT}/system/services/"*.timer "${ROOTFS_DIR}/etc/systemd/system/" 2>/dev/null || true

    # --- Copy scripts ---
    cp "${PROJECT_ROOT}/system/scripts/"*.sh "${ROOTFS_DIR}/opt/amitos/scripts/"
    chmod +x "${ROOTFS_DIR}/opt/amitos/scripts/"*.sh

    # --- Copy kernel tuning ---
    cp "${PROJECT_ROOT}/kernel/sysctl-amitos.conf" "${ROOTFS_DIR}/etc/sysctl.d/99-amitos.conf"
    cp "${PROJECT_ROOT}/kernel/modules-load.conf" "${ROOTFS_DIR}/etc/modules-load.d/amitos.conf"

    # --- Netplan default config ---
    mkdir -p "${ROOTFS_DIR}/etc/netplan"
    cat > "${ROOTFS_DIR}/etc/netplan/01-amitos.yaml" <<EOF
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      dhcp4: true
EOF

    # --- Enable core services ---
    chroot "${ROOTFS_DIR}" /bin/bash -c "
        systemctl enable ssh || true
        systemctl enable nginx || true
        systemctl enable nftables || true
        systemctl enable amitos-health.timer || true
    " 2>/dev/null || log_warn "Some services could not be enabled in chroot."

    # --- Set root password (changeme) ---
    chroot "${ROOTFS_DIR}" /bin/bash -c "echo 'root:amitos' | chpasswd" 2>/dev/null || true

    # --- Create amitos user ---
    chroot "${ROOTFS_DIR}" /bin/bash -c "
        useradd -m -s /bin/bash -G sudo,docker amitos 2>/dev/null || true
        echo 'amitos:amitos' | chpasswd
    " 2>/dev/null || true

    log_info "amitOS rootfs configured."
}

run_hooks() {
    log_step "Running customization hooks..."

    if [[ -d "${HOOKS_DIR}" ]]; then
        for hook in "${HOOKS_DIR}"/*.sh; do
            if [[ -x "${hook}" ]]; then
                log_info "Running hook: $(basename "${hook}")"
                ROOTFS="${ROOTFS_DIR}" bash "${hook}"
            fi
        done
    else
        log_info "No hooks directory found. Skipping."
    fi
}

create_tarball() {
    log_step "Creating rootfs tarball..."

    mkdir -p "${OUTPUT_DIR}"
    local tarball="${OUTPUT_DIR}/${OUTPUT_NAME}.tar.gz"

    tar czf "${tarball}" -C "${ROOTFS_DIR}" .

    log_info "Tarball: ${tarball} ($(du -h "${tarball}" | cut -f1))"
}

create_disk_image() {
    log_step "Creating raw disk image..."

    mkdir -p "${OUTPUT_DIR}"
    local img="${OUTPUT_DIR}/${OUTPUT_NAME}.img"

    # Create empty image
    truncate -s "${IMAGE_SIZE}" "${img}"

    # Partition (GPT: EFI + root)
    parted -s "${img}" mklabel gpt
    parted -s "${img}" mkpart ESP fat32 1MiB 512MiB
    parted -s "${img}" set 1 esp on
    parted -s "${img}" mkpart root ext4 512MiB 100%

    # Set up loop device
    local loop
    loop="$(losetup --find --show --partscan "${img}")"

    # Format partitions
    mkfs.fat -F 32 "${loop}p1"
    mkfs.ext4 -q "${loop}p2"

    # Mount and copy rootfs
    local mnt="/tmp/amitos-mnt"
    mkdir -p "${mnt}"
    mount "${loop}p2" "${mnt}"
    mkdir -p "${mnt}/boot/efi"
    mount "${loop}p1" "${mnt}/boot/efi"

    rsync -a "${ROOTFS_DIR}/" "${mnt}/"

    # Cleanup
    umount "${mnt}/boot/efi"
    umount "${mnt}"
    losetup -d "${loop}"
    rm -rf "${mnt}"

    log_info "Disk image: ${img} ($(du -h "${img}" | cut -f1))"
}

print_summary() {
    echo ""
    echo "============================================================================"
    echo "  amitOS Image Build Complete"
    echo "============================================================================"
    echo ""
    echo "  Version:       ${AMITOS_VERSION}"
    echo "  Architecture:  ${ARCH}"
    echo "  Suite:         ${SUITE}"
    echo "  Output:        ${OUTPUT_DIR}/"
    echo ""
    echo "  Files:"
    ls -lh "${OUTPUT_DIR}/${OUTPUT_NAME}"* 2>/dev/null | awk '{print "    " $NF " (" $5 ")"}'
    echo ""
    echo "  Flash to USB:"
    echo "    sudo dd if=${OUTPUT_DIR}/${OUTPUT_NAME}.img of=/dev/sdX bs=4M status=progress"
    echo ""
    echo "============================================================================"
}

cleanup() {
    log_info "Cleaning up..."
    # Unmount any leftover mounts
    umount "${ROOTFS_DIR}/proc" 2>/dev/null || true
    umount "${ROOTFS_DIR}/sys" 2>/dev/null || true
    umount "${ROOTFS_DIR}/dev/pts" 2>/dev/null || true
    umount "${ROOTFS_DIR}/dev" 2>/dev/null || true
}

trap cleanup EXIT

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
    echo -e "\033[2m  Image Builder\033[0m"
    echo ""

    parse_args "$@"
    check_prerequisites
    bootstrap_rootfs
    configure_rootfs
    run_hooks
    create_tarball
    create_disk_image
    print_summary
}

main "$@"
