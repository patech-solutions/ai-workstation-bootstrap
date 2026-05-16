# PaTech AI Workstation Implementatieplan

## Systeeminformatie

| Onderdeel | Waarde |
|---|---|
| Workstation naam | `patech-wsa-01` |
| Platform | Windows 11 Pro |
| Linux laag | WSL2 Ubuntu |
| Repository | `ai-workstation-bootstrap` |
| Git platform | Gitea |
| Interne Gitea URL | `http://ugreendxp2800.local:3000` |

---

# Doelarchitectuur

## Windows 11 Host

Windows 11 is de primaire hostlaag voor:

- hardware drivers
- NVIDIA GPU ondersteuning
- Docker Desktop
- WSL2
- lokale desktop tooling
- Git bootstrap
- vendor firmware/BIOS tooling

## WSL2 Ubuntu

WSL2 Ubuntu is de technische werklaag voor:

- development tooling
- AI tooling
- Hermes Agent
- Honcho memory
- Codex CLI
- Claude tooling
- Docker CLI workflows
- scripts en automation

---

# Naming Conventie

```text
<organisatie>-<rol>-<nummer>

patech-wsa-01   = AI workstation
patech-web-01   = webserver
patech-rp-01    = reverse proxy
patech-git-01   = Gitea
patech-doc-01   = Outline
patech-ai-01    = centrale AI-services
```

Zones horen bij DNS, firewall, IaC-tags of documentatie, niet in de hostname zelf.

## Hostnaam

Windows hostname:

```text
patech-wsa-01
```

WSL hostname:

```text
patech-wsa-01-wsl
```

SSH key comment:

```text
pascal@patech-wsa-01
```

---

# Repository Workflow

## Repository naam

```text
ai-workstation-bootstrap
```

## Repository clonen op patech-wsa-01

Maak eerst een lokale werkmap:

```powershell
mkdir C:\git
cd C:\git
```

Clone via interne Gitea URL:

```powershell
git clone http://ugreendxp2800.local:3000/Paikke/ai-workstation-bootstrap.git
cd ai-workstation-bootstrap
```

Later kan de remote naar SSH worden gezet:

```powershell
git remote set-url origin git@ugreendxp2800.local:Paikke/ai-workstation-bootstrap.git
```

---

# Verwachte Repository Structuur

```text
ai-workstation-bootstrap/
├─ README.md
├─ docs/
│  ├─ 00-checklist.md
│  ├─ 01-windows.md
│  ├─ 02-wsl.md
│  ├─ 03-ai-stack.md
│  ├─ 04-models.md
│  └─ 05-hermes-honcho-codex-claude.md
├─ scripts/
│  ├─ windows/
│  │  ├─ 00-set-hostname.ps1
│  │  ├─ 01-enable-wsl.ps1
│  │  ├─ 02-install-winget-packages.ps1
│  │  ├─ 03-windows-security-baseline.ps1
│  │  ├─ 04-remove-windows-bloatware.ps1
│  │  ├─ 90-bootstrap-windows.ps1
│  │  └─ 99-verify-windows.ps1
│  └─ wsl/
│     ├─ 00-bootstrap-ubuntu.sh
│     ├─ 01-dev-tools.sh
│     ├─ 02-ai-tools.sh
│     ├─ 03-hermes-agent.sh
│     ├─ 04-honcho.sh
│     ├─ 05-codex-claude.sh
│     ├─ 06-models-ollama.sh
│     ├─ 90-bootstrap-wsl.sh
│     └─ 99-verify-wsl.sh
├─ config/
│  ├─ winget-packages.txt
│  ├─ ollama-models.txt
│  ├─ gitconfig.template
│  ├─ ssh-config.template
│  ├─ hermes-config.template.yaml
│  └─ honcho-config.template.yaml
└─ compose/
   ├─ open-webui.compose.yml
   └─ litellm.compose.yml
```

---

# Eerste Hardware Configuratie

Direct na uitpakken:

```text
[ ] Windows activatie
[ ] Microsoft-account overslaan indien gewenst
[ ] Lokaal account aanmaken
[ ] Windows Update volledig uitvoeren
[ ] Reboot
[ ] Nogmaals Windows Update controleren
[ ] BIOS/Firmware updates installeren
[ ] NVIDIA Studio Driver installeren
[ ] BitLocker activeren
[ ] Windows Hello configureren
[ ] Repository clonen
```

---

# Windows Bootstrap Runner

## Doel

In plaats van script voor script uitvoeren is er een runner-script:

```text
scripts/windows/90-bootstrap-windows.ps1
```

Dit voert de Windows-fases uit in logische volgorde en gebruikt marker files in:

```text
.bootstrap-state
```

Na een reboot kan hetzelfde script opnieuw worden uitgevoerd. Reeds afgeronde fases worden overgeslagen.

## Uitvoeren

Open PowerShell als Administrator:

```powershell
cd C:\git\ai-workstation-bootstrap
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
.\scripts\windows\90-bootstrap-windows.ps1
```

## Fases

```text
00-set-hostname.ps1
01-enable-wsl.ps1
02-install-winget-packages.ps1
03-windows-security-baseline.ps1
04-remove-windows-bloatware.ps1
99-verify-windows.ps1
```

---

# Windows Hostname

Script:

```text
scripts/windows/00-set-hostname.ps1
```

Functie:

- controleert huidige computernaam
- wijzigt computernaam naar `patech-wsa-01`
- meldt of reboot nodig is

Handmatig:

```powershell
Rename-Computer -NewName "patech-wsa-01" -Restart
```

---

# WSL Activeren

Script:

```text
scripts/windows/01-enable-wsl.ps1
```

Functie:

- installeert Ubuntu 24.04 via WSL
- zet WSL default version op 2

Uitvoeren via runner of los:

```powershell
.\scripts\windows\01-enable-wsl.ps1
```

---

# Windows Packages

Script:

```text
scripts/windows/02-install-winget-packages.ps1
```

Packagebron:

```text
config/winget-packages.txt
```

Voorbeelden:

```text
Git.Git
Microsoft.VisualStudioCode
Docker.DockerDesktop
Microsoft.PowerShell
OpenJS.NodeJS.LTS
Python.Python.3.12
Ollama.Ollama
7zip.7zip
```

---

# Windows Security Baseline

Script:

```text
scripts/windows/03-windows-security-baseline.ps1
```

Taken:

- Windows Firewall aanzetten
- BitLocker status tonen
- RDP uitschakelen tenzij expliciet nodig

Checklist:

```text
[ ] BitLocker enabled
[ ] Windows Defender enabled
[ ] Windows Firewall enabled
[ ] Secure Boot enabled
[ ] BIOS password ingesteld
[ ] NVIDIA Studio Driver gebruikt
```

---

# Windows Bloatware en Gaming Noise Verwijderen

Script:

```text
scripts/windows/04-remove-windows-bloatware.ps1
```

## Dry run

```powershell
.\scripts\windows\04-remove-windows-bloatware.ps1 -WhatIfOnly
```

## Echt uitvoeren

```powershell
.\scripts\windows\04-remove-windows-bloatware.ps1
```

## Wat doet dit script?

Het script verwijdert of beperkt onder andere:

- Xbox apps
- Game Bar
- Game DVR
- consumer suggestions
- Widgets/Chat taakbalkruis
- Spotify/TikTok/Disney/Facebook/Instagram trial apps indien aanwezig
- consumer Teams
- onnodige AppX consumer packages
- MSI/SteelSeries/Nahimic autostart-noise waar mogelijk
- geplande taken voor overlays waar mogelijk

## Wat doet dit script bewust niet?

Het verwijdert niet agressief:

- Microsoft Store
- App Installer / winget
- Windows Terminal
- drivers
- firmware tooling
- NVIDIA tooling
- essentiële MSI hardware support

## Keyboard RGB

Keyboard RGB is meestal niet betrouwbaar generiek te scripten omdat MSI/SteelSeries verlichting via embedded controller of vendor app loopt.

Het script maakt daarom een duidelijke manual follow-up note aan:

```text
%USERPROFILE%\patech-setup-notes\keyboard-rgb-manual-check.txt
```

Aanbevolen instelling:

```text
SteelSeries GG / MSI Center
Keyboard illumination = Off
of Static White, Low brightness
Startup/idle effects = Off
```

---

# Docker Desktop Configuratie

Instellingen:

```text
Use WSL2 based engine = enabled
WSL integration for Ubuntu = enabled
```

---

# WSL Bootstrap Runner

## Doel

WSL heeft ook een runner-script:

```text
scripts/wsl/90-bootstrap-wsl.sh
```

Dit voert de Linux/AI-fases uit en gebruikt marker files in:

```text
.bootstrap-state-wsl
```

## Uitvoeren

Na eerste Ubuntu start:

```bash
cd /mnt/c/git/ai-workstation-bootstrap
chmod +x scripts/wsl/*.sh
./scripts/wsl/90-bootstrap-wsl.sh
```

## Fases

```text
00-bootstrap-ubuntu.sh
01-dev-tools.sh
02-ai-tools.sh
03-hermes-agent.sh
04-honcho.sh
05-codex-claude.sh
06-models-ollama.sh
99-verify-wsl.sh
```

---

# AI Stack

De workstation bevat:

- Ollama
- Open WebUI
- Hermes Agent
- Honcho memory
- Codex CLI
- Claude tooling

---

# Hermes Agent

Doel:

- primaire agentlaag
- model routing
- provider fallback
- memory integratie
- tooling orchestration
- AI workflow management

Script:

```text
scripts/wsl/03-hermes-agent.sh
```

Let op: exacte Hermes-installatiebron kan afhankelijk zijn van jouw actuele eigen repo/packagebron.

---

# Honcho Memory

Doel:

- lokale AI memory laag
- context persistence
- memory retrieval
- agent geheugenlaag

Script:

```text
scripts/wsl/04-honcho.sh
```

---

# Codex CLI

Script:

```text
scripts/wsl/05-codex-claude.sh
```

Voorbeeldinstallatie:

```bash
npm install -g @openai/codex
codex login
```

---

# Claude Tooling

Script:

```text
scripts/wsl/05-codex-claude.sh
```

Voorbeeldinstallatie:

```bash
npm install -g @anthropic-ai/claude-code
```

Let op: Claude OAuth en billing kunnen aanvullende activatie vanuit Anthropic vereisen.

---

# Ollama Modellen

Modelbestand:

```text
config/ollama-models.txt
```

Voorbeeld:

```text
qwen3:8b
qwen3:14b
mistral-small:latest
devstral:latest
nomic-embed-text:latest
```

Script:

```text
scripts/wsl/06-models-ollama.sh
```

---

# Open WebUI

Compose bestand:

```text
compose/open-webui.compose.yml
```

Starten:

```bash
docker compose -f compose/open-webui.compose.yml up -d
```

---

# Verificatie

## Windows

```powershell
.\scripts\windows\99-verify-windows.ps1
```

Controleert:

- hostname
- WSL
- Docker
- NVIDIA
- Ollama

## WSL

```bash
./scripts/wsl/99-verify-wsl.sh
```

Controleert:

- OS
- Docker
- Python
- Node
- uv
- Ollama
- Codex/Claude waar aanwezig

---

# Eerste Dag Workflow

```text
[ ] Laptop uitpakken
[ ] Windows setup afronden
[ ] Windows updates uitvoeren
[ ] BIOS/Firmware updates uitvoeren
[ ] NVIDIA Studio Driver installeren
[ ] Git installeren indien nog nodig
[ ] Repository clonen naar C:\git
[ ] PowerShell als Administrator openen
[ ] 90-bootstrap-windows.ps1 uitvoeren
[ ] Reboot waar nodig
[ ] 90-bootstrap-windows.ps1 opnieuw uitvoeren tot afgerond
[ ] Ubuntu openen
[ ] 90-bootstrap-wsl.sh uitvoeren
[ ] Docker Desktop WSL integration controleren
[ ] Open WebUI starten
[ ] Verificatie scripts uitvoeren
[ ] Keyboard RGB handmatig uitzetten indien nodig
```

---

# Recovery Concept

Nieuwe machine of herinstallatie:

1. Windows basisinstallatie afronden
2. Git installeren indien nodig
3. Repository clonen
4. `90-bootstrap-windows.ps1` uitvoeren
5. Reboot waar nodig
6. Ubuntu openen
7. `90-bootstrap-wsl.sh` uitvoeren
8. Configuratie/secrets herstellen
9. Verificatie scripts uitvoeren

Doel:

```text
Workstation-as-Code in plaats van handmatige inrichting.
```

Voordelen:

- reproduceerbaarheid
- snellere recovery
- consistente configuratie
- documenteerbare infrastructuur
- schaalbaarheid naar meerdere AI nodes
- eenvoudiger beheer
