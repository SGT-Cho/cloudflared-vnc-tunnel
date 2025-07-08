# Troubleshooting Guide

## 🔍 Common Issues and Solutions

### 1. Authentication URL Not Appearing

**Symptoms:**
- No authentication URL shown after running `start`
- Tunnel seems stuck at initialization

**Solutions:**
```bash
# Check logs for the URL
./vnc-client.sh logs | grep "https://"

# Restart the tunnel
./vnc-client.sh restart

# Check if container is running
docker ps | grep vnc-cloudflared
```

### 2. Connection Refused on localhost:5902

**Symptoms:**
- VNC Viewer shows "Connection refused"
- Cannot connect to local port

**Solutions:**
```bash
# Test the connection
./vnc-client.sh test

# Check port binding
netstat -tlnp | grep 5902

# Verify container ports
docker port vnc-cloudflared-client
```

### 3. VNC Protocol Not Responding

**Symptoms:**
- Port is open but VNC handshake fails
- `test` command shows port open but protocol not responding

**Solutions:**
```bash
# Check authentication status
./vnc-client.sh logs | grep -i "auth"

# Verify tunnel configuration
docker exec vnc-cloudflared-client cloudflared tunnel info

# Test DNS resolution
nslookup vnc.yourdomain.com
```

### 4. Docker Permission Errors

**Symptoms:**
- "permission denied while trying to connect to the Docker daemon"

**Solutions:**
```bash
# Add user to docker group
sudo usermod -aG docker $USER

# Log out and back in, or run
newgrp docker

# Test Docker access
docker ps
```

### 5. Cloudflare Authentication Loop

**Symptoms:**
- Authentication keeps asking for login
- Browser redirects endlessly

**Solutions:**
- Clear browser cookies for `*.cloudflareaccess.com`
- Try incognito/private browsing mode
- Check Cloudflare Access policies in dashboard

## 🛠️ Debug Commands

### Basic Debugging
```bash
# Enter interactive debug mode
./vnc-client.sh debug

# View all container logs
docker logs vnc-cloudflared-client --tail 100

# Check container health
docker inspect vnc-cloudflared-client --format='{{.State.Health}}'
```

### Network Debugging
```bash
# Test Cloudflare connectivity
docker exec vnc-cloudflared-client ping -c 4 cloudflare.com

# Check DNS resolution
docker exec vnc-cloudflared-client nslookup vnc.yourdomain.com

# Verify tunnel connectivity
docker exec vnc-cloudflared-client cloudflared tunnel info
```

### Advanced Debugging
```bash
# Watch logs in real-time with filters
./vnc-client.sh logs | grep -E "(ERROR|WARN|auth)"

# Check resource usage
docker stats vnc-cloudflared-client

# Inspect network configuration
docker network inspect vnc-cloudflared-network
```

## 📊 Performance Issues

### High CPU Usage
```bash
# Check resource limits
docker inspect vnc-cloudflared-client | grep -A 5 "CpuShares"

# Monitor in real-time
docker stats --no-stream vnc-cloudflared-client
```

### Memory Leaks
```bash
# Set memory limits in docker-compose.yml
deploy:
  resources:
    limits:
      memory: 256M
```

## 🔐 Security Troubleshooting

### Certificate Errors
- Ensure system time is correct
- Update cloudflared image: `./vnc-client.sh update`
- Check Cloudflare SSL settings

### Access Denied
- Verify Cloudflare Access policies
- Check service token expiration
- Ensure email is authorized in Access policy

## 📝 Log Locations

- **Container logs**: `docker logs vnc-cloudflared-client`
- **Cloudflared logs**: Inside container at `/home/nonroot/.cloudflared/`
- **Docker daemon logs**: `/var/log/docker.log` (varies by OS)

## 🆘 Getting Help

If you're still experiencing issues:

1. Collect debug information:
   ```bash
   ./vnc-client.sh debug > debug-output.txt 2>&1
   docker version >> debug-output.txt
   docker compose version >> debug-output.txt
   ```

2. Check existing issues: [GitHub Issues](https://github.com/yourusername/vnc-cloudflared-docker/issues)

3. Create a new issue with:
   - Problem description
   - Steps to reproduce
   - Debug output
   - Environment details (OS, Docker version)

## 🔄 Common Fixes

### Quick Reset
```bash
# Stop everything
./vnc-client.sh stop

# Clean volumes (warning: removes authentication)
docker volume rm vnc-docker-client_cloudflared-config

# Restart fresh
./vnc-client.sh start
```

### Full Reset
```bash
# Complete cleanup
./vnc-client.sh clean

# Rebuild and start
./vnc-client.sh start
```