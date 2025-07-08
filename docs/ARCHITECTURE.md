# Architecture Overview

This document provides a detailed overview of the VNC Cloudflared Docker Client architecture, explaining how components interact and data flows through the system.

## Table of Contents

- [System Architecture](#system-architecture)
- [Component Overview](#component-overview)
- [Data Flow](#data-flow)
- [Security Model](#security-model)
- [Network Architecture](#network-architecture)
- [Container Architecture](#container-architecture)
- [Authentication Flow](#authentication-flow)

## System Architecture

### High-Level Architecture

```
┌──────────────────────────────────────────────────────────────────────────┐
│                            Client Machine                                 │
│                                                                          │
│  ┌─────────────┐     ┌──────────────┐     ┌─────────────────────────┐  │
│  │ VNC Viewer  │────▶│  localhost   │────▶│  Cloudflared Container  │  │
│  │ Application │     │    :5902     │     │  (Docker)               │  │
│  └─────────────┘     └──────────────┘     └───────────┬─────────────┘  │
│                                                        │                 │
└────────────────────────────────────────────────────────┼─────────────────┘
                                                         │
                                    Internet             │ Encrypted
                                        │                │ TCP Tunnel
                                        ▼                │
                              ┌─────────────────┐        │
                              │   Cloudflare    │◀───────┘
                              │  Global Network │
                              └────────┬────────┘
                                       │
                                       │ Encrypted
                                       │ Outbound Only
                                       ▼
                          ┌────────────────────────────┐
                          │     VNC Server Machine     │
                          │                            │
                          │  ┌──────────────────────┐  │
                          │  │ Cloudflared Server   │  │
                          │  └──────────┬───────────┘  │
                          │             │              │
                          │             ▼              │
                          │  ┌──────────────────────┐  │
                          │  │    VNC Server        │  │
                          │  │    (Port 5900)       │  │
                          │  └──────────────────────┘  │
                          └────────────────────────────┘
```

## Component Overview

### 1. VNC Viewer Application
- **Purpose**: User interface for remote desktop access
- **Protocols**: RFB (Remote Framebuffer) protocol
- **Connection**: Connects to localhost:5902 (configurable)
- **Examples**: RealVNC, TightVNC, TigerVNC, macOS Screen Sharing

### 2. Cloudflared Client Container
- **Base Image**: Official cloudflare/cloudflared:latest
- **Purpose**: Establishes secure tunnel to Cloudflare
- **Features**:
  - Non-root user execution
  - Health monitoring
  - Automatic reconnection
  - Metrics collection
- **Configuration**: Environment variables and command-line arguments

### 3. Management Script (vnc-client.sh)
- **Purpose**: Orchestrates Docker containers and provides user interface
- **Features**:
  - Container lifecycle management
  - Configuration validation
  - Log aggregation
  - Connection testing
  - Profile support

### 4. Docker Compose Configuration
- **Purpose**: Defines container services and networking
- **Components**:
  - Service definitions
  - Network configuration
  - Volume management
  - Resource constraints
  - Health checks

## Data Flow

### Connection Establishment

```
1. User starts tunnel:        ./vnc-client.sh start
                                    │
                                    ▼
2. Docker Compose:           Creates container
                                    │
                                    ▼
3. Cloudflared client:       Connects to Cloudflare
                                    │
                                    ▼
4. Authentication:           Browser-based auth (first time)
                                    │
                                    ▼
5. Tunnel established:       TCP tunnel ready
                                    │
                                    ▼
6. VNC connection:          VNC Viewer → localhost:5902
                                    │
                                    ▼
7. Traffic routing:         Container → Cloudflare → Server
```

### Data Packet Journey

1. **VNC Viewer** generates RFB protocol packets
2. **TCP Socket** on localhost:5902 receives packets
3. **Docker NAT** forwards to container port 5901
4. **Cloudflared client** encapsulates in HTTPS
5. **Cloudflare Network** routes to destination
6. **Cloudflared server** decapsulates packets
7. **VNC Server** processes RFB commands
8. **Response** travels back through same path

## Security Model

### Defense in Depth

```
┌─────────────────────────────────────────┐
│          Application Layer              │
│  • VNC password authentication          │
│  • Optional VNC encryption              │
├─────────────────────────────────────────┤
│          Transport Layer                │
│  • TLS 1.3 encryption                   │
│  • Certificate validation               │
│  • Zero Trust authentication            │
├─────────────────────────────────────────┤
│          Network Layer                  │
│  • No exposed ports on server           │
│  • Outbound-only connections            │
│  • Cloudflare DDoS protection          │
├─────────────────────────────────────────┤
│          Container Layer                │
│  • Non-root user execution              │
│  • Read-only filesystem                 │
│  • Resource limitations                 │
│  • Isolated network namespace           │
└─────────────────────────────────────────┘
```

### Security Features

1. **End-to-End Encryption**
   - TLS 1.3 between client and Cloudflare
   - TLS 1.3 between Cloudflare and server
   - Optional VNC-level encryption

2. **Authentication**
   - Cloudflare Access (Zero Trust)
   - Email/SSO authentication
   - Service tokens for automation
   - VNC password as final layer

3. **Network Security**
   - No inbound ports on server
   - All traffic through Cloudflare
   - DDoS protection included
   - IP allowlisting available

4. **Container Security**
   - Minimal attack surface
   - No elevated privileges
   - Resource constraints
   - Regular updates

## Network Architecture

### Docker Network

```yaml
networks:
  vnc-network:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16
```

### Port Mappings

| Component | Internal Port | External Port | Purpose |
|-----------|--------------|---------------|---------|
| Container | 5901 | 5902 | VNC traffic |
| Container | 2000 | 2000 | Metrics (localhost only) |
| VNC Server | 5900 | N/A | Server-side VNC |

### Network Isolation

```
┌─────────────────────────────────────┐
│         Host Network                │
│                                     │
│  ┌─────────────────────────────┐   │
│  │   Docker Bridge Network      │   │
│  │   (vnc-tunnel_network)       │   │
│  │                              │   │
│  │  ┌───────────────────────┐  │   │
│  │  │ cloudflared container │  │   │
│  │  │ IP: 172.20.0.2        │  │   │
│  │  └───────────────────────┘  │   │
│  │                              │   │
│  └─────────────────────────────┘   │
│                                     │
└─────────────────────────────────────┘
```

## Container Architecture

### Container Layers

```
┌─────────────────────────────────────┐
│        User Application             │
│         (cloudflared)               │
├─────────────────────────────────────┤
│        Runtime Layer                │
│    • Non-root user (nonroot)        │
│    • Minimal permissions            │
├─────────────────────────────────────┤
│        Base Image Layer             │
│    • Alpine Linux (minimal)         │
│    • Security updates               │
└─────────────────────────────────────┘
```

### Volume Mounts

| Mount Point | Purpose | Persistence |
|-------------|---------|-------------|
| `/home/nonroot/.cloudflared` | Authentication data | Persistent |
| `/etc/localtime` | Time synchronization | Read-only |
| `/tmp` | Temporary files | tmpfs |
| `/run` | Runtime files | tmpfs |

### Resource Management

```yaml
deploy:
  resources:
    limits:
      cpus: '0.5'      # 50% of one CPU
      memory: 256M     # 256 MB RAM
    reservations:
      cpus: '0.1'      # 10% CPU guaranteed
      memory: 128M     # 128 MB RAM guaranteed
```

## Authentication Flow

### Initial Authentication

```
1. Container starts
       │
       ▼
2. Cloudflared attempts connection
       │
       ▼
3. No valid credentials found
       │
       ▼
4. Generates authentication URL
       │
       ▼
5. User opens URL in browser
       │
       ▼
6. Cloudflare Access authentication
       │
       ▼
7. Token saved to volume
       │
       ▼
8. Tunnel established
```

### Subsequent Connections

```
1. Container starts
       │
       ▼
2. Reads saved credentials
       │
       ▼
3. Validates with Cloudflare
       │
       ▼
4. Tunnel established
```

### Token Lifecycle

- **Storage**: Docker volume (encrypted at rest)
- **Expiration**: Configurable in Cloudflare Access
- **Rotation**: Automatic before expiration
- **Revocation**: Via Cloudflare dashboard

## Performance Considerations

### Latency Components

1. **Local**: VNC Viewer ↔ Container (~1ms)
2. **Container**: Processing overhead (~1-2ms)
3. **Network**: Container ↔ Cloudflare (varies)
4. **Cloudflare**: Edge routing (~5-10ms)
5. **Server**: Cloudflare ↔ VNC Server (varies)

### Optimization Strategies

1. **Edge Selection**: Cloudflare automatically routes to nearest edge
2. **Connection Pooling**: Reuses HTTPS connections
3. **Compression**: VNC protocol compression supported
4. **Caching**: DNS responses cached locally
5. **Resource Limits**: Prevents container resource exhaustion

## Monitoring and Observability

### Metrics Endpoint

```
http://localhost:2000/metrics

# Example metrics:
cloudflared_tunnel_connections_total
cloudflared_tunnel_bytes_sent
cloudflared_tunnel_bytes_received
cloudflared_tunnel_response_time_seconds
```

### Log Aggregation

```
Container Logs → Docker → Management Script → User
                    ↓
              JSON Format → Log Analysis Tools
```

### Health Monitoring

```yaml
healthcheck:
  test: ["CMD", "cloudflared", "version"]
  interval: 30s
  timeout: 10s
  retries: 3
```

## Scalability Patterns

### Multiple Tunnels

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  Profile:   │     │  Profile:   │     │  Profile:   │
│ Production  │     │ Development │     │   Testing   │
│ Port: 5902  │     │ Port: 5903  │     │ Port: 5904  │
└─────────────┘     └─────────────┘     └─────────────┘
       │                   │                   │
       └───────────────────┴───────────────────┘
                           │
                    Cloudflare Network
```

### Load Distribution

- Each tunnel maintains independent connection
- Cloudflare handles global load balancing
- No single point of failure
- Automatic failover between edges

## Conclusion

The VNC Cloudflared Docker Client architecture provides:

- **Security**: Multiple layers of protection
- **Simplicity**: Easy deployment and management
- **Flexibility**: Configurable for various use cases
- **Reliability**: Automatic recovery and health monitoring
- **Performance**: Optimized routing through Cloudflare's network

This architecture ensures secure, reliable remote access while maintaining ease of use and deployment flexibility.