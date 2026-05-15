# PaTech AI Workstation Bootstrap

Bootstrap-repository voor de mobiele AI-workstation `patech-wsa-01`.

Uitgangspunt:

- Windows 11 als primaire host
- WSL2 Ubuntu als technische werklaag
- Docker Desktop met WSL2-backend
- Ollama en Open WebUI voor lokale AI-runtime
- Hermes Agent als primaire agentlaag
- Honcho als lokale memory-laag
- OpenAI Codex CLI via OAuth
- Claude Code/CLI via Anthropic
- Herbruikbaar, scriptbaar en geschikt voor beheer via Gitea

## Naming convention

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

## Snelle start

1. Pak de laptop uit en voltooi Windows 11 setup.
2. Draai Windows Update en vendor firmware updates.
3. Open PowerShell als Administrator.
4. Voer uit:

```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
.\scripts\windows\00-set-hostname.ps1
.\scripts\windows\01-enable-wsl.ps1
.\scripts\windows\02-install-winget-packages.ps1
.\scripts\windows\03-windows-security-baseline.ps1
```

5. Herstart wanneer nodig.
6. Start Ubuntu en voer uit:

```bash
cd /mnt/c/path/to/ai-workstation-bootstrap
chmod +x scripts/wsl/*.sh
./scripts/wsl/00-bootstrap-ubuntu.sh
./scripts/wsl/01-dev-tools.sh
./scripts/wsl/02-ai-tools.sh
./scripts/wsl/03-hermes-agent.sh
./scripts/wsl/04-honcho.sh
./scripts/wsl/05-codex-claude.sh
./scripts/wsl/06-models-ollama.sh
./scripts/wsl/99-verify-wsl.sh
```

## Let op

Hermes Agent en Honcho kunnen afhankelijk zijn van jouw actuele eigen installatiemethode, repo of packagebron. De scripts zijn daarom bewust veilig en idempotent opgezet: ze installeren generieke dependencies, maken directories en templates aan, en falen niet hard als de exacte bron nog ingevuld moet worden.
