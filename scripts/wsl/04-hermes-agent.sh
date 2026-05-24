#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CONFIG_DIR="$REPO_ROOT/config/hermes"

echo "== Hermes Agent installeren =="

# Installeer Hermes
curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh | bash

# faster-whisper voor lokale STT
echo "-- faster-whisper installeren --"
uv pip install faster-whisper --python "$HOME/.hermes/hermes-agent/venv/bin/python"

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
  phi4:14b@http://localhost:11434/v1: 131072
  phi4:14b@http://localhost:11434/v1/: 131072
  phi4-tools:14b@http://localhost:11434/v1: 131072
  phi4-tools:14b@http://localhost:11434/v1/: 131072
  aya-expanse:8b@http://localhost:11434/v1: 131072
  aya-expanse:8b@http://localhost:11434/v1/: 131072
EOF

# phi4-tools:14b — custom Modelfile met tool-support en num_ctx 8192
# Altijd herbouwen: Modelfile-wijzigingen (num_ctx, template) worden anders overgeslagen.
echo "-- phi4-tools:14b Modelfile bouwen --"
MODELFILE_SRC="$CONFIG_DIR/modelfiles/phi4-tools.Modelfile"
if [[ -f "$MODELFILE_SRC" ]]; then
    ollama create phi4-tools:14b -f "$MODELFILE_SRC"
    echo "   phi4-tools:14b gebouwd"
else
    echo "   WAARSCHUWING: $MODELFILE_SRC niet gevonden — phi4-tools:14b niet aangemaakt"
fi

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
cp "$CONFIG_DIR/config.yaml" "$CONFIG_YAML_DST"
echo "   config.yaml geïnstalleerd"

# patch_yaml — idempotent YAML-sleutel patcher (voor geneste sleutels als honcho.contextTokens)
# Gebruik: patch_yaml <bestand> <ouder_sleutel> <kind_sleutel> <waarde>
patch_yaml() {
  local file="$1" parent="$2" child="$3" value="$4"
  python3 - "$file" "$parent" "$child" "$value" <<'PYEOF'
import sys, re

file, parent, child, value = sys.argv[1:]

with open(file, encoding="utf-8") as f:
    text = f.read()

# Probeer bestaande child-sleutel onder parent te vervangen
pattern = rf"(?m)(^{re.escape(parent)}:\s*\n(?:[ \t]+[^\n]*\n)*?[ \t]+{re.escape(child)}:\s*)(\S+)"
replacement = lambda m: m.group(1) + value
new_text = re.sub(pattern, replacement, text)

if new_text == text:
    # Voeg child toe onder parent als parent bestaat maar child niet
    parent_pattern = rf"(?m)^({re.escape(parent)}:)([ \t]*)\n"
    def add_child(m):
        return f"{m.group(1)}\n  {child}: {value}\n"
    new_text = re.sub(parent_pattern, add_child, text, count=1)

if new_text != text:
    with open(file, "w", encoding="utf-8") as f:
        f.write(new_text)
    print(f"   {parent}.{child} = {value}")
else:
    print(f"   {parent}.{child} ongewijzigd (al correct of parent niet gevonden)")
PYEOF
}

# Kritieke instellingen garanderen (zelfs als config.yaml handmatig gewijzigd is)
echo "-- kritieke config.yaml instellingen patchen --"
patch_yaml "$CONFIG_YAML_DST" "honcho" "contextTokens" "3000"

# honcho.json — altijd vanuit repo installeren (bevat pinPeerName en peer config)
echo "-- honcho.json installeren --"
HONCHO_DST="$HOME/.hermes/honcho.json"
if [[ -f "$HONCHO_DST" ]]; then
    BACKUP="${HONCHO_DST}.bak.$(date +%Y%m%d_%H%M%S)"
    cp "$HONCHO_DST" "$BACKUP"
    echo "   bestaande honcho.json gebackupt naar: $BACKUP"
fi
cp "$CONFIG_DIR/honcho.json" "$HONCHO_DST"
echo "   honcho.json geïnstalleerd"

# SOUL.md — altijd vanuit repo installeren (is configuratie, geen data)
# Bestaande versie wordt gebackupt zodat niets verloren gaat
echo "-- SOUL.md installeren --"
SOUL_DST="$HOME/.hermes/SOUL.md"
if [[ -f "$SOUL_DST" ]]; then
    BACKUP="${SOUL_DST}.bak.$(date +%Y%m%d_%H%M%S)"
    cp "$SOUL_DST" "$BACKUP"
    echo "   bestaande SOUL.md gebackupt naar: $BACKUP"
fi
cp "$CONFIG_DIR/SOUL.md" "$SOUL_DST"
echo "   SOUL.md geïnstalleerd"

# MEMORY.md en USER.md — alleen installeren bij frisse installatie (zijn data, groeien over tijd)
echo "-- basis geheugen installeren --"
mkdir -p "$HOME/.hermes/memories"

MEMORY_DST="$HOME/.hermes/memories/MEMORY.md"
if [[ ! -f "$MEMORY_DST" ]]; then
    cp "$CONFIG_DIR/MEMORY.md" "$MEMORY_DST"
    echo "   MEMORY.md geïnstalleerd"
else
    echo "   MEMORY.md bestaat al — overgeslagen (gebruik --reset-memory om te overschrijven)"
fi

USER_DST="$HOME/.hermes/memories/USER.md"
if [[ ! -f "$USER_DST" ]]; then
    cp "$CONFIG_DIR/USER.md" "$USER_DST"
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
        cp "$CONFIG_DIR/$f" "$DST"
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
    → Workspace: patech-wsa-01
    → User peer: pascal / AI peer: atlas

Na setup:
  systemctl --user enable hermes-gateway.service
  systemctl --user start hermes-gateway.service

SOUL.md en honcho.json worden hersteld door dit script opnieuw te draaien.
Let op: hermes setup overschrijft honcho.json. Herstel daarna met:
  cp ~/ai-workstation-bootstrap/config/hermes/honcho.json ~/.hermes/honcho.json
MSG
