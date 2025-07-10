# VNC Cloudflare Tunnel Client

[![Cloudflare](https://img.shields.io/badge/Cloudflare-F38020?style=for-the-badge&logo=Cloudflare&logoColor=white)](https://www.cloudflare.com/)
[![systemd](https://img.shields.io/badge/systemd-0B7A0D?style=for-the-badge&logo=linux&logoColor=white)](https://systemd.io/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![CI/CD](https://github.com/SGT-Cho/cloudflared-vnc-tunnel/workflows/CI/badge.svg)](https://github.com/SGT-Cho/cloudflared-vnc-tunnel/actions)

A lightweight, native Linux service for creating secure VNC connections through Cloudflare Tunnel - no Docker required!

## ✨ Features

- 🔒 **Secure Tunneling** - End-to-end encryption via Cloudflare
- 🚀 **Native Performance** - No container overhead
- 📂 **Profile Management** - Easy multi-server connections
- 🔄 **Auto-restart** - systemd handles connection reliability
- 📊 **Built-in Logging** - Integrated with journald
- 🛠️ **Simple Setup** - One-command installation

## 🚀 Quick Start

```bash
# Clone and install
git clone https://github.com/SGT-Cho/cloudflared-vnc-tunnel.git
cd cloudflared-vnc-tunnel
sudo ./install.sh

# Configure your connection
sudo nano /etc/vnc-tunnel/profiles/default

# Start the service
sudo systemctl start vnc-tunnel@default
sudo systemctl enable vnc-tunnel@default

# Connect with VNC viewer to localhost:5900
```

## 📋 Prerequisites

- Linux system with systemd
- cloudflared installed ([installation guide](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/install-and-setup/installation/))
- Cloudflare Access configured for your VNC server

## 🔧 Installation

### 1. Install cloudflared

```bash
# Debian/Ubuntu
wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
sudo dpkg -i cloudflared-linux-amd64.deb

# RHEL/CentOS/Fedora
wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-x86_64.rpm
sudo rpm -i cloudflared-linux-x86_64.rpm

# Arch Linux
yay -S cloudflared
```

### 2. Install VNC Tunnel

```bash
# Clone the repository
git clone https://github.com/SGT-Cho/cloudflared-vnc-tunnel.git
cd cloudflared-vnc-tunnel

# Run installer
sudo ./install.sh
```

### 3. Configure Profile

Edit `/etc/vnc-tunnel/profiles/default`:

```bash
# Required settings
VNC_HOSTNAME=vnc.yourdomain.com    # Your Cloudflare tunnel hostname
VNC_URL=tcp://localhost:5900       # Local VNC port

# Optional
CLOUDFLARED_OPTIONS="--loglevel info"
```

### 4. First-time Authentication

```bash
# Start the service
sudo systemctl start vnc-tunnel@default

# Check logs for auth URL
sudo journalctl -u vnc-tunnel@default -f

# Copy the authentication URL and open in browser
# Complete Cloudflare Access authentication
```

## 📚 Usage

### Basic Commands

```bash
# Start/stop/restart service
sudo systemctl start vnc-tunnel@default
sudo systemctl stop vnc-tunnel@default
sudo systemctl restart vnc-tunnel@default

# Enable auto-start on boot
sudo systemctl enable vnc-tunnel@default

# Check status
sudo systemctl status vnc-tunnel@default

# View logs
sudo journalctl -u vnc-tunnel@default -f
```

### Multiple Connections

Create additional profiles for different servers:

```bash
# Create new profile
sudo cp /etc/vnc-tunnel/profiles/default /etc/vnc-tunnel/profiles/server2

# Edit the new profile
sudo nano /etc/vnc-tunnel/profiles/server2

# Start multiple connections
sudo systemctl start vnc-tunnel@default
sudo systemctl start vnc-tunnel@server2
```

### Profile Examples

**Production Server** (`/etc/vnc-tunnel/profiles/production`):
```bash
VNC_HOSTNAME=vnc-prod.company.com
VNC_URL=tcp://localhost:5901
CLOUDFLARED_OPTIONS="--loglevel warn"
```

**Development Server** (`/etc/vnc-tunnel/profiles/development`):
```bash
VNC_HOSTNAME=vnc-dev.company.com
VNC_URL=tcp://localhost:5902
CLOUDFLARED_OPTIONS="--loglevel debug"
```

## 🚨 Troubleshooting

### Authentication Issues

```bash
# Check for auth URL in logs
sudo journalctl -u vnc-tunnel@default | grep https://

# If no URL appears, restart the service
sudo systemctl restart vnc-tunnel@default
```

### Connection Problems

```bash
# Test if port is available
sudo lsof -i :5900

# Check service status
sudo systemctl status vnc-tunnel@default

# View detailed logs
sudo journalctl -u vnc-tunnel@default -n 100
```

### Permission Errors

```bash
# Ensure service user exists
id vnc-tunnel

# Check file permissions
ls -la /etc/vnc-tunnel/profiles/
```

## 🏗️ Architecture

```
VNC Viewer → localhost:5900 → cloudflared → Cloudflare Network → VNC Server
```

### File Structure

```
/usr/local/bin/vnc-tunnel           # Main executable
/etc/vnc-tunnel/profiles/           # Connection profiles
/etc/systemd/system/vnc-tunnel@.service  # systemd service
/var/log/vnc-tunnel/                # Log directory
```

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing`)
3. Commit changes (`git commit -m 'Add feature'`)
4. Push to branch (`git push origin feature/amazing`)
5. Open a Pull Request

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [Cloudflare](https://www.cloudflare.com/) for the tunnel service
- systemd for reliable service management
- The open-source community

---

<p align="center">
  Made with ❤️ for simple, secure VNC connections<br>
  ⭐ Star this repo if it helps you!
</p>