# Docker → Podman Migration Guide

## Why Podman?

| | Docker | Podman |
|---|---|---|
| Daemon | Requires root Docker daemon | Daemonless |
| Default user | Runs containers as root | Runs rootless by default |
| Security | Daemon escape = root access | No daemon to escape |
| uCore/Fedora fit | Available but not native | Native to RHEL/Fedora ecosystem |
| Compose | `docker-compose` (separate) | `podman-compose` built-in |
| Systemd integration | External | Native (Quadlets) |
| Docker API compat | Native | Via socket shim ✅ |

## Portainer with Podman

Portainer expects a Docker-compatible API socket. The `podman` Ansible role:
1. Starts `podman.socket` (user service) — exposes `podman.sock`
2. Creates a symlink at the Docker socket path
3. Portainer connects to this socket and works transparently

You will see "Docker" in Portainer's UI even though it's Podman underneath — this is expected and harmless.

## Migrating Existing Docker Compose Files

### Option A — Use podman-compose directly
```bash
# Most docker-compose.yml files work as-is
podman-compose up -d
```

### Option B — Convert to Quadlets (recommended for production)
Quadlets are Podman's native systemd integration. They're more reliable than compose for persistent services because systemd manages restart, ordering, and dependencies.

**Example: docker-compose.yml → Quadlet**

Before (docker-compose.yml):
```yaml
services:
  myapp:
    image: myimage:latest
    ports:
      - "8080:8080"
    volumes:
      - ./data:/app/data
    environment:
      - KEY=value
    restart: always
```

After (myapp.container — place in `~/.config/containers/systemd/`):
```ini
[Unit]
Description=My Application
After=network-online.target

[Container]
Image=myimage:latest
PublishPort=8080:8080
Volume=/home/user/data:/app/data:z
Environment=KEY=value

[Service]
Restart=always

[Install]
WantedBy=default.target
```

Then: `systemctl --user daemon-reload && systemctl --user start myapp`

### Attach your existing compose files

When you're ready to migrate your existing compose files, share them here and I'll convert them to Quadlets for you.

## Key Differences to Know

```bash
# Docker → Podman equivalents
docker run      → podman run
docker ps       → podman ps
docker images   → podman images
docker exec     → podman exec
docker logs     → podman logs  (or: journalctl --user -u <service>)
docker-compose  → podman-compose

# Rootless-specific
docker volume   → podman volume (stored in ~/.local/share/containers/storage/volumes/)
```

## SELinux Volume Labels

Always use `:z` or `:Z` on volume mounts for SELinux compatibility:
- `:z` — shared label (multiple containers can read)
- `:Z` — private label (only this container can read)

```bash
# Without :z you'll get "permission denied" on SELinux systems
podman run -v /home/user/data:/app/data:z myimage
```

## Auto-Updates

Podman supports automatic image updates via `podman auto-update`:

```bash
# Check for updates (dry run)
podman auto-update --dry-run

# Apply updates (restarts affected containers)
podman auto-update
```

Labels are already set on all Bevbot containers:
```ini
Label=io.containers.autoupdate=registry
```

Set up a systemd timer for automatic weekly updates:
```bash
systemctl --user enable --now podman-auto-update.timer
```
