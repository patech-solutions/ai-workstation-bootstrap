$ErrorActionPreference = "Stop"

$sshDir = Join-Path $env:USERPROFILE ".ssh"
$keyPath = Join-Path $sshDir "id_ed25519_gitea"

if (!(Test-Path $sshDir)) {
    New-Item -ItemType Directory -Path $sshDir | Out-Null
}

if (Test-Path $keyPath) {
    Write-Host "Key already exists: $keyPath"
} else {
    ssh-keygen -t ed25519 -C "vandeborp@gitea-ai-workstation" -f $keyPath
}

Write-Host ""
Write-Host "Public key:"
Get-Content "$keyPath.pub"
Write-Host ""
Write-Host "Add this public key to Gitea."
