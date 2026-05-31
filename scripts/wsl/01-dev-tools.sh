#!/usr/bin/env bash
set -eo pipefail

echo "== AI Workstation bootstrap: dev tools =="

if ! command -v uv >/dev/null 2>&1; then
  curl -LsSf https://astral.sh/uv/install.sh | sh
fi

export PATH="$HOME/.local/bin:$PATH"

if ! grep -q 'export PATH="$HOME/.local/bin:$PATH"' "$HOME/.bashrc"; then
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
fi

uv --version

if ! command -v node >/dev/null 2>&1; then
  curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
  sudo apt install -y nodejs
fi

node --version
npm --version

# Docker CE (native in WSL2 — niet Docker Desktop)
# Docker Desktop containers zitten in een geïsoleerd netwerk en kunnen Ollama in WSL2
# niet bereiken. Native docker-ce deelt hetzelfde netwerk als Ollama en Hermes.
if ! command -v docker >/dev/null 2>&1 || ! docker info >/dev/null 2>&1; then
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] \
    https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
    | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  sudo apt-get update -qq
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
fi

sudo systemctl enable docker
sudo systemctl start docker

if ! groups "$USER" | grep -qw docker; then
  sudo usermod -aG docker "$USER"
  echo "INFO: Gebruiker toegevoegd aan docker group. Heropen shell of gebruik 'newgrp docker'."
fi

docker --version

echo "== Dev tools bootstrap complete =="
