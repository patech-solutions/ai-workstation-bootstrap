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
# → Default model: qwen3:14b

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
- `~/.hermes/honcho.json` — Honcho verbinding en peer-configuratie (canoniek: `config/hermes/honcho.json`)

**Patch: `!new` maakt ook nieuwe Honcho sessie aan.** Het bootstrap script patcht automatisch `plugins/memory/honcho/client.py` na de Hermes installatie. Zonder patch gebruikt de gateway altijd de Matrix room ID als Honcho sessie-ID, waardoor `!new` geen effect heeft op Honcho. Met patch: `sessionStrategy: "per-session"` in `honcho.json` laat de Hermes session_id (opgeslagen in `sessions.json`) de Honcho sessie bepalen — nieuw na elke `!new`, persistent over gateway-herstarts.

**Belangrijk:** Na `hermes memory setup` moet `honcho.json` handmatig worden aangevuld met `pinPeerName: true` in het `hosts.hermes` blok. Zonder dit wordt de Matrix user ID (`@pascal:thuis.matrix.duckdns.org`) gebruikt als peer naam, wat een leading dash introduceert en `honcho_conclude` kapot maakt:

```json
{
  "hosts": {
    "hermes": {
      "peerName": "pascal",
      "aiPeer": "atlas",
      "workspace": "patech-wsa-01",
      "pinPeerName": true,
      ...
    }
  }
}
```

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
- Maakt `docker-compose.override.yml` aan met `restart: "no"` voor de deriver (zie sectie Deriver hieronder)
- Stopt de deriver container na het starten

### Configuratie

Honcho gebruikt Ollama via OpenAI-compatibele API. Alle LLM-taken (summary, dream, dialectic) draaien op `qwen3:14b` — hetzelfde model als Hermes, zodat het warm blijft in VRAM.

Embeddings lopen via `nomic-embed-text` (274 MB bestand, ~595 MB VRAM, 768 dimensies).

#### recallMode en dialecticCadence

`honcho.json` gebruikt `recallMode: "hybrid"`. Dit combineert:
- **Session-start prewarm**: bij elke `!new` sessie start een achtergrond-thread die automatisch de Honcho dialectic aanroept en de context injecteert in het eerste antwoord — zonder dat de gebruiker iets hoeft te typen.
- **`honcho_reasoning` tool**: Atlas kan op elk moment expliciet geheugen opvragen.

De `dialecticCadence` bepaalt hoe vaak Honcho tussentijds een achtergrond-LLM-call doet om context te verversen (in beurten). Op een single-GPU setup concurreert deze achtergrondcall rechtstreeks met de hoofdinferentie van `qwen3:14b`, wat tot GPU contention en stille timeouts leidt.

**Instelling: `dialecticCadence: 10`** (was `2`). De eerste achtergrondrefresh verschuift naar beurt 10. De session-start prewarm biedt context voor de eerste 9 beurten; in langere sessies volgt daarna een periodieke refresh.

> **Niet terug naar `1` of `2`:** Bij cadence 2 trad een stille `honcho_conclude`-fout op tijdens W3 van het testprotocol omdat de Honcho API bezet was met een dialectic prefetch-call naar `qwen3:14b`. Atlas meldde "informatie verwerkt" terwijl de conclusie niet was opgeslagen.

Sleutelconfiguratie in `.env`:

| Variabele | Waarde | Reden |
|---|---|---|
| `LLM_OPENAI_API_KEY` | `ollama` | Ollama accepteert elke waarde als API key |
| `EMBED_MESSAGES` | `false` | Geen berichtembeddings; alleen representaties |
| `EMBEDDING_MODEL_CONFIG__MODEL` | `nomic-embed-text` | Past in VRAM naast qwen3:14b |
| `EMBEDDING_VECTOR_DIMENSIONS` | `768` | Dimensies van nomic-embed-text |
| `DERIVER_FLUSH_ENABLED` | `false` | Deriver uitgeschakeld (zie sectie Deriver) |
| `DERIVER_STALE_SESSION_TIMEOUT_MINUTES` | `15` | Wacht 15 min inactiviteit voor verwerking |
| `DERIVER_DEDUPLICATE` | `true` | Dedupliceert conclusions binnen een deriver-run |
| `DREAM_IDLE_TIMEOUT_MINUTES` | `30` | Dream consolideert na 30 min inactiviteit (na het bereiken van de drempel) |
| `DREAM_MIN_HOURS_BETWEEN_DREAMS` | `4` | Maximaal één Dream-cyclus per 4 uur |
| `DREAM_DOCUMENT_THRESHOLD` | `50` (standaard) | Minimaal aantal expliciete documenten per collectie voordat Dream triggert. Elke deriver-sessie voegt ~10-15 docs toe. |
| Alle `*_MODEL_CONFIG__MODEL` | `qwen3:14b` | Één model in VRAM, geen evictie |

### Deriver

**De deriver is ingeschakeld.** Verwerkt sessies automatisch na 15 minuten inactiviteit en extraheert conclusies. Dream consolideert conclusies naar peer-representaties na 30 minuten inactiviteit (minimaal 4 uur tussen cycli).

**Dream hallucineert in deductieve laag bij speculatieve Atlas-antwoorden.** De deriver extraheert observaties van beide kanten — ook Atlas's antwoorden. Als Atlas suggestieve of vooruitblikkende antwoorden geeft, worden die als feiten opgeslagen. Dream's deductieve redenering voegt daar niet-ondersteunde specificiteit aan toe (verzonnen deadlines, causaliteitsketens). qwen3:14b gebruikt de systeemdatum als anker.

Dit is primair een **procesprobleem**: Dream heeft geen verificatiestap en maakt geen onderscheid tussen feitelijke gebruikersuitspraken en intentie-uitspraken van Atlas. Beide worden als gelijkwaardige invoer behandeld. Het model is secundair — een groter model zou conservatiever zijn, maar het structurele risico blijft bij speculatieve invoer.

**Mitigatie:** Houd contextsessies feitelijk en vermijd open vragen die Atlas aanzetten tot speculatieve plannen. De expliciete observatielaag blijft betrouwbaar — hallucinaties ontstaan in de deductieve inferentie bovenop speculatieve bronobservaties.

Eerdere evaluatie toonde hallucinaties, maar deze waren niet eenduidig aan de deriver toe te schrijven — er waren destijds meerdere variabelen tegelijk gewijzigd. Validatie loopt via `08-playbooks/Atlas-testprotocol-deriver-dream.md`.

**Uitschakelen** (indien hallucinaties optreden):
```bash
# Zet DERIVER_FLUSH_ENABLED=false in .env
cd ~/.local/share/patech/honcho
docker restart honcho-deriver-1
```

Of permanent via override:
```bash
cat > ~/.local/share/patech/honcho/docker-compose.override.yml << 'EOF'
services:
  deriver:
    restart: "no"
EOF
docker compose -f docker-compose.yml -f docker-compose.override.yml stop deriver
```

Alle Ollama-aanroepen vanuit Docker gaan via `host.docker.internal:11434` (= `172.17.0.1` via `host-gateway` in `extra_hosts`).

### VRAM-profiel

| Component | VRAM |
|---|---|
| qwen3:14b | ~9.3 GB |
| nomic-embed-text | ~0.6 GB |
| **Totaal** | **~9.9 GB van 12.2 GB** |

KV-cache (num_ctx 8192): ~0.5 GB extra. Totaal ~10.4 GB — past binnen 12 GB zonder model-evictie tijdens actief gebruik.

> **Cold start na inactiviteit:** Ondanks `OLLAMA_KEEP_ALIVE=-1` geeft WSL2 GPU-geheugen terug aan het host-OS na langere inactiviteit (uren). `ollama ps` kan het model nog als geladen tonen terwijl het feitelijk uit VRAM is — Windows Performance Monitor toont dan 0 GB. Reken bij de eerste call na een lange pauze op 1-3 minuten laadtijd. Dit geldt ook voor deriver, dream en de session-start prewarm.

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
