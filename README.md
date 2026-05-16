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

## Repository clonen op de workstation

Maak eerst een lokale werkmap aan:

```powershell
mkdir C:\git
cd C:\git
```

Clone via interne Gitea HTTP URL:

```powershell
git clone http://ugreendxp2800.local:3000/Paikke/ai-workstation-bootstrap.git
cd ai-workstation-bootstrap
```

Later kan dit naar SSH worden omgezet:

```powershell
git remote set-url origin git@ugreendxp2800.local:Paikke/ai-workstation-bootstrap.git
```

## Snelle Windows-start

Open PowerShell als Administrator in de repositorymap:

```powershell
cd C:\git\ai-workstation-bootstrap
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
.\scripts\windows\90-bootstrap-windows.ps1
```

Het runner-script voert fases uit en schrijft markers in `.bootstrap-state`.
Na een reboot kun je hetzelfde script opnieuw draaien; afgeronde fases worden overgeslagen.

### Alleen cleanup droog testen

```powershell
.\scripts\windows\04-remove-windows-bloatware.ps1 -WhatIfOnly
```

### Cleanup echt uitvoeren

```powershell
.\scripts\windows\04-remove-windows-bloatware.ps1
```

## Windows-fases

De Windows runner gebruikt deze scripts:

```text
scripts/windows/00-set-hostname.ps1
scripts/windows/01-enable-wsl.ps1
scripts/windows/02-install-winget-packages.ps1
scripts/windows/03-windows-security-baseline.ps1
scripts/windows/04-remove-windows-bloatware.ps1
scripts/windows/99-verify-windows.ps1
```

Belangrijke wijzigingen:

- computernaam naar `patech-wsa-01`
- WSL2 Ubuntu activeren
- winget packages installeren
- Windows security baseline toepassen
- consumer bloatware verwijderen
- Xbox/Game Bar/Widgets/consumer suggestions uitschakelen
- MSI/SteelSeries/Nahimic autostart-noise beperken
- handmatige marker voor keyboard RGB-check aanmaken

Let op: keyboard RGB kan meestal niet betrouwbaar generiek gescript worden op MSI/SteelSeries hardware. Het script maakt daarom een duidelijke follow-up note aan in:

```text
%USERPROFILE%\patech-setup-notes\keyboard-rgb-manual-check.txt
```

Aanbevolen instelling:

```text
SteelSeries GG / MSI Center:
Keyboard illumination = Off
of Static White, Low brightness
Startup/idle effects = Off
```

## WSL-start

Start Ubuntu na installatie en voer uit:

```bash
cd /mnt/c/git/ai-workstation-bootstrap
chmod +x scripts/wsl/*.sh
./scripts/wsl/90-bootstrap-wsl.sh
```

De WSL runner schrijft markers in `.bootstrap-state-wsl` en slaat afgeronde fases over.

## WSL-fases

```text
scripts/wsl/00-bootstrap-ubuntu.sh
scripts/wsl/01-dev-tools.sh
scripts/wsl/02-ai-tools.sh
scripts/wsl/03-hermes-agent.sh
scripts/wsl/04-honcho.sh
scripts/wsl/05-codex-claude.sh
scripts/wsl/06-models-ollama.sh
scripts/wsl/99-verify-wsl.sh
```

## Verificatie

Windows:

```powershell
.\scripts\windows\99-verify-windows.ps1
```

WSL:

```bash
./scripts/wsl/99-verify-wsl.sh
```

## Git workflow

Nieuwe wijzigingen in deze repo:

```powershell
git status
git add .
git commit -m "Update AI workstation bootstrap"
git push
```

## Let op

Hermes Agent en Honcho kunnen afhankelijk zijn van jouw actuele eigen installatiemethode, repo of packagebron. De scripts zijn daarom bewust veilig en idempotent opgezet: ze installeren generieke dependencies, maken directories en templates aan, en falen niet hard als de exacte bron nog ingevuld moet worden.

## Recovery concept

Nieuwe machine of herinstallatie:

1. Windows basisinstallatie afronden
2. Git installeren indien nodig
3. Repository clonen
4. `90-bootstrap-windows.ps1` uitvoeren
5. Reboot waar nodig
6. Ubuntu openen
7. `90-bootstrap-wsl.sh` uitvoeren
8. Verificatie scripts draaien

Doel: workstation-as-code in plaats van handmatige inrichting.
