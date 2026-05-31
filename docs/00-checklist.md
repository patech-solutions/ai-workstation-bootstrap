# Checklist implementatie AI workstation

## Voorbereiding

- [ ] Laptop fysiek controleren
- [ ] Windows 11 setup afronden
- [ ] Microsoft-account/lokaal account volgens beleid kiezen
- [ ] Windows Update volledig afronden
- [ ] Vendor firmware/BIOS updates uitvoeren
- [ ] NVIDIA Studio Driver installeren
- [ ] BitLocker inschakelen
- [ ] Herstelcode veilig opslaan
- [ ] Computernaam instellen (zie `BOOTSTRAP_HOSTNAME` in `config/bootstrap.env`)

## Basis tooling

- [ ] Git installeren
- [ ] VS Code installeren
- [ ] WSL2 Ubuntu installeren
- [ ] PowerShell 7 installeren
- [ ] Windows Terminal installeren
- [ ] Docker CE installeren in WSL2 (via 01-dev-tools.sh — niet Docker Desktop)

## WSL/dev

- [ ] Ubuntu updaten
- [ ] Git config instellen
- [ ] SSH key aanmaken
- [ ] Gitea SSH toegang testen
- [ ] Docker vanuit WSL testen
- [ ] Python/uv installeren
- [ ] Node/npm installeren

## AI-stack

- [ ] Ollama installeren (`02-install-ollama.sh`)
- [ ] Modellen pullen (`03-models-ollama.sh` — qwen3:14b, gemma4:e4b, qwen3:8b, llama3.1:8b)
- [ ] Open WebUI starten (`06-open-webui.sh` — bereikbaar op `:3000`)
- [ ] Hermes Agent installeren (`04-hermes-agent.sh` — SOUL.md + basis geheugen)
- [ ] Hermes setup afronden (`hermes setup` + `hermes memory setup` — interactief, zie `05-hermes-honcho-codex-claude.md`)
- [ ] SOUL.md herstellen na `hermes setup` (setup overschrijft het bestand)
- [ ] Honcho starten (`05-honcho.sh` — Docker stack + dashboard service)
- [ ] Honcho API bereikbaar: `curl http://localhost:8000/health`
- [ ] Honcho Dashboard bereikbaar: `http://localhost:8080`
- [ ] Codex CLI installeren (`npm install -g @openai/codex`)
- [ ] Claude CLI installeren (`npm install -g @anthropic-ai/claude-code`)

## Validatie

- [ ] `nvidia-smi` werkt op Windows
- [ ] `nvidia-smi` werkt in WSL
- [ ] `docker compose version` werkt
- [ ] `ollama list` werkt
- [ ] Open WebUI bereikbaar op `http://localhost:3000`
- [ ] Gitea push/pull werkt
