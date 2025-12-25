# Seanime + VPN + Tailscale Funnel

This configuration routes all traffic through a VPN (Gluetun) but uses [tsbridge](https://github.com/jtdowney/tsbridge) to expose the Seanime UI via [Tailscale Funnel](https://tailscale.com/kb/1223/funnel).

This allows you to access your Seanime instance remotely without port forwarding, even though the container is hidden behind a VPN.

## Requirements

1. **Tailscale Account:** You need a Tailscale account.
2. **OAuth Client:** Create an OAuth Client in your Tailscale Admin Console, [following the tsbridge docs](https://github.com/jtdowney/tsbridge/blob/main/docs/quickstart.md).
3. **HTTPS:** Tailscale Funnel requires HTTPS (Tailscale provisions this automatically).
4. **Security:** Since this exposes Seanime to the internet, you **should** enable the Seanime [Server Password](https://seanime.app/docs/config#server-password) and ideally use [Tailscale ACLs](https://tailscale.com/kb/1018/acls).

## Prerequisites (v3.2.3+)

**User Permissions:**
Seanime runs as UID `1000`. Ensure your config and data directories on the host are owned by UID `1000` before starting.

```bash
mkdir ./config/ ./data/
sudo chown -R 1000:1000 ./config/seanime ./data
```

## Setup

### 1. Configure `.env`

Create your environment file by copying the example:

```bash
cp .env.example .env
```

Open `.env` and populate the fields with your VPN and Tailscale credentials.

### 2. Start the Services

```bash
docker compose up -d
```

### 3. Verify VPN Connection

Check the logs of the `gluetun` container:

```bash
docker logs gluetun
```

_You should see "Ip address: x.x.x.x" confirming the connection._

## Usage

The URLs are determined by the labels in your `docker-compose.yml`.

1. **Seanime:** Access at `https://seanime.your-tailnet.ts.net`

- Set your library path to `/data`.
- **Note:** This is served to the internet by default (Funnel). To restrict it to your private Tailnet, change `funnel=true` to `funnel=false` in the compose file labels.

2. **Transmission:** Access at `https://torrent.your-tailnet.ts.net`

- Login with the user/pass defined in your `.env`.

3. **Link Them:**
   Inside Seanime settings, set the Torrent Client to `Transmission`:

- **Host:** `localhost` (Since they share the same network container)
- **Port:** `9091`
- **Username/Password:** (As configured in `.env`)

## Troubleshooting

**Check Connection:**
If Seanime cannot connect to the internet, ensure `gluetun` is healthy:

```bash
docker ps
```

**Check your URLs:**
Check the `tsbridge` logs to confirm your Funnel URLs:

```bash
docker logs tsbridge
```

**Check Permissions:**
If Seanime crashes immediately, check the logs (`docker logs seanime`). It is could be a **Permission Denied** error, ensure you ran the `chown` commands mentioned in the Prerequisites.
