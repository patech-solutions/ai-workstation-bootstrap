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
git clone https://github.com/patech-solutions/ai-workstation-bootstrap.git
cd ai-workstation-bootstrap
```

## 4. WSL bootstrap

```bash
chmod +x scripts/wsl/*.sh
./scripts/wsl/00-bootstrap-ubuntu.sh
./scripts/wsl/01-dev-tools.sh
```

## 5. Ollama + modellen

```bash
./scripts/wsl/02-install-ollama.sh
./scripts/wsl/03-models-ollama.sh
```

## 6. Agent tools

```bash
./scripts/wsl/04-hermes-agent.sh
./scripts/wsl/05-honcho.sh
```

Na `04-hermes-agent.sh`: voer `hermes setup` en `hermes memory setup` uit (interactief, zie `docs/05-hermes-honcho-vibe.md`).

## 7. Web interfaces

```bash
./scripts/wsl/06-open-webui.sh
./scripts/wsl/07-firecrawl.sh
```

## 8. CLI tools

```bash
pip install -U mistral-vibe
vibe auth login
```

## 9. Verify

```bash
./scripts/wsl/99-verify-wsl.sh
```

Controleer ook handmatig:
- Hermes: `systemctl --user status hermes-gateway.service`
- Honcho API: `curl http://localhost:8000/health`
- Honcho Dashboard: open `http://localhost:8080` in browser
- Open WebUI: open `http://localhost:3000` in browser
