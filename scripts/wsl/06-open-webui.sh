cat > scripts/wsl/06-open-webui.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

echo "== Start Open WebUI =="

if ! command -v docker >/dev/null 2>&1; then
  echo "WARN: docker not found in WSL. Enable Docker Desktop WSL integration first."
  exit 0
fi

if [ ! -f compose/open-webui.compose.yml ]; then
  echo "WARN: compose/open-webui.compose.yml not found. Skipping Open WebUI."
  exit 0
fi

docker compose -f compose/open-webui.compose.yml up -d

echo "Open WebUI started."
EOF

chmod +x scripts/wsl/06-open-webui.sh