#!/usr/bin/env bash
set -euo pipefail

sudo apt update
sudo apt upgrade -y

sudo apt install -y \
  build-essential \
  curl \
  wget \
  git \
  jq \
  unzip \
  ca-certificates \
  gnupg \
  lsb-release \
  htop \
  btop \
  nvtop \
  tmux \
  direnv \
  ripgrep \
  fd-find \
  fzf \
  tree \
  shellcheck

sudo hostnamectl set-hostname patech-wsa-01-wsl || true

git config --global user.name "Pascal van de Bor"
git config --global user.email "vandeborp@gmail.com"
git config --global init.defaultBranch main

echo "WSL bootstrap complete for patech-wsa-01-wsl."
