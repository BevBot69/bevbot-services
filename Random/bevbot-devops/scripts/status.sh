#!/usr/bin/env bash
# scripts/status.sh
# Quick status check — run ON a Bevbot host to see all service states.

set -euo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

check_service() {
  local name="$1"
  local scope="${2:-user}"  # user or system
  if systemctl --"${scope}" is-active --quiet "${name}" 2>/dev/null; then
    echo -e "  ${GREEN}●${NC} ${name}"
  elif systemctl --"${scope}" is-enabled --quiet "${name}" 2>/dev/null; then
    echo -e "  ${RED}✗${NC} ${name} (enabled but not running)"
  else
    echo -e "  ${YELLOW}○${NC} ${name} (disabled)"
  fi
}

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Bevbot Service Status — $(hostname)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo ""
echo "System Services:"
check_service tailscaled system
check_service sshd system
check_service firewalld system
check_service fail2ban system
check_service cockpit.socket system

echo ""
echo "Container Services (rootless):"
check_service podman.socket user
check_service portainer user
check_service immich-server user 2>/dev/null || true
check_service jellyfin user 2>/dev/null || true
check_service minecraft user 2>/dev/null || true
check_service forest user 2>/dev/null || true
check_service starbound user 2>/dev/null || true
check_service ollama user 2>/dev/null || true

echo ""
echo "Tailscale:"
if command -v tailscale &>/dev/null; then
  TS_STATUS=$(tailscale status --json 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('BackendState','unknown'))" 2>/dev/null || echo "unknown")
  TS_IP=$(tailscale ip -4 2>/dev/null || echo "not connected")
  echo "  State: ${TS_STATUS}"
  echo "  IP:    ${TS_IP}"
fi

echo ""
echo "Mounts:"
if mountpoint -q /mnt/nasraid 2>/dev/null; then
  echo -e "  ${GREEN}●${NC} /mnt/nasraid (NAS RAID)"
else
  echo -e "  ${YELLOW}○${NC} /mnt/nasraid (not mounted)"
fi
if mountpoint -q /mnt/bevbot_media 2>/dev/null; then
  echo -e "  ${GREEN}●${NC} /mnt/bevbot_media (Bevbot SMB)"
else
  echo -e "  ${YELLOW}○${NC} /mnt/bevbot_media (not mounted)"
fi

echo ""
echo "Podman Summary:"
if command -v podman &>/dev/null; then
  RUNNING=$(podman ps --format "{{.Names}}" 2>/dev/null | wc -l)
  echo "  Running containers: ${RUNNING}"
  podman ps --format "  {{.Names}}\t{{.Status}}" 2>/dev/null || true
fi

echo ""
