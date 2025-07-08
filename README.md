# VNC Cloudflared Docker Client

[![Docker](https://img.shields.io/badge/docker-%230db7ed.svg?style=for-the-badge&logo=docker&logoColor=white)](https://www.docker.com/)
[![Cloudflare](https://img.shields.io/badge/Cloudflare-F38020?style=for-the-badge&logo=Cloudflare&logoColor=white)](https://www.cloudflare.com/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)

A secure, dockerized VNC client that connects through Cloudflare Tunnel, providing encrypted remote desktop access without exposing ports.

## ✨ Features

- 🔒 **Secure by Default** - All traffic encrypted through Cloudflare's network
- 🐳 **Fully Containerized** - Easy deployment with Docker Compose
- 🚀 **Multiple Profile Support** - Manage connections to different servers
- 🔄 **Auto-reconnection** - Automatic recovery from connection failures
- 📊 **Health Monitoring** - Built-in health checks and status reporting
- 🎯 **Zero Configuration** - Works out of the box with minimal setup
- 🔍 **Auto-detection** - Automatically detects and displays authentication URLs
- 🧪 **Connection Testing** - Built-in utilities to verify connectivity

## 📋 Prerequisites

- Docker Engine 20.10+ and Docker Compose v2.0+
- A Cloudflare account with an active domain
- A VNC server configured with Cloudflare Tunnel
- Basic understanding of Docker and networking concepts

## 🚀 Quick Start

```bash
# Clone the repository
git clone https://github.com/SGT-Cho/cloudflared-tunnel-vnc-docker-client.git
cd cloudflared-tunnel-vnc-docker-client

# Copy and configure environment variables
cp .env.example .env
# Edit .env with your settings

# Make the script executable
chmod +x vnc-client.sh

# Start the VNC tunnel
./vnc-client.sh start

# Connect using any VNC viewer to localhost:5902
```

## 📖 Documentation

- [Installation Guide](docs/INSTALLATION.md) - Detailed setup instructions
- [Configuration Reference](docs/CONFIGURATION.md) - All available options
- [Architecture Overview](docs/ARCHITECTURE.md) - System design and flow
- [Troubleshooting Guide](docs/TROUBLESHOOTING.md) - Common issues and solutions
- [Security Best Practices](docs/SECURITY.md) - Production deployment guidelines

## 🎮 Usage

### Basic Commands

```bash
# Start the VNC tunnel
./vnc-client.sh start

# Stop the tunnel
./vnc-client.sh stop

# Check status
./vnc-client.sh status

# View logs
./vnc-client.sh logs

# Test connection
./vnc-client.sh test
```

### Advanced Usage

```bash
# Use different profiles for multiple servers
./vnc-client.sh start production
./vnc-client.sh start development

# Update to latest Cloudflared version
./vnc-client.sh update

# Debug mode for troubleshooting
./vnc-client.sh debug

# Complete cleanup
./vnc-client.sh clean
```

## 🔧 Configuration

### Environment Variables

Create a `.env` file with your settings:

```bash
# Required
VNC_HOSTNAME=vnc.example.com      # Your Cloudflare tunnel hostname

# Optional
VNC_LOCAL_PORT=5902               # Local port for VNC connection (default: 5902)
TUNNEL_LOGLEVEL=info              # Log level: trace, debug, info, warn, error
TUNNEL_TRANSPORT_LOGLEVEL=warn    # Transport log level
COMPOSE_PROJECT_NAME=vnc-tunnel   # Docker Compose project name
TZ=UTC                            # Timezone (e.g., America/New_York, Europe/London)
```

### Multiple Profiles

Create profile-specific environment files:

```bash
# .env.production
VNC_HOSTNAME=vnc-prod.example.com
VNC_LOCAL_PORT=5902

# .env.development
VNC_HOSTNAME=vnc-dev.example.com
VNC_LOCAL_PORT=5903
```

## 🏗️ Architecture

```
┌─────────────┐     ┌──────────────┐     ┌─────────────┐     ┌─────────────┐
│ VNC Viewer  │────▶│  localhost   │────▶│ Cloudflared │────▶│ Cloudflare  │
│             │     │    :5902     │     │   Client    │     │   Network   │
└─────────────┘     └──────────────┘     └─────────────┘     └─────────────┘
                                                                      │
                                                                      ▼
                                         ┌─────────────┐     ┌─────────────┐
                                         │ Cloudflared │◀────│ VNC Server  │
                                         │   Server    │     │   :5900     │
                                         └─────────────┘     └─────────────┘
```

## 🛡️ Security

- **End-to-end encryption** via Cloudflare's global network
- **Zero Trust authentication** support
- **No exposed ports** on your server
- **Isolated containers** with resource limits
- **Environment variable** protection

See [Security Best Practices](docs/SECURITY.md) for detailed guidelines.

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [Cloudflare](https://www.cloudflare.com/) for their excellent tunnel service
- [Docker](https://www.docker.com/) for containerization technology
- The open-source community for continuous inspiration

## 💬 Support

- 📧 [Open an issue](https://github.com/SGT-Cho/cloudflared-tunnel-vnc-docker-client/issues) for bug reports
- 💡 [Start a discussion](https://github.com/SGT-Cho/cloudflared-tunnel-vnc-docker-client/discussions) for questions and ideas
- 📖 Check our [FAQ](docs/FAQ.md) for common questions

---

<p align="center">Made with ❤️ by the open-source community</p>