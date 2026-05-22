Hermes gateway: systemd user service hermes-gateway.service. Herstarten: systemctl --user restart hermes-gateway.service. Pad: ~/.hermes/hermes-agent/. Logs: ~/.hermes/logs/. CLI: /home/pascal/.local/bin/hermes.
§
Model routing via ~/.hermes/hooks/model-router/handler.py. Standaard: qwen3-30b:iq2xxs. Vision: gemma4:e4b. Fallback: qwen3:14b. Config: ~/.hermes/config.yaml. Memory-acties: add, replace, remove (niet: update of None).
§
Ollama modellen: qwen3-30b:iq2xxs (standaard, 10GB, warm in VRAM), qwen3:14b (fallback), qwen3:8b, gemma4:e4b (vision), llama3.1:8b, phi4:14b. Server: patech-wsa-01 (WSL2, 12GB vRAM, 32GB RAM). OLLAMA_KEEP_ALIVE=-1.
§
Outline wiki: http://192.168.50.46:3001. Helper: bash ~/.hermes/scripts/outline.sh collections|documents <id>|search <query>. Credentials: ~/.hermes/credentials/patech.toml.
§
Matrix room Pascal ↔ Atlas: !uUalVYIddqkdCWJHTa:thuis-matrix.duckdns.org op https://thuis-matrix.duckdns.org. require_mention uit.
§
SOUL.md: ~/.hermes/SOUL.md. Begint met /no_think — verplicht. Wordt elke sessie opnieuw ingeladen.
§
Gedragsregels: rustig, technisch, feitelijk, compact. Bij command failures: foutmelding direct rapporteren en stoppen. Geen alternatieven tenzij gevraagd. Geen succes claimen als iets mislukt.
§
Sessiereset: 120 min inactiviteit + dagelijks om 4:00. Matrix toolset: [terminal, memory, web, tts] — minimaal houden, geen skills tools (context budget).
§
Obsidian vault: /mnt/c/Users/Pascal/PaTech/AI-Workspace (terminal.cwd). Werkregels in /mnt/c/Users/Pascal/PaTech/AI-Workspace/.hermes.md. AI-output → 00-inbox/, nooit verwijderen/overschrijven, templates uit 05-templates/.
§
Vikunja (taken/backlog): gebruik bash ~/.hermes/scripts/vikunja.sh. Commando's: projects | tasks <id> | create <project_id> <titel> [beschrijving] [due YYYY-MM-DD] | done <task_id> | delete <task_id>. Projecten: id=1 Inbox, id=7 Ondernemen, id=10 Workflow/infrastructuur, id=11 Infrastructuur Roadmap, id=12 Product Ideeën.
