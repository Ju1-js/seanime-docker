# Seanime + VPN (Gluetun) + Transmission

This setup runs Seanime and Transmission behind a VPN using [Gluetun](https://github.com/qdm12/gluetun).

## Setup

### 1. Environment

Create your environment file by copying the example:

```bash
cp .env.example .env
```

Open `.env` and populate the fields with your VPN credentials.

### 2\. Start the Services

```bash
docker compose up -d
```

### 3\. Verify VPN Connection

Check the logs of the `gluetun` container to ensure it connected successfully:

```bash
docker logs gluetun
```

_You should see "Ip address: x.x.x.x" confirming the connection. This may take a few attempts depending on your provider._

## Usage

1.  **Seanime:** Access at `http://localhost:43211`
    - Set your library path to `/data`
2.  **Transmission:** Access at `http://localhost:9091`
    - Login with the user/pass defined in your `.env`.
3.  **Link Them:**
    Inside Seanime settings, set the Torrent Client to `Transmission` with the following settings:
    - **Host:** `localhost` (Since they share the same network container)
    - **Port:** `9091`
    - **Username/Password:** (As configured in `.env`)

## Troubleshooting

If Seanime cannot connect to the internet, ensure `gluetun` is healthy:

```bash
docker ps
```

Both `seanime` and `transmission` depend on `gluetun`. If `gluetun` is unhealthy (bad VPN creds, failed connection), the other containers will not start.
