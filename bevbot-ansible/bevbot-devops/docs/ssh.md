# SSH Setup Guide

## Overview

Bevbot uses a **two-layer SSH strategy**:

| Layer | Method | Use Case |
|---|---|---|
| Primary | **Tailscale SSH** | Recommended for all day-to-day connections. Device-trust enforced via Tailscale ACLs. No managing authorized_keys per-device. |
| Fallback | **OpenSSH (key-only)** | LAN access when Tailscale is unavailable. Hardened config — password auth permanently disabled. |

---

## Step 1 — Generate SSH Keys (on each client device)

Use Ed25519 — it's the most secure and smallest key type available in OpenSSH.

```bash
# On each device (laptop, desktop, phone via Termius/etc.)
ssh-keygen -t ed25519 -C "your-device-name@bevbot" -f ~/.ssh/bevbot_ed25519

# Never share the private key (~/.ssh/bevbot_ed25519)
# Add the PUBLIC key (.pub) to group_vars/all/main.yml → authorized_keys
```

**Mobile (iOS/Android — Termius, Blink, etc.):** Generate the key inside the app and export the `.pub` portion. Add it to `authorized_keys` in this repo and re-run Ansible.

---

## Step 2 — Tailscale SSH Setup

Tailscale SSH is already configured by the `tailscale` Ansible role (`--ssh` flag). Once the machines are on your tailnet:

### Check which devices can SSH where

In the Tailscale admin console → **Access Controls**, your default policy looks like:

```json
{
  "ssh": [
    {
      "action": "accept",
      "src": ["autogroup:member"],
      "dst": ["tag:bevbot"],
      "users": ["autogroup:nonroot"]
    }
  ]
}
```

**To lock it down further** (recommended — only specific devices can reach Bevbot):

```json
{
  "tagOwners": {
    "tag:bevbot": ["your@email.com"],
    "tag:trusted-client": ["your@email.com"]
  },
  "ssh": [
    {
      "action": "accept",
      "src": ["tag:trusted-client"],
      "dst": ["tag:bevbot"],
      "users": ["your_username"]
    },
    {
      "action": "check",
      "src": ["autogroup:member"],
      "dst": ["tag:bevbot"],
      "users": ["autogroup:nonroot"]
    }
  ]
}
```

Tag your trusted devices in the Tailscale admin as `tag:trusted-client` and both servers as `tag:bevbot`.

### Connect via Tailscale SSH

```bash
# Using MagicDNS hostname (easiest)
ssh your_username@bevbot1.your-tailnet.ts.net

# Or using Tailscale IP
ssh your_username@100.x.x.x

# Tailscale SSH doesn't require your SSH key to be pre-trusted —
# it authenticates via your Tailscale identity (SSO)
```

### Check current Tailscale SSH status on a host

```bash
tailscale status           # Shows connected peers
tailscale ssh-status       # Shows SSH configuration
```

---

## Step 3 — OpenSSH Fallback (LAN)

The `ssh` Ansible role deploys a hardened `sshd_config` with:

- ✅ Ed25519 keys only (no RSA, no ECDSA, no DSA)
- ✅ Key-based auth only (`PasswordAuthentication no`)
- ✅ Root login disabled
- ✅ Only your user allowed (`AllowUsers`)
- ✅ Modern KEx/Cipher/MAC algorithms only
- ✅ No X11/TCP/agent forwarding

```bash
# LAN SSH (fallback)
ssh -i ~/.ssh/bevbot_ed25519 your_username@192.168.1.10

# Add to ~/.ssh/config for convenience
Host bevbot
    HostName 192.168.1.10
    User your_username
    IdentityFile ~/.ssh/bevbot_ed25519
    Port 22

Host bevbot2
    HostName 192.168.1.11
    User your_username
    IdentityFile ~/.ssh/bevbot_ed25519
    Port 22
```

---

## Adding a New Device

1. Generate an Ed25519 key on the new device
2. Add its public key to `ansible/group_vars/all/main.yml` → `authorized_keys`
3. Run: `ansible-playbook ansible/playbooks/common.yml --tags ssh --ask-vault-pass`
4. For Tailscale SSH: add the device to your tailnet and tag it appropriately in ACLs

---

## Revoking a Device

1. Remove its public key from `authorized_keys` in `group_vars/all/main.yml`
2. Run: `ansible-playbook ansible/playbooks/common.yml --tags ssh --ask-vault-pass`
   - The `exclusive: true` flag on `authorized_key` task removes all unlisted keys
3. For Tailscale: remove the device from your tailnet in the admin console

---

## Security Recommendation: Tailscale vs OpenSSH

**Use Tailscale SSH as your primary method.** Here's why:

| | Tailscale SSH | OpenSSH |
|---|---|---|
| Authentication | Your Tailscale identity (tied to your account) | Static SSH keys |
| Revocation | Instant (remove device from tailnet) | Requires Ansible re-run |
| MFA support | ✅ Via your Tailscale SSO provider | ❌ Not configured |
| Network exposure | Zero — encrypted overlay network | Exposed on LAN |
| Key management | None needed | Per-device keys |
| Fallback if Tailscale goes down | ❌ | ✅ |
