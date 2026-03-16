#!/usr/bin/env bash
# ============================================================================
# amitOS — Adapter Management Script
# ============================================================================
# Manage amitOS industrial adapters (enable, disable, status, restart, logs).
#
# Usage:
#   amitos-adapter <command> [adapter-name]
#   amitos-adapter list
#   amitos-adapter status modbus
#   amitos-adapter enable mqtt
#   amitos-adapter disable siemens-s7
#   amitos-adapter restart bacnet
#   amitos-adapter logs rest-bridge
#
# Install to: /opt/amitos/scripts/amitos-adapter.sh
# ============================================================================
set -euo pipefail

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# --- Adapter Registry ---
declare -A ADAPTERS=(
    [modbus]="modbus-adapter"
    [mqtt]="mqtt-adapter"
    [siemens-s7]="siemens-s7-adapter"
    [bacnet]="bacnet-adapter"
    [rest-bridge]="rest-bridge-adapter"
)

CONFIG_DIR="/etc/amitos/adapters"

# --- Functions ---
usage() {
    cat <<EOF
${BOLD}amitOS Adapter Manager${NC}

Usage: $(basename "$0") <command> [adapter-name]

Commands:
  list                 List all available adapters and their status
  status <name>        Show detailed status of an adapter
  enable <name>        Enable and start an adapter
  disable <name>       Stop and disable an adapter
  restart <name>       Restart an adapter
  logs <name>          Follow adapter logs (Ctrl+C to stop)
  config <name>        Open adapter configuration in editor

Adapter names: ${!ADAPTERS[*]}

Examples:
  $(basename "$0") list
  $(basename "$0") enable modbus
  $(basename "$0") logs mqtt
EOF
    exit 0
}

resolve_service() {
    local name="$1"
    if [[ -z "${ADAPTERS[${name}]+x}" ]]; then
        echo -e "${RED}Error: Unknown adapter '${name}'${NC}"
        echo "Available adapters: ${!ADAPTERS[*]}"
        exit 1
    fi
    echo "${ADAPTERS[${name}]}"
}

cmd_list() {
    echo -e "\n${BOLD}${CYAN}  amitOS Adapters${NC}\n"
    printf "  ${BOLD}%-16s %-22s %-12s %-8s${NC}\n" "ADAPTER" "SERVICE" "STATUS" "ENABLED"
    echo "  ─────────────────────────────────────────────────────────"

    for name in "${!ADAPTERS[@]}"; do
        local svc="${ADAPTERS[${name}]}"
        local status enabled

        if systemctl is-active --quiet "${svc}" 2>/dev/null; then
            status="${GREEN}● active${NC}"
        else
            status="${RED}○ inactive${NC}"
        fi

        if systemctl is-enabled --quiet "${svc}" 2>/dev/null; then
            enabled="${GREEN}yes${NC}"
        else
            enabled="${YELLOW}no${NC}"
        fi

        printf "  %-16s %-22s $(echo -e "${status}")     $(echo -e "${enabled}")\n" "${name}" "${svc}"
    done

    # Check for config files
    echo ""
    echo -e "  ${BOLD}Configuration:${NC} ${CONFIG_DIR}/"
    echo ""
}

cmd_status() {
    local svc
    svc="$(resolve_service "$1")"
    systemctl status "${svc}" --no-pager
}

cmd_enable() {
    local svc
    svc="$(resolve_service "$1")"
    echo -e "Enabling ${BOLD}${1}${NC} adapter..."
    sudo systemctl enable "${svc}"
    sudo systemctl start "${svc}"
    echo -e "${GREEN}✓ ${1} adapter enabled and started.${NC}"
}

cmd_disable() {
    local svc
    svc="$(resolve_service "$1")"
    echo -e "Disabling ${BOLD}${1}${NC} adapter..."
    sudo systemctl stop "${svc}"
    sudo systemctl disable "${svc}"
    echo -e "${YELLOW}✓ ${1} adapter stopped and disabled.${NC}"
}

cmd_restart() {
    local svc
    svc="$(resolve_service "$1")"
    echo -e "Restarting ${BOLD}${1}${NC} adapter..."
    sudo systemctl restart "${svc}"
    echo -e "${GREEN}✓ ${1} adapter restarted.${NC}"
}

cmd_logs() {
    local svc
    svc="$(resolve_service "$1")"
    echo -e "Following logs for ${BOLD}${1}${NC} (Ctrl+C to stop)..."
    journalctl -u "${svc}" -f --no-pager
}

cmd_config() {
    local config_file="${CONFIG_DIR}/${1}.yaml"
    if [[ ! -f "${config_file}" ]]; then
        echo -e "${RED}Error: Config file not found: ${config_file}${NC}"
        exit 1
    fi
    ${EDITOR:-nano} "${config_file}"
}

# --- Main ---
if [[ $# -eq 0 ]]; then
    usage
fi

COMMAND="$1"
ADAPTER_NAME="${2:-}"

case "${COMMAND}" in
    list)
        cmd_list
        ;;
    status|enable|disable|restart|logs|config)
        if [[ -z "${ADAPTER_NAME}" ]]; then
            echo -e "${RED}Error: Adapter name required.${NC}"
            echo "Usage: $(basename "$0") ${COMMAND} <adapter-name>"
            exit 1
        fi
        "cmd_${COMMAND}" "${ADAPTER_NAME}"
        ;;
    -h|--help|help)
        usage
        ;;
    *)
        echo -e "${RED}Error: Unknown command '${COMMAND}'${NC}"
        usage
        ;;
esac
