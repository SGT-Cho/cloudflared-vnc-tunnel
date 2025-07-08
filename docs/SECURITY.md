# Security Best Practices

This document outlines security considerations and best practices for deploying VNC Cloudflared Docker Client in production environments.

## Table of Contents

- [Security Overview](#security-overview)
- [Configuration Security](#configuration-security)
- [Network Security](#network-security)
- [Container Security](#container-security)
- [Authentication & Authorization](#authentication--authorization)
- [Operational Security](#operational-security)
- [Compliance Considerations](#compliance-considerations)
- [Security Checklist](#security-checklist)

## Security Overview

### Threat Model

```
┌─────────────────────────────────────────────────────────┐
│                    Potential Threats                     │
├─────────────────────────────────────────────────────────┤
│ • Unauthorized VNC access                               │
│ • Man-in-the-middle attacks                            │
│ • Container escape attempts                             │
│ • Credential theft                                      │
│ • Resource exhaustion (DoS)                             │
│ • Data exfiltration                                    │
└─────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────┐
│                  Security Controls                       │
├─────────────────────────────────────────────────────────┤
│ • End-to-end encryption (TLS 1.3)                      │
│ • Zero Trust authentication                             │
│ • Container isolation                                   │
│ • Secrets management                                    │
│ • Resource limits                                       │
│ • Audit logging                                         │
└─────────────────────────────────────────────────────────┘
```

## Configuration Security

### Environment Variables

#### DO: Secure Practices
```bash
# Use .env files for local development only
echo ".env" >> .gitignore

# Use Docker secrets for production
docker secret create vnc_hostname vnc_hostname.txt

# Use environment-specific configs
production/
├── .env.production.encrypted
└── decrypt.sh
```

#### DON'T: Common Mistakes
```bash
# Don't commit secrets
git add .env  # WRONG!

# Don't hardcode in scripts
VNC_HOSTNAME="vnc.company.com"  # WRONG!

# Don't log sensitive data
echo "Password: $VNC_PASSWORD"  # WRONG!
```

### Secure Configuration Example

```yaml
# docker-compose.production.yml
version: '3.8'

services:
  vnc-tunnel:
    image: vnc-cloudflared:latest
    secrets:
      - vnc_hostname
      - tunnel_token
    environment:
      VNC_HOSTNAME_FILE: /run/secrets/vnc_hostname
      TUNNEL_TOKEN_FILE: /run/secrets/tunnel_token
    deploy:
      mode: replicated
      replicas: 1
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3

secrets:
  vnc_hostname:
    external: true
  tunnel_token:
    external: true
```

### File Permissions

```bash
# Secure file permissions
chmod 600 .env                  # Owner read/write only
chmod 700 vnc-client.sh         # Owner read/write/execute
chmod 644 docker-compose.yml    # Owner write, others read

# Verify permissions
ls -la
```

## Network Security

### Firewall Configuration

#### iptables (Linux)
```bash
# Allow only localhost connections to VNC port
iptables -A INPUT -p tcp --dport 5902 -s 127.0.0.1 -j ACCEPT
iptables -A INPUT -p tcp --dport 5902 -j DROP

# Allow metrics only from localhost
iptables -A INPUT -p tcp --dport 2000 -s 127.0.0.1 -j ACCEPT
iptables -A INPUT -p tcp --dport 2000 -j DROP

# Save rules
iptables-save > /etc/iptables/rules.v4
```

#### UFW (Ubuntu)
```bash
# Default policies
ufw default deny incoming
ufw default allow outgoing

# Allow SSH (adjust port as needed)
ufw allow 22/tcp

# Block external VNC access
ufw deny 5902/tcp

# Enable firewall
ufw enable
```

### Network Isolation

```yaml
# Create isolated network for VNC
networks:
  vnc-network:
    driver: bridge
    internal: true  # No external access
    ipam:
      config:
        - subnet: 172.30.0.0/24
          ip_range: 172.30.0.0/28  # Limit IP range
```

### TLS Configuration

```bash
# Enforce minimum TLS version
export TUNNEL_TLS_MIN_VERSION=1.3

# Disable weak ciphers
export TUNNEL_TLS_CIPHER_SUITES="TLS_AES_128_GCM_SHA256,TLS_AES_256_GCM_SHA384,TLS_CHACHA20_POLY1305_SHA256"

# Enable certificate pinning (if applicable)
export TUNNEL_CERT_PIN="sha256//YourCertificatePin"
```

## Container Security

### Docker Security Options

```yaml
# docker-compose.yml security configurations
services:
  vnc-tunnel:
    security_opt:
      - no-new-privileges:true      # Prevent privilege escalation
      - apparmor:docker-default     # AppArmor profile
      - seccomp:seccomp-profile.json # Seccomp profile
    
    # Read-only root filesystem
    read_only: true
    
    # Temporary filesystems for writable areas
    tmpfs:
      - /tmp:noexec,nosuid,size=100M
      - /run:noexec,nosuid,size=10M
    
    # Drop all capabilities and add only required
    cap_drop:
      - ALL
    cap_add:
      - NET_BIND_SERVICE  # Only if binding to port < 1024
    
    # Run as non-root user
    user: "1000:1000"
```

### Seccomp Profile Example

```json
{
  "defaultAction": "SCMP_ACT_ERRNO",
  "architectures": ["SCMP_ARCH_X86_64"],
  "syscalls": [
    {
      "names": [
        "accept", "bind", "connect", "getpeername",
        "getsockname", "getsockopt", "listen",
        "read", "write", "close", "openat"
      ],
      "action": "SCMP_ACT_ALLOW"
    }
  ]
}
```

### Image Security

```dockerfile
# Multi-stage build for smaller attack surface
FROM cloudflare/cloudflared:latest as cloudflared
FROM alpine:3.19

# Install security updates
RUN apk update && apk upgrade && rm -rf /var/cache/apk/*

# Copy only necessary files
COPY --from=cloudflared /usr/local/bin/cloudflared /usr/local/bin/

# Create non-root user
RUN adduser -D -u 1000 tunnel

# Switch to non-root user
USER tunnel

# Health check without shell
HEALTHCHECK --interval=30s --timeout=3s \
  CMD ["/usr/local/bin/cloudflared", "version"]
```

## Authentication & Authorization

### Cloudflare Access Configuration

```yaml
# Cloudflare Access policy example
name: "VNC Access Policy"
decision: "allow"
include:
  - email:
      email: "admin@company.com"
  - email_domain:
      domain: "company.com"
  - ip_range:
      ip: "10.0.0.0/8"  # Internal network only
  - geo:
      country: ["US", "CA"]  # Restrict by country
require:
  - mfa:
      provider: "duo"  # Require MFA
session_duration: "8h"
```

### Service Token Authentication

```bash
# Generate service token in Cloudflare dashboard
# Store securely
docker secret create cf_service_token_id token_id.txt
docker secret create cf_service_token_secret token_secret.txt

# Use in production
CF_SERVICE_TOKEN_ID=$(cat /run/secrets/cf_service_token_id)
CF_SERVICE_TOKEN_SECRET=$(cat /run/secrets/cf_service_token_secret)
```

### VNC Authentication

```bash
# Generate strong VNC password
VNC_PASSWORD=$(openssl rand -base64 32)

# Store securely
echo "$VNC_PASSWORD" | docker secret create vnc_password -

# Configure VNC server with encryption
x11vnc -storepasswd "$VNC_PASSWORD" ~/.vnc/passwd
x11vnc -rfbauth ~/.vnc/passwd -ssl -sslonly
```

## Operational Security

### Logging and Monitoring

```yaml
# Enhanced logging configuration
logging:
  driver: "json-file"
  options:
    max-size: "10m"
    max-file: "3"
    labels: "service=vnc-tunnel,environment=production"
    env: "COMPOSE_PROJECT_NAME,VNC_HOSTNAME"
    
# Send to centralized logging
logging:
  driver: "syslog"
  options:
    syslog-address: "tcp+tls://logs.company.com:6514"
    syslog-tls-cert: "/etc/ssl/certs/client-cert.pem"
    syslog-tls-key: "/etc/ssl/private/client-key.pem"
    syslog-tls-skip-verify: "false"
```

### Audit Requirements

```bash
# Enable Docker daemon audit logging
cat > /etc/docker/daemon.json <<EOF
{
  "log-level": "info",
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "live-restore": true,
  "userland-proxy": false,
  "no-new-privileges": true
}
EOF
```

### Incident Response

```bash
# Quick security check script
#!/bin/bash
echo "=== Security Audit ==="

# Check for suspicious processes
docker top vnc-tunnel

# Review recent logs
docker logs --since 1h vnc-tunnel | grep -E "(error|fail|denied)"

# Check network connections
docker exec vnc-tunnel netstat -an

# Verify file integrity
docker exec vnc-tunnel find / -type f -perm /4000 2>/dev/null
```

## Compliance Considerations

### Data Protection

1. **Encryption in Transit**
   - All data encrypted with TLS 1.3
   - Perfect Forward Secrecy enabled
   - Strong cipher suites only

2. **Encryption at Rest**
   - Docker volumes encrypted (platform-dependent)
   - Secrets stored in Docker secrets
   - No sensitive data in images

3. **Data Residency**
   - Cloudflare edge selection honors geography
   - Configure specific regions if required
   - No data stored in Cloudflare (pass-through only)

### Compliance Frameworks

| Framework | Relevant Controls |
|-----------|------------------|
| SOC 2 | Access controls, encryption, monitoring |
| ISO 27001 | Risk assessment, incident response |
| HIPAA | Encryption, audit trails, access controls |
| PCI DSS | Network segmentation, strong crypto |
| GDPR | Data minimization, encryption, audit logs |

### Audit Trail

```yaml
# Enable comprehensive audit logging
services:
  vnc-tunnel:
    labels:
      - "audit.enable=true"
      - "audit.level=verbose"
    environment:
      - TUNNEL_AUDIT_LOG=/var/log/audit/cloudflared.log
      - TUNNEL_AUDIT_EVENTS=all
```

## Security Checklist

### Pre-Deployment

- [ ] Review and update all dependencies
- [ ] Scan images for vulnerabilities
- [ ] Configure firewall rules
- [ ] Set up centralized logging
- [ ] Test authentication flow
- [ ] Review resource limits
- [ ] Enable security options
- [ ] Document security procedures

### Deployment

- [ ] Use secure configuration management
- [ ] Deploy with minimal privileges
- [ ] Enable monitoring and alerting
- [ ] Verify network isolation
- [ ] Test incident response procedures
- [ ] Configure automatic updates
- [ ] Set up backup procedures

### Post-Deployment

- [ ] Regular security assessments
- [ ] Monitor for anomalies
- [ ] Review access logs
- [ ] Update dependencies
- [ ] Rotate credentials
- [ ] Test disaster recovery
- [ ] Security training for operators

### Incident Response Plan

```bash
#!/bin/bash
# incident-response.sh

# 1. Isolate
docker pause vnc-tunnel

# 2. Assess
docker logs --tail 1000 vnc-tunnel > incident-$(date +%s).log

# 3. Contain
docker stop vnc-tunnel
iptables -I INPUT -p tcp --dport 5902 -j DROP

# 4. Investigate
docker exec vnc-tunnel sh -c 'ps aux; netstat -an; find /tmp'

# 5. Remediate
docker rm vnc-tunnel
docker volume rm vnc-tunnel_cloudflared-config

# 6. Recover
./vnc-client.sh start

# 7. Document
echo "Incident handled at $(date)" >> security-log.txt
```

## Additional Resources

- [Cloudflare Zero Trust Documentation](https://developers.cloudflare.com/cloudflare-one/)
- [Docker Security Best Practices](https://docs.docker.com/engine/security/)
- [NIST Cybersecurity Framework](https://www.nist.gov/cyberframework)
- [OWASP Docker Security Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Docker_Security_Cheat_Sheet.html)

Remember: Security is not a one-time configuration but an ongoing process. Regular reviews, updates, and training are essential for maintaining a secure deployment.