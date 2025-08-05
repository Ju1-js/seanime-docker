# Seanime Docker

[![Docker Pulls](https://img.shields.io/docker/pulls/ju1js/seanime.svg)](https://hub.docker.com/r/ju1js/seanime)

This repository provides a simple, multi-arch Docker image for [Seanime](https://seanime.rahim.app/), a self-hosted anime streaming platform. It re-integrates [Coyenn's](https://github.com/Coyenn/seanime-docker) original image with [umag's](https://github.com/umag/seanime-docker) multi-architecture support. Video transcoding via [FFmpeg](https://ffmpeg.org/) is included and works out of the box.

## Table of Contents

- [Platform Support](#platform-support)
- [Usage](#usage)
    - [Docker CLI](#docker-cli)
    - [Docker Compose](#docker-compose)
- [Configuration](#configuration)
    - [Ports](#ports)
    - [Volumes](#volumes)
- [Contributing](#contributing)
- [License](#license)

## Platform Support

This Docker image is built with multi-architecture support and should be compatible with the following platforms:

- **`linux/amd64`** - For standard x86-64 PCs and servers.
- **`linux/arm64`** - For 64-bit ARM devices like the Raspberry Pi 4 and 5.
- **`linux/arm/v7`** - For older 32-bit ARM devices.

**Note:** While the image is built for all the above platforms, it is primarily tested and used on a Raspberry Pi 5 (`linux/arm64`). Feedback and issue reports for all platforms are highly encouraged and appreciated!

## Usage

You can run the Seanime Docker image using either the Docker command-line interface (CLI) or Docker Compose.

### Docker CLI

To quickly get started, you can use the following Docker command to run the Seanime container:

```bash
docker run -it -p 3000:8080 -p 3001:8081 --restart=always --name seanime ju1js/seanime
```

### Docker Compose

For more complex setups, it is recommended to use Docker Compose.

#### Persisting Configuration

If you want to persist your Seanime and qBittorrent settings, you'll need to use a bind mount for the `/config` directory. Before you use this volume mount in your `docker-compose.yml`, you **must** first copy the default configuration files from this repository to a folder on your host machine.

You can find the necessary files at the following location in the repository:
[**`.docker/config`**](https://github.com/Ju1-js/seanime-docker/tree/main/.docker/config) [Download](https://download-directory.github.io/?url=https%3A%2F%2Fgithub.com%2FJu1-js%2Fseanime-docker%2Ftree%2Fmain%2F.docker%2Fconfig)

Create a folder (e.g., `seanime-config`) on your host machine and copy the contents of the repository's `.docker/config` directory into it.

#### Basic Example

Here is a basic `docker-compose.yml` file to run Seanime.

```yaml
services:
    seanime:
        image: ju1js/seanime
        container_name: seanime
        ports:
            - "3000:8080" # Seanime web interface
            - "3001:8081" # qBittorrent web interface
        volumes:
            - ./seanime-data:/data # Bind mount for downloads and media files
            # IMPORTANT: See "Persisting Configuration" above before uncommenting the next line.
            # - ./seanime-config:/config # Bind mount for configuration files
        restart: unless-stopped
```

#### Example with Wireguard

For users who want to route the container's traffic through a WireGuard VPN, you can use the following `docker-compose.yml` configuration. This is useful for enhancing privacy and bypassing network restrictions.

In this setup, the `seanime` container uses the network of the `wireguard` container.

```yaml
services:
    wireguard:
        image: lscr.io/linuxserver/wireguard:latest
        container_name: wireguard
        pull_policy: always
        cap_add:
            - NET_ADMIN
            - SYS_MODULE
        environment:
            - PUID=1000
            - PGID=1000
            - TZ=Etc/UTC
        volumes:
            - ./wireguard-config:/config # Path for WireGuard client config (e.g., wg0.conf)
            - /lib/modules:/lib/modules
        # All ports for services using WireGuard's network must be exposed here
        ports:
            - "3000:8080" # Seanime web interface
            - "3001:8081" # qBittorrent web interface
            - "51820:51820/udp" # WireGuard's own port
        sysctls:
            - net.ipv4.conf.all.src_valid_mark=1
        restart: unless-stopped

    seanime:
        image: ju1js/seanime
        container_name: seanime
        pull_policy: always
        # This container's network is handled by the wireguard service
        network_mode: "service:wireguard"
        volumes:
            - ./seanime-data:/data # Path for downloads and media files
            # IMPORTANT: See "Persisting Configuration" above before creating this volume.
            - ./seanime-config:/config # Path for Seanime's configuration files
        # Depends on wireguard to ensure it starts first
        depends_on:
            - wireguard
        restart: unless-stopped
```

## Configuration

### Ports

- **`8080`**: The web interface for Seanime.
- **`8081`**: The web interface for the built-in qBittorrent client.

### Volumes

- **`/data`**: This volume is used to store downloaded media files. You should map this to a directory on your host machine to persist your media.
- **`/config`**: This volume stores the configuration files for Seanime, qBittorrent, and Supervisor. It is recommended to map this to a host directory to maintain your settings across container restarts.

`/config` - This is where the configuration files for Seanime, qBittorrent, and Supervisor are located.

## Contributing

Contributions are welcome! If you have any suggestions, bug reports, or feature requests, please open an issue or submit a pull request on the [GitHub repository](https://github.com/ju1js/seanime-docker).

## License

> **License Disclaimer:** Portions of this repository are based on the original works of Coyenn and umag. All original and modified contributions in this repository are licensed under the GNU General Public License v3.0 (GPL-3.0).
