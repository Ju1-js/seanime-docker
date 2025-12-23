# syntax=docker/dockerfile:1.4

# Node.js Builder
FROM --platform=$BUILDPLATFORM node:lts-slim AS node-builder
WORKDIR /tmp/build
COPY --link src/seanime-web/package.json src/seanime-web/package-lock.json* ./
RUN --mount=type=cache,target=/root/.npm npm ci
COPY --link src/seanime-web ./
RUN npm run build

# Go Builder
FROM --platform=$BUILDPLATFORM golang:alpine AS go-builder
ARG TARGETOS
ARG TARGETARCH
ARG TARGETVARIANT
WORKDIR /tmp/build
COPY --link src/go.mod src/go.sum ./
RUN --mount=type=cache,target=/go/pkg/mod go mod download
COPY --link src/ .
COPY --from=node-builder --link /tmp/build/out /tmp/build/web
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    set -e && \
    export CGO_ENABLED=0 && \
    export GOOS=$TARGETOS && \
    export GOARCH=$TARGETARCH && \
    if [ "$TARGETARCH" = "arm" ] && [ "$TARGETVARIANT" = "v7" ]; then \
    export GOARM=7; \
    fi && \
    echo "Building for $TARGETOS/$TARGETARCH (variant: $TARGETVARIANT)..." && \
    go build -tags timetzdata -o seanime -trimpath -ldflags="-s -w"

# Base Image
FROM --platform=$TARGETPLATFORM alpine:3.22 AS base
WORKDIR /app
RUN apk add --no-cache ca-certificates
COPY --link assets/Comodo_AAA_Services_root.crt /usr/local/share/ca-certificates/
RUN update-ca-certificates
COPY --from=go-builder --link /tmp/build/seanime /app/
EXPOSE 43211
CMD ["/app/seanime"]

# Slim
FROM base AS slim
RUN apk add --no-cache ffmpeg

# Hwaccel
FROM base AS hwaccel
ARG TARGETARCH

RUN sed -i -e 's/^#\s*\(.*\/\)community/\1community/' /etc/apk/repositories && \
    apk update && \
    PACKAGES="jellyfin-ffmpeg mesa-va-gallium opencl-icd-loader" && \
    if [ "$TARGETARCH" = "amd64" ]; then \
    PACKAGES="$PACKAGES intel-media-driver libva-intel-driver"; \
    fi && \
    apk add --no-cache $PACKAGES && \
    ln -s /usr/bin/jellyfin-ffmpeg /usr/bin/ffmpeg && \
    ln -s /usr/bin/jellyfin-ffprobe /usr/bin/ffprobe