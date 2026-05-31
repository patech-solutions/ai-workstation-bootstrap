[CmdletBinding()]
param(
    [switch]$SkipHostname,
    [switch]$SkipBloatware,
    [switch]$SkipWsl
)

$ErrorActionPreference = "Stop"

$ConfigFile = Join-Path $PSScriptRoot "..\..\config\bootstrap.ps1"
if (Test-Path $ConfigFile) {
    . $ConfigFile
} else {
    Write-Warning "config\bootstrap.ps1 niet gevonden. Kopieer bootstrap.ps1.example en vul in."
}

$hostname = if ($BOOTSTRAP_HOSTNAME) { $BOOTSTRAP_HOSTNAME } else { "ai-workstation" }
Write-Host "AI Workstation Windows bootstrap — $hostname"

if (-not $SkipHostname -and (Test-Path "$PSScriptRoot\00-set-hostname.ps1")) {
    & "$PSScriptRoot\00-set-hostname.ps1"
}

& "$PSScriptRoot\01-install-winget-packages.ps1"

if (-not $SkipBloatware -and (Test-Path "$PSScriptRoot\04-remove-windows-bloatware.ps1")) {
    & "$PSScriptRoot\04-remove-windows-bloatware.ps1" -AggressiveNortonCleanup
}

if (-not $SkipWsl -and (Test-Path "$PSScriptRoot\00-enable-wsl.ps1")) {
    & "$PSScriptRoot\00-enable-wsl.ps1"
}

Write-Host "Windows bootstrap phase complete."
Write-Warning "Reboot Windows if hostname or WSL changed."
Write-Warning "After reboot, open Ubuntu and run scripts/wsl/90-bootstrap-wsl.sh"
