#!/bin/bash
# ╔══════════════════════════════════════════════════════════╗
# ║          GIF BACKGROUND - INSTALLER                      ║
# ║        Animated GIF Wallpaper for Linux (X11)            ║
# ╚══════════════════════════════════════════════════════════╝
set -e

# ── Colors ─────────────────────────────────────────────────
R='\033[1;31m'
G='\033[1;32m'
Y='\033[1;33m'
B='\033[1;34m'
M='\033[1;35m'
C='\033[1;36m'
W='\033[1;37m'
NC='\033[0m'
BOLD='\033[1m'
DIM='\033[2m'

# ── Progress bar ───────────────────────────────────────────
progressbar() {
    local current=$1 total=$2 width=30
    local pct=$(( current * 100 / total ))
    local filled=$(( current * width / total ))
    local empty=$(( width - filled ))
    printf "\r  ${C}[${G}"
    printf '█%.0s' $(seq 1 $filled 2>/dev/null) || true
    printf "${DIM}"
    printf '░%.0s' $(seq 1 $empty 2>/dev/null) || true
    printf "${NC}${C}] ${W}%3d%%${NC}" "$pct"
}

spin() {
    local chars='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0
    while kill -0 "$1" 2>/dev/null; do
        printf "\r  ${C}${chars:i++%${#chars}:1}${NC} %s" "$2"
        sleep 0.1
    done
    printf "\r  ${G}✔${NC} %s\n" "$2"
}

# ── Banner ─────────────────────────────────────────────────
clear
echo -e "${M}  ╔═══════════════════════════════════════════╗${NC}"
echo -e "${M}  ║        ${W}★ Stephen's Studio${M} ★               ║${NC}"
echo -e "${M}  ╚═══════════════════════════════════════════╝${NC}"
echo ""
echo -e "${M}"
cat << 'EOF'
   ██████╗██████╗ ████████╗███████╗██████╗ ███╗   ███╗██╗███╗   ██╗██████╗
  ██╔════╝██╔══██╗╚══██╔══╝██╔════╝██╔══██╗████╗ ████║██║████╗  ██║██╔══██╗
  ██║     ██████╔╝   ██║   █████╗  ██████╔╝██╔████╔██║██║██╔██╗ ██║██║  ██║
  ██║     ██╔══██╗   ██║   ██╔══╝  ██╔══██╗██║╚██╔╝██║██║██║╚██╗██║██║  ██║
  ╚██████╗██║  ██║   ██║   ███████╗██║  ██║██║ ╚═╝ ██║██║██║ ╚████║██████╔╝
   ╚═════╝╚═╝  ╚═╝   ╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝╚═╝  ╚═══╝╚═════╝
EOF
echo -e "${NC}"
echo -e "${W}  ── Animated GIF Wallpaper for Linux Desktop ──${NC}"
echo ""

# ── Menu ───────────────────────────────────────────────────
echo -e "${B}[MENU]${NC} Choose an option:"
echo -e "  ${G}1)${NC} Full Install (recommended)"
echo -e "  ${Y}2)${NC} Install System Packages Only"
echo -e "  ${Y}3)${NC} Setup Autostart Only"
echo -e "  ${R}4)${NC} Uninstall"
echo ""
read -p "$(echo -e ${B}'Select [1-4]: '${NC})" CHOICE

case $CHOICE in
    4)
        echo -e "\n${R}╔═══════════════════════════════════════╗${NC}"
        echo -e "${R}║    UNINSTALL GIF BACKGROUND           ║${NC}"
        echo -e "${R}╚═══════════════════════════════════════╝${NC}"
        read -p "$(echo -e ${R}'Stop background & remove autostart? [y/N]: '${NC})" CONFIRM
        if [[ "$CONFIRM" == "y" || "$CONFIRM" == "Y" ]]; then
            bash animebg.sh stop 2>/dev/null || true
            rm -f ~/.config/autostart/anime-bg.desktop 2>/dev/null
            rm -f ~/.local/bin/animebg.sh 2>/dev/null
            echo -e "${G}Background stopped and autostart removed.${NC}"
        fi
        echo -e "${G}Done.${NC}"
        exit 0
        ;;
    2)
        INSTALL_SYSTEM=1; INSTALL_AUTOSTART=0
        ;;
    3)
        INSTALL_SYSTEM=0; INSTALL_AUTOSTART=1
        ;;
    *)
        INSTALL_SYSTEM=1; INSTALL_AUTOSTART=1
        ;;
esac

# ── Helper functions ───────────────────────────────────────
step() { echo -e "\n${G}[$1/$TOTAL]${NC} ${W}$2${NC}"; }
ok()   { echo -e "  ${G}✔${NC} $1"; }
warn() { echo -e "  ${Y}⚠${NC} $1"; }

TOTAL=3
STEP=0

# ── Step 1: System packages ────────────────────────────────
if [[ $INSTALL_SYSTEM -eq 1 ]]; then
    STEP=$((STEP+1))
    step $STEP "Installing system packages..."
    sudo apt-get update -qq 2>/dev/null
    for i in $(seq 1 10); do progressbar $i 10; sleep 0.1; done; echo ""
    sudo apt-get install -y -qq \
        python3 python3-gi gir1.2-gtk-3.0 \
        mpv x11-xserver-utils 2>/dev/null || true
    for i in $(seq 1 10); do progressbar $((10+i)) 20; sleep 0.05; done; echo ""
    ok "System packages installed"

    STEP=$((STEP+1))
    step $STEP "Checking for xwinwrap..."
    for i in $(seq 1 3); do progressbar $i 3; sleep 0.15; done; echo ""
    if command -v xwinwrap &> /dev/null || [ -f "$HOME/.local/bin/xwinwrap" ]; then
        ok "xwinwrap found"
    else
        warn "xwinwrap not found"
        echo -e "  ${DIM}Install from: https://github.com/adi1090x/rofi/releases${NC}"
        echo -e "  ${DIM}Or build from source and place at ~/.local/bin/xwinwrap${NC}"
    fi
fi

# ── Step: Setup paths ──────────────────────────────────────
STEP=$((STEP+1))
step $STEP "Setting up paths..."
mkdir -p ~/.local/bin
chmod +x animebg.sh start-bg.sh gif-control.py 2>/dev/null || true
for i in $(seq 1 3); do progressbar $i 3; sleep 0.1; done; echo ""
ok "Scripts ready"

# ── Step: Autostart ────────────────────────────────────────
if [[ $INSTALL_AUTOSTART -eq 1 ]]; then
    STEP=$((STEP+1))
    step $STEP "Setting up autostart..."
    mkdir -p ~/.config/autostart
    mkdir -p ~/.local/bin
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    cp "$SCRIPT_DIR/animebg.sh" ~/.local/bin/animebg.sh
    chmod +x ~/.local/bin/animebg.sh
    cp "$SCRIPT_DIR/anime-bg.desktop" ~/.config/autostart/anime-bg.desktop
    for i in $(seq 1 5); do progressbar $i 5; sleep 0.1; done; echo ""
    ok "Autostart configured"
fi

# ── Done ───────────────────────────────────────────────────
echo ""
echo -e "${G}╔═══════════════════════════════════════╗${NC}"
echo -e "${G}║       INSTALLATION COMPLETE!          ║${NC}"
echo -e "${G}╚═══════════════════════════════════════╝${NC}"
echo ""
echo -e "  ${W}Start animated background:${NC}"
echo -e "    ${C}bash animebg.sh start${NC}"
echo -e "    ${C}bash animebg.sh start /path/to/file.gif${NC}"
echo ""
echo -e "  ${W}Stop animated background:${NC}"
echo -e "    ${C}bash animebg.sh stop${NC}"
echo ""
echo -e "  ${W}Open control panel:${NC}"
echo -e "    ${C}python3 gif-control.py${NC}"
echo ""
echo -e "  ${W}Autostart:${NC}"
echo -e "    ${DIM}Enabled - starts on next login${NC}"
echo ""
echo -e "  ${M}★ Stephen's Studio ★${NC}"
echo ""
