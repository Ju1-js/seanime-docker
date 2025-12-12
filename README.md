# Seanime Docker

[![Docker Pulls](https://img.shields.io/docker/pulls/ju1js/seanime.svg)](https://hub.docker.com/r/ju1js/seanime)

A simple, multi-arch Docker image for [Seanime](https://seanime.rahim.app/), a self-hosted anime streaming platform. Video transcoding via [FFmpeg](https://ffmpeg.org/) is included and works out of the box.

## Table of Contents

- [Platform Support](#platform-support)
- [Usage](#usage)
  - [Docker CLI](#docker-cli)
  - [Docker Compose](#docker-compose)
  - [Advanced Examples](#advanced-examples)
- [Configuration](#configuration)
- [Contributing](#contributing)
- [License](#license)

## Platform Support

This Docker image is built with multi-architecture support and should be compatible with the following platforms:

- **`linux/amd64`** - Standard x86-64 PCs and servers.
- **`linux/arm64`** - 64-bit ARM devices (Raspberry Pi 4/5).
- **`linux/arm/v7`** - Older 32-bit ARM devices.

**Note:** primarily tested on Raspberry Pi 5 (`linux/arm64`). Feedback for other platforms is appreciated!

## Usage

### Docker CLI

To quickly get started:

```bash
docker run -d \
  -p 43211:43211 \
  -v ./seanime-config:/root/.config/Seanime \
  --restart=unless-stopped \
  --name seanime \
  ju1js/seanime:latest
```

### Docker Compose

For a standard setup, create a `docker-compose.yml`:

```yaml
services:
  seanime:
    image: ju1js/seanime:latest
    container_name: seanime
    ports:
      - "43211:43211"
    volumes:
      - ./config:/root/.config/Seanime
      - ./data:/data # Optional: Mount a directory for your media
    restart: unless-stopped
```

### Advanced Examples

For complex setups, such as running Seanime behind a VPN or using Tailscale, please refer to the **Examples** directory:

- **[01-basic](examples/01-basic)**: The standard setup (shown above).
- **[02-vpn-gluetun](examples/02-vpn-gluetun)**: Routes Seanime and Transmission through a WireGuard VPN (Gluetun) with healthchecks.
- **[03-tailscale-vpn-bridge](examples/03-tailscale-vpn-bridge)**: Advanced routing using `tsbridge` (Tailscale) + Gluetun.

## Configuration

### Ports

- **`43211`**: The default internal port for the Seanime web interface.

### Volumes

- **`/root/.config/Seanime`**: Stores the configuration files for Seanime.
- **`/data`**: A common directory for storing your media files. Recommended for organization.

### Environment Variables

- **`SEANIME_SERVER_HOST`**: Overrides the default server host (`0.0.0.0`).
- **`SEANIME_SERVER_PORT`**: Overrides the default server port inside the container (`43211`).

## Contributing

Contributions are welcome\! If you have any suggestions, bug reports, or feature requests, please open an issue or submit a pull request on the [GitHub repository](https://github.com/Ju1-js/seanime-docker).

## License

> **License Disclaimer:** Portions of this repository are based on the original works of Coyenn and umag. All original and modified contributions in this repository are licensed under the GNU General Public License v3.0 (GPL-3.0).
