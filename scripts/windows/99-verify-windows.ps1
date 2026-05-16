Write-Host "== Hostname =="
$env:COMPUTERNAME

Write-Host "== WSL =="
wsl --list --verbose

Write-Host "== Docker =="
docker version

Write-Host "== NVIDIA =="
nvidia-smi

Write-Host "== Ollama =="
ollama --version
