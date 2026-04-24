#!/usr/bin/env bash
# scripts/generate-ssh-keys.sh
# Generates Ed25519 SSH keys for all your devices and prints the public keys
# to add to group_vars/all/main.yml → authorized_keys.
#
# Run this on your CONTROL machine (laptop/desktop), not on the servers.

set -euo pipefail

KEY_DIR="${HOME}/.ssh"
KEY_NAME="bevbot_ed25519"
KEY_PATH="${KEY_DIR}/${KEY_NAME}"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Bevbot SSH Key Generator"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [[ -f "${KEY_PATH}" ]]; then
  echo "Key already exists at ${KEY_PATH}"
  echo "Public key:"
  cat "${KEY_PATH}.pub"
else
  DEVICE_NAME=$(hostname)
  ssh-keygen -t ed25519 -C "${DEVICE_NAME}@bevbot" -f "${KEY_PATH}" -N ""
  echo ""
  echo "✓ Key generated: ${KEY_PATH}"
  echo ""
  echo "Add this public key to ansible/group_vars/all/main.yml → authorized_keys:"
  echo "────────────────────────────────────────"
  cat "${KEY_PATH}.pub"
  echo "────────────────────────────────────────"
fi

echo ""
echo "Next: add the public key above to group_vars/all/main.yml, then run:"
echo "  ansible-playbook ansible/playbooks/common.yml --tags ssh --ask-vault-pass"
