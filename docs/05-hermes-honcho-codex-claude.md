# Hermes, Honcho, Codex en Claude

## Hermes Agent

Hermes Agent is de primaire agentlaag. Installeer via:

```bash
./scripts/wsl/04-hermes-agent.sh
```

Dit script:
- Installeert Hermes Agent via het officiële install-script
- Installeert `faster-whisper` voor lokale STT
- Schrijft `context_length_cache.yaml` (Hermes rapporteert 40960 tokens voor Ollama, cache overschrijft naar 131072)
- Installeert `SOUL.md` vanuit de repo (altijd, met backup van bestaande versie)
- Installeert `MEMORY.md` en `USER.md` alleen bij eerste installatie (zijn data, groeien over tijd)

Na installatie is handmatige setup vereist (interactieve terminal):

```bash
hermes setup
# → Matrix als platform
# → custom provider (Ollama)
# → Base URL: http://localhost:11434/v1
# → Default model: qwen3-30b:iq2xxs

hermes memory setup
# → honcho
# → Base URL: http://localhost:8000
# → Workspace: patech-wsa-01
# → User peer: pascal / AI peer: atlas
```

Daarna de gateway als service starten:

```bash
systemctl --user enable --now hermes-gateway.service
```

**Let op:** `hermes setup` overschrijft `SOUL.md`. Herstel daarna:

```bash
cp ~/ai-workstation-bootstrap/config/hermes/SOUL.md ~/.hermes/SOUL.md
```

Relevante bestanden:
- `~/.hermes/SOUL.md` — Atlas identiteit en gedragsregels (canoniek: `config/hermes/SOUL.md`)
- `~/.hermes/memories/MEMORY.md` — werkgeheugen (canoniek: `config/hermes/MEMORY.md`)
- `~/.hermes/config.yaml` — Hermes configuratie (model, memory backend, etc.)

---

## Honcho

Honcho is de lokale memory-laag. Draait als Docker Compose stack in WSL2.

```bash
./scripts/wsl/05-honcho.sh
```

Dit script:
- Kloont of updatet Honcho naar `~/.local/share/patech/honcho/`
- Schrijft `.env` met alle benodigde variabelen
- Installeert `honcho-dashboard.py` naar `~/.hermes/scripts/`
- Start de Honcho Docker Compose stack
- Installeert `honcho-dashboard.service` als systemd user service

### Configuratie

Honcho gebruikt Ollama via OpenAI-compatibele API. Alle LLM-taken (deriver, summary, dream, dialectic) draaien op `qwen3-30b:iq2xxs` — hetzelfde model als Hermes, zodat het warm blijft in VRAM.

Embeddings lopen via `nomic-embed-text` (274 MB bestand, ~595 MB VRAM, 768 dimensies).

Sleutelconfiguratie in `.env`:

| Variabele | Waarde | Reden |
|---|---|---|
| `LLM_OPENAI_API_KEY` | `ollama` | Ollama accepteert elke waarde als API key |
| `EMBED_MESSAGES` | `false` | Geen berichtembeddings; alleen representaties |
| `EMBEDDING_MODEL_CONFIG__MODEL` | `nomic-embed-text` | Past in VRAM naast qwen3-30b |
| `EMBEDDING_VECTOR_DIMENSIONS` | `768` | Dimensies van nomic-embed-text |
| `DERIVER_FLUSH_ENABLED` | `true` | Verwerkt representaties direct i.p.v. wachten op tokenbatch |
| `DERIVER_STALE_SESSION_TIMEOUT_MINUTES` | `15` | Wacht 15 min inactiviteit voor verwerking |
| `DERIVER_DEDUPLICATE` | `true` | Dedupliceert conclusions binnen een deriver-run |
| `DREAM_IDLE_TIMEOUT_MINUTES` | `30` | Dream consolideert na 30 min inactiviteit |
| `DREAM_MIN_HOURS_BETWEEN_DREAMS` | `4` | Maximaal één Dream-cyclus per 4 uur |
| Alle `*_MODEL_CONFIG__MODEL` | `qwen3-30b:iq2xxs` | Één model in VRAM, geen evictie |

Alle Ollama-aanroepen vanuit Docker gaan via `host.docker.internal:11434` (= `172.17.0.1` via `host-gateway` in `extra_hosts`).

### VRAM-profiel

| Component | VRAM |
|---|---|
| qwen3-30b:iq2xxs | ~11.0 GB |
| nomic-embed-text | ~0.6 GB |
| **Totaal** | **~11.6 GB van 12.2 GB** |

Met een tweede model (bijv. qwen3:14b = 10 GB) zou qwen3-30b uit VRAM worden gezet.

### DB-vectordimensies

Bij eerste installatie of na dimensiewijziging moeten de pg vectorkolommen kloppen:

```bash
docker exec -it honcho-db-1 psql -U postgres -c \
  "ALTER TABLE documents ALTER COLUMN embedding TYPE vector(768) USING NULL;
   ALTER TABLE message_embeddings ALTER COLUMN embedding TYPE vector(768) USING NULL;"
```

### Dashboard

Bereikbaar op: `http://localhost:8080`

Functionaliteit:
- **Overzicht**: queue-status, VRAM-gebruik, overzicht peers
- **Sessies**: sessielijst → doorklikken naar berichtconversatie (gepagineerd)
- **Geheugen**: observaties/conclusions met filter op observer/observed
- **Peers**: volledige representatie + context per observer

Het dashboard draait als `honcho-dashboard.service` (systemd user service).

```bash
systemctl --user status honcho-dashboard.service
```

---

## Codex CLI

Codex wordt via npm geïnstalleerd:

```bash
npm install -g @openai/codex
```

Daarna inloggen via de CLI/OAuth-flow.

---

## Claude CLI / Claude Code

Claude wordt via npm geïnstalleerd:

```bash
npm install -g @anthropic-ai/claude-code
```

Inloggen via `claude` (OAuth of API key). Vereist een Anthropic-account met API-toegang.
