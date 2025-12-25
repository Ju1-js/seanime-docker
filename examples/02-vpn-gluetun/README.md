# Seanime + VPN (Gluetun) + Transmission

This setup runs Seanime and Transmission behind a VPN using [Gluetun](https://github.com/qdm12/gluetun).

## Prerequisites (v3.2.3+)

**User Permissions:**
Seanime runs as UID `1000`. Ensure your config and data directories on the host are owned by UID `1000` before starting.

```bash
mkdir ./config/ ./data/
sudo chown -R 1000:1000 ./config/seanime ./data
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

**Check Permissions:**
If Seanime crashes immediately, check the logs (`docker logs seanime`). It is could be a **Permission Denied** error, ensure you ran the `chown` commands mentioned in the Prerequisites.
