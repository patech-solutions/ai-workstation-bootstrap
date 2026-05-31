# AI Workstation Implementatieplan

## Context

Dit document beschrijft de inrichting van een mobiele AI-workstation op basis van Windows 11, met WSL2 Ubuntu als technische werklaag. De inrichting is herhaalbaar en configureerbaar via dit bootstrap repository.

## Doelen

- Veilige basisinrichting van Windows 11.
- Herhaalbare installatie via scripts.
- AI tooling lokaal en remote combineren.
- Lokale LLM runtime via Ollama.
- Agentlaag via Hermes Agent.
- Memorylaag via Honcho.
- Code-assistentie via Codex en Claude.
- Configuratie geschikt voor demonstraties, ontwikkeling en klantwerk.

## Architectuurlagen

### Laag 1 — Windows 11 Host

Windows blijft de primaire hostlaag voor hardware, drivers, BitLocker, vendor tooling, Docker Desktop en eventueel native Ollama.

Belangrijkste onderdelen:

- Windows Update
- Firmware/BIOS update
- NVIDIA Studio Driver
- BitLocker
- Windows Defender
- Windows Terminal
- Docker Desktop
- WSL2 Ubuntu 24.04

### Laag 2 — WSL2 Ubuntu

WSL2 is de primaire technische laag voor scripts, Git, Python, Node, CLI tooling, agent tooling en automation.

Belangrijkste onderdelen:

- Git
- Python/uv
- Node/npm/nvm
- Docker CLI via Docker Desktop
- jq, ripgrep, fzf, tmux, shellcheck
- Codex CLI
- Claude CLI
- Hermes Agent
- Honcho client/server integratie

### Laag 3 — AI Runtime

Lokale AI runtime bestaat minimaal uit:

- Ollama
- Open WebUI
- Lokale modellen
- Embeddingmodel
- Optioneel LiteLLM of routerlaag later

### Laag 4 — Agent en Memory

Hermes Agent is de primaire agentlaag. Honcho wordt gebruikt als lokale of self-hosted memorylaag.

Voorbeeldrollen:

- Hermes: taakuitvoering, routing, toolgebruik.
- Honcho: context/memory.
- Ollama: lokale modellen.
- OpenRouter/OpenAI/Anthropic: remote modellen.

## Implementatievolgorde

1. Laptop uitpakken en Windows 11 eerste setup afronden.
2. Windows Update volledig draaien.
3. BIOS/firmware/vendor updates uitvoeren.
4. NVIDIA Studio Driver installeren.
5. BitLocker controleren of activeren.
6. WSL2 + Ubuntu 24.04 installeren.
7. Docker Desktop installeren.
8. Docker WSL integration aanzetten.
9. Gitea SSH key maken en toevoegen.
10. Repository clonen.
11. Windows bootstrap scripts draaien.
12. WSL bootstrap scripts draaien.
13. Ollama en Open WebUI testen.
14. Hermes Agent configureren.
15. Honcho configureren.
16. Codex CLI installeren en login uitvoeren.
17. Claude CLI installeren en login uitvoeren.
18. Lokale modellen downloaden.
19. Verificatiescript draaien.
20. Resultaat documenteren.

## Gitea Repository

Voorgestelde repositorynaam:

```text
ai-workstation-bootstrap
```

Structuur:

```text
ai-workstation-bootstrap/
├─ README.md
├─ config/
├─ compose/
├─ docs/
│  └─ outline/
└─ scripts/
   ├─ windows/
   └─ wsl/
```

## Secretsbeleid

Nooit tokens of API keys committen.

Gebruik:

- Windows Credential Manager
- environment variables
- lokale `.env.local`
- SSH keys in `~/.ssh`
- secrets in Hermes/Honcho config buiten Git

Bestanden zoals `.env`, `.env.local`, `*.pem`, `*.key` en credentials staan in `.gitignore`.

## Windows Scripts

Uit te voeren als Administrator:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

.\scripts\windows\00-enable-wsl.ps1
.\scripts\windows\01-install-winget-packages.ps1
.\scripts\windows\02-windows-security-baseline.ps1
.\scripts\windows\03-create-gitea-ssh-key.ps1
.\scripts\windows\99-verify-windows.ps1
```

## WSL Scripts

Uit te voeren vanuit Ubuntu/WSL:

```bash
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

## Lokale modellen

Startset:

```text
qwen3:8b
qwen3:14b
mistral-small:latest
devstral:latest
nomic-embed-text:latest
```

De lijst staat in:

```text
config/ollama-models.txt
```

## Open WebUI

Open WebUI draait via Docker Compose:

```bash
docker compose -f compose/open-webui.compose.yml up -d
```

Daarna bereikbaar op:

```text
http://localhost:3000
```

## Honcho

Honcho draait via Docker Compose-template:

```bash
docker compose -f compose/honcho.compose.yml up -d
```

Daarna standaard verwacht op:

```text
http://localhost:8000
```

Let op: controleer de definitieve Honcho image/tag of installatiebron. Het meegeleverde composebestand is bewust als template opgezet.

## Hermes Agent

Het script maakt configuratiepaden aan:

```text
~/.hermes
~/.config/hermes/config.yaml
```

Hermes zelf wordt niet blind geïnstalleerd omdat jouw exacte distributie/installatiebron leidend moet zijn. Plaats de executable bij voorkeur in:

```text
~/.local/bin/hermes
```

## Codex CLI

Installatie:

```bash
npm install -g @openai/codex
codex login
```

Gebruik OAuth waar mogelijk. API keys niet in Git plaatsen.

## Claude CLI / Claude Code

Installatie:

```bash
npm install -g @anthropic-ai/claude-code
claude
```

Let op: Anthropic kan extra billing/usage setup vereisen voordat OAuth/API-gebruik werkt.

## Acceptatiecriteria

De workstation is initieel goed ingericht wanneer:

- Windows is bijgewerkt.
- BitLocker staat aan of is bewust beoordeeld.
- WSL2 Ubuntu draait.
- Docker Desktop werkt met WSL integration.
- `nvidia-smi` werkt op Windows en bij voorkeur ook in WSL.
- Git kan pushen naar Gitea.
- Ollama reageert op `localhost:11434`.
- Open WebUI draait op `localhost:3000`.
- Honcho draait of is bewust als TODO gemarkeerd.
- Codex CLI is geïnstalleerd.
- Claude CLI is geïnstalleerd.
- Hermes config staat klaar.
- Verificatiescript geeft geen onverwachte fouten.

## Dag 1 Checklist

- [ ] Windows eerste setup afgerond
- [ ] Windows Update klaar
- [ ] Firmware/BIOS update klaar
- [ ] NVIDIA Studio Driver geïnstalleerd
- [ ] BitLocker gecontroleerd
- [ ] WSL2 Ubuntu geïnstalleerd
- [ ] Docker Desktop geïnstalleerd
- [ ] Docker WSL integration aan
- [ ] Gitea SSH key aangemaakt
- [ ] Repo gepusht naar Gitea
- [ ] Windows scripts gedraaid
- [ ] WSL scripts gedraaid
- [ ] Open WebUI bereikbaar
- [ ] Ollama modellen gedownload
- [ ] Hermes Agent klaar voor configuratie
- [ ] Honcho klaar voor configuratie
- [ ] Codex login gedaan
- [ ] Claude login gedaan
- [ ] Verificatie uitgevoerd

## Latere uitbreidingen

- Ansible voor idempotente configuratie.
- LiteLLM als router/proxy.
- GPU benchmarking.
- Demo datasets.
- Offline fallback-profielen.
- Back-up en restore scripts.
- Integratie met Outline, Moneybird en interne MCP endpoints.
