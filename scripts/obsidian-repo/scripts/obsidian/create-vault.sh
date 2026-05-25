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

cat > "${OBSIDIAN_VAULT_DIR}/AI-Workspace-Rules.md" <<'EOF'
# PaTech AI Workspace Regels

## Algemeen

Deze Obsidian vault is de primaire AI-ondersteunde werkruimte voor PaTech Solutions.

De vault bevat:
- klantdocumentatie
- architectuurnotities
- projectonderzoek
- AI-geheugen
- conceptrapporten
- herbruikbare sjablonen

Alle inhoud is op markdown gebaseerd.

---

# Mapgebruik

## Leestoegang

Toegestaan:
- 01-clients
- 02-projects
- 03-architecture
- 04-research
- 05-templates
- 08-playbooks

## Schrijftoegang

Toegestaan:
- 00-inbox
- 06-ai-memory
- 07-publish/staging

## Verboden

Nooit benaderen of wijzigen:
- .obsidian
- .git
- .secrets
- .private

---

# Bestandsbeheer

- Verwijder nooit bestanden
- Overschrijf nooit bestaande bestanden
- Maak bij voorkeur nieuwe markdown-bestanden aan
- Gebruik UTF-8 codering
- Houd bestanden klein en gefocust
- Gebruik sjablonen waar mogelijk
- Sla tijdelijke AI-uitvoer op in 00-inbox

---

# Klantveiligheid

- Nooit vertrouwelijke informatie blootleggen
- Nooit klantgegevens verzinnen
- Aannames duidelijk markeren
- Voorkeur voor gestructureerde markdown

---

# Werkwijze

1. Lees relevante project- en klantnotities
2. Lees relevante sjablonen
3. Genereer concept in 00-inbox
4. Mens beoordeelt de inhoud
5. Mens verplaatst inhoud naar permanente mappen

---

# Stijl

- Technisch maar leesbaar
- Gestructureerde secties
- Voorkeur voor opsommingslijsten
- Tabellen voor risico's en vergelijkingen
- Beknopte samenvattingen
EOF

cat > "${OBSIDIAN_VAULT_DIR}/.hermes.md" <<EOF
# PaTech AI Workspace

Dit is de Obsidian vault van ${OBSIDIAN_USER_DISPLAY_NAME} (${OBSIDIAN_COMPANY_NAME}).
Vault locatie: \`${OBSIDIAN_VAULT_DIR}\`

Lees de volledige werkregels in: \`${OBSIDIAN_VAULT_DIR}/AI-Workspace-Rules.md\`

## Mappen en paden

| Map | Absoluut pad | Toegang |
|---|---|---|
| Inbox (AI output) | \`${OBSIDIAN_VAULT_DIR}/00-inbox/\` | Schrijven |
| Klanten | \`${OBSIDIAN_VAULT_DIR}/01-clients/\` | Lezen |
| Projecten | \`${OBSIDIAN_VAULT_DIR}/02-projects/\` | Lezen |
| Architectuur | \`${OBSIDIAN_VAULT_DIR}/03-architecture/\` | Lezen |
| Onderzoek | \`${OBSIDIAN_VAULT_DIR}/04-research/\` | Lezen |
| Templates | \`${OBSIDIAN_VAULT_DIR}/05-templates/\` | Lezen |
| Playbooks | \`${OBSIDIAN_VAULT_DIR}/08-playbooks/\` | Lezen |
| Memory    | \`${OBSIDIAN_VAULT_DIR}/06-ai-memory/\` | Schrijven |

## Werkregels

- Schrijf AI-output altijd naar \`${OBSIDIAN_VAULT_DIR}/00-inbox/\`
- Nooit bestanden verwijderen of overschrijven
- Gebruik templates uit \`05-templates/\` bij het aanmaken van nieuwe documenten
- Nooit \`.obsidian/\`, \`.git/\`, \`.secrets/\` of \`.private/\` aanraken

## Workflow

1. Lees relevante project- of klantnotities
2. Lees het bijpassende template
3. Maak een draft aan in \`${OBSIDIAN_VAULT_DIR}/00-inbox/\`
4. Pascal beoordeelt en promoot naar de permanente map

## Sync

\`00-inbox/\` en \`06-ai-memory/\` zijn lokaal-only (niet gesynchroniseerd via git).
EOF

echo "Vault structure created."