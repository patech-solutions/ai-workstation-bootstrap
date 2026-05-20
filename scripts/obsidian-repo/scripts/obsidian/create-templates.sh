#!/usr/bin/env bash
set -euo pipefail

export LANG=en_US.UTF-8

: "${OBSIDIAN_VAULT_DIR:?OBSIDIAN_VAULT_DIR is not set}"

TEMPLATE_DIR="${OBSIDIAN_VAULT_DIR}/05-templates"

mkdir -p "${TEMPLATE_DIR}"

cat > "${TEMPLATE_DIR}/template-klantrapport.md" <<'EOF'
---
type: client-report
client:
project:
date:
status: draft
---

# Managementsamenvatting

# Aanleiding

# Huidige situatie

# Observaties

# Risico's

| Risico | Impact | Kans | Advies |
|---|---|---|---|

# Aanbevelingen

# Architectuuradvies

# Actiepunten

| Actie | Eigenaar | Prioriteit | Deadline |
|---|---|---|---|

# Openstaande vragen
EOF

cat > "${TEMPLATE_DIR}/template-klantgesprek.md" <<'EOF'
---
type: meeting-note
client:
project:
date:
participants:
---

# Context

# Besproken onderwerpen

# Technische situatie

# Problemen

# Mogelijke oplossingen

# Actiepunten

| Actie | Eigenaar | Deadline |
|---|---|---|

# Follow-up
EOF

cat > "${TEMPLATE_DIR}/template-adr.md" <<'EOF'
---
type: adr
status: proposed
date:
---

# Architectuurbesluit

## Context

## Besluit

## Alternatieven

## Consequenties

### Positief

### Negatief

## Risico's
EOF

cat > "${TEMPLATE_DIR}/template-research.md" <<'EOF'
---
type: research
topic:
date:
---

# Onderzoeksvraag

# Samenvatting

# Bevindingen

# Vergelijking

| Optie | Voordelen | Nadelen |
|---|---|---|

# Conclusie

# Vervolgstappen
EOF

cat > "${TEMPLATE_DIR}/template-hermes-memory.md" <<'EOF'
---
type: hermes-memory
scope:
date:
---

# Context

# Relevantie

# Wanneer gebruiken

# Beperkingen
EOF

cat > "${TEMPLATE_DIR}/template-playbook.md" <<'EOF'
---
type: playbook
domain:
date:
---

# Doel

# Benodigdheden

# Procedure

1.
2.
3.

# Validatie

# Veelvoorkomende fouten
EOF

echo "Templates created."