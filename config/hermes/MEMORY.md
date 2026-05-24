Model routing: standaard qwen3:14b, vision gemma4:e4b, fallback qwen3:8b. Hook ~/.hermes/hooks/model-router/handler.py. Config ~/.hermes/config.yaml. Memory-acties: add, replace, remove (niet: update).
§
Hermes gateway: systemctl --user restart hermes-gateway.service. Pad ~/.hermes/hermes-agent/. CLI /home/pascal/.local/bin/hermes.
§
Gedragsregels: technisch, feitelijk, compact. Bij command failures: foutmelding direct rapporteren en stoppen. Geen alternatieven tenzij gevraagd. Geen succes claimen als iets mislukt.
§
Sessiereset: 120 min inactiviteit + dagelijks om 4:00. Matrix toolset: [terminal, memory, web, tts] — minimaal houden, geen skills (context budget).
§
Obsidian vault: /mnt/c/Users/Pascal/PaTech/AI-Workspace (terminal.cwd). AI-output → 00-inbox/, nooit verwijderen/overschrijven. Templates in 05-templates/.
