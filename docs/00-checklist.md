# Checklist implementatie patech-wsa-01

## Voorbereiding

- [ ] Laptop fysiek controleren
- [ ] Windows 11 setup afronden
- [ ] Microsoft-account/lokaal account volgens beleid kiezen
- [ ] Windows Update volledig afronden
- [ ] Vendor firmware/BIOS updates uitvoeren
- [ ] NVIDIA Studio Driver installeren
- [ ] BitLocker inschakelen
- [ ] Herstelcode veilig opslaan
- [ ] Computernaam instellen op `patech-wsa-01`

## Basis tooling

- [ ] Git installeren
- [ ] VS Code installeren
- [ ] Docker Desktop installeren
- [ ] WSL2 Ubuntu installeren
- [ ] PowerShell 7 installeren
- [ ] Windows Terminal installeren
- [ ] Ollama installeren

## WSL/dev

- [ ] Ubuntu updaten
- [ ] Git config instellen
- [ ] SSH key aanmaken
- [ ] Gitea SSH toegang testen
- [ ] Docker vanuit WSL testen
- [ ] Python/uv installeren
- [ ] Node/npm installeren

## AI-stack

- [ ] Ollama bereikbaar
- [ ] Open WebUI starten
- [ ] Modellen pullen
- [ ] Hermes Agent configureren
- [ ] Honcho configureren
- [ ] Codex CLI installeren
- [ ] Claude CLI installeren

## Validatie

- [ ] `nvidia-smi` werkt op Windows
- [ ] `nvidia-smi` werkt in WSL
- [ ] `docker compose version` werkt
- [ ] `ollama list` werkt
- [ ] Open WebUI bereikbaar op `http://localhost:3000`
- [ ] Gitea push/pull werkt
