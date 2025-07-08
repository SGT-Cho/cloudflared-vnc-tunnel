# VNC Cloudflared Docker Client - Dockerfile
# Copyright (c) 2025 VNC Cloudflared Docker Contributors
# Licensed under the MIT License
#
# This Dockerfile creates a minimal container for running Cloudflare Tunnel client
# Based on the official Cloudflare image for security and compatibility

# Use official Cloudflare cloudflared image
FROM cloudflare/cloudflared:latest

# Labels for metadata
LABEL maintainer="VNC Cloudflared Docker Contributors"
LABEL description="Cloudflare Tunnel client for secure VNC connections"
LABEL version="1.0.0"
LABEL org.opencontainers.image.source="https://github.com/yourusername/vnc-cloudflared-docker"
LABEL org.opencontainers.image.licenses="MIT"

# Run as non-root user (already configured in base image)
USER nonroot

# Health check to ensure cloudflared is responsive
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD cloudflared version || exit 1

# The entrypoint is inherited from the base image
# Command will be specified in docker-compose.yml for flexibility
ENTRYPOINT ["cloudflared"]

# Default command (can be overridden)
CMD ["--help"]