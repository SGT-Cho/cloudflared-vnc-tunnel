#!/bin/bash
# VNC Tunnel Installation Script

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
INSTALL_DIR="/usr/local/bin"
CONFIG_DIR="/etc/vnc-tunnel"
SYSTEMD_DIR="/etc/systemd/system"
SERVICE_USER="vnc-tunnel"
REPO_URL="https://github.com/SGT-Cho/cloudflared-vnc-tunnel"

# Helper functions
log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   log_error "This script must be run as root"
   exit 1
fi

# Check prerequisites
log_info "Checking prerequisites..."

if ! command -v cloudflared &> /dev/null; then
    log_error "cloudflared is not installed"
    echo "Please install cloudflared first:"
    echo "  wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb"
    echo "  dpkg -i cloudflared-linux-amd64.deb"
    exit 1
fi

if ! command -v systemctl &> /dev/null; then
    log_error "systemd is required but not found"
    exit 1
fi

# Create service user
if ! id "$SERVICE_USER" &>/dev/null; then
    log_info "Creating service user: $SERVICE_USER"
    useradd -r -s /bin/false -d /nonexistent -c "VNC Tunnel Service" "$SERVICE_USER"
fi

# Create directories
log_info "Creating directories..."
mkdir -p "$CONFIG_DIR/profiles"
mkdir -p "/var/log/vnc-tunnel"
chown "$SERVICE_USER:$SERVICE_USER" "/var/log/vnc-tunnel"

# Install files
log_info "Installing VNC tunnel manager..."
cp bin/vnc-tunnel "$INSTALL_DIR/"
chmod +x "$INSTALL_DIR/vnc-tunnel"

log_info "Installing systemd service..."
cp systemd/vnc-tunnel@.service "$SYSTEMD_DIR/"

log_info "Installing default profile..."
cp profiles/default "$CONFIG_DIR/profiles/"
cp profiles/example-* "$CONFIG_DIR/profiles/" 2>/dev/null || true

# Set permissions
chown -R root:root "$CONFIG_DIR"
chmod 755 "$CONFIG_DIR"
chmod 644 "$CONFIG_DIR/profiles"/*

# Reload systemd
log_info "Reloading systemd..."
systemctl daemon-reload

# Print usage instructions
echo -e "\n${GREEN}Installation complete!${NC}\n"
echo "To get started:"
echo "  1. Edit profile: sudo nano $CONFIG_DIR/profiles/default"
echo "  2. Start service: sudo systemctl start vnc-tunnel@default"
echo "  3. Enable on boot: sudo systemctl enable vnc-tunnel@default"
echo "  4. Check logs: sudo journalctl -u vnc-tunnel@default -f"
echo ""
echo "For multiple connections, create new profiles in $CONFIG_DIR/profiles/"
echo "and start them with: sudo systemctl start vnc-tunnel@<profile-name>"