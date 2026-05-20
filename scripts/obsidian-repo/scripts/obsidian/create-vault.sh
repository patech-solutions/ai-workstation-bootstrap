#!/usr/bin/env bash
set -euo pipefail

export LANG=en_US.UTF-8

: "${OBSIDIAN_VAULT_DIR:?OBSIDIAN_VAULT_DIR is not set}"

mkdir -p "${OBSIDIAN_VAULT_DIR}"

mkdir -p \
  "${OBSIDIAN_VAULT_DIR}/00-inbox" \
  "${OBSIDIAN_VAULT_DIR}/01-clients" \
  "${OBSIDIAN_VAULT_DIR}/02-projects" \
  "${OBSIDIAN_VAULT_DIR}/03-architecture" \
  "${OBSIDIAN_VAULT_DIR}/04-research" \
  "${OBSIDIAN_VAULT_DIR}/05-templates" \
  "${OBSIDIAN_VAULT_DIR}/06-ai-memory/clients" \
  "${OBSIDIAN_VAULT_DIR}/06-ai-memory/technical" \
  "${OBSIDIAN_VAULT_DIR}/06-ai-memory/preferences" \
  "${OBSIDIAN_VAULT_DIR}/06-ai-memory/architecture" \
  "${OBSIDIAN_VAULT_DIR}/06-ai-memory/sessions" \
  "${OBSIDIAN_VAULT_DIR}/07-publish/staging" \
  "${OBSIDIAN_VAULT_DIR}/08-playbooks" \
  "${OBSIDIAN_VAULT_DIR}/99-archive"

cat > "${OBSIDIAN_VAULT_DIR}/README.md" <<'EOF'
# PaTech AI Workspace

Lokale Obsidian vault voor AI-assisted werk.

## Structuur

- 00-inbox → tijdelijke AI output
- 01-clients → klantcontext
- 02-projects → actieve projecten
- 03-architecture → architectuurkennis
- 04-research → onderzoeken
- 05-templates → templates
- 06-ai-memory → Hermes memory
- 07-publish → review/publicatie
- 08-playbooks → herbruikbare workflows
- 99-archive → archief

## Werkregels

- AI output eerst naar inbox/staging
- Geen directe publicatie zonder review
- Kleine markdown bestanden prefereren
- Git gebruiken voor alle wijzigingen
EOF

echo "Vault structure created."