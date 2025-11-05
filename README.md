# Seanime Docker

[![Docker Pulls](https://img.shields.io/docker/pulls/ju1js/seanime.svg)](https://hub.docker.com/r/ju1js/seanime)

A simple, multi-arch Docker image for [Seanime](https://seanime.rahim.app/), a self-hosted anime streaming platform. Video transcoding via [FFmpeg](https://ffmpeg.org/) is included and works out of the box.

## Notes:

- `Release` is effectively identical to umagistr's image, `Dev` targets the TLS PR.
- `arm/v7` support disabled since version 3.0.0 till 5rahim finds workaround (from umag's repo)

## Table of Contents

- [Platform Support](#platform-support)
- [Usage](#usage)
  - [Docker CLI](#docker-cli)
  - [Docker Compose (Basic)](#docker-compose-basic)
  - [Docker Compose (Advanced with VPN)](#docker-compose-advanced-with-vpn)
- [Configuration](#configuration)
  - [Ports](#ports)
  - [Volumes](#volumes)
  - [Environment Variables](#environment-variables)
- [Contributing](#contributing)
- [License](#license)

## Platform Support

This Docker image is built with multi-architecture support and should be compatible with the following platforms:

- **`linux/amd64`** - For standard x86-64 PCs and servers.
- **`linux/arm64`** - For 64-bit ARM devices like the Raspberry Pi 4 and 5.
- **New versions disabled:** **`linux/arm/v7`** - For older 32-bit ARM devices.

**Note:** While the image is built for all the above platforms, it is primarily tested and used on a Raspberry Pi 5 (`linux/arm64`). Feedback and issue reports for all platforms are highly encouraged and appreciated!

## Usage

You can run the Seanime Docker image using either the Docker command-line interface (CLI) or Docker Compose.

### Docker CLI

To quickly get started, you can use the following Docker command to run the Seanime container:

```bash
docker run -d \
  -p 43211:43211 \
  -v ./seanime-config:/root/.config/Seanime \
  --restart=unless-stopped \
  --name seanime \
  ju1js/seanime
```

### Docker Compose (Basic)

For a simple setup using Docker Compose, create a `docker-compose.yml` file with the following content:

```yaml
services:
  seanime:
    image: ju1js/seanime
    container_name: seanime
    ports:
      - "43211:43211"
    volumes:
      - ./seanime-config:/root/.config/Seanime
      - ./seanime-data:/data # Optional: Mount a directory for your media
    restart: unless-stopped
```

### Docker Compose (Advanced with VPN)

This example demonstrates routing the container's traffic through a WireGuard VPN using [Gluetun](https://github.com/qdm12/gluetun) and includes a Transmission torrent client.

First, create an `.env` file in the same directory as your `docker-compose.yml` to define your environment variables:

```env
# General Settings
PUID=1000
PGID=1000
TZ=Etc/UTC

# Seanime
SEANIME_UI_PORT=43211

# Transmission
TRANSMISSION_WEB_PORT=9091
TRANSMISSION_PEER_PORT=51413
TRANSMISSION_USER=user
TRANSMISSION_PASS=password

# Gluetun - See https://github.com/qdm12/gluetun-wiki/tree/main/setup
VPN_SERVICE_PROVIDER=
VPN_TYPE=
WIREGUARD_PRIVATE_KEY=
WIREGUARD_ADDRESSES=
OPENVPN_USER=
OPENVPN_PASSWORD=
SERVER_COUNTRIES=
SERVER_CITIES=
```

Next, create the `docker-compose.yml` file:

```yaml
services:
  gluetun:
    image: qmcgaw/gluetun:latest
    container_name: gluetun
    cap_add:
      - NET_ADMIN
    devices:
      - /dev/net/tun:/dev/net/tun
    environment:
      # See https://github.com/qdm12/gluetun-wiki for provider-specific variables
      - VPN_SERVICE_PROVIDER=${VPN_SERVICE_PROVIDER}
      - VPN_TYPE=${VPN_TYPE}
      - WIREGUARD_PRIVATE_KEY=${WIREGUARD_PRIVATE_KEY}
      - WIREGUARD_ADDRESSES=${WIREGUARD_ADDRESSES}
      - SERVER_COUNTRIES=${SERVER_COUNTRIES}
      - SERVER_CITIES=${SERVER_CITIES}
      - FIREWALL_INPUT_PORTS=${SEANIME_UI_PORT},${TRANSMISSION_WEB_PORT}
      - TZ=${TZ}
    ports:
      - "${SEANIME_UI_PORT}:${SEANIME_UI_PORT}" # Seanime WebUI
      - "${TRANSMISSION_WEB_PORT}:9091" # Transmission WebUI
      - "${TRANSMISSION_PEER_PORT}:${TRANSMISSION_PEER_PORT}" # Transmission Peer Port
      - "${TRANSMISSION_PEER_PORT}:${TRANSMISSION_PEER_PORT}/udp" # Transmission Peer Port
    restart: unless-stopped

  seanime:
    image: ju1js/seanime
    container_name: seanime
    network_mode: "service:gluetun"
    environment:
      - SEANIME_SERVER_HOST=0.0.0.0
      - SEANIME_SERVER_PORT=${SEANIME_UI_PORT}
    volumes:
      - ./config/seanime:/root/.config/Seanime
      - ./data:/data # Media directory
    depends_on:
      - gluetun
    restart: unless-stopped

  transmission:
    image: lscr.io/linuxserver/transmission:latest
    container_name: transmission
    network_mode: "service:gluetun"
    environment:
      - PUID=${PUID}
      - PGID=${PGID}
      - TZ=${TZ}
      - USER=${TRANSMISSION_USER}
      - PASS=${TRANSMISSION_PASS}
      - PEERPORT=${TRANSMISSION_PEER_PORT}
    volumes:
      - ./config/transmission:/config
      - ./data:/downloads # Downloads directory, shared with Seanime
    depends_on:
      - gluetun
    restart: unless-stopped
```

## Configuration

### Ports

- **`43211`**: The default internal port for the Seanime web interface.

### Volumes

- **`/root/.config/Seanime`**: Stores the configuration files for Seanime.
- **`/data`**: A common directory for storing your media files. This is not mandatory but recommended for organization.

### Environment Variables

- **`SEANIME_SERVER_HOST`**: Overrides the default server host (`0.0.0.0`).
- **`SEANIME_SERVER_PORT`**: Overrides the default server port inside the container (`43211`).

## Contributing

Contributions are welcome! If you have any suggestions, bug reports, or feature requests, please open an issue or submit a pull request on the [GitHub repository](https://github.com/Ju1-js/seanime-docker).

## License

> **License Disclaimer:** Portions of this repository are based on the original works of Coyenn and umag. All original and modified contributions in this repository are licensed under the GNU General Public License v3.0 (GPL-3.0).
