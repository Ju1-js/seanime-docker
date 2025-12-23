# Seanime Docker

[![Docker Pulls](https://img.shields.io/docker/pulls/ju1js/seanime.svg)](https://hub.docker.com/r/ju1js/seanime)
[![Publish Docker image](https://github.com/Ju1-js/seanime-docker/actions/workflows/publish.yml/badge.svg)](https://github.com/Ju1-js/seanime-docker/actions/workflows/publish.yml)

A simple, multi-arch Docker image for [Seanime](https://seanime.rahim.app/), a self-hosted anime streaming platform.

Now available in **Standard** and **Hardware Accelerated** variants.

## Table of Contents

- [Image Variants](#image-variants)
- [Platform Support](#platform-support)
- [Usage](#usage)
  - [Docker CLI](#docker-cli)
  - [Docker Compose](#docker-compose)
  - [Hardware Acceleration](#hardware-acceleration)
  - [Advanced Examples](#advanced-examples)
- [Configuration](#configuration)
- [Contributing](#contributing)
- [License](#license)

## Image Variants

| Tag          | Suffix            | Description                                                                | Best For                                                                    |
| :----------- | :---------------- | :------------------------------------------------------------------------- | :-------------------------------------------------------------------------- |
| **Standard** | `:latest`         | Alpine Linux + Standard FFmpeg.                                            | Raspberry Pi, ARM devices, or users who Direct Play media (no transcoding). |
| **HW Accel** | `:latest-hwaccel` | Includes **Jellyfin-FFmpeg**, Intel Media Drivers (QSV/VAAPI), and OpenCL. | **Intel CPUs** (iGPU) requiring hardware transcoding.                       |

## Platform Support

This Docker image is built with multi-architecture support and should be compatible with the following platforms:

- **`linux/amd64`** - Standard x86-64 PCs and servers.
- **`linux/arm64`** - 64-bit ARM devices (Raspberry Pi 4/5).
- **`linux/arm/v7`** - Older 32-bit ARM devices.

**Note:** The Intel drivers included in the `-hwaccel` image are only active on `amd64` platforms. The image will still run on ARM devices, but will fall back to software transcoding. The `-hwaccel` images are recent additions (and therefore their reliability cannot be guaranteed).

## Usage

### Docker CLI

To quickly get started with the **Standard** image:

```bash
docker run -d \
  -p 43211:43211 \
  -v ./seanime-config:/root/.config/Seanime \
  --restart=unless-stopped \
  --name seanime \
  ju1js/seanime:latest
```

To run with **Hardware Acceleration** (Intel iGPU):

```bash
docker run -d \
  -p 43211:43211 \
  -v ./seanime-config:/root/.config/Seanime \
  --device /dev/dri:/dev/dri \
  --restart=unless-stopped \
  --name seanime \
  ju1js/seanime:latest-hwaccel
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

### Hardware Acceleration

If you are using the `:latest-hwaccel` tag on an Intel machine, you must pass the render device to the container for transcoding to work.

Update your `docker-compose.yml`:

```yaml
services:
  seanime:
    image: ju1js/seanime:latest-hwaccel # <--- Use the hwaccel tag
    container_name: seanime
    devices:
      - /dev/dri:/dev/dri # <--- Pass the GPU device
    ports:
      - "43211:43211"
    volumes:
      - ./config:/root/.config/Seanime
      - ./data:/data
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
