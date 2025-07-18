# Seanime Docker

*Re-integrates [Coyenn's](https://github.com/Coyenn/seanime-docker/) image with [umag's](https://github.com/umag/seanime-docker) multi-arch.*

A simple, Docker image for [Seanime](https://seanime.rahim.app/).

Video transcoding via [FFmpeg](https://ffmpeg.org/) works out of the box.


## Usage

### Docker CLI

```bash
docker run -it -p 3000:8080 -p 3001:8081 --restart=always --name seanime ju1js/seanime
```

### Docker Compose

```yaml
services:
  seanime:
    image: ju1js/seanime
    container_name: seanime
    ports:
      - "3000:8080" # Seanime web interface
      - "3001:8081" # qBittorrent web interface
    volumes:
      - ./data:/data # Bind mount for downloads and media files
      # IMPORTANT: Copy the .docker/config directory from the repo to your host before using this bind mount.
      # - ./config:/config # Bind mount for configuration files
    restart: unless-stopped
```

## Configuration

### Ports

`8080` - Seanime web interface.

`8081` - qBittorrent web interface.

### Volumes

`/data` - Downloads and media files are stored here.

`/config` - This is where the configuration files for Seanime, qBittorrent, and Supervisor are located.
