[CmdletBinding()]
param()

Write-Host "== Windows verification =="

Write-Host "`n== Computer name =="
$env:COMPUTERNAME

Write-Host "`n== WSL =="
wsl --list --verbose

Write-Host "`n== Docker =="
docker version

Write-Host "`n== NVIDIA =="
nvidia-smi

Write-Host "`n== Git =="
git --version

Write-Host "`n== Ollama Windows check =="
if (Get-Command ollama -ErrorAction SilentlyContinue) {
    Write-Warning "Ollama is installed on Windows. Current baseline expects Ollama native in WSL."
    ollama --version
}
else {
    Write-Host "OK: Ollama not installed on Windows. Expected: WSL-native Ollama."
}
