#!/usr/bin/env bash
set -euo pipefail

echo "== Start Open WebUI =="

if ! command -v docker >/dev/null 2>&1; then
  echo "FOUT: docker niet gevonden. Voer eerst 01-dev-tools.sh uit."
  exit 1
fi

# Verwijder oude container als die bestaat (idempotent)
if docker ps -a --format '{{.Names}}' | grep -q '^open-webui$'; then
  echo "INFO: bestaande open-webui container gevonden — verwijderen voor herinstallatie."
  docker rm -f open-webui
fi

# Open WebUI als standalone container
# --add-host=host.docker.internal:host-gateway zorgt dat de container Ollama
# kan bereiken op 172.17.0.1:11434 (native Docker bridge naar WSL2 host)
docker run -d \
  --name open-webui \
  --add-host=host.docker.internal:host-gateway \
  -p 3000:8080 \
  -v open-webui:/app/backend/data \
  --restart always \
  ghcr.io/open-webui/open-webui:main

echo "Open WebUI gestart op http://localhost:3000"
echo "Ollama wordt automatisch ontdekt via host.docker.internal:11434"
