# Basic Setup

This configuration runs Seanime in a standard Docker container. It is the recommended setup for local networks where VPN routing is not required.

## Prerequisites (v3.2.3+)

**User Permissions:**
Seanime runs as UID `1000`. Ensure your config and data directories on the host are owned by UID `1000` before starting.

```bash
sudo chown -R 1000:1000 ./config/seanime ./data
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
- This maps to the `./data` folder in your current directory (ensure you placed your media there and permissions are correct).

## Customization

If you need to change the port or volume locations, edit the `docker-compose.yml` file directly.

- **Ports:** Change `"43211:43211"` to `"YOUR_PORT:43211"`
- **Config:** The internal config path is `/home/seanime/.config/Seanime`.
- **Media:** Update `- ./data:/data` to point to your existing media library (e.g., `- /mnt/media/anime:/data`).
- _Note: Your external media library must also be readable/writable by UID 1000._

## Troubleshooting

**Check Permissions:**
If Seanime crashes immediately, check the logs (`docker logs seanime`). It is could be a **Permission Denied** error, ensure you ran the `chown` commands mentioned in the Prerequisites.
