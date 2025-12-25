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

# Fixes: CVE-2025-5953, CVE-2025-4914
RUN go get github.com/quic-go/quic-go@v0.54.1 && \
    go get github.com/pion/interceptor@v0.1.39 && \
    go mod tidy

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

RUN apk update && \
    apk upgrade --no-cache && \
    apk add --no-cache ca-certificates tzdata && \
    addgroup -S appgroup -g 1000 && \
    adduser -S appuser -G appgroup -u 1000

WORKDIR /app
COPY --link assets/Comodo_AAA_Services_root.crt /usr/local/share/ca-certificates/
RUN update-ca-certificates
COPY --from=go-builder --link --chown=1000:1000 /tmp/build/seanime /app/

EXPOSE 43211

USER 1000
CMD ["/app/seanime"]

FROM base AS slim
USER root
RUN sed -i -e 's/^#\s*\(.*\/\)community/\1community/' /etc/apk/repositories && \
    apk update && \
    apk add --no-cache jellyfin-ffmpeg --repository=https://repo.jellyfin.org/releases/alpine/ && \
    ln -s /usr/bin/jellyfin-ffmpeg /usr/bin/ffmpeg && \
    ln -s /usr/bin/jellyfin-ffprobe /usr/bin/ffprobe

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
    ln -s /usr/bin/jellyfin-ffmpeg /usr/bin/ffmpeg && \
    ln -s /usr/bin/jellyfin-ffprobe /usr/bin/ffprobe

RUN addgroup appuser video || true && \
    addgroup appuser render || true

USER 1000