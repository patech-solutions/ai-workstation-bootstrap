#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "../config/obsidian.env"

#"${BASE_DIR}/scripts/obsidian/install-obsidian.sh"
"${BASE_DIR}/scripts/obsidian/create-vault.sh"
"${BASE_DIR}/scripts/obsidian/create-templates.sh"
"${BASE_DIR}/scripts/obsidian/init-git.sh"

echo ""
echo "======================================="
echo "PaTech AI Workspace initialized"
echo "Vault: ${OBSIDIAN_VAULT_DIR}"
echo "======================================="
