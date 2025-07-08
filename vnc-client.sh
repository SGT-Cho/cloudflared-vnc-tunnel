#!/usr/bin/env bash
#
# VNC Cloudflared Docker Client
# Copyright (c) 2025 VNC Cloudflared Docker Contributors
# Licensed under the MIT License
#
# Description: Manages VNC connections through Cloudflare Tunnel using Docker
# Repository: https://github.com/yourusername/vnc-cloudflared-docker
#

set -euo pipefail

# Script configuration
readonly SCRIPT_VERSION="1.0.0"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly DEFAULT_PROFILE="default"
readonly DEFAULT_PORT="5902"
readonly DEFAULT_LOG_LEVEL="info"
readonly DEFAULT_TIMEZONE="UTC"

# Change to script directory
cd "$SCRIPT_DIR"

# Profile support - allow multiple concurrent tunnels
PROFILE="${2:-$DEFAULT_PROFILE}"
export COMPOSE_PROJECT_NAME="vnc-tunnel-${PROFILE}"

# Color codes for output formatting
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Logging functions with consistent formatting
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $*"
}

error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

# Check if Docker is installed and running
check_docker() {
    if ! command -v docker &> /dev/null; then
        error "Docker is not installed. Please install Docker first."
        error "Visit: https://docs.docker.com/get-docker/"
        exit 1
    fi
    
    if ! docker info &> /dev/null; then
        error "Docker daemon is not running. Please start Docker."
        case "$(uname -s)" in
            Darwin)
                error "On macOS: Open Docker Desktop application"
                ;;
            Linux)
                error "On Linux: Run 'sudo systemctl start docker'"
                ;;
            *)
                error "Please start the Docker daemon"
                ;;
        esac
        exit 1
    fi
}

# Check Docker Compose availability
check_compose() {
    if ! docker compose version &> /dev/null; then
        if ! docker-compose version &> /dev/null; then
            error "Docker Compose is not installed."
            error "Visit: https://docs.docker.com/compose/install/"
            exit 1
        fi
        COMPOSE_CMD="docker-compose"
    else
        COMPOSE_CMD="docker compose"
    fi
}

# Load environment variables from .env files
load_env() {
    # Load default .env if exists
    if [ -f .env ]; then
        info "Loading environment from .env"
        set -a
        source .env
        set +a
    fi
    
    # Load profile-specific .env if exists
    if [ "$PROFILE" != "$DEFAULT_PROFILE" ] && [ -f ".env.${PROFILE}" ]; then
        info "Loading profile-specific environment from .env.${PROFILE}"
        set -a
        source ".env.${PROFILE}"
        set +a
    fi
}

# Validate required configuration
validate_config() {
    if [ -z "${VNC_HOSTNAME:-}" ]; then
        error "VNC_HOSTNAME is not set. Please configure it in .env file"
        error "Example: VNC_HOSTNAME=vnc.example.com"
        exit 1
    fi
    
    # Validate port number
    local port="${VNC_LOCAL_PORT:-$DEFAULT_PORT}"
    if ! [[ "$port" =~ ^[0-9]+$ ]] || [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
        error "Invalid port number: $port"
        exit 1
    fi
    
    # Check if port is already in use
    if command -v lsof &> /dev/null; then
        if lsof -i ":$port" &> /dev/null; then
            warn "Port $port is already in use. The tunnel may fail to bind."
        fi
    fi
}

# Watch for Cloudflare authentication URL in logs
watch_auth_url() {
    log "Watching for authentication URL..."
    
    # Run in background to not block the script
    {
        local count=0
        local max_attempts=30
        
        while [ $count -lt $max_attempts ]; do
            AUTH_URL=$($COMPOSE_CMD logs vnc-tunnel 2>&1 | grep -oE "https://[^[:space:]]+/cdn-cgi/access/cli[^[:space:]]+" | tail -1)
            if [[ -n "$AUTH_URL" ]]; then
                echo ""
                warn "Authentication required! Please open this URL in your browser:"
                echo -e "${BLUE}$AUTH_URL${NC}"
                echo ""
                break
            fi
            sleep 1
            ((count++))
        done
    } &
}

# Test VNC connection
test_connection() {
    log "Testing VNC connection..."
    
    local port=${VNC_LOCAL_PORT:-$DEFAULT_PORT}
    
    # Check if port is open
    if command -v nc &> /dev/null; then
        if nc -zv localhost "$port" 2>&1 | grep -q succeeded; then
            log "✅ Port $port is open and listening"
            
            # Test VNC protocol handshake
            if echo -n "RFB" | timeout 2 nc localhost "$port" 2>/dev/null | grep -q "RFB"; then
                log "✅ VNC protocol is responding correctly"
                info "Connection test passed! You can connect with your VNC viewer to localhost:$port"
                return 0
            else
                warn "Port is open but VNC protocol is not responding"
                warn "This usually means the tunnel needs authentication"
                return 1
            fi
        else
            error "Connection failed on port $port"
            error "Is the tunnel running? Check with: $0 status"
            return 1
        fi
    else
        warn "netcat (nc) not found. Cannot perform connection test."
        info "You can manually test by connecting your VNC viewer to localhost:$port"
    fi
}

# Check for cloudflared updates
check_updates() {
    log "Checking for cloudflared updates..."
    
    local current_digest=$(docker images --digests cloudflare/cloudflared:latest --format "{{.Digest}}" | head -1)
    
    if docker pull cloudflare/cloudflared:latest 2>&1 | grep -q "Status: Downloaded newer image"; then
        warn "New cloudflared version available!"
        info "Run '$0 update' to update and restart the tunnel"
        return 0
    else
        log "You are running the latest version"
        return 1
    fi
}

# Update cloudflared and restart if necessary
update_tunnel() {
    log "Updating cloudflared..."
    
    docker pull cloudflare/cloudflared:latest
    
    if $COMPOSE_CMD ps 2>/dev/null | grep -q "Up"; then
        warn "Tunnel is running. Restarting with new version..."
        restart_tunnel
    else
        log "Update complete. Run '$0 start' to start the tunnel"
    fi
}

# Start the VNC tunnel
start_tunnel() {
    log "Starting VNC tunnel (profile: $PROFILE)..."
    
    check_docker
    check_compose
    load_env
    validate_config
    
    info "Building cloudflared image..."
    $COMPOSE_CMD build --quiet
    
    info "Starting services..."
    if $COMPOSE_CMD up -d; then
        log "Waiting for tunnel to initialize..."
        sleep 3
        
        info "Checking tunnel status..."
        if $COMPOSE_CMD ps | grep -q "Up"; then
            log "✅ VNC tunnel started successfully!"
            info "Profile: $PROFILE"
            info "Local VNC port: ${VNC_LOCAL_PORT:-$DEFAULT_PORT}"
            info "Remote hostname: ${VNC_HOSTNAME}"
            
            warn "Please complete Cloudflare authentication if this is your first connection"
            
            watch_auth_url
            
            echo ""
            log "Connect with your VNC viewer to: localhost:${VNC_LOCAL_PORT:-$DEFAULT_PORT}"
        else
            error "Failed to start tunnel. Check logs with: $0 logs"
            exit 1
        fi
    else
        error "Failed to start services"
        exit 1
    fi
}

# Stop the VNC tunnel
stop_tunnel() {
    log "Stopping VNC tunnel (profile: $PROFILE)..."
    
    check_compose
    if $COMPOSE_CMD down; then
        log "VNC tunnel stopped successfully"
    else
        error "Failed to stop tunnel"
        exit 1
    fi
}

# Restart the VNC tunnel
restart_tunnel() {
    log "Restarting VNC tunnel (profile: $PROFILE)..."
    stop_tunnel
    sleep 2
    start_tunnel
}

# Show container logs
show_logs() {
    check_compose
    $COMPOSE_CMD logs -f --tail=100
}

# Show tunnel status and resource usage
show_status() {
    check_compose
    
    echo -e "\n${BLUE}=== VNC Tunnel Status (Profile: $PROFILE) ===${NC}"
    $COMPOSE_CMD ps
    
    echo -e "\n${BLUE}=== Container Details ===${NC}"
    local container_name="vnc-tunnel-${PROFILE}_vnc-tunnel_1"
    if docker ps --filter "name=$container_name" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -q vnc; then
        docker ps --filter "name=$container_name" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
        
        echo -e "\n${BLUE}=== Resource Usage ===${NC}"
        docker stats --no-stream --filter "name=$container_name"
        
        echo -e "\n${BLUE}=== Health Status ===${NC}"
        docker inspect "$container_name" --format='{{json .State.Health}}' 2>/dev/null | jq '.' 2>/dev/null || echo "No health check data available"
    else
        warn "No running VNC tunnel containers found for profile: $PROFILE"
    fi
}

# Enter debug mode with diagnostic information
debug_mode() {
    log "Entering debug mode (profile: $PROFILE)..."
    
    check_compose
    
    echo -e "\n${BLUE}=== Environment Information ===${NC}"
    echo "Script Version: $SCRIPT_VERSION"
    echo "Profile: $PROFILE"
    echo "Docker Version: $(docker --version)"
    echo "Compose Version: $($COMPOSE_CMD version)"
    
    echo -e "\n${BLUE}=== Configuration ===${NC}"
    echo "VNC_HOSTNAME: ${VNC_HOSTNAME:-<not set>}"
    echo "VNC_LOCAL_PORT: ${VNC_LOCAL_PORT:-$DEFAULT_PORT}"
    echo "TUNNEL_LOGLEVEL: ${TUNNEL_LOGLEVEL:-$DEFAULT_LOG_LEVEL}"
    
    echo -e "\n${BLUE}=== Container Logs (last 50 lines) ===${NC}"
    $COMPOSE_CMD logs --tail=50
    
    echo -e "\n${BLUE}=== Network Configuration ===${NC}"
    docker network inspect "vnc-tunnel-${PROFILE}_vnc-network" 2>/dev/null || warn "Network not found"
    
    echo -e "\n${BLUE}=== Volume Information ===${NC}"
    docker volume inspect "vnc-tunnel-${PROFILE}_cloudflared-config" 2>/dev/null || warn "Volume not found"
    
    echo -e "\n${BLUE}=== Container Shell ===${NC}"
    local container_name="vnc-tunnel-${PROFILE}_vnc-tunnel_1"
    if docker ps -q -f "name=$container_name" &>/dev/null; then
        info "Entering container shell (type 'exit' to quit)..."
        docker exec -it "$container_name" sh || true
    else
        warn "Container is not running"
    fi
}

# Clean up all resources
clean_all() {
    warn "This will remove all VNC tunnel containers, images, and volumes for profile: $PROFILE"
    read -p "Are you sure? (y/N) " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log "Cleaning up..."
        
        check_compose
        $COMPOSE_CMD down -v --rmi all
        
        # Clean up specific volumes and networks
        docker volume rm "vnc-tunnel-${PROFILE}_cloudflared-config" 2>/dev/null || true
        docker network rm "vnc-tunnel-${PROFILE}_vnc-network" 2>/dev/null || true
        
        log "Cleanup complete"
    else
        info "Cleanup cancelled"
    fi
}

# Display help information
show_help() {
    cat << EOF
${BLUE}VNC Cloudflared Docker Client v${SCRIPT_VERSION}${NC}

${GREEN}Usage:${NC} $0 [command] [profile]

${GREEN}Commands:${NC}
  start     Start the VNC tunnel
  stop      Stop the VNC tunnel
  restart   Restart the VNC tunnel
  status    Show tunnel status and resource usage
  logs      Show container logs (follow mode)
  test      Test VNC connection
  update    Check and apply cloudflared updates
  debug     Enter debug mode with diagnostics
  clean     Remove all containers, images, and volumes
  version   Show version information
  help      Show this help message

${GREEN}Profile Support:${NC}
  Profiles allow running multiple tunnels simultaneously
  Default profile: '${DEFAULT_PROFILE}'
  Profile-specific env files: .env.<profile>

${GREEN}Environment Variables:${NC}
  VNC_HOSTNAME               Remote VNC hostname (required)
  VNC_LOCAL_PORT             Local port for VNC (default: ${DEFAULT_PORT})
  TUNNEL_LOGLEVEL            Cloudflared log level (default: ${DEFAULT_LOG_LEVEL})
  TUNNEL_TRANSPORT_LOGLEVEL  Transport log level (default: warn)
  TZ                         Timezone (default: ${DEFAULT_TIMEZONE})

${GREEN}Examples:${NC}
  $0 start                   # Start tunnel with default profile
  $0 start production        # Start tunnel with production profile
  $0 status development      # Check status of development profile
  $0 logs                    # View logs for default profile
  $0 test                    # Test VNC connection

${GREEN}Quick Setup:${NC}
  1. Copy .env.example to .env
  2. Edit .env with your VNC_HOSTNAME
  3. Run: $0 start
  4. Complete browser authentication if prompted
  5. Connect VNC viewer to localhost:${DEFAULT_PORT}

${GREEN}Documentation:${NC}
  https://github.com/yourusername/vnc-cloudflared-docker

EOF
}

# Show version information
show_version() {
    echo "VNC Cloudflared Docker Client v${SCRIPT_VERSION}"
    echo "Copyright (c) 2025 VNC Cloudflared Docker Contributors"
    echo "Licensed under the MIT License"
}

# Main command handler
case "${1:-help}" in
    start)
        start_tunnel
        ;;
    stop)
        stop_tunnel
        ;;
    restart)
        restart_tunnel
        ;;
    status)
        show_status
        ;;
    logs)
        show_logs
        ;;
    test)
        test_connection
        ;;
    update)
        update_tunnel
        ;;
    debug)
        debug_mode
        ;;
    clean)
        clean_all
        ;;
    version|--version|-v)
        show_version
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