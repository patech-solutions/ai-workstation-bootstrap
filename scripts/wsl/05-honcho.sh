#!/usr/bin/env bash
set -euo pipefail

echo "== Install local Honcho =="

BASE_DIR="$HOME/.local/share/patech"
HONCHO_DIR="$BASE_DIR/honcho"

mkdir -p "$BASE_DIR"

if [ ! -d "$HONCHO_DIR/.git" ]; then
  git clone https://github.com/plastic-labs/honcho.git "$HONCHO_DIR"
fi

cd "$HONCHO_DIR"

if [ ! -f docker-compose.yml ] && [ -f docker-compose.yml.example ]; then
  cp docker-compose.yml.example docker-compose.yml
fi

if [ ! -f .env ] && [ -f .env.template ]; then
  cp .env.template .env
fi

docker compose up -d

cat <<'MSG'
Honcho local/self-hosted started.

Expected endpoint:
  http://localhost:8000

Set for local tooling:
  export HONCHO_URL=http://localhost:8000

Add this to ~/.bashrc if desired.
MSG
