# Seanime + VPN (Gluetun) + Tailscale

This setup runs [Seanime](https://github.com/5rahim/seanime) and [Transmission](https://transmissionbt.com/) through [Gluetun](https://github.com/qdm12/gluetun). It uses [Tailscale](https://tailscale.com/) on the Raspberry Pi for remote playback.

## Setup

### 1. Prepare the Pi

Install Docker Compose and Tailscale on the host. Create the local config and media directories:

```bash
cp .env.example .env
mkdir -p ./config/{seanime,transmission} ./data/{complete,incomplete}
```

Fill in the WireGuard provider settings and Transmission credentials in `.env`. Set `PUID` and `PGID` to the owner of Transmission's directories. Seanime runs as UID `1000`.

### 2. Start the Services

```bash
docker compose up -d
docker compose ps
```

Seanime listens on `http://127.0.0.1:43211` on the Pi.

### 3. Set Up Remote Access

**Private (Serve)**. Run on the Pi, then open the printed URL from a device on your tailnet.

```bash
tailscale serve --bg http://127.0.0.1:43211
```

**Public (Funnel)**. Enable Seanime authentication first. Funnel makes port 443 public and replaces any Serve listener on that port. Verify from a signed-out browser that API and media routes require authentication.

```bash
tailscale funnel --bg --tls-terminated-tcp=443 tcp://127.0.0.1:43211
tailscale funnel status
```

See the [Serve](https://tailscale.com/docs/reference/tailscale-cli/serve) and [Funnel](https://tailscale.com/docs/features/tailscale-funnel) docs for prerequisites.

## Usage

- **Library:** Set the path to `/data` or `/data/complete`.
- **Transmission:** In Seanime, use `127.0.0.1:9091` and the credentials from `.env`. If needed, map `/downloads/complete` to `/data/complete`.

## Troubleshooting

- **Slow playback:** Compare the same file in direct play. On one Pi 5, playback went from about 1 MB/s via Newt to at least 3 MB/s via Funnel. Funnel has bandwidth limits.
- **Slow downloads:** Check `docker compose logs gluetun` for the selected WireGuard implementation. The default is `auto`.
