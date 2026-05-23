#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "== Install local Honcho =="

BASE_DIR="$HOME/.local/share/patech"
HONCHO_DIR="$BASE_DIR/honcho"

mkdir -p "$BASE_DIR"

if [ ! -d "$HONCHO_DIR/.git" ]; then
  git clone https://github.com/plastic-labs/honcho.git "$HONCHO_DIR"
else
  git -C "$HONCHO_DIR" pull --ff-only
fi

cd "$HONCHO_DIR"

if [ ! -f docker-compose.yml ] && [ -f docker-compose.yml.example ]; then
  cp docker-compose.yml.example docker-compose.yml
fi

# .env configureren voor lokale Ollama via native Docker bridge (host-gateway = 172.17.0.1)
# host.docker.internal wordt via extra_hosts in docker-compose.yml gezet op host-gateway.
# OLLAMA_HOST=0.0.0.0 in ollama keepalive.conf is vereist zodat dit werkt.
if [ ! -f .env ] && [ -f .env.template ]; then
  cp .env.template .env
fi

# Idempotent: stel variabelen in via sed (overschrijf alleen de regel, voeg toe als afwezig)
set_env() {
  local key="$1" value="$2" file=".env"
  if grep -q "^${key}=" "$file" 2>/dev/null; then
    sed -i "s|^${key}=.*|${key}=${value}|" "$file"
  else
    echo "${key}=${value}" >> "$file"
  fi
}

# LLM provider: Ollama via OpenAI-compatible API
set_env LLM_OPENAI_API_KEY "ollama"

# Embeddings via Ollama — nomic-embed-text (274 MB, past naast qwen3-30b:iq2xxs in VRAM)
set_env EMBED_MESSAGES "false"
set_env EMBEDDING_MODEL_CONFIG__TRANSPORT "openai"
set_env EMBEDDING_MODEL_CONFIG__MODEL "nomic-embed-text"
set_env EMBEDDING_MODEL_CONFIG__OVERRIDES__BASE_URL "http://host.docker.internal:11434/v1"
set_env EMBEDDING_VECTOR_DIMENSIONS "768"

# Deriver — achtergrondverwerking van geheugen (licht model)
set_env DERIVER_MODEL_CONFIG__TRANSPORT "openai"
set_env DERIVER_MODEL_CONFIG__MODEL "qwen3-30b:iq2xxs"
set_env DERIVER_MODEL_CONFIG__OVERRIDES__BASE_URL "http://host.docker.internal:11434/v1"
set_env DERIVER_STALE_SESSION_TIMEOUT_MINUTES "15"
set_env DERIVER_FLUSH_ENABLED "true"
set_env DERIVER_DEDUPLICATE "true"

# Dream — drempelwaarden voor consolidatiecyclus
set_env DREAM_IDLE_TIMEOUT_MINUTES "30"
set_env DREAM_MIN_HOURS_BETWEEN_DREAMS "4"

# Summary
set_env SUMMARY_MODEL_CONFIG__TRANSPORT "openai"
set_env SUMMARY_MODEL_CONFIG__MODEL "qwen3-30b:iq2xxs"
set_env SUMMARY_MODEL_CONFIG__OVERRIDES__BASE_URL "http://host.docker.internal:11434/v1"

# Dream — geheugenconsolidatie op de achtergrond
set_env DREAM_DEDUCTION_MODEL_CONFIG__TRANSPORT "openai"
set_env DREAM_DEDUCTION_MODEL_CONFIG__MODEL "qwen3-30b:iq2xxs"
set_env DREAM_DEDUCTION_MODEL_CONFIG__OVERRIDES__BASE_URL "http://host.docker.internal:11434/v1"
set_env DREAM_INDUCTION_MODEL_CONFIG__TRANSPORT "openai"
set_env DREAM_INDUCTION_MODEL_CONFIG__MODEL "qwen3-30b:iq2xxs"
set_env DREAM_INDUCTION_MODEL_CONFIG__OVERRIDES__BASE_URL "http://host.docker.internal:11434/v1"

# Dialectic — zelfde model als Hermes zodat het warm blijft in VRAM
for level in minimal low medium high max; do
  set_env "DIALECTIC_LEVELS__${level}__MODEL_CONFIG__TRANSPORT" "openai"
  set_env "DIALECTIC_LEVELS__${level}__MODEL_CONFIG__MODEL" "qwen3-30b:iq2xxs"
  set_env "DIALECTIC_LEVELS__${level}__MODEL_CONFIG__OVERRIDES__BASE_URL" "http://host.docker.internal:11434/v1"
done

# Vector store
set_env VECTOR_STORE_TYPE "pgvector"
set_env VECTOR_STORE_MIGRATED "false"

docker compose up -d --build

# Honcho dashboard — script vanuit repo installeren
DASHBOARD_SCRIPT="$HOME/.hermes/scripts/honcho-dashboard.py"
SERVICE_FILE="$HOME/.config/systemd/user/honcho-dashboard.service"

mkdir -p "$HOME/.hermes/scripts"
cp "$REPO_ROOT/config/hermes/scripts/honcho-dashboard.py" "$DASHBOARD_SCRIPT"
echo "honcho-dashboard.py geïnstalleerd"

# Systemd user service
if true; then
  mkdir -p "$HOME/.config/systemd/user"
  cat > "$SERVICE_FILE" << 'EOF'
[Unit]
Description=Honcho Memory Dashboard
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 /home/pascal/.hermes/scripts/honcho-dashboard.py
WorkingDirectory=/home/pascal/.hermes
Environment="HONCHO_URL=http://localhost:8000"
Environment="HONCHO_WORKSPACE=patech-wsa-01"
Environment="DASHBOARD_PORT=8080"
Restart=always
RestartSec=5

[Install]
WantedBy=default.target
EOF
  systemctl --user daemon-reload
  systemctl --user enable --now honcho-dashboard.service
  echo "Dashboard beschikbaar op http://localhost:8080"
fi  # end systemd block

echo ""
echo "Honcho gestart op http://localhost:8000"
echo "Stel in Hermes in via: hermes memory setup → Lokaal → http://localhost:8000"
