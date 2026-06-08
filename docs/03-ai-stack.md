# AI-stack

## Lagen

1. Windows 11 host
2. WSL2 Ubuntu werklaag
3. Native docker-ce in WSL2 (niet Docker Desktop)
4. Ollama voor lokale modellen (native in WSL2, luistert op `0.0.0.0:11434`)
5. Honcho voor lokale memory (Docker, bereikt Ollama via `host.docker.internal`)
6. Honcho Dashboard voor monitoring en inzage (systemd user service, `:8080`)
7. Open WebUI voor lokale browserinterface (Docker, bereikt Ollama via `host.docker.internal`)
8. Firecrawl voor web extractie (Docker)
9. Hermes Agent voor agentische workflows (systemd user service)

## Waarom native docker-ce en niet Docker Desktop

Docker Desktop draait containers in een eigen geïsoleerde VM. Containers in die VM
kunnen Ollama in WSL2 niet bereiken via `host.docker.internal` zonder een
Windows-zijdige poortproxy (`netsh interface portproxy`). Dit geeft problemen voor
Honcho (dialectic timeout) en elke andere container die Ollama nodig heeft.

Native docker-ce in WSL2 draait containers in dezelfde network namespace als Ollama.
Via het `docker0` bridge-interface (`172.17.0.1`) kunnen containers direct verbinden.
`host-gateway` in `extra_hosts` resolvet naar `172.17.0.1`, wat Ollama bereikt op
`0.0.0.0:11434`.

## Open WebUI starten

```bash
./scripts/wsl/06-open-webui.sh
```

Bereikbaar op: `http://localhost:3000`

Ollama wordt automatisch ontdekt via `host.docker.internal:11434`.

## Honcho starten

```bash
./scripts/wsl/05-honcho.sh
```

Bereikbaar op: `http://localhost:8000`

Dashboard op: `http://localhost:8080`

Na installatie: `hermes memory setup` → kies Lokaal → `http://localhost:8000`

Zie `docs/05-hermes-honcho-vibe.md` voor uitleg over embeddings, VRAM-profiel en configuratieparameters.

## LiteLLM optioneel

LiteLLM kan worden gebruikt als router/proxy tussen lokale modellen en cloud providers.

```bash
docker compose -f compose/litellm.compose.yml up -d
```
