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
    export CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH && \
    if [ "$TARGETARCH" = "arm" ] && [ "$TARGETVARIANT" = "v7" ]; then export GOARM=7; fi && \
    go build -tags timetzdata -o seanime -trimpath -ldflags="-s -w"

FROM --platform=$TARGETPLATFORM alpine:3.23.2 AS base

RUN apk update && \
    apk upgrade --no-cache && \
    apk add --no-cache ca-certificates tzdata && \
    addgroup -S seanime -g 1000 && \
    adduser -S seanime -G seanime -u 1000

WORKDIR /app
COPY --from=go-builder --link --chown=1000:1000 /tmp/build/seanime /app/

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://127.0.0.1:43211 || \
    wget --no-verbose --tries=1 --spider --no-check-certificate https://127.0.0.1:43211 || \
    exit 1

EXPOSE 43211

USER 1000
CMD ["/app/seanime"]

FROM base AS slim
USER root
RUN sed -i -e 's/^#\s*\(.*\/\)community/\1community/' /etc/apk/repositories && \
    apk update && \
    apk add --no-cache jellyfin-ffmpeg --repository=https://repo.jellyfin.org/releases/alpine/ && \
    ln -s /usr/lib/jellyfin-ffmpeg/ffmpeg /usr/bin/ffmpeg && \
    ln -s /usr/lib/jellyfin-ffmpeg/ffprobe /usr/bin/ffprobe

USER 1000

FROM base AS hwaccel
ARG TARGETARCH

USER root
RUN sed -i -e 's/^#\s*\(.*\/\)community/\1community/' /etc/apk/repositories && \
    apk update && \
    apk upgrade --no-cache && \
    PACKAGES="jellyfin-ffmpeg mesa-va-gallium opencl-icd-loader" && \
    if [ "$TARGETARCH" = "amd64" ]; then \
    PACKAGES="$PACKAGES intel-media-driver libva-intel-driver"; \
    fi && \
    apk add --no-cache $PACKAGES && \
    ln -s /usr/lib/jellyfin-ffmpeg/ffmpeg /usr/bin/ffmpeg && \
    ln -s /usr/lib/jellyfin-ffmpeg/ffprobe /usr/bin/ffprobe

RUN addgroup seanime video || true && \
    addgroup seanime render || true

USER 1000

FROM nvidia/cuda:13.1.0-runtime-ubuntu24.04 AS cuda

RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates wget gnupg && \
    mkdir -p /etc/apt/keyrings && \
    wget -qO - https://repo.jellyfin.org/jellyfin_team.gpg.key | gpg --dearmor -o /etc/apt/keyrings/jellyfin.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/jellyfin.gpg] https://repo.jellyfin.org/ubuntu noble main" > /etc/apt/sources.list.d/jellyfin.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends jellyfin-ffmpeg7 && \
    ln -s /usr/lib/jellyfin-ffmpeg/ffmpeg /usr/bin/ffmpeg && \
    ln -s /usr/lib/jellyfin-ffmpeg/ffprobe /usr/bin/ffprobe && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN userdel -r ubuntu 2>/dev/null || true && \
    groupdel ubuntu 2>/dev/null || true && \
    groupadd -g 1000 seanime && \
    useradd -u 1000 -g seanime -d /app -s /bin/false seanime

WORKDIR /app
COPY --from=go-builder --link --chown=1000:1000 /tmp/build/seanime /app/

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://127.0.0.1:43211 || \
    wget --no-verbose --tries=1 --spider --no-check-certificate https://127.0.0.1:43211 || \
    exit 1

EXPOSE 43211
USER 1000
CMD ["/app/seanime"]