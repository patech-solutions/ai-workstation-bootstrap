# Run as Administrator
$ErrorActionPreference = "Stop"

Write-Host "Enabling WSL2 and installing Ubuntu 24.04..."

wsl --install -d Ubuntu-24.04
wsl --set-default-version 2

Write-Host "Done. Reboot if Windows asks for it. Then start Ubuntu once and create your Linux user."
