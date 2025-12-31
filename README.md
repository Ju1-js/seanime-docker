# Seanime Docker

[![Docker Pulls](https://img.shields.io/docker/pulls/ju1js/seanime.svg)](https://hub.docker.com/r/ju1js/seanime)
[![Publish Docker image](https://github.com/Ju1-js/seanime-docker/actions/workflows/publish.yml/badge.svg)](https://github.com/Ju1-js/seanime-docker/actions/workflows/publish.yml)

A simple, multi-arch Docker image for [Seanime](https://seanime.rahim.app/), a self-hosted anime streaming platform.

Now available in **Standard**, **Hardware Accelerated (Intel/AMD)**, and **NVIDIA CUDA** variants.

## **Breaking Changes (v3.2.3)**

**The internal container user has changed.**
To improve security, this image now runs as a non-root user named `seanime` (UID: `1000`, GID: `1000`).

1.  **Update Volume Paths:** You need to change your volume mapping for the config directory.
    - **Old:** `/root/.config/Seanime`
    - **New:** `/home/seanime/.config/Seanime`
2.  **Check Permissions:** Ensure the directories you mount on your host (config and data) are readable and writable by **UID 1000**.

---

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

| Tag          | Suffix            | Base OS | Description                                                                  | Best For                                              |
| :----------- | :---------------- | :------ | :--------------------------------------------------------------------------- | :---------------------------------------------------- |
| **Standard** | `:latest`         | Alpine  | Minimal footprint. Includes Jellyfin-FFmpeg.                                 | Raspberry Pi, ARM devices, or Direct Play (CPU only). |
| **HW Accel** | `:latest-hwaccel` | Alpine  | Adds Intel Media Drivers (QSV/VAAPI), Mesa (AMD), and OpenCL.                | **Intel CPUs** (iGPU) or AMD GPUs.                    |
| **CUDA**     | `:latest-cuda`    | Ubuntu  | Based on `nvidia/cuda:runtime`. Includes Jellyfin-FFmpeg with NVENC support. | **NVIDIA GPUs** requiring hardware transcoding.       |

## Platform Support

This Docker image is built with multi-architecture support:

- **`linux/amd64`** - Standard x86-64 PCs and servers.
- **`linux/arm64`** - 64-bit ARM devices (Raspberry Pi 4/5, NVIDIA Jetson).
- **`linux/arm/v7`** - Older 32-bit ARM devices (_Standard/HW Accel only_).

## Usage

### Docker CLI

**Standard (CPU):**

```bash
docker run -d \
  -p 43211:43211 \
  -v ./config/seanime:/home/seanime/.config/Seanime \
  --restart=unless-stopped \
  --name seanime \
  ju1js/seanime:latest
```

**Intel iGPU (QSV):**

```bash
docker run -d \
  -p 43211:43211 \
  -v ./config/seanime:/home/seanime/.config/Seanime \
  --device /dev/dri:/dev/dri \
  --restart=unless-stopped \
  --name seanime \
  ju1js/seanime:latest-hwaccel
```

**NVIDIA GPU (NVENC):**
_Requires the [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html) on the host._

```bash
docker run -d \
  -p 43211:43211 \
  -v ./config/seanime:/home/seanime/.config/Seanime \
  --gpus all \
  --restart=unless-stopped \
  --name seanime \
  ju1js/seanime:latest-cuda
```

### Docker Compose

For a standard setup, create a `docker-compose.yml`:

```yaml
services:
  seanime:
    image: ju1js/seanime:latest
    container_name: seanime
    environment:
      - SEANIME_SERVER_HOST=0.0.0.0
      - SEANIME_SERVER_PORT=43211
    ports:
      - "43211:43211"
    volumes:
      - ./config/seanime:/home/seanime/.config/Seanime
      - ./data:/data
    restart: unless-stopped
```

### Hardware Acceleration

Depending on your hardware, update the image tag and device mappings in your `docker-compose.yml`.

#### Option A: Intel (QuickSync)

```yaml
services:
  seanime:
    image: ju1js/seanime:latest-hwaccel
    devices:
      - /dev/dri:/dev/dri # Passes the iGPU
    environment:
      - SEANIME_SERVER_HOST=0.0.0.0
      - SEANIME_SERVER_PORT=43211
    ports:
      - "43211:43211"
    volumes:
      - ./config/seanime:/home/seanime/.config/Seanime
      - ./data:/data
    restart: unless-stopped
```

#### Option B: NVIDIA (NVENC)

Ensure you have the **NVIDIA Container Toolkit** installed on your host.

```yaml
services:
  seanime:
    image: ju1js/seanime:latest-cuda
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: 1
              capabilities: [gpu, video]
    environment:
      - SEANIME_SERVER_HOST=0.0.0.0
      - SEANIME_SERVER_PORT=43211
    ports:
      - "43211:43211"
    volumes:
      - ./config/seanime:/home/seanime/.config/Seanime
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

- **`/home/seanime/.config/Seanime`**: Stores the configuration files for Seanime.
- **`/data`**: A common directory for storing your media files. Recommended for organization.

> **Permissions Note:** The container runs as user `1000`. Ensure your host directories mapped to these volumes are owned by UID `1000` to prevent "Permission Denied" errors.
>
> **Quick Fix:** Run `mkdir -p ./config/seanime ./data` on your host _before_ starting Docker. This ensures the folders are owned by you, not root.

### Environment Variables

- **`SEANIME_SERVER_HOST`**: Overrides the default server host (`0.0.0.0`).
- **`SEANIME_SERVER_PORT`**: Overrides the default server port inside the container (`43211`).

## Contributing

Contributions are welcome! If you have any suggestions, bug reports, or feature requests, please open an issue or submit a pull request on the [GitHub repository](https://github.com/Ju1-js/seanime-docker).

## License

> **License Disclaimer:** Portions of this repository are based on the original works of Coyenn and umag. All original and modified contributions in this repository are licensed under the GNU General Public License v3.0 (GPL-3.0).
