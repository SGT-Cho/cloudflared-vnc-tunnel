# VNC Security Setup Guide

This guide provides practical security recommendations for using VNC with Cloudflare Tunnel.

## VNC Server Security

### 1. Change Default VNC Password

Never use default or weak VNC passwords. Here's how to set a strong password:

#### TightVNC (Windows)
```powershell
# Run TightVNC Server Configuration
# Set both "Primary password" and "View-only password"
# Use at least 12 characters with mixed case, numbers, and symbols
```

#### x11vnc (Linux)
```bash
# Generate password file
x11vnc -storepasswd $(openssl rand -base64 16) ~/.vnc/passwd

# Start VNC with password file
x11vnc -display :0 -rfbauth ~/.vnc/passwd -forever -shared
```

#### macOS Screen Sharing
```bash
# System Preferences > Sharing > Screen Sharing
# Click "Computer Settings..."
# Set "VNC viewers may control screen with password"
# Use a strong, unique password
```

### 2. Enable VNC Encryption

#### Using x11vnc with SSL
```bash
# Generate SSL certificate
openssl req -x509 -nodes -newkey rsa:2048 \
  -keyout vnc-server.key -out vnc-server.crt \
  -days 365 -subj "/CN=vnc-server"

# Start VNC with SSL
x11vnc -ssl vnc-server.crt -sslonly -display :0
```

#### TigerVNC with encryption
```bash
# Configure TigerVNC to require encryption
echo "SecurityTypes=TLSVnc,X509Vnc" >> ~/.vnc/config
```

### 3. Limit VNC Access

#### Bind to localhost only
```bash
# x11vnc
x11vnc -localhost -display :0

# TigerVNC
vncserver -localhost yes

# In docker-compose.yml
ports:
  - "127.0.0.1:5901:5900"  # Only accessible from localhost
```

## Cloudflare Access Security

### 1. Configure Access Policies

```yaml
# Recommended Cloudflare Access policy
name: "Secure VNC Access"
decision: "allow"
include:
  # Require specific email domains
  - email_domain:
      domain: "@yourcompany.com"
  
  # Require multi-factor authentication
  - authentication:
      mfa: required
  
  # Limit by geography
  - geo:
      country: ["US", "CA", "GB"]
  
  # Restrict by IP range (office networks)
  - ip_range:
      ip: "10.0.0.0/8"

exclude:
  # Block specific emails if compromised
  - email:
      email: "compromised@yourcompany.com"

# Session settings
session_duration: "8h"
enable_automatic_reauthentication: false
```

### 2. Service Token Best Practices

```bash
# Never commit service tokens to git
echo "CF_SERVICE_TOKEN_ID=xxx" >> .env
echo "CF_SERVICE_TOKEN_SECRET=yyy" >> .env
echo ".env" >> .gitignore

# Rotate tokens regularly (every 90 days)
# Set calendar reminder for token rotation

# Use different tokens for different environments
# prod.env, dev.env, staging.env
```

### 3. Enable Access Audit Logs

In Cloudflare Dashboard:
1. Go to Zero Trust > Logs > Access
2. Enable "Log all authentication events"
3. Set up alerts for:
   - Failed authentication attempts
   - Access from new locations
   - After-hours access

## Container Security

### 1. Run as Non-Root User

```dockerfile
# In Dockerfile
USER 1000:1000

# Or in docker-compose.yml
services:
  vnc-tunnel:
    user: "1000:1000"
```

### 2. Read-Only Root Filesystem

```yaml
# docker-compose.yml
services:
  vnc-tunnel:
    read_only: true
    tmpfs:
      - /tmp
      - /run
```

### 3. Security Scanning

```bash
# Scan images for vulnerabilities
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy image vnc-cloudflared:latest

# Check for secrets in code
docker run --rm -v $(pwd):/src \
  zricethezav/gitleaks:latest detect --source="/src"
```

## Network Security

### 1. Firewall Rules

```bash
# UFW (Ubuntu)
# Block all VNC ports from external access
sudo ufw deny from any to any port 5900:5999 proto tcp

# Allow only Docker networks
sudo ufw allow from 172.16.0.0/12 to any port 5900:5999 proto tcp

# iptables
iptables -A INPUT -p tcp --dport 5900:5999 -s 0.0.0.0/0 -j DROP
iptables -A INPUT -p tcp --dport 5900:5999 -s 172.17.0.0/16 -j ACCEPT
```

### 2. Network Isolation

```yaml
# docker-compose.yml
networks:
  vnc-network:
    driver: bridge
    internal: true  # No external access
    ipam:
      config:
        - subnet: 172.30.0.0/24
```

## Monitoring and Alerts

### 1. Failed Connection Attempts

```bash
# Monitor logs for failed attempts
#!/bin/bash
# monitor-vnc.sh

LOGFILE="/var/log/vnc-monitor.log"
ALERT_THRESHOLD=5

# Count failed attempts in last hour
FAILED_COUNT=$(docker logs vnc-cloudflared-client --since 1h 2>&1 | \
  grep -c "authentication failed\|connection refused")

if [ $FAILED_COUNT -gt $ALERT_THRESHOLD ]; then
  echo "[ALERT] $FAILED_COUNT failed VNC attempts in last hour" | \
    mail -s "VNC Security Alert" admin@company.com
fi
```

### 2. Unusual Access Patterns

```bash
# Check for access outside business hours
CURRENT_HOUR=$(date +%H)
if [ $CURRENT_HOUR -lt 6 ] || [ $CURRENT_HOUR -gt 22 ]; then
  # Log after-hours access
  echo "[WARNING] After-hours VNC access at $(date)" >> $LOGFILE
fi
```

## Security Checklist

Before deploying to production:

- [ ] Changed all default VNC passwords
- [ ] Enabled VNC encryption (SSL/TLS)
- [ ] Configured Cloudflare Access policies
- [ ] Enabled MFA requirement
- [ ] Set up IP restrictions
- [ ] Configured session timeouts
- [ ] Enabled audit logging
- [ ] Implemented firewall rules
- [ ] Set up monitoring alerts
- [ ] Documented incident response plan
- [ ] Scheduled regular security reviews
- [ ] Planned token rotation schedule

## Incident Response

If you suspect unauthorized access:

1. **Immediate Actions**
   ```bash
   # Stop all VNC tunnels
   ./vnc-client.sh stop
   
   # Revoke Cloudflare tokens
   # Go to Cloudflare Dashboard > Access > Service Tokens
   ```

2. **Investigation**
   ```bash
   # Check access logs
   docker logs vnc-cloudflared-client > incident-$(date +%s).log
   
   # Review Cloudflare Access logs
   # Dashboard > Zero Trust > Logs > Access
   ```

3. **Remediation**
   - Change all VNC passwords
   - Rotate all service tokens
   - Review and update Access policies
   - Document lessons learned

## Additional Resources

- [Cloudflare Zero Trust Security](https://developers.cloudflare.com/cloudflare-one/policies/filtering/)
- [Docker Security Best Practices](https://docs.docker.com/engine/security/)
- [VNC Security Considerations](https://wiki.archlinux.org/title/TigerVNC#Security)
- [NIST Cybersecurity Framework](https://www.nist.gov/cyberframework)