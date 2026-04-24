#!/usr/bin/env bash
# scripts/setup-auto-update.sh
# Run ON a Bevbot host to enable weekly automatic container image updates.
# Podman will pull updated images and restart affected containers.

set -euo pipefail

echo "Enabling Podman auto-update timer..."

# Enable the systemd user timer
systemctl --user enable --now podman-auto-update.timer

# Show next scheduled run
echo ""
echo "Auto-update timer status:"
systemctl --user status podman-auto-update.timer --no-pager

echo ""
echo "Next scheduled run:"
systemctl --user list-timers podman-auto-update.timer --no-pager

echo ""
echo "To manually trigger an update now:"
echo "  podman auto-update"
echo ""
echo "To check what WOULD be updated (dry run):"
echo "  podman auto-update --dry-run"
