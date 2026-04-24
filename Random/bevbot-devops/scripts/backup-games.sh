#!/usr/bin/env bash
# scripts/backup-games.sh
# Backs up game server worlds from Bevbot 2.0 to a local directory.
# Run from your control machine. Configure variables below.

set -euo pipefail

# ── Configure These ───────────────────────────────────────────────────────────
BEVBOT2_HOST="bevbot2"                          # SSH alias or IP
BEVBOT2_USER="your_username"
REMOTE_BASE="/home/${BEVBOT2_USER}/.local/share/gameservers"
LOCAL_BACKUP_DIR="${HOME}/backups/bevbot-games"
SSH_KEY="${HOME}/.ssh/bevbot_ed25519"
RETENTION_DAYS=30
# ─────────────────────────────────────────────────────────────────────────────

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="${LOCAL_BACKUP_DIR}/${TIMESTAMP}"

mkdir -p "${BACKUP_DIR}"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Bevbot Game Server Backup"
echo "  $(date)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Stop servers before backup to avoid corrupt world saves
echo "Stopping game servers for safe backup..."
ssh -i "${SSH_KEY}" "${BEVBOT2_USER}@${BEVBOT2_HOST}" \
  "systemctl --user stop minecraft forest starbound 2>/dev/null || true"

echo "Syncing game data..."
rsync -avz --progress \
  -e "ssh -i ${SSH_KEY}" \
  "${BEVBOT2_USER}@${BEVBOT2_HOST}:${REMOTE_BASE}/" \
  "${BACKUP_DIR}/"

echo "Restarting game servers..."
ssh -i "${SSH_KEY}" "${BEVBOT2_USER}@${BEVBOT2_HOST}" \
  "systemctl --user start minecraft 2>/dev/null || true"

echo "Cleaning up backups older than ${RETENTION_DAYS} days..."
find "${LOCAL_BACKUP_DIR}" -maxdepth 1 -type d -mtime +${RETENTION_DAYS} -exec rm -rf {} + 2>/dev/null || true

BACKUP_SIZE=$(du -sh "${BACKUP_DIR}" | cut -f1)
echo ""
echo "✓ Backup complete: ${BACKUP_DIR} (${BACKUP_SIZE})"
echo ""
