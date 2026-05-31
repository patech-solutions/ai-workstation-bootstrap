#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_ROOT="$(cd "${BASE_DIR}/../.." && pwd)"
BOOTSTRAP_ENV="${REPO_ROOT}/config/bootstrap.env"

if [[ ! -f "$BOOTSTRAP_ENV" ]]; then
    echo "ERROR: $BOOTSTRAP_ENV niet gevonden."
    echo "Kopieer config/bootstrap.env.example naar config/bootstrap.env en vul in."
    exit 1
fi
source "$BOOTSTRAP_ENV"

# Windows-gebruikersnaam afleiden als niet opgegeven
if [[ -z "${BOOTSTRAP_WINDOWS_USER:-}" ]]; then
    BOOTSTRAP_WINDOWS_USER="$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r' || echo "${USER}")"
fi

# Placeholders invullen in obsidian.env
OBSIDIAN_ENV="${BASE_DIR}/config/obsidian.env"
sed \
    -e "s|__BOOTSTRAP_WINDOWS_USER__|${BOOTSTRAP_WINDOWS_USER}|g" \
    -e "s|__BOOTSTRAP_OBSIDIAN_VAULT_SUBDIR__|${BOOTSTRAP_OBSIDIAN_VAULT_SUBDIR:-AI-Workspace}|g" \
    -e "s|__BOOTSTRAP_GIT_USERNAME__|${BOOTSTRAP_GIT_USERNAME}|g" \
    -e "s|__BOOTSTRAP_USER_EMAIL__|${BOOTSTRAP_USER_EMAIL}|g" \
    -e "s|__BOOTSTRAP_USER_FULLNAME__|${BOOTSTRAP_USER_FULLNAME}|g" \
    -e "s|__BOOTSTRAP_COMPANY_NAME__|${BOOTSTRAP_COMPANY_NAME}|g" \
    "${OBSIDIAN_ENV}" > /tmp/obsidian.env.rendered
source /tmp/obsidian.env.rendered

"${BASE_DIR}/scripts/obsidian/create-vault.sh"
"${BASE_DIR}/scripts/obsidian/create-templates.sh"
"${BASE_DIR}/scripts/obsidian/init-git.sh"

echo ""
echo "======================================="
echo "AI Workspace initialized"
echo "Vault: ${OBSIDIAN_VAULT_DIR}"
echo "======================================="
