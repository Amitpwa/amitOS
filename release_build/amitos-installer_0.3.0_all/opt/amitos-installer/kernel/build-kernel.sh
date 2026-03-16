#!/usr/bin/env bash
# ============================================================================
# amitOS — Kernel Build Script
# ============================================================================
# Builds a custom Debian kernel with amitOS industrial optimizations.
#
# Usage:
#   sudo ./kernel/build-kernel.sh [--arch amd64|arm64] [--jobs N]
#
# Prerequisites:
#   apt install build-essential fakeroot dpkg-dev libncurses-dev
#   apt install flex bison libssl-dev libelf-dev bc rsync
#
# Output:
#   build/output/linux-image-*.deb
#   build/output/linux-headers-*.deb
# ============================================================================
set -euo pipefail
IFS=$'\n\t'

# --- Constants ---
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
readonly BUILD_DIR="${PROJECT_ROOT}/build/kernel-build"
readonly OUTPUT_DIR="${PROJECT_ROOT}/build/output"
readonly FRAGMENT="${SCRIPT_DIR}/config-amitos.fragment"
readonly KERNEL_VERSION="${KERNEL_VERSION:-6.1}"
readonly AMITOS_VERSION="$(date +%Y%m%d)"

# --- Defaults ---
ARCH="${1:-amd64}"
JOBS="${2:-$(nproc)}"
CLEAN=false

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# --- Functions ---
log_info()    { echo -e "${GREEN}[INFO]${NC}  $*"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $*" >&2; }
log_step()    { echo -e "${BLUE}[STEP]${NC}  $*"; }

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Build a custom Debian kernel with amitOS industrial optimizations.

OPTIONS:
  --arch ARCH     Target architecture: amd64 (default) or arm64
  --jobs N        Number of parallel build jobs (default: all cores)
  --clean         Clean build directory before building
  --menuconfig    Open kernel menuconfig after applying fragment
  --help          Show this help message

ENVIRONMENT VARIABLES:
  KERNEL_VERSION  Debian kernel series to build (default: 6.1)

EXAMPLES:
  sudo ./kernel/build-kernel.sh
  sudo ./kernel/build-kernel.sh --arch arm64 --jobs 4
  sudo ./kernel/build-kernel.sh --clean --menuconfig
EOF
    exit 0
}

check_prerequisites() {
    log_step "Checking prerequisites..."

    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root (sudo)."
        exit 1
    fi

    local missing_pkgs=()
    local required_pkgs=(
        "build-essential"
        "fakeroot"
        "dpkg-dev"
        "libncurses-dev"
        "flex"
        "bison"
        "libssl-dev"
        "libelf-dev"
        "bc"
        "rsync"
        "cpio"
        "kmod"
        "dwarves"
    )

    for pkg in "${required_pkgs[@]}"; do
        if ! dpkg -l "$pkg" &>/dev/null; then
            missing_pkgs+=("$pkg")
        fi
    done

    if [[ ${#missing_pkgs[@]} -gt 0 ]]; then
        log_warn "Missing packages: ${missing_pkgs[*]}"
        log_info "Installing missing packages..."
        apt-get update -qq
        apt-get install -y -qq "${missing_pkgs[@]}"
    fi

    if [[ ! -f "${FRAGMENT}" ]]; then
        log_error "Kernel config fragment not found: ${FRAGMENT}"
        exit 1
    fi

    log_info "All prerequisites satisfied."
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --arch)
                ARCH="$2"
                shift 2
                ;;
            --jobs)
                JOBS="$2"
                shift 2
                ;;
            --clean)
                CLEAN=true
                shift
                ;;
            --menuconfig)
                MENUCONFIG=true
                shift
                ;;
            --help|-h)
                usage
                ;;
            *)
                log_error "Unknown option: $1"
                usage
                ;;
        esac
    done

    if [[ "${ARCH}" != "amd64" && "${ARCH}" != "arm64" ]]; then
        log_error "Unsupported architecture: ${ARCH}. Use 'amd64' or 'arm64'."
        exit 1
    fi
}

fetch_kernel_source() {
    log_step "Fetching Debian kernel source (${KERNEL_VERSION} series)..."

    mkdir -p "${BUILD_DIR}"

    if [[ "${CLEAN}" == true && -d "${BUILD_DIR}" ]]; then
        log_info "Cleaning previous build directory..."
        rm -rf "${BUILD_DIR:?}"/*
    fi

    cd "${BUILD_DIR}"

    # Enable deb-src repos if not already
    if ! grep -q "^deb-src" /etc/apt/sources.list /etc/apt/sources.list.d/*.list 2>/dev/null; then
        log_warn "deb-src repos may not be enabled. Attempting to enable..."
        sed -i 's/^# *deb-src/deb-src/' /etc/apt/sources.list 2>/dev/null || true
        apt-get update -qq
    fi

    # Download kernel source
    if [[ ! -d "linux-${KERNEL_VERSION}"* ]]; then
        apt-get source "linux-image-${ARCH}" 2>/dev/null || \
        apt-get source "linux" 2>/dev/null || {
            log_error "Failed to fetch kernel source. Ensure deb-src is enabled."
            exit 1
        }
    fi

    # Find the extracted source directory
    KERNEL_SRC="$(find . -maxdepth 1 -type d -name 'linux-*' | head -1)"
    if [[ -z "${KERNEL_SRC}" ]]; then
        log_error "Kernel source directory not found after extraction."
        exit 1
    fi

    log_info "Kernel source: ${KERNEL_SRC}"
}

apply_config_fragment() {
    log_step "Applying amitOS kernel configuration fragment..."

    cd "${BUILD_DIR}/${KERNEL_SRC}"

    # Start with Debian's default config
    local debian_config
    if [[ "${ARCH}" == "amd64" ]]; then
        debian_config="debian/config/kernelarch-x86/config"
    else
        debian_config="debian/config/kernelarch-arm64/config"
    fi

    # If Debian's structured config exists, use it
    if [[ -f "${debian_config}" ]]; then
        log_info "Using Debian structured config: ${debian_config}"
        cp "${debian_config}" .config
    elif [[ -f "/boot/config-$(uname -r)" ]]; then
        log_info "Using current running kernel config as base."
        cp "/boot/config-$(uname -r)" .config
    else
        log_info "Generating default config for ${ARCH}..."
        make defconfig
    fi

    # Apply the amitOS fragment on top
    if [[ -f "scripts/kconfig/merge_config.sh" ]]; then
        log_info "Merging amitOS config fragment via merge_config.sh..."
        ./scripts/kconfig/merge_config.sh -m .config "${FRAGMENT}"
    else
        log_info "merge_config.sh not found. Appending fragment manually..."
        cat "${FRAGMENT}" >> .config
        make olddefconfig
    fi

    # Set local version
    sed -i "s/^CONFIG_LOCALVERSION=.*/CONFIG_LOCALVERSION=\"-amitos-${AMITOS_VERSION}\"/" .config

    log_info "Kernel configuration applied."
}

run_menuconfig() {
    if [[ "${MENUCONFIG:-false}" == true ]]; then
        log_step "Opening menuconfig for manual review..."
        cd "${BUILD_DIR}/${KERNEL_SRC}"
        make menuconfig
    fi
}

build_kernel() {
    log_step "Building kernel (${JOBS} parallel jobs)..."

    cd "${BUILD_DIR}/${KERNEL_SRC}"

    # Build .deb packages
    make -j"${JOBS}" bindeb-pkg \
        LOCALVERSION="-amitos" \
        KDEB_PKGVERSION="$(make kernelversion)-amitos-${AMITOS_VERSION}" \
        2>&1 | tee "${BUILD_DIR}/build.log"

    log_info "Kernel build complete."
}

collect_output() {
    log_step "Collecting output packages..."

    mkdir -p "${OUTPUT_DIR}"

    # Move .deb files to output
    find "${BUILD_DIR}" -maxdepth 1 -name "*.deb" -exec mv {} "${OUTPUT_DIR}/" \;

    log_info "Output packages:"
    ls -lh "${OUTPUT_DIR}"/*.deb 2>/dev/null || log_warn "No .deb files found."
}

print_summary() {
    echo ""
    echo "============================================================================"
    echo "  amitOS Kernel Build Complete"
    echo "============================================================================"
    echo ""
    echo "  Architecture:  ${ARCH}"
    echo "  Kernel:        ${KERNEL_VERSION}-amitos-${AMITOS_VERSION}"
    echo "  Output:        ${OUTPUT_DIR}/"
    echo ""
    echo "  Install with:"
    echo "    sudo dpkg -i ${OUTPUT_DIR}/linux-image-*.deb"
    echo "    sudo dpkg -i ${OUTPUT_DIR}/linux-headers-*.deb"
    echo "    sudo update-grub"
    echo "    sudo reboot"
    echo ""
    echo "============================================================================"
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
    echo -e "\033[2m  Kernel Build System\033[0m"
    echo ""

    parse_args "$@"
    check_prerequisites
    fetch_kernel_source
    apply_config_fragment
    run_menuconfig
    build_kernel
    collect_output
    print_summary
}

main "$@"
