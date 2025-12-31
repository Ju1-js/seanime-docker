# Seanime + VPN (Gluetun) + Transmission

This setup runs Seanime and Transmission behind a VPN using [Gluetun](https://github.com/qdm12/gluetun).

## Prerequisites (v3.2.3+)

**Prepare Folders:**
Seanime runs as UID `1000`. To prevent permission issues, **create the directories manually** before starting the container. This ensures they are owned by your user account rather than the root user.

```bash
mkdir -p ./config/seanime ./data
```

## Setup

### 1. Environment

Create your environment file by copying the example:

```bash
cp .env.example .env
```

Open `.env` and populate the fields with your VPN credentials.

### 2. Start the Services

```bash
docker compose up -d
```

### 3. Verify VPN Connection

Check the logs of the `gluetun` container to ensure it connected successfully:

```bash
docker logs gluetun
```

_You should see "Ip address: x.x.x.x" confirming the connection. This may take a few attempts depending on your provider._

## Usage

1. **Seanime:** Access at `http://localhost:43211`

- Set your library path to `/data`

2. **Transmission:** Access at `http://localhost:9091`

- Login with the user/pass defined in your `.env`.

3. **Link Them:**
   Inside Seanime settings, set the Torrent Client to `Transmission` with the following settings:

- **Host:** `localhost` (Since they share the same network container)
- **Port:** `9091`
- **Username/Password:** (As configured in `.env`)

## Troubleshooting

**Check Connection:**
If Seanime cannot connect to the internet, ensure `gluetun` is healthy:

```bash
docker ps
```

**Permission Errors / Container Crashing:**
If Seanime crashes immediately, check the logs (`docker logs seanime`). If you see **Permission Denied** errors, your user (UID 1000) likely does not own the config or data folders.

**Fix:** Manually set the ownership to UID 1000:

```bash
sudo chown -R 1000:1000 ./config ./data
docker compose restart
```
