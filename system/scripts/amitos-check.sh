#!/usr/bin/env bash
# ============================================================================
# amitOS — System Health Check Script
# ============================================================================
# Performs health checks on all amitOS components.
# Used by systemd health timer and the installer.
#
# Usage:
#   amitos-check.sh [--full | --service NAME | --quick]
#
# Exit codes:
#   0 = all checks passed
#   1 = one or more checks failed
#
# Install to: /opt/amitos/scripts/amitos-check.sh
# ============================================================================
set -euo pipefail

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

LOG_FILE="/var/log/amitos/health.log"
FAILURES=0
CHECKS=0
MODE="${1:---quick}"
SERVICE_NAME="${2:-}"

# --- Functions ---
pass() {
    ((CHECKS++))
    echo -e "  ${GREEN}✓${NC} $1"
    echo "[$(date -Iseconds)] PASS: $1" >> "${LOG_FILE}" 2>/dev/null || true
}

fail() {
    ((CHECKS++))
    ((FAILURES++))
    echo -e "  ${RED}✗${NC} $1"
    echo "[$(date -Iseconds)] FAIL: $1" >> "${LOG_FILE}" 2>/dev/null || true
}

warn() {
    echo -e "  ${YELLOW}⚠${NC} $1"
    echo "[$(date -Iseconds)] WARN: $1" >> "${LOG_FILE}" 2>/dev/null || true
}

check_service() {
    local svc="$1"
    if systemctl is-active --quiet "${svc}" 2>/dev/null; then
        pass "${svc} is running"
    elif systemctl is-enabled --quiet "${svc}" 2>/dev/null; then
        warn "${svc} is enabled but not running"
    else
        # Only fail if it was expected to be running
        warn "${svc} is not configured"
    fi
}

check_service_strict() {
    local svc="$1"
    if systemctl is-active --quiet "${svc}" 2>/dev/null; then
        pass "${svc} is running"
    else
        fail "${svc} is NOT running"
    fi
}

# --- Checks ---
check_filesystem() {
    echo -e "\n  ── Filesystem ──"

    [[ -d /etc/amitos ]] && pass "/etc/amitos exists" || fail "/etc/amitos missing"
    [[ -d /opt/amitos ]] && pass "/opt/amitos exists" || fail "/opt/amitos missing"
    [[ -d /var/log/amitos ]] && pass "/var/log/amitos exists" || fail "/var/log/amitos missing"
}

check_kernel() {
    echo -e "\n  ── Kernel ──"

    local kver
    kver="$(uname -r)"
    pass "Kernel: ${kver}"

    if grep -q "PREEMPT" /proc/version 2>/dev/null; then
        pass "PREEMPT enabled"
    else
        warn "PREEMPT not detected in running kernel"
    fi

    if [[ -f /proc/sys/net/ipv4/ip_forward ]]; then
        local fwd
        fwd="$(cat /proc/sys/net/ipv4/ip_forward)"
        [[ "${fwd}" == "1" ]] && pass "IP forwarding enabled" || warn "IP forwarding disabled"
    fi
}

check_core_services() {
    echo -e "\n  ── Core Services ──"
    check_service_strict "opcua-server"
    check_service "nginx"
    check_service "docker"
}

check_adapters() {
    echo -e "\n  ── Adapters ──"
    for adapter in modbus-adapter mqtt-adapter siemens-s7-adapter bacnet-adapter rest-bridge-adapter; do
        check_service "${adapter}"
    done
}

check_network() {
    echo -e "\n  ── Network ──"

    if ip link show up 2>/dev/null | grep -q "state UP"; then
        pass "Network interface(s) UP"
    else
        fail "No network interfaces UP"
    fi

    if ss -tlnp 2>/dev/null | grep -q ":4840"; then
        pass "OPC UA port 4840 listening"
    else
        warn "OPC UA port 4840 not listening"
    fi

    if ss -tlnp 2>/dev/null | grep -q ":443"; then
        pass "Nginx HTTPS port 443 listening"
    elif ss -tlnp 2>/dev/null | grep -q ":80"; then
        warn "Nginx HTTP port 80 listening (HTTPS not configured)"
    else
        warn "Nginx port not listening"
    fi
}

check_gpu() {
    echo -e "\n  ── GPU / AI ──"

    if command -v nvidia-smi &>/dev/null && nvidia-smi &>/dev/null; then
        pass "NVIDIA GPU detected"
        local gpu_temp
        gpu_temp="$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader 2>/dev/null || echo 'N/A')"
        if [[ "${gpu_temp}" != "N/A" && "${gpu_temp}" -gt 85 ]]; then
            warn "GPU temperature high: ${gpu_temp}°C"
        else
            pass "GPU temperature: ${gpu_temp}°C"
        fi
    else
        warn "No NVIDIA GPU / driver detected (optional)"
    fi

    if python3 -c "import onnxruntime" 2>/dev/null; then
        pass "ONNX Runtime available"
    else
        warn "ONNX Runtime not installed (optional)"
    fi
}

check_disk() {
    echo -e "\n  ── Disk ──"

    local usage
    usage="$(df / 2>/dev/null | awk 'NR==2{print $5}' | tr -d '%')"
    if [[ "${usage}" -gt 90 ]]; then
        fail "Root disk usage critical: ${usage}%"
    elif [[ "${usage}" -gt 80 ]]; then
        warn "Root disk usage high: ${usage}%"
    else
        pass "Root disk usage: ${usage}%"
    fi
}

check_single_service() {
    echo -e "\n  ── Service Check: ${SERVICE_NAME} ──"
    check_service_strict "${SERVICE_NAME}"
}

# --- Main ---
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
echo -e "\033[2m  Health Check\033[0m"

mkdir -p /var/log/amitos 2>/dev/null || true

case "${MODE}" in
    --service)
        check_single_service
        ;;
    --quick)
        check_filesystem
        check_core_services
        ;;
    --full)
        check_filesystem
        check_kernel
        check_core_services
        check_adapters
        check_network
        check_gpu
        check_disk
        ;;
    *)
        echo "Usage: $(basename "$0") [--full | --service NAME | --quick]"
        exit 1
        ;;
esac

echo ""
echo "  ──────────────────────────────────────"
if [[ ${FAILURES} -eq 0 ]]; then
    echo -e "  ${GREEN}All ${CHECKS} checks passed.${NC}"
else
    echo -e "  ${RED}${FAILURES}/${CHECKS} checks failed.${NC}"
fi
echo ""

exit "${FAILURES}"
