#!/usr/bin/env bash
set -euo pipefail

echo "Preparing Honcho local memory service..."

if [ -f "compose/honcho.compose.yml" ]; then
  docker compose -f compose/honcho.compose.yml up -d || {
    echo "Honcho Docker start failed. Check whether the image/tag is available or update compose/honcho.compose.yml."
    exit 0
  }
fi

echo "Honcho check:"
curl -fsS http://localhost:8000/health || echo "Honcho health endpoint not reachable yet; verify the selected Honcho image/config."
