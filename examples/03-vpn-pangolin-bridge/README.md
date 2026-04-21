# Seanime + VPN (Gluetun) + Pangolin Bridge

This setup routes traffic through a VPN using [Gluetun](https://github.com/qdm12/gluetun) and exposes Seanime remotely via [Pangolin](https://github.com/fosrl/pangolin) with the [Newt](https://github.com/fosrl/newt) tunnel agent, without port forwarding.

## Pangolin

[Pangolin](https://github.com/fosrl/pangolin) is an open-source reverse tunnel proxy. It can be self-hosted or used via [app.pangolin.net](https://app.pangolin.net). Free subdomains are available on `hostlocal.app`, `tunneled.to`, and `tunnelmy.app` (subject to availability). You can also use your own domain.

`newt` connects outbound to your Pangolin instance, registers as a Site, and forwards traffic to `http://gluetun:43211`, reachable by container name on the shared `pangolin` Docker network.

## Prerequisites

Create the `pangolin` external Docker network before starting:

```bash
docker network create pangolin
```

Create the host directories before starting to prevent permission issues:

```bash
mkdir -p ./config/seanime ./config/transmission ./data/complete ./data/incomplete
```

## Setup

### 1. Create a site in Pangolin

In your Pangolin dashboard, create a new Site:

- Name: anything (e.g. `RPi5`)
- Connection Type: Newt

Open the site and go to the Credentials tab. Copy the Newt ID and Newt Secret into your `.env`.

### 2. Environment

```bash
cp .env.example .env
```

- `PANGOLIN_ENDPOINT`: your Pangolin instance URL (e.g. `https://app.pangolin.net`)
- `NEWT_ID` / `NEWT_SECRET`: from the site Credentials tab
- VPN fields: see [Gluetun docs](https://github.com/qdm12/gluetun-wiki/tree/main/setup)

### 3. Start the services

```bash
docker compose up -d
```

Confirm the site shows Online in the Pangolin dashboard.

### 4. Create a resource in Pangolin

Under your site, create a new Resource with target `http://gluetun:43211`. Pangolin routes to `gluetun` by name because Newt and Gluetun share the same `pangolin` Docker network.

### 5. Configure resource rules (required)

Seanime's API and media streaming paths must bypass Pangolin's auth or playback will break. Under Resource Rules, add these Bypass Auth rules:

| Path | Match type |
|---|---|
| `/api/*` | Path |
| `/events` | Path |
| `/manifest.json` | Path |
| `/mediastream/*` | Path |
| `/directstream/*` | Path |

### 6. Access controls (optional)

Pangolin supports SSO, password protection, PIN codes, and email whitelisting. Since Seanime is internet-facing here, enabling at least one is recommended.

## Usage

**Seanime:** Access at the URL assigned to your resource. Set your library path to `/data`.

**Transmission:** Create a second resource pointing to `http://gluetun:9091` for remote access.

To link Transmission in Seanime, go to Settings > Torrent Client and set:
- Host: `localhost` (shares the Gluetun network)
- Port: `9091`
- Username/Password: as set in `.env`

## Troubleshooting

**VPN not connecting:**

```bash
docker logs gluetun
docker ps
```

**Newt not registering / site shows offline:**

```bash
docker logs newt
```

Double-check `PANGOLIN_ENDPOINT`, `NEWT_ID`, and `NEWT_SECRET` in your `.env`.

**Streaming or API calls failing through Pangolin:**
Check that the resource rules from step 5 are saved and enabled. Without them, Pangolin's auth will block Seanime's backend requests.

**Permission errors / container crashing:**
Check `docker logs seanime`. If you see Permission Denied errors, the host directories aren't owned by the right user.

Option A: add `user: "UID:GID"` to the `seanime` service, where UID and GID match the owner of your host directories. Run `stat -c "%u:%g" ./config` to find them:

```yaml
seanime:
  user: "1000:1000"  # replace with your host directory's UID:GID
  ...
```

Option B: transfer ownership of the host directories to UID 1000 (the container's internal user):

```bash
sudo chown -R 1000:1000 ./config ./data
docker compose restart
```
