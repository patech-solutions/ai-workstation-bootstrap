#!/usr/bin/env bash
set -euo pipefail

# Ollama GPU Warmup — heartbeat timer zodat qwen3:14b warm blijft in VRAM
# Voorkomt cold-start vertraging (1-3 min) na lange inactiviteit in WSL2.
#
# Aanvullend: zet in Windows PowerShell vóór WSL-start:
#   Copy-Item "config\wslconfig" "$env:USERPROFILE\.wslconfig"
#   wsl --shutdown
# Daarna WSL opnieuw opstarten om guiApplications=false en
# autoMemoryReclaim=disabled te activeren.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

HEARTBEAT_MODEL="${OLLAMA_HEARTBEAT_MODEL:-qwen3:14b}"

echo "== Ollama GPU warmup instellen =="

# Heartbeat shell script
echo "-- heartbeat script installeren --"
if [[ ! -f /usr/local/bin/ollama-heartbeat.sh ]] || \
   ! grep -q "$HEARTBEAT_MODEL" /usr/local/bin/ollama-heartbeat.sh 2>/dev/null; then
    sudo tee /usr/local/bin/ollama-heartbeat.sh > /dev/null << SCRIPT
#!/usr/bin/env bash
# Stuur minimale generate-call om model in VRAM te houden
curl -s -X POST http://localhost:11434/api/generate \\
  -d '{"model":"${HEARTBEAT_MODEL}","prompt":"hi","stream":false,"options":{"num_predict":1}}' \\
  -o /dev/null
SCRIPT
    sudo chmod +x /usr/local/bin/ollama-heartbeat.sh
    echo "   heartbeat script geïnstalleerd (model: ${HEARTBEAT_MODEL})"
else
    echo "   heartbeat script al aanwezig"
fi

# Systemd service
echo "-- ollama-heartbeat.service installeren --"
SERVICE_FILE=/etc/systemd/system/ollama-heartbeat.service
SERVICE_CONTENT="[Unit]
Description=Ollama GPU Heartbeat — houdt model warm in VRAM
After=ollama.service

[Service]
Type=oneshot
ExecStart=/usr/local/bin/ollama-heartbeat.sh"

if [[ ! -f "$SERVICE_FILE" ]] || ! diff -q <(echo "$SERVICE_CONTENT") "$SERVICE_FILE" > /dev/null 2>&1; then
    echo "$SERVICE_CONTENT" | sudo tee "$SERVICE_FILE" > /dev/null
    echo "   service geïnstalleerd"
else
    echo "   service al aanwezig"
fi

# Systemd timer (elke 10 minuten)
echo "-- ollama-heartbeat.timer installeren --"
TIMER_FILE=/etc/systemd/system/ollama-heartbeat.timer
TIMER_CONTENT="[Unit]
Description=Ollama GPU Heartbeat Timer

[Timer]
OnBootSec=5min
OnUnitActiveSec=10min
Unit=ollama-heartbeat.service

[Install]
WantedBy=timers.target"

if [[ ! -f "$TIMER_FILE" ]] || ! diff -q <(echo "$TIMER_CONTENT") "$TIMER_FILE" > /dev/null 2>&1; then
    echo "$TIMER_CONTENT" | sudo tee "$TIMER_FILE" > /dev/null
    echo "   timer geïnstalleerd"
else
    echo "   timer al aanwezig"
fi

# Activeren
echo "-- timer activeren --"
sudo systemctl daemon-reload
sudo systemctl enable --now ollama-heartbeat.timer
echo "   timer actief"

echo ""
systemctl status ollama-heartbeat.timer --no-pager
