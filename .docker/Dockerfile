# syntax=docker/dockerfile:1.4

# Node.js Builder
FROM --platform=$BUILDPLATFORM node:lts-slim AS node-builder

WORKDIR /tmp/build

COPY --link ./seanime-web/package.json ./seanime-web/package-lock.json* ./

RUN --mount=type=cache,target=/root/.npm \
    npm ci

COPY --link ./seanime-web ./

RUN npm run build

# Go Builder
FROM --platform=$BUILDPLATFORM golang:alpine AS go-builder

ARG TARGETOS
ARG TARGETARCH
ARG TARGETVARIANT

WORKDIR /tmp/build

# Copy modules first
COPY --link go.mod go.sum ./

RUN --mount=type=cache,target=/go/pkg/mod \
    go mod download

COPY --link . ./

# Copy build frontend assets
COPY --from=node-builder --link /tmp/build/out /tmp/build/web

RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    <<EOT
    set -e
    export CGO_ENABLED=0
    export GOOS=$TARGETOS
    export GOARCH=$TARGETARCH

    # Handle ARMv7 specific logic
    if [ "$TARGETARCH" = "arm" ] && [ "$TARGETVARIANT" = "v7" ]; then
        export GOARM=7
    fi

    go build -o seanime -trimpath -ldflags="-s -w"
EOT

# Final Image
FROM --platform=$TARGETPLATFORM alpine:3.22

RUN apk add --no-cache ffmpeg ca-certificates

COPY --link Comodo_AAA_Services_root.crt /usr/local/share/ca-certificates/
RUN update-ca-certificates

COPY --from=go-builder --link /tmp/build/seanime /app/

WORKDIR /app
EXPOSE 43211
CMD ["/app/seanime"]