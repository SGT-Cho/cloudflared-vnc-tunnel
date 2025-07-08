#!/usr/bin/env bash
#
# Multi-Tunnel Management Script
# Example of managing multiple VNC tunnels simultaneously
#

set -euo pipefail

# Configuration
declare -A TUNNELS=(
    ["production"]="5902"
    ["development"]="5903"
    ["testing"]="5904"
    ["staging"]="5905"
)

# Colors for output
readonly GREEN='\033[0;32m'
readonly RED='\033[0;31m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m'

# Base directory
readonly BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
readonly SCRIPT="$BASE_DIR/vnc-client.sh"

# Functions
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $*"
}

error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

# Start all tunnels
start_all() {
    log "Starting all VNC tunnels..."
    
    for profile in "${!TUNNELS[@]}"; do
        log "Starting $profile tunnel on port ${TUNNELS[$profile]}..."
        if VNC_LOCAL_PORT="${TUNNELS[$profile]}" "$SCRIPT" start "$profile"; then
            log "✅ $profile tunnel started"
        else
            error "Failed to start $profile tunnel"
        fi
        sleep 2
    done
}

# Stop all tunnels
stop_all() {
    log "Stopping all VNC tunnels..."
    
    for profile in "${!TUNNELS[@]}"; do
        log "Stopping $profile tunnel..."
        if "$SCRIPT" stop "$profile"; then
            log "✅ $profile tunnel stopped"
        else
            warn "Failed to stop $profile tunnel (may not be running)"
        fi
    done
}

# Show status of all tunnels
status_all() {
    echo -e "\n${GREEN}=== VNC Tunnel Status Overview ===${NC}\n"
    
    for profile in "${!TUNNELS[@]}"; do
        echo -e "${YELLOW}Profile: $profile (Port: ${TUNNELS[$profile]})${NC}"
        "$SCRIPT" status "$profile" 2>/dev/null | grep -E "(STATUS|Up|Exited)" || echo "Not running"
        echo ""
    done
}

# Test all connections
test_all() {
    log "Testing all VNC connections..."
    
    for profile in "${!TUNNELS[@]}"; do
        port="${TUNNELS[$profile]}"
        echo -e "\n${YELLOW}Testing $profile on port $port...${NC}"
        
        if nc -zv localhost "$port" 2>&1 | grep -q succeeded; then
            log "✅ $profile tunnel is accessible"
        else
            error "❌ $profile tunnel is not accessible"
        fi
    done
}

# Show logs for specific tunnel
show_logs() {
    local profile="${1:-}"
    
    if [[ -z "$profile" ]]; then
        error "Please specify a profile: production, development, testing, or staging"
        exit 1
    fi
    
    if [[ ! "${TUNNELS[$profile]+isset}" ]]; then
        error "Unknown profile: $profile"
        exit 1
    fi
    
    "$SCRIPT" logs "$profile"
}

# Main menu
show_help() {
    cat << EOF
Multi-Tunnel Management Script

Usage: $0 [command] [profile]

Commands:
  start     Start all VNC tunnels
  stop      Stop all VNC tunnels
  status    Show status of all tunnels
  test      Test all tunnel connections
  logs      Show logs for specific tunnel
  help      Show this help message

Profiles:
EOF
    for profile in "${!TUNNELS[@]}"; do
        echo "  - $profile (port ${TUNNELS[$profile]})"
    done
    
    cat << EOF

Examples:
  $0 start              # Start all tunnels
  $0 stop               # Stop all tunnels
  $0 status             # Check all tunnel status
  $0 logs production    # View production tunnel logs

EOF
}

# Command handler
case "${1:-help}" in
    start)
        start_all
        ;;
    stop)
        stop_all
        ;;
    status)
        status_all
        ;;
    test)
        test_all
        ;;
    logs)
        show_logs "${2:-}"
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        error "Unknown command: $1"
        show_help
        exit 1
        ;;
esac