#!/usr/bin/env bash
# ============================================================================
# amitOS — System Information Script
# ============================================================================
# Displays comprehensive system information for diagnostics and support.
#
# Usage: amitos-info [--json]
# Install to: /opt/amitos/scripts/amitos-info.sh
# ============================================================================
set -euo pipefail

# --- Colors ---
BOLD='\033[1m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

JSON_MODE=false
[[ "${1:-}" == "--json" ]] && JSON_MODE=true

section() {
    if [[ "${JSON_MODE}" == false ]]; then
        echo -e "\n${BOLD}${CYAN}━━━ $1 ━━━${NC}"
    fi
}

kv() {
    if [[ "${JSON_MODE}" == false ]]; then
        printf "  ${GREEN}%-24s${NC} %s\n" "$1:" "$2"
    fi
}

# --- Gather Data ---
AMITOS_VERSION="$(cat /etc/amitos/version 2>/dev/null || echo 'unknown')"
HOSTNAME="$(hostname)"
UPTIME="$(uptime -p 2>/dev/null || echo 'unknown')"
KERNEL="$(uname -r)"
ARCH="$(uname -m)"
DEBIAN_VERSION="$(cat /etc/debian_version 2>/dev/null || echo 'unknown')"
CPU_MODEL="$(grep -m1 'model name' /proc/cpuinfo 2>/dev/null | cut -d: -f2 | xargs || echo 'unknown')"
CPU_CORES="$(nproc 2>/dev/null || echo 'unknown')"
MEM_TOTAL="$(free -h 2>/dev/null | awk '/Mem:/{print $2}' || echo 'unknown')"
MEM_USED="$(free -h 2>/dev/null | awk '/Mem:/{print $3}' || echo 'unknown')"
DISK_ROOT="$(df -h / 2>/dev/null | awk 'NR==2{print $3"/"$2" ("$5" used)"}' || echo 'unknown')"
GPU_INFO="$(nvidia-smi --query-gpu=name,driver_version,memory.total --format=csv,noheader 2>/dev/null || echo 'No NVIDIA GPU detected')"
CUDA_VERSION="$(nvcc --version 2>/dev/null | grep -oP 'release \K[0-9.]+' || echo 'not installed')"
DOCKER_VERSION="$(docker --version 2>/dev/null | cut -d' ' -f3 | tr -d ',' || echo 'not installed')"
PYTHON_VERSION="$(python3 --version 2>/dev/null | cut -d' ' -f2 || echo 'not installed')"

# --- JSON Output ---
if [[ "${JSON_MODE}" == true ]]; then
    cat <<EOF
{
  "amitos_version": "${AMITOS_VERSION}",
  "hostname": "${HOSTNAME}",
  "uptime": "${UPTIME}",
  "kernel": "${KERNEL}",
  "arch": "${ARCH}",
  "debian": "${DEBIAN_VERSION}",
  "cpu": "${CPU_MODEL}",
  "cpu_cores": "${CPU_CORES}",
  "memory_total": "${MEM_TOTAL}",
  "memory_used": "${MEM_USED}",
  "disk_root": "${DISK_ROOT}",
  "gpu": "${GPU_INFO}",
  "cuda": "${CUDA_VERSION}",
  "docker": "${DOCKER_VERSION}",
  "python": "${PYTHON_VERSION}"
}
EOF
    exit 0
fi

# --- Pretty Output ---
echo -e "${BOLD}"
echo "  ╔══════════════════════════════════════╗"
echo "  ║         amitOS System Info           ║"
echo "  ╚══════════════════════════════════════╝"
echo -e "${NC}"

section "SYSTEM"
kv "amitOS Version" "${AMITOS_VERSION}"
kv "Hostname" "${HOSTNAME}"
kv "Uptime" "${UPTIME}"
kv "Kernel" "${KERNEL}"
kv "Architecture" "${ARCH}"
kv "Debian" "${DEBIAN_VERSION}"

section "HARDWARE"
kv "CPU" "${CPU_MODEL}"
kv "CPU Cores" "${CPU_CORES}"
kv "Memory (Total)" "${MEM_TOTAL}"
kv "Memory (Used)" "${MEM_USED}"
kv "Disk (root)" "${DISK_ROOT}"

section "GPU / AI"
kv "GPU" "${GPU_INFO}"
kv "CUDA" "${CUDA_VERSION}"

section "SOFTWARE"
kv "Docker" "${DOCKER_VERSION}"
kv "Python" "${PYTHON_VERSION}"

section "SERVICES"
for svc in opcua-server modbus-adapter mqtt-adapter siemens-s7-adapter bacnet-adapter rest-bridge-adapter nginx docker; do
    if systemctl is-active --quiet "${svc}" 2>/dev/null; then
        kv "${svc}" "● active"
    elif systemctl is-enabled --quiet "${svc}" 2>/dev/null; then
        kv "${svc}" "○ enabled (inactive)"
    else
        kv "${svc}" "✗ not configured"
    fi
done

section "NETWORK"
ip -br addr show 2>/dev/null | while read -r iface state addrs; do
    kv "${iface}" "${state}  ${addrs}"
done

echo ""
