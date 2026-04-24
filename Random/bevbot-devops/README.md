# Bevbot DevOps

Infrastructure-as-Code for the Bevbot homelab. All configuration is managed via Ansible with Podman containers, Portainer CE, Tailscale, and Cockpit.

## Servers

| Host | Role | OS | Key Services |
|---|---|---|---|
| `bevbot` (Bevbot 1.0) | NAS / Primary | uCore | Immich, SMB/RAID NAS, Portainer, Cockpit |
| `bevbot2` (Bevbot 2.0) | Compute / Media | uCore | Jellyfin, Game Servers, Ollama (ad-hoc), Portainer, Cockpit |

---

## Quick Start

### 1. Prerequisites (on your control machine)

```bash
pip install ansible
ansible-galaxy install -r requirements.yml
```

### 2. Configure inventory

Copy and edit the inventory to match your actual IPs/hostnames:

```bash
cp ansible/inventory/hosts.example.yml ansible/inventory/hosts.yml
# Edit hosts.yml with your IPs and tailscale node names
```

### 3. Configure secrets

```bash
cp ansible/group_vars/all/vault.example.yml ansible/group_vars/all/vault.yml
ansible-vault encrypt ansible/group_vars/all/vault.yml
# Edit with: ansible-vault edit ansible/group_vars/all/vault.yml
```

### 4. Deploy

```bash
# Bootstrap both hosts (base OS hardening, SSH, Tailscale, Podman, Portainer, Cockpit)
ansible-playbook ansible/playbooks/site.yml --ask-vault-pass

# Bootstrap only Bevbot 1.0
ansible-playbook ansible/playbooks/bevbot.yml --ask-vault-pass

# Bootstrap only Bevbot 2.0
ansible-playbook ansible/playbooks/bevbot2.yml --ask-vault-pass

# Deploy a specific service
ansible-playbook ansible/playbooks/site.yml --tags immich --ask-vault-pass
```

---

## Architecture

```
Control Machine (your laptop)
        │ Ansible over SSH / Tailscale SSH
        ├─────────────────────────────────────┐
        ▼                                     ▼
   bevbot (1.0)                         bevbot2 (2.0)
   uCore / Podman                       uCore / Podman
   ├─ Cockpit                           ├─ Cockpit
   ├─ Portainer CE                      ├─ Portainer CE
   ├─ Tailscale                         ├─ Tailscale
   ├─ Immich (photos)                   ├─ Jellyfin (media via SMB→bevbot)
   └─ RAID NAS (SMB)                    ├─ Game Servers (Minecraft, etc.)
                                        └─ Ollama (ad-hoc)
```

## SSH Access

All SSH is locked down to key-based auth only. Tailscale SSH is the **recommended** path — it uses ACLs in your tailnet to control who can connect to what.

See [docs/ssh.md](docs/ssh.md) for full setup guide.

## Security Notes

- Password authentication disabled on both hosts
- Root login disabled
- Tailscale SSH uses ACL-controlled device trust
- All secrets managed via `ansible-vault`
- Podman runs **rootless** containers by default
- UFW/nftables firewall enabled — only Tailscale, SSH (port-limited), Cockpit, and LAN services exposed
- See [docs/security.md](docs/security.md) for full security posture

## GPU Notes

### Bevbot 1.0 — GTS 430
The GTS 430 uses the legacy Nouveau driver on modern kernels. NVIDIA dropped proprietary support at driver 340.x which is not compatible with current kernels. **Recommendation:** Leave it on Nouveau (passable for display, useless for compute). Not worth the effort for media transcoding — use CPU transcoding in Jellyfin on bevbot2 instead.

### Bevbot 2.0 — RTX PRO 500 Blackwell
Full NVIDIA Container Toolkit support via CDI in Podman. See the `nvidia` role. Ollama will auto-detect the GPU.

## Repo Layout

```
bevbot-devops/
├── ansible/
│   ├── inventory/          # Host definitions
│   ├── group_vars/         # Variables (all, bevbot, bevbot2)
│   ├── roles/              # Reusable roles
│   │   ├── base/           # OS hardening, firewall, updates
│   │   ├── ssh/            # OpenSSH hardening
│   │   ├── tailscale/      # Tailscale install + config
│   │   ├── podman/         # Podman + rootless setup
│   │   ├── portainer/      # Portainer CE container
│   │   ├── cockpit/        # Cockpit web console
│   │   ├── immich/         # Immich photo server
│   │   ├── jellyfin/       # Jellyfin media server
│   │   ├── smb_client/     # Mount bevbot SMB share on bevbot2
│   │   ├── nvidia/         # NVIDIA CDI + container toolkit
│   │   ├── ollama/         # Ollama LLM server (ad-hoc)
│   │   └── game_servers/   # Minecraft, The Forest, Starbound
│   └── playbooks/          # Top-level plays
├── docs/                   # Extended documentation
└── scripts/                # Helper shell scripts
```
