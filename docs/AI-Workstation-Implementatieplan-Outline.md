# Implementatieplan mobiele AI-workstation — patech-wsa-01

## Doel

Deze workstation wordt ingericht als mobiele AI/demo/development machine voor PaTech Solutions.

Uitgangspunten:

- Windows 11 als primaire host
- WSL2 Ubuntu als technische werklaag
- Docker Desktop met WSL2-backend
- Lokale AI-runtime via Ollama
- Lokale AI-interface via Open WebUI
- Hermes Agent als primaire agentlaag
- Honcho als lokale memory-laag
- Codex CLI via OpenAI OAuth
- Claude CLI/Claude Code via Anthropic
- Beheer en herhaalbaarheid via Gitea

## Naamgeving

Hostname:

```text
patech-wsa-01
```

Conventie:

```text
<organisatie>-<rol>-<nummer>
```

Voorbeelden:

```text
patech-web-01   = webserver
patech-rp-01    = reverse proxy
patech-git-01   = Gitea
patech-doc-01   = Outline
patech-wsa-01   = AI workstation
```

Zones worden niet in de hostname opgenomen. Zones horen in DNS, firewallregels, tags, documentatie of IaC.

## Implementatiefasen

### Fase 1 — Windows basis

- Windows 11 setup afronden
- Windows Update uitvoeren
- Firmware/BIOS updates uitvoeren
- NVIDIA Studio Driver installeren
- Hostname instellen op `patech-wsa-01`
- BitLocker inschakelen
- Firewall en Defender controleren

### Fase 2 — Tooling

Installatie via winget:

- Git
- VS Code
- Docker Desktop
- PowerShell 7
- Windows Terminal
- Python
- Node.js LTS
- Ollama
- 7-Zip
- WinSCP

### Fase 3 — WSL2

- Ubuntu 24.04 installeren
- WSL2 default maken
- Hostname in WSL instellen op `patech-wsa-01-wsl`
- Git configureren
- SSH key genereren
- Gitea toegang testen

### Fase 4 — AI runtime

- Ollama installeren/testen
- Modellen pullen
- Open WebUI via Docker Compose starten
- GPU zichtbaarheid testen

### Fase 5 — Agent tooling

- Hermes Agent voorbereiden/configureren
- Honcho voorbereiden/configureren
- Codex CLI installeren
- Claude CLI installeren

### Fase 6 — Validatie

Controleer:

```bash
nvidia-smi
docker version
docker compose version
ollama list
git remote -v
```

Open WebUI:

```text
http://localhost:3000
```

## Herhaalbaarheid

Alle stappen zijn ondergebracht in scripts:

```text
scripts/windows/
scripts/wsl/
config/
compose/
docs/
```

Deze repository kan in Gitea worden geplaatst en later worden uitgebreid met:

- Ansible
- Terraform/OpenTofu
- PowerShell DSC
- Chocolatey of winget pinning
- Backup/restore scripts
- Gitea Actions runner
