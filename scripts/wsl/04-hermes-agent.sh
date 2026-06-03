#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CONFIG_DIR="$REPO_ROOT/config/hermes"
BOOTSTRAP_ENV="$REPO_ROOT/config/bootstrap.env"

# Laad bootstrap-variabelen als beschikbaar
[[ -f "$BOOTSTRAP_ENV" ]] && source "$BOOTSTRAP_ENV"
OBSIDIAN_WINDOWS_USER="${BOOTSTRAP_WINDOWS_USER:-${USER}}"
OBSIDIAN_VAULT_SUBDIR="${BOOTSTRAP_OBSIDIAN_VAULT_SUBDIR:-AI-Workspace}"

echo "== Hermes Agent installeren =="

# Installeer Hermes
curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh | bash

# faster-whisper voor lokale STT
echo "-- faster-whisper installeren --"
uv pip install faster-whisper --python "$HOME/.hermes/hermes-agent/venv/bin/python"

# qwen3:14b Modelfile bouwen — PARAMETER num_ctx 8192 zodat Ollama altijd 8192 alloceert,
# ook bij aanroepen vanuit Honcho Docker (die geen num_ctx meesturen).
echo "-- qwen3:14b Modelfile bouwen --"
mkdir -p "$HOME/.hermes/modelfiles"
cp "$CONFIG_DIR/modelfiles/qwen3-14b.Modelfile" "$HOME/.hermes/modelfiles/qwen3-14b.Modelfile"
ollama create qwen3:14b -f "$HOME/.hermes/modelfiles/qwen3-14b.Modelfile"
echo "   qwen3:14b gebouwd met num_ctx 8192"

# Context length cache (Hermes vereist >=64K, Ollama rapporteert 40960)
echo "-- context_length_cache.yaml instellen --"
cat > "$HOME/.hermes/context_length_cache.yaml" <<'EOF'
context_lengths:
  qwen3-30b:iq2xxs@http://localhost:11434/v1: 131072
  qwen3-30b:iq2xxs@http://localhost:11434/v1/: 131072
  qwen3:14b@http://localhost:11434/v1: 131072
  qwen3:14b@http://localhost:11434/v1/: 131072
  gemma4:e4b@http://localhost:11434/v1: 131072
  gemma4:e4b@http://localhost:11434/v1/: 131072
  qwen3:8b@http://localhost:11434/v1: 131072
  qwen3:8b@http://localhost:11434/v1/: 131072
  llama3.1:8b@http://localhost:11434/v1: 131072
  llama3.1:8b@http://localhost:11434/v1/: 131072
  aya-expanse:8b@http://localhost:11434/v1: 131072
  aya-expanse:8b@http://localhost:11434/v1/: 131072
EOF

# config.yaml — altijd vanuit repo installeren (bevat alle gateway-instellingen)
# Bevat geen credentials (die staan in ~/.hermes/.env).
# Kritieke instellingen worden ook via patch_yaml gegarandeerd (idempotent).
echo "-- config.yaml installeren --"
CONFIG_YAML_DST="$HOME/.hermes/config.yaml"
if [[ -f "$CONFIG_YAML_DST" ]]; then
    BACKUP="${CONFIG_YAML_DST}.bak.$(date +%Y%m%d_%H%M%S)"
    cp "$CONFIG_YAML_DST" "$BACKUP"
    echo "   bestaande config.yaml gebackupt naar: $BACKUP"
fi
sed \
    -e "s|__BOOTSTRAP_WINDOWS_USER__|${OBSIDIAN_WINDOWS_USER}|g" \
    -e "s|__BOOTSTRAP_OBSIDIAN_VAULT_SUBDIR__|${OBSIDIAN_VAULT_SUBDIR}|g" \
    -e "s|__BOOTSTRAP_HOME__|${HOME}|g" \
    "$CONFIG_DIR/config.yaml" > "$CONFIG_YAML_DST"
echo "   config.yaml geïnstalleerd"

# honcho.json — genereer vanuit template met bootstrap-variabelen
echo "-- honcho.json installeren --"
HONCHO_PEER="${BOOTSTRAP_HONCHO_PEER_NAME:-${USER}}"
HONCHO_AI="${BOOTSTRAP_HONCHO_AI_PEER:-atlas}"
HONCHO_WS="${BOOTSTRAP_HONCHO_WORKSPACE:-default}"

HONCHO_DST="$HOME/.hermes/honcho.json"
if [[ -f "$HONCHO_DST" ]]; then
    BACKUP="${HONCHO_DST}.bak.$(date +%Y%m%d_%H%M%S)"
    cp "$HONCHO_DST" "$BACKUP"
    echo "   bestaande honcho.json gebackupt naar: $BACKUP"
fi
sed \
    -e "s|__HONCHO_PEER_NAME__|${HONCHO_PEER}|g" \
    -e "s|__HONCHO_AI_PEER__|${HONCHO_AI}|g" \
    -e "s|__HONCHO_WORKSPACE__|${HONCHO_WS}|g" \
    "$CONFIG_DIR/honcho.json" > "$HONCHO_DST"
echo "   honcho.json geïnstalleerd (peer: ${HONCHO_PEER}, workspace: ${HONCHO_WS})"

# model_metadata.py patch: MINIMUM_CONTEXT_LENGTH verlaagd naar qwen3:14b native max (40960).
# De upstream waarde (64000) overschrijdt de native context van qwen3:14b en blokkeert tool use
# op 12GB VRAM setups. 40960 is het maximum van qwen3:14b en past binnen 12GB VRAM.
echo "-- model_metadata.py patchen (MINIMUM_CONTEXT_LENGTH voor 12GB VRAM) --"
python3 - << 'PYEOF'
import pathlib
p = pathlib.Path.home() / '.hermes/hermes-agent/agent/model_metadata.py'
if not p.exists():
    print("   WAARSCHUWING: model_metadata.py niet gevonden, patch overgeslagen")
    exit(0)
old = p.read_text()
old_str = 'MINIMUM_CONTEXT_LENGTH = 64_000'
new_str = 'MINIMUM_CONTEXT_LENGTH = 40_960  # patched: qwen3:14b native max on 12GB VRAM'
if new_str in old:
    print("   patch al aanwezig")
elif old_str in old:
    p.write_text(old.replace(old_str, new_str, 1))
    print("   patch toegepast")
else:
    print("   WAARSCHUWING: patch-target niet gevonden — Hermes versie gewijzigd?")
PYEOF

# Honcho client.py patch: per-session strategie bypassed gateway_session_key zodat
# !new in Matrix een nieuwe Honcho sessie aanmaakt (session_id uit sessions.json).
echo "-- honcho client.py patchen (per-session gateway bypass) --"
python3 - << 'PYEOF'
import pathlib
p = pathlib.Path.home() / '.hermes/hermes-agent/plugins/memory/honcho/client.py'
if not p.exists():
    print("   WAARSCHUWING: client.py niet gevonden, patch overgeslagen")
    exit(0)
old = p.read_text()
old_str = 'if gateway_session_key:'
new_str = 'if gateway_session_key and self.session_strategy != "per-session":'
if new_str in old:
    print("   patch al aanwezig")
elif old_str in old:
    p.write_text(old.replace(old_str, new_str, 1))
    print("   patch toegepast")
else:
    print("   WAARSCHUWING: patch-target niet gevonden — Hermes versie gewijzigd?")
PYEOF

# honcho __init__.py patch: decoupleer _first_turn_timeout van de HTTP-client timeout.
# Door "timeout" in honcho.json te verhogen (120s) kan de dialectic call slagen nadat de
# hoofd-inference de GPU vrijgeeft. Zonder deze patch blokkeert diezelfde "timeout" ook
# de first-turn join van de hoofdthread, waardoor de eerste response 120s vertraagd wordt.
# De patch hardcodeert de first-turn join op 8s zodat responses niet worden vertraagd.
echo "-- honcho __init__.py patchen (first-turn timeout decoupleren van HTTP timeout) --"
python3 - << 'PYEOF'
import pathlib
p = pathlib.Path.home() / '.hermes/hermes-agent/plugins/memory/honcho/__init__.py'
if not p.exists():
    print("   WAARSCHUWING: __init__.py niet gevonden, patch overgeslagen")
    exit(0)
old = p.read_text()
old_str = '            _first_turn_timeout = (\n                self._config.timeout if self._config and self._config.timeout else 8.0\n            )'
new_str = '            _first_turn_timeout = 8.0  # patched: decoupleer van HTTP timeout (config.timeout)'
if new_str in old:
    print("   patch al aanwezig")
elif old_str in old:
    p.write_text(old.replace(old_str, new_str, 1))
    print("   patch toegepast")
else:
    print("   WAARSCHUWING: patch-target niet gevonden — Hermes versie gewijzigd?")
PYEOF

# memory_tool.py patch: coerceer None/lege action en map veelgebruikte synoniemen.
# qwen3:14b (en andere modellen) sturen soms action=None of synoniemen (update, store)
# bij cognitieve druk. De patch voorkomt een fout-retour en onnodige retry-ronde.
echo "-- memory_tool.py patchen (action=None coercion + synoniem-mapping) --"
python3 - << 'PYEOF'
import pathlib
p = pathlib.Path.home() / '.hermes/hermes-agent/tools/memory_tool.py'
if not p.exists():
    print("   WAARSCHUWING: memory_tool.py niet gevonden, patch overgeslagen")
    exit(0)
old = p.read_text()
old_str = '    if action == "add":'
new_str = (
    '    # patched: coerce None/empty + map common synonyms before dispatch\n'
    '    action = action or ""\n'
    '    _synonyms = {"update": "replace", "edit": "replace", "store": "add", "save": "add"}\n'
    '    action = _synonyms.get(action, action)\n'
    '    if action.lower() in ("", "none", "nothing_to_save", "skip", "no_action"):\n'
    '        return json.dumps({"success": True, "skipped": True, "message": "No memory action taken"}, ensure_ascii=False)\n'
    '\n'
    '    if action == "add":'
)
if '# patched: coerce None/empty' in old:
    print("   patch al aanwezig")
elif old_str in old:
    p.write_text(old.replace(old_str, new_str, 1))
    print("   patch toegepast")
else:
    print("   WAARSCHUWING: patch-target niet gevonden — Hermes versie gewijzigd?")
PYEOF

# SOUL.md — altijd vanuit repo installeren (is configuratie, geen data)
# Bestaande versie wordt gebackupt zodat niets verloren gaat
echo "-- SOUL.md installeren --"
SOUL_DST="$HOME/.hermes/SOUL.md"
if [[ -f "$SOUL_DST" ]]; then
    BACKUP="${SOUL_DST}.bak.$(date +%Y%m%d_%H%M%S)"
    cp "$SOUL_DST" "$BACKUP"
    echo "   bestaande SOUL.md gebackupt naar: $BACKUP"
fi
HONCHO_PEER="${BOOTSTRAP_HONCHO_PEER_NAME:-${USER}}"
HONCHO_AI="${BOOTSTRAP_HONCHO_AI_PEER:-atlas}"
sed \
    -e "s|__BOOTSTRAP_HONCHO_AI_PEER__|${HONCHO_AI}|g" \
    -e "s|__BOOTSTRAP_USER_FULLNAME__|${BOOTSTRAP_USER_FULLNAME:-${USER}}|g" \
    -e "s|__BOOTSTRAP_COMPANY_NAME__|${BOOTSTRAP_COMPANY_NAME:-Your Company}|g" \
    -e "s|__BOOTSTRAP_HOSTNAME__|${BOOTSTRAP_HOSTNAME:-ai-workstation}|g" \
    -e "s|__BOOTSTRAP_VIKUNJA_HOST__|${BOOTSTRAP_VIKUNJA_HOST:-}|g" \
    -e "s|__BOOTSTRAP_OUTLINE_URL__|${BOOTSTRAP_OUTLINE_URL:-}|g" \
    -e "s|__BOOTSTRAP_MATRIX_ROOM_ID__|${BOOTSTRAP_MATRIX_ROOM_ID:-}|g" \
    -e "s|__BOOTSTRAP_WINDOWS_USER__|${OBSIDIAN_WINDOWS_USER}|g" \
    -e "s|__BOOTSTRAP_OBSIDIAN_VAULT_SUBDIR__|${OBSIDIAN_VAULT_SUBDIR}|g" \
    -e "s|__BOOTSTRAP_NAS_HOST__|${BOOTSTRAP_NAS_HOST:-}|g" \
    "$CONFIG_DIR/SOUL.md" > "$SOUL_DST"
echo "   SOUL.md geïnstalleerd"

# .hermes.md — altijd installeren in hermes-agent werkmap (operationele context: Vikunja, Obsidian, systeem)
# Staat in de gateway CWD zodat build_context_files_prompt() het automatisch laadt.
# Gitignored in hermes-agent repo — wordt niet overschreven door git pull.
echo "-- .hermes.md installeren --"
HERMES_MD_DST="$HOME/.hermes/hermes-agent/.hermes.md"
sed \
    -e "s|__BOOTSTRAP_HONCHO_AI_PEER__|${HONCHO_AI}|g" \
    -e "s|__BOOTSTRAP_HOSTNAME__|${BOOTSTRAP_HOSTNAME:-ai-workstation}|g" \
    -e "s|__BOOTSTRAP_NAS_HOST__|${BOOTSTRAP_NAS_HOST:-}|g" \
    -e "s|__BOOTSTRAP_MATRIX_ROOM_ID__|${BOOTSTRAP_MATRIX_ROOM_ID:-}|g" \
    -e "s|__BOOTSTRAP_OUTLINE_URL__|${BOOTSTRAP_OUTLINE_URL:-}|g" \
    -e "s|__BOOTSTRAP_VIKUNJA_HOST__|${BOOTSTRAP_VIKUNJA_HOST:-}|g" \
    -e "s|__BOOTSTRAP_WINDOWS_USER__|${OBSIDIAN_WINDOWS_USER}|g" \
    -e "s|__BOOTSTRAP_OBSIDIAN_VAULT_SUBDIR__|${OBSIDIAN_VAULT_SUBDIR}|g" \
    "$CONFIG_DIR/.hermes.md" > "$HERMES_MD_DST"
echo "   .hermes.md geïnstalleerd in ~/.hermes/hermes-agent/"

# MEMORY.md en USER.md — alleen installeren bij frisse installatie (zijn data, groeien over tijd)
echo "-- basis geheugen installeren --"
mkdir -p "$HOME/.hermes/memories"

_render_memory_file() {
    local src="$1" dst="$2"
    sed \
        -e "s|__BOOTSTRAP_WINDOWS_USER__|${OBSIDIAN_WINDOWS_USER}|g" \
        -e "s|__BOOTSTRAP_OBSIDIAN_VAULT_SUBDIR__|${OBSIDIAN_VAULT_SUBDIR}|g" \
        -e "s|__BOOTSTRAP_USER_FULLNAME__|${BOOTSTRAP_USER_FULLNAME:-${USER}}|g" \
        -e "s|__BOOTSTRAP_COMPANY_NAME__|${BOOTSTRAP_COMPANY_NAME:-Your Company}|g" \
        "$src" > "$dst"
}

MEMORY_DST="$HOME/.hermes/memories/MEMORY.md"
if [[ ! -f "$MEMORY_DST" ]]; then
    _render_memory_file "$CONFIG_DIR/MEMORY.md" "$MEMORY_DST"
    echo "   MEMORY.md geïnstalleerd"
else
    echo "   MEMORY.md bestaat al — overgeslagen (gebruik --reset-memory om te overschrijven)"
fi

USER_DST="$HOME/.hermes/memories/USER.md"
if [[ ! -f "$USER_DST" ]]; then
    _render_memory_file "$CONFIG_DIR/USER.md" "$USER_DST"
    echo "   USER.md geïnstalleerd"
else
    echo "   USER.md bestaat al — overgeslagen"
fi

# --reset-memory flag: overschrijf geheugenbestanden ook (met backup)
if [[ "${1:-}" == "--reset-memory" ]]; then
    echo "-- geheugen resetten (--reset-memory) --"
    for f in MEMORY.md USER.md; do
        DST="$HOME/.hermes/memories/$f"
        if [[ -f "$DST" ]]; then
            cp "$DST" "${DST}.bak.$(date +%Y%m%d_%H%M%S)"
        fi
        _render_memory_file "$CONFIG_DIR/$f" "$DST"
        echo "   $f hersteld vanuit repo"
    done
fi

cat <<'MSG'

== Hermes Agent geïnstalleerd ==

Nog handmatig uitvoeren (vereist interactieve terminal):

  hermes setup
    → Kies: Matrix als platform
    → Kies: custom provider (Ollama)
    → Base URL: http://localhost:11434/v1
    → Default model: qwen3-30b:iq2xxs

  hermes memory setup
    → Kies: honcho
    → Base URL: http://localhost:8000
    → Workspace: (zie BOOTSTRAP_HONCHO_WORKSPACE in config/bootstrap.env)
    → User peer: (zie BOOTSTRAP_HONCHO_PEER_NAME) / AI peer: (zie BOOTSTRAP_HONCHO_AI_PEER)

Na setup:
  systemctl --user enable hermes-gateway.service
  systemctl --user start hermes-gateway.service

SOUL.md en honcho.json worden hersteld door dit script opnieuw te draaien.
Let op: hermes setup overschrijft honcho.json. Herstel daarna met:
  cp ~/ai-workstation-bootstrap/config/hermes/honcho.json ~/.hermes/honcho.json
MSG
