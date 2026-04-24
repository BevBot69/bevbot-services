# Game Servers Setup Guide

## Minecraft Java Edition

Minecraft is fully automated — the `itzg/minecraft-server` image handles everything.

**Enable and configure in `ansible/group_vars/bevbot2/main.yml`:**
```yaml
minecraft_enabled: true
minecraft_version: "latest"   # or "1.21.4", "1.20.4", etc.
minecraft_memory: "4G"        # Adjust based on available RAM
```

**Deploy:**
```bash
ansible-playbook ansible/playbooks/bevbot2.yml --tags game_servers --ask-vault-pass
```

**Manage:**
```bash
# RCON console (from bevbot2)
podman exec -it minecraft rcon-cli

# View logs
journalctl --user -u minecraft -f

# Restart
systemctl --user restart minecraft
```

---

## The Forest Dedicated Server

The Forest requires the dedicated server binary which must be obtained via Steam.

### Setup Steps

1. **Install SteamCMD on your desktop/laptop** and download the server files:
   ```bash
   steamcmd +login anonymous +app_update 556450 +quit
   ```
   App ID `556450` is The Forest Dedicated Server.

2. **Copy files to Bevbot 2.0:**
   ```bash
   rsync -avz ~/.steam/steamapps/common/TheForestDedicatedServer/ \
     your_username@bevbot2:/home/your_username/.local/share/gameservers/forest/
   ```

3. **Enable in group_vars:**
   ```yaml
   forest_enabled: true
   ```

4. **Configure the server** — edit `forest/config/` files after first run.

5. **Deploy:**
   ```bash
   ansible-playbook ansible/playbooks/bevbot2.yml --tags game_servers --ask-vault-pass
   ```

**Note:** The Forest dedicated server is a Windows binary. The container uses `cm2network/steamcmd` which includes Wine. Performance may vary.

---

## Starbound

Starbound's Linux dedicated server binary is included with your Steam purchase.

### Setup Steps

1. **Find your Starbound installation** (Steam → Right click → Manage → Browse local files)

2. **Copy the Linux server files to Bevbot 2.0:**
   ```bash
   rsync -avz /path/to/Starbound/linux/ \
     your_username@bevbot2:/home/your_username/.local/share/gameservers/starbound/
   ```
   You need: `starbound_server`, `libsteam_api.so`, and the `assets/` directory.

3. **Configure** — edit `starbound/storage/starbound_server.config`:
   ```json
   {
     "serverPort": 21025,
     "maxPlayers": 8,
     "serverName": "Bevbot Starbound"
   }
   ```

4. **Enable in group_vars:**
   ```yaml
   starbound_enabled: true
   ```

5. **Deploy:**
   ```bash
   ansible-playbook ansible/playbooks/bevbot2.yml --tags game_servers --ask-vault-pass
   ```

---

## Managing All Game Servers

```bash
# Check status of all game services
systemctl --user status minecraft forest starbound

# View logs
journalctl --user -u minecraft -f
journalctl --user -u forest -f
journalctl --user -u starbound -f

# Stop a server gracefully
systemctl --user stop minecraft

# Enable/disable autostart
systemctl --user enable minecraft
systemctl --user disable forest
```

## Backups

Game world data is stored under `~/.local/share/gameservers/`. Back up regularly:

```bash
# Quick backup script (run on your control machine)
scripts/backup-games.sh
```

See `scripts/backup-games.sh` for a cron-friendly rsync backup to an external location.
