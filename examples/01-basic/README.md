# Basic Setup

This configuration runs Seanime in a standard Docker container. It is the recommended setup for local networks where VPN routing is not required.

## Setup

### 1. Start the Service

Run the following command in this directory:

```bash
docker compose up -d
```

_Docker will automatically create the `config/` and `data/` directories for you._

### 2\. Verify Status

Ensure the container is running and healthy:

```bash
docker ps
```

## Usage

1.  **Access Seanime:** Open your browser to `http://localhost:43211`.
2.  **First Run Setup:**
    - When prompted for the **Library Path**, enter: `/data`
    - This maps to the `./data` folder in your current directory (where you should place your anime media).

## Customization

If you need to change the port or volume locations, edit the `docker-compose.yml` file directly.

- **Ports:** Change `"43211:43211"` to `"YOUR_PORT:43211"`
- **Media:** Update `- ./data:/data` to point to your existing media library (e.g., `- /mnt/media/anime:/data`).
