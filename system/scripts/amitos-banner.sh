#!/usr/bin/env bash
# ============================================================================
# amitOS — ASCII Logo / Banner
# ============================================================================
# Source this file to use the banner function:
#   source /opt/amitos/scripts/amitos-banner.sh
#   amitos_banner
#
# Or run directly: bash amitos-banner.sh
# ============================================================================

# Colors
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BLUE='\033[0;34m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

amitos_banner() {
    echo -e "${CYAN}"
    cat << 'LOGO'
        ╭──────────────────────────╮
        │  ██                      │
        │ ████       ╭──────╮     │
        │ ████       │ ╭──╮ │     │
        │  ██        │ ╰──╯ │     │
        │            ╰──────╯     │
        ╰──────────────────────────╯
LOGO
    echo -e "${WHITE}${BOLD}"
    cat << 'TEXT'
       ██████╗ ███╗   ███╗██╗████████╗ ██████╗ ███████╗
      ██╔══██╗████╗ ████║██║╚══██╔══╝██╔═══██╗██╔════╝
      ███████║██╔████╔██║██║   ██║   ██║   ██║███████╗
      ██╔══██║██║╚██╔╝██║██║   ██║   ██║   ██║╚════██║
      ██║  ██║██║ ╚═╝ ██║██║   ██║   ╚██████╔╝███████║
      ╚═╝  ╚═╝╚═╝     ╚═╝╚═╝   ╚═╝    ╚═════╝ ╚══════╝
TEXT
    echo -e "${NC}"
    echo -e "${DIM}  Industrial Automation OS │ Edge AI │ GPU-Powered${NC}"
    echo -e "${DIM}  ─────────────────────────────────────────────────${NC}"
    echo ""
}

amitos_banner_compact() {
    echo -e "${CYAN}${BOLD}"
    cat << 'TEXT'
   ╔══════════════════════════════════════╗
   ║   ◈  amitOS — Industrial Edge AI    ║
   ╚══════════════════════════════════════╝
TEXT
    echo -e "${NC}"
}

amitos_banner_mini() {
    echo -e "${CYAN}◈${NC} ${WHITE}${BOLD}amitOS${NC} ${DIM}v$(cat /etc/amitos/version 2>/dev/null || echo 'dev')${NC}"
}

# If run directly (not sourced), show the full banner
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    amitos_banner
fi
