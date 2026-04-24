# Tailscale ACL Configuration Guide

## Overview

Tailscale ACLs (Access Control Lists) define which of your devices can
communicate with which services. Paste these into your Tailscale Admin Console
at: https://login.tailscale.com/admin/acls

---

## Recommended ACL Configuration

```json
{
  "tagOwners": {
    "tag:bevbot-server": ["your@email.com"],
    "tag:trusted-client": ["your@email.com"]
  },

  "acls": [
    {
      "comment": "Trusted clients can reach all Bevbot services",
      "action": "accept",
      "src":  ["tag:trusted-client"],
      "dst":  ["tag:bevbot-server:*"]
    },
    {
      "comment": "Bevbot servers can talk to each other (for SMB)",
      "action": "accept",
      "src":  ["tag:bevbot-server"],
      "dst":  ["tag:bevbot-server:445"]
    },
    {
      "comment": "Block everything else by default (implicit)",
      "action": "accept",
      "src":  ["*"],
      "dst":  ["*:0"]
    }
  ],

  "ssh": [
    {
      "comment": "Trusted clients can SSH to Bevbot servers",
      "action": "accept",
      "src":   ["tag:trusted-client"],
      "dst":   ["tag:bevbot-server"],
      "users": ["your_username"]
    },
    {
      "comment": "Check-mode for other tailnet members (requires re-auth)",
      "action": "check",
      "src":   ["autogroup:member"],
      "dst":   ["tag:bevbot-server"],
      "users": ["autogroup:nonroot"]
    }
  ],

  "nodeAttrs": [
    {
      "comment": "Enable Tailscale SSH on Bevbot servers",
      "target": ["tag:bevbot-server"],
      "attr":   ["ssh"]
    }
  ]
}
```

## Setup Steps

### 1. Tag your servers (Bevbot 1.0 and 2.0)
In Tailscale Admin Console → Machines:
- Click on `bevbot1` → Edit → Add tag: `bevbot-server`
- Click on `bevbot2` → Edit → Add tag: `bevbot-server`

### 2. Tag your client devices
In Tailscale Admin Console → Machines:
- Click on your laptop → Edit → Add tag: `trusted-client`
- Click on your desktop → Edit → Add tag: `trusted-client`
- Click on your phone → Edit → Add tag: `trusted-client`

### 3. Enable Key Expiry (recommended)
In Tailscale Admin Console → Settings → Keys:
- Enable "Device Key Expiry" — devices must re-authenticate periodically
- Recommended: 90 days

### 4. Enable MFA (highly recommended)
In Tailscale Admin Console → Settings → Auth:
- Connect your SSO provider (Google, GitHub, etc.)
- Require MFA for your account

---

## Port Reference (for Tailscale ACL dst rules)

| Service | Port | Host |
|---|---|---|
| SSH | 22 | Both |
| Cockpit | 9090 | Both |
| Portainer | 9443 | Both |
| Immich | 2283 | bevbot1 |
| Jellyfin HTTP | 8096 | bevbot2 |
| Jellyfin HTTPS | 8920 | bevbot2 |
| Ollama | 11434 | bevbot2 |
| SMB | 445 | bevbot1 |
| Minecraft | 25565 | bevbot2 |

---

## Verifying Your ACLs

```bash
# On any device with Tailscale installed
tailscale ping bevbot1                    # Should succeed from trusted-client
tailscale ssh your_username@bevbot1       # Should open a shell

# Check what routes your device has
tailscale status --peers

# From bevbot — who can reach me?
tailscale whois <peer-ip>
```

## MagicDNS Hostnames

With Tailscale MagicDNS enabled, you can reach hosts by name:

```
bevbot1.your-tailnet.ts.net
bevbot2.your-tailnet.ts.net
```

Or just the short name if on the same tailnet:
```
bevbot1
bevbot2
```
