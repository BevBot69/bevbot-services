# Security Posture

## Overview

```
Internet
   │
   ▼
[ Tailscale Network ]  ← encrypted overlay, no open ports to internet
   │
   ├── Your Phone / Laptop / Desktop (Tailscale clients)
   │
   ├── Bevbot 1.0 ──── firewall: only SSH(LAN), Tailscale, Cockpit, Immich(LAN)
   │
   └── Bevbot 2.0 ──── firewall: only SSH(LAN), Tailscale, Cockpit, Jellyfin(LAN)
                                  game ports (public-facing — see below)
```

---

## Layers of Defense

### 1. Network — Tailscale
- All management traffic (SSH, Portainer, Cockpit) flows over Tailscale's encrypted WireGuard overlay
- Neither server has any ports open to the public internet except game server ports
- Tailscale ACLs define exactly which of your devices can reach which servers

### 2. Host Firewall — firewalld
- Default zone: `drop` (deny all incoming)
- Only explicitly allowed services/ports pass through
- Tailscale interface (`tailscale0`) is in the `trusted` zone
- Ollama is only reachable via `trusted` zone (Tailscale)

### 3. SSH Hardening
- Ed25519 keys only
- Password authentication permanently disabled
- Root login disabled
- Only listed users allowed
- Modern algorithms only (no legacy ciphers)
- See [ssh.md](ssh.md) for full details

### 4. Containers — Rootless Podman
- All containers run as your regular user, not root
- Even a compromised container cannot escape to root
- No Docker daemon running as root
- Podman uses user namespaces for additional isolation
- `NoNewPrivileges=true` set on all container units
- SELinux labels applied via `:z` volume mounts

### 5. Secret Management — Ansible Vault
- All passwords, tokens, and keys stored in `vault.yml` (never committed plaintext)
- Vault file encrypted with AES-256
- Only the vault password unlocks secrets at deploy time

### 6. System Hardening
- Kernel parameters hardened via sysctl (IP forwarding, ICMP, BPF JIT)
- fail2ban blocks brute-force SSH attempts after 5 failures
- Automatic security updates via `rpm-ostreed-automatic`
- NTP synchronized via chrony

---

## Port Exposure Reference

### Bevbot 1.0
| Port | Service | Exposed To |
|---|---|---|
| 22 | SSH | LAN only |
| 9090 | Cockpit | LAN + Tailscale |
| 9443 | Portainer | LAN + Tailscale |
| 2283 | Immich | LAN + Tailscale |
| 445 | SMB (RAID share) | LAN only |

### Bevbot 2.0
| Port | Service | Exposed To |
|---|---|---|
| 22 | SSH | LAN only |
| 9090 | Cockpit | LAN + Tailscale |
| 9443 | Portainer | LAN + Tailscale |
| 8096 | Jellyfin HTTP | LAN + Tailscale |
| 8920 | Jellyfin HTTPS | LAN + Tailscale |
| 11434 | Ollama | Tailscale only |
| 25565 | Minecraft | Public (if hosting friends) |
| 27016-27017 | The Forest | Public (if enabled) |
| 21025 | Starbound | Public (if enabled) |

**Game server note:** Game ports are the only services exposed to the internet. If you're not actively running a public game server, disable the firewall rules:
```bash
firewall-cmd --remove-port=25565/tcp --permanent
firewall-cmd --reload
```

---

## Recommendations

### High Priority
- [ ] Set a strong Portainer admin password on first login
- [ ] Enable MFA on your Tailscale account (protects all SSH access)
- [ ] Rotate the Tailscale auth key after initial deployment (one-time keys)
- [ ] Use a password manager to generate all vault secrets

### Medium Priority
- [ ] Set up Tailscale ACL tags to restrict which client devices reach which servers
- [ ] Enable Tailscale Key Expiry so device keys must be re-authenticated periodically
- [ ] Consider a reverse proxy (Caddy/nginx) with TLS for Jellyfin/Immich if you ever want external access without VPN

### Low Priority / Optional
- [ ] Set up log shipping to a central location (Cockpit → Logs shows journald)
- [ ] Enable LUKS encryption on Bevbot 2.0 SSD at OS install time (too late after the fact without reinstall)

---

## GTS 430 (Bevbot 1.0 GPU) — Security Note

The NVIDIA proprietary driver for GTS 430 (340.x series) has not received security patches since 2019 and is incompatible with current kernels. **Do not attempt to install it.** The Nouveau open-source driver is the correct choice — it receives ongoing kernel security maintenance. For compute/transcoding, use Bevbot 2.0's RTX PRO 500.
