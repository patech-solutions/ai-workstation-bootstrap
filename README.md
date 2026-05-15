# AI Workstation Bootstrap

Herbruikbare bootstrap repository voor een Windows 11 mobiele AI-workstation met WSL2, Docker Desktop, Ollama, Open WebUI, Hermes Agent, Honcho, OpenAI Codex CLI en Claude CLI/Code.

## Uitgangspunten

- Host OS: Windows 11 Pro
- Primaire werklaag: WSL2 Ubuntu 24.04
- Container runtime: Docker Desktop met WSL2 backend
- Lokale LLM runtime: Ollama
- UI: Open WebUI
- Agentlaag: Hermes Agent
- Memorylaag: Honcho
- Code tooling: OpenAI Codex CLI en Claude CLI/Code
- Repo doel: herhaalbaar, veilig, uitbreidbaar en geschikt voor Gitea

## Eerste gebruik

1. Clone deze repository naar de Windows-machine.
2. Open PowerShell als Administrator.
3. Draai:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
.\scripts\windows\00-enable-wsl.ps1
.\scripts\windows\01-install-winget-packages.ps1
.\scripts\windows\02-windows-security-baseline.ps1
.\scripts\windows\04-remove-windows-bloatware.ps1
```

4. Herstart indien nodig.
5. Start Ubuntu 24.04 eenmalig en maak je Linux user aan.
6. Vanuit WSL:

```bash
cd /mnt/c/path/to/ai-workstation-bootstrap
chmod +x scripts/wsl/*.sh
./scripts/wsl/00-bootstrap-ubuntu.sh
./scripts/wsl/01-dev-tools.sh
./scripts/wsl/02-ai-tools.sh
./scripts/wsl/03-hermes-agent.sh
./scripts/wsl/04-honcho.sh
./scripts/wsl/05-codex-cli.sh
./scripts/wsl/06-claude-cli.sh
./scripts/wsl/07-models-ollama.sh
./scripts/wsl/99-verify-wsl.sh
```

## Belangrijke volgorde

1. Windows updates, firmware en NVIDIA driver.
2. BitLocker, security baseline en bloatware verwijderen.
3. WSL2 + Ubuntu.
4. Docker Desktop met WSL integration.
5. Gitea SSH-key.
6. Dev tooling.
7. AI runtime.
8. Hermes, Honcho, Codex en Claude.
9. Lokale modellen.
10. Verificatie.

## Windows bloatware verwijderen

De repo bevat een conservatief Windows 11 debloat script:

```powershell
.\scripts\windows\04-remove-windows-bloatware.ps1
```

Eerst controleren zonder wijzigingen kan met:

```powershell
.\scripts\windows\04-remove-windows-bloatware.ps1 -WhatIfOnly
```

OneDrive wordt standaard niet verwijderd. Dat kan expliciet met:

```powershell
.\scripts\windows\04-remove-windows-bloatware.ps1 -RemoveOneDrive
```

## Secrets

Zet tokens nooit in Git. Gebruik:

- Windows Credential Manager
- WSL environment files buiten de repo
- `.env.local`, maar commit deze nooit
- SSH keys in `~/.ssh`

Zie `.gitignore`.
