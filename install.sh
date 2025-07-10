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
log_info() { printf "${GREEN}[INFO]${NC} %s\n" "$1"; }
log_error() { printf "${RED}[ERROR]${NC} %s\n" "$1" >&2; }
log_warn() { printf "${YELLOW}[WARN]${NC} %s\n" "$1"; }

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
if [[ ! -f "bin/vnc-tunnel" ]]; then
    log_error "bin/vnc-tunnel not found. Are you running from the correct directory?"
    exit 1
fi
cp bin/vnc-tunnel "$INSTALL_DIR/" || { log_error "Failed to copy vnc-tunnel"; exit 1; }
chmod +x "$INSTALL_DIR/vnc-tunnel"

log_info "Installing systemd service..."
if [[ ! -f "systemd/vnc-tunnel@.service" ]]; then
    log_error "systemd/vnc-tunnel@.service not found"
    exit 1
fi
cp systemd/vnc-tunnel@.service "$SYSTEMD_DIR/" || { log_error "Failed to copy service file"; exit 1; }

log_info "Installing default profile..."
if [[ ! -f "profiles/default" ]]; then
    log_error "profiles/default not found"
    exit 1
fi
cp profiles/default "$CONFIG_DIR/profiles/" || { log_error "Failed to copy default profile"; exit 1; }
# Copy example profiles if they exist
if compgen -G "profiles/example-*" > /dev/null; then
    cp profiles/example-* "$CONFIG_DIR/profiles/" || log_warn "Failed to copy some example profiles"
fi

# Set permissions
chown -R root:root "$CONFIG_DIR"
chmod 755 "$CONFIG_DIR"
chmod 644 "$CONFIG_DIR/profiles"/*

# Reload systemd
log_info "Reloading systemd..."
systemctl daemon-reload

# Print usage instructions
printf "\n${GREEN}Installation complete!${NC}\n\n"
echo "To get started:"
echo "  1. Edit profile: sudo nano $CONFIG_DIR/profiles/default"
echo "  2. Start service: sudo systemctl start vnc-tunnel@default"
echo "  3. Enable on boot: sudo systemctl enable vnc-tunnel@default"
echo "  4. Check logs: sudo journalctl -u vnc-tunnel@default -f"
echo ""
echo "For multiple connections, create new profiles in $CONFIG_DIR/profiles/"
echo "and start them with: sudo systemctl start vnc-tunnel@<profile-name>"