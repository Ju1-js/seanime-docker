# Configuration Examples

This directory provides Docker Compose configurations for various deployment scenarios, ranging from direct container networking to isolated VPN routing.

## Available Examples

| Example                                                | Complexity              | Network Topology                                                                       |
| :----------------------------------------------------- | :---------------------- | :------------------------------------------------------------------------------------- |
| **[01-basic](./01-basic)**                             | 🟢 Easy                 | **Direct Networking:** Best for local LAN usage where traffic masking is not required. |
| **[02-vpn-gluetun](./02-vpn-gluetun)**                 | 🟡 Medium               | **VPN Tunneling:** Routes all outgoing traffic through a WireGuard/OpenVPN tunnel.     |
| **[03-vpn-pangolin-bridge](./03-vpn-pangolin-bridge)** | 🔴 Advanced(&#8209;ish) | **Split Routing:** Combines a VPN for privacy with Pangolin (Newt) for remote access.  |

## Usage

1. Navigate to the desired configuration directory:

    ```bash
    cd examples/02-vpn-gluetun
    ```

2. Review the `README.md` within that directory for specific environment variable requirements and deployment steps.
