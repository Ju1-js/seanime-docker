# syntax=docker/dockerfile:1.4

# Node.js Builder
FROM --platform=$BUILDPLATFORM node:lts-slim AS node-builder

WORKDIR /tmp/build

# Point to the src folder for package files
COPY --link src/seanime-web/package.json src/seanime-web/package-lock.json* ./

RUN --mount=type=cache,target=/root/.npm \
    npm ci

# Copy the web source from src
COPY --link src/seanime-web ./

RUN npm run build

# Go Builder
FROM --platform=$BUILDPLATFORM golang:alpine AS go-builder

ARG TARGETOS
ARG TARGETARCH
ARG TARGETVARIANT

WORKDIR /tmp/build

# Copy go modules from src
COPY --link src/go.mod src/go.sum ./

RUN --mount=type=cache,target=/go/pkg/mod \
    go mod download

# Copy the rest of the source code from src
COPY --link src/ .

# Copy built frontend assets
COPY --from=node-builder --link /tmp/build/out /tmp/build/web

RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    <<EOT
    set -e
    export CGO_ENABLED=0
    export GOOS=$TARGETOS
    export GOARCH=$TARGETARCH

    if [ "$TARGETARCH" = "arm" ] && [ "$TARGETVARIANT" = "v7" ]; then
        export GOARM=7
    fi

    go build -o seanime -trimpath -ldflags="-s -w"
EOT

# Final Image
FROM --platform=$TARGETPLATFORM alpine:3.22

RUN apk add --no-cache ffmpeg ca-certificates

COPY --link assets/Comodo_AAA_Services_root.crt /usr/local/share/ca-certificates/
RUN update-ca-certificates

COPY --from=go-builder --link /tmp/build/seanime /app/

WORKDIR /app
EXPOSE 43211
CMD ["/app/seanime"]