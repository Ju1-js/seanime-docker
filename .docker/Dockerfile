# syntax=docker/dockerfile:1.4

# Stage 1: Node.js Builder
FROM --platform=$BUILDPLATFORM node:latest AS node-builder

# Set build args for cross-platform compatibility
ARG TARGETOS
ARG TARGETARCH

COPY ./seanime-web /tmp/build

WORKDIR /tmp/build

RUN npm ci
RUN npm run build

# Stage 2: Go Builder
FROM --platform=$BUILDPLATFORM golang:latest AS go-builder

ARG TARGETOS
ARG TARGETARCH
ARG TARGETVARIANT

COPY . /tmp/build
COPY --from=node-builder /tmp/build/out /tmp/build/web

WORKDIR /tmp/build

# Handle armv7 (32-bit ARM) builds specifically
RUN if [ "$TARGETARCH" = "arm" ] && [ "$TARGETVARIANT" = "v7" ]; then \
    CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH GOARM=7 go build -o seanime -trimpath -ldflags="-s -w"; \
    else \
    CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH go build -o seanime -trimpath -ldflags="-s -w"; \
    fi

# Stage 3: Final Stage
FROM --platform=$TARGETPLATFORM alpine:latest

# Install necessary packages
RUN apk add --no-cache \
    qbittorrent-nox \
    supervisor \
    ffmpeg

# Copy the Go-built application from the previous stage
COPY --from=go-builder /tmp/build/seanime /app/

# Create directories for qBittorrent and Supervisord
RUN mkdir -p /data /var/log/supervisor

# Work in /app directory
WORKDIR /app

# Add QBittorrent configuration file
#
# The default credentials are:
# Username: admin
# Password: adminadmin
COPY ./.docker/config /config

# Create and use seanime-user
RUN adduser -D seanime-user
RUN chown -R seanime-user:seanime-user /config
RUN chown -R seanime-user:seanime-user /data
RUN chown -R seanime-user:seanime-user /var/log/supervisor

USER seanime-user

# Define volumes for persistent data
VOLUME /data
VOLUME /config

# Expose ports: 43211 for Seanime, 43212 for qBittorrent Web UI
EXPOSE 43211 43212

# Start both services via Supervisord
CMD ["/usr/bin/supervisord", "-c", "/config/Supervisord/supervisord.conf"]
