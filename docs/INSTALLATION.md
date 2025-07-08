# Installation Guide

This guide will walk you through the complete installation process for VNC Cloudflared Docker Client.

## Table of Contents

- [System Requirements](#system-requirements)
- [Prerequisites Setup](#prerequisites-setup)
- [Installation Steps](#installation-steps)
- [Configuration](#configuration)
- [Verification](#verification)
- [Troubleshooting](#troubleshooting)

## System Requirements

### Minimum Requirements

- **CPU**: 1 core (2+ cores recommended)
- **RAM**: 512MB (1GB+ recommended)
- **Storage**: 500MB free space
- **Network**: Stable internet connection
- **OS**: Linux, macOS, or Windows with WSL2

### Software Requirements

- Docker Engine 20.10 or later
- Docker Compose v2.0 or later
- Bash 4.0+ (for the management script)
- Git (for cloning the repository)

## Prerequisites Setup

### 1. Install Docker

#### Linux (Ubuntu/Debian)
```bash
# Update package index
sudo apt-get update

# Install prerequisites
sudo apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Add Docker's official GPG key
sudo mkdir -m 0755 -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Set up repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add user to docker group
sudo usermod -aG docker $USER
newgrp docker
```

#### macOS
```bash
# Install Docker Desktop from:
# https://www.docker.com/products/docker-desktop/

# Or use Homebrew
brew install --cask docker
```

#### Windows
1. Install [Docker Desktop for Windows](https://www.docker.com/products/docker-desktop/)
2. Enable WSL2 backend
3. Restart your computer

### 2. Verify Docker Installation

```bash
# Check Docker version
docker --version

# Check Docker Compose version
docker compose version

# Verify Docker is running
docker ps
```

## Installation Steps

### 1. Clone the Repository

```bash
# Clone via HTTPS
git clone https://github.com/yourusername/vnc-cloudflared-docker.git

# Or clone via SSH
git clone git@github.com:yourusername/vnc-cloudflared-docker.git

# Enter the directory
cd vnc-cloudflared-docker
```

### 2. Set Up Configuration

```bash
# Copy the example environment file
cp .env.example .env

# Edit the configuration
# Use your preferred editor (nano, vim, code, etc.)
nano .env
```

**Required configuration**:
```bash
# Set your Cloudflare tunnel hostname
VNC_HOSTNAME=vnc.yourdomain.com
```

### 3. Make Script Executable

```bash
# Grant execute permission
chmod +x vnc-client.sh

# Verify permissions
ls -la vnc-client.sh
```

### 4. Build Docker Image

```bash
# Build the cloudflared image
docker compose build

# Or use the script
./vnc-client.sh start
```

## Configuration

### Basic Configuration

Edit `.env` file with your settings:

```bash
# Required: Your Cloudflare tunnel hostname
VNC_HOSTNAME=vnc.example.com

# Optional: Local VNC port (default: 5902)
VNC_LOCAL_PORT=5902

# Optional: Log level (trace, debug, info, warn, error)
TUNNEL_LOGLEVEL=info

# Optional: Timezone
TZ=America/New_York
```

### Advanced Configuration

For advanced users, additional options are available:

```bash
# Resource limits
CONTAINER_CPU_LIMIT=0.5
CONTAINER_MEMORY_LIMIT=256M

# Health check settings
HEALTHCHECK_INTERVAL=30s
HEALTHCHECK_TIMEOUT=10s

# Network configuration
NETWORK_SUBNET=172.20.0.0/16
```

See [Configuration Reference](CONFIGURATION.md) for all available options.

### Multiple Profiles

To run multiple tunnels simultaneously:

```bash
# Create profile-specific configuration
cp .env .env.production
cp .env .env.development

# Edit each file with different settings
# VNC_HOSTNAME=vnc-prod.example.com  # in .env.production
# VNC_HOSTNAME=vnc-dev.example.com   # in .env.development

# Start with specific profile
./vnc-client.sh start production
./vnc-client.sh start development
```

## Verification

### 1. Start the Tunnel

```bash
./vnc-client.sh start
```

Expected output:
```
[2025-01-15 10:30:00] Starting VNC tunnel (profile: default)...
[INFO] Building cloudflared image...
[INFO] Starting services...
[2025-01-15 10:30:03] ✅ VNC tunnel started successfully!
[INFO] Profile: default
[INFO] Local VNC port: 5902
[INFO] Remote hostname: vnc.example.com
```

### 2. Check Status

```bash
./vnc-client.sh status
```

### 3. Test Connection

```bash
./vnc-client.sh test
```

Expected output:
```
[2025-01-15 10:31:00] Testing VNC connection...
[2025-01-15 10:31:01] ✅ Port 5902 is open and listening
[2025-01-15 10:31:02] ✅ VNC protocol is responding correctly
[INFO] Connection test passed! You can connect with your VNC viewer to localhost:5902
```

### 4. Connect with VNC Viewer

1. Open your VNC viewer application
2. Connect to: `localhost:5902`
3. Enter VNC password when prompted

## Troubleshooting

### Common Issues

#### Docker not running
```bash
# Linux
sudo systemctl start docker

# macOS/Windows
# Start Docker Desktop application
```

#### Permission denied
```bash
# Fix script permissions
chmod +x vnc-client.sh

# Fix Docker permissions (Linux)
sudo usermod -aG docker $USER
newgrp docker
```

#### Port already in use
```bash
# Check what's using the port
lsof -i :5902

# Use a different port in .env
VNC_LOCAL_PORT=5903
```

#### Authentication required
- Check logs for authentication URL: `./vnc-client.sh logs`
- Open the URL in your browser
- Complete Cloudflare authentication

### Getting Help

If you encounter issues:

1. Check the [Troubleshooting Guide](TROUBLESHOOTING.md)
2. Search [existing issues](https://github.com/yourusername/vnc-cloudflared-docker/issues)
3. Join our [Discussions](https://github.com/yourusername/vnc-cloudflared-docker/discussions)
4. Create a new issue with:
   - System information
   - Error messages
   - Steps to reproduce

## Next Steps

- Read the [Architecture Overview](ARCHITECTURE.md) to understand how it works
- Check [Security Best Practices](SECURITY.md) for production deployments
- Explore [Configuration Reference](CONFIGURATION.md) for customization
- Set up [multiple profiles](../examples/profiles/) for different servers

Congratulations! You've successfully installed VNC Cloudflared Docker Client. 🎉