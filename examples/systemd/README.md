# SystemD Service Configuration

This directory contains example SystemD service files for running VNC Cloudflared Tunnel as a system service.

## Installation

1. **Copy the service file:**
   ```bash
   sudo cp vnc-tunnel.service /etc/systemd/system/
   ```

2. **Create service user (optional but recommended):**
   ```bash
   sudo useradd -r -s /bin/false -d /opt/vnc-cloudflared-docker vnc-operator
   sudo usermod -aG docker vnc-operator
   ```

3. **Set up working directory:**
   ```bash
   sudo mkdir -p /opt/vnc-cloudflared-docker
   sudo cp -r /path/to/vnc-cloudflared-docker/* /opt/vnc-cloudflared-docker/
   sudo chown -R vnc-operator:docker /opt/vnc-cloudflared-docker
   ```

4. **Create environment file (optional):**
   ```bash
   sudo mkdir -p /etc/vnc-tunnel
   sudo tee /etc/vnc-tunnel/environment << EOF
   VNC_HOSTNAME=vnc.example.com
   VNC_LOCAL_PORT=5902
   COMPOSE_PROJECT_NAME=vnc-tunnel-system
   EOF
   sudo chmod 600 /etc/vnc-tunnel/environment
   ```

5. **Enable and start the service:**
   ```bash
   sudo systemctl daemon-reload
   sudo systemctl enable vnc-tunnel.service
   sudo systemctl start vnc-tunnel.service
   ```

## Management Commands

```bash
# Check status
sudo systemctl status vnc-tunnel

# View logs
sudo journalctl -u vnc-tunnel -f

# Restart service
sudo systemctl restart vnc-tunnel

# Stop service
sudo systemctl stop vnc-tunnel

# Disable auto-start
sudo systemctl disable vnc-tunnel
```

## Multiple Instances

To run multiple VNC tunnels as separate services:

1. **Copy service file with different name:**
   ```bash
   sudo cp vnc-tunnel.service /etc/systemd/system/vnc-tunnel-prod.service
   sudo cp vnc-tunnel.service /etc/systemd/system/vnc-tunnel-dev.service
   ```

2. **Modify each service file:**
   ```ini
   # In vnc-tunnel-prod.service
   [Service]
   Environment="COMPOSE_PROJECT_NAME=vnc-tunnel-prod"
   Environment="VNC_LOCAL_PORT=5902"
   ExecStart=/opt/vnc-cloudflared-docker/vnc-client.sh start production
   ExecStop=/opt/vnc-cloudflared-docker/vnc-client.sh stop production
   ```

3. **Enable all services:**
   ```bash
   sudo systemctl enable vnc-tunnel-prod vnc-tunnel-dev
   sudo systemctl start vnc-tunnel-prod vnc-tunnel-dev
   ```

## Security Hardening

For production environments, consider additional hardening:

```ini
[Service]
# Additional security options
ProtectKernelTunables=true
ProtectKernelModules=true
ProtectControlGroups=true
RestrictRealtime=true
RestrictSUIDSGID=true
PrivateDevices=true
LockPersonality=true

# Capability restrictions
CapabilityBoundingSet=CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_BIND_SERVICE

# System call filtering
SystemCallFilter=@system-service
SystemCallErrorNumber=EPERM
```

## Troubleshooting

### Service fails to start
```bash
# Check service logs
sudo journalctl -u vnc-tunnel -n 50

# Verify Docker is running
sudo systemctl status docker

# Check permissions
ls -la /opt/vnc-cloudflared-docker
```

### Permission errors
```bash
# Ensure user is in docker group
sudo usermod -aG docker vnc-operator

# Fix ownership
sudo chown -R vnc-operator:docker /opt/vnc-cloudflared-docker
```

### Environment variables not loaded
```bash
# Verify environment file
sudo cat /etc/vnc-tunnel/environment

# Check file permissions
sudo chmod 600 /etc/vnc-tunnel/environment
```