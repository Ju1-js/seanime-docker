# Basic Setup

This configuration runs Seanime in a standard Docker container. It is the recommended setup for local networks where VPN routing is not required.

## Prerequisites (v3.2.3+)

**Prepare Folders:**
Seanime runs as UID `1000`. To prevent permission issues, **create the directories manually** before starting the container. This ensures they are owned by your user account rather than the root user.

```bash
mkdir -p ./config/seanime ./data
```

## Setup

### 1. Start the Service

Run the following command in this directory:

```bash
docker compose up -d
```

### 2. Verify Status

Ensure the container is running and healthy:

```bash
docker ps
```

## Usage

1. **Access Seanime:** Open your browser to `http://localhost:43211`.
2. **First Run Setup:**

- When prompted for the **Library Path**, enter: `/data`
- This maps to the `./data` folder in your current directory (ensure you placed your media there).

## Customization

If you need to change the port or volume locations, edit the `docker-compose.yml` file directly.

- **Ports:** Change `"43211:43211"` to `"YOUR_PORT:43211"`
- **Config:** The internal config path is `/home/seanime/.config/Seanime`.
- **Media:** Update `- ./data:/data` to point to your existing media library (e.g., `- /mnt/media/anime:/data`).
- _Note: Your external media library must also be readable/writable by UID 1000._

## Troubleshooting

**Permission Errors / Container Crashing:**
If the container crashes immediately or fails to save settings, check the logs (`docker logs seanime`). If you see **Permission Denied** errors, your user (UID 1000) likely does not own the config or data folders.

**Fix:** Manually set the ownership to UID 1000:

```bash
sudo chown -R 1000:1000 ./config ./data
docker compose restart
```
