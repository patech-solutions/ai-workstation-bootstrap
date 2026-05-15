# First Day Runbook

## 1. Windows

Run PowerShell as Administrator:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
.\scripts\windows\00-enable-wsl.ps1
.\scripts\windows\01-install-winget-packages.ps1
.\scripts\windows\02-windows-security-baseline.ps1
```

Reboot if required.

## 2. Ubuntu first start

Open Ubuntu 24.04 from Start Menu and create Linux user.

## 3. Clone repo

```bash
git clone git@gitea.patechsolutions.nl:patech/ai-workstation-bootstrap.git
cd ai-workstation-bootstrap
```

## 4. WSL bootstrap

```bash
chmod +x scripts/wsl/*.sh
./scripts/wsl/00-bootstrap-ubuntu.sh
./scripts/wsl/01-dev-tools.sh
./scripts/wsl/02-ai-tools.sh
```

## 5. Agent tools

```bash
./scripts/wsl/03-hermes-agent.sh
./scripts/wsl/04-honcho.sh
./scripts/wsl/05-codex-cli.sh
./scripts/wsl/06-claude-cli.sh
```

## 6. Models

```bash
./scripts/wsl/07-models-ollama.sh
```

## 7. Verify

```bash
./scripts/wsl/99-verify-wsl.sh
```
