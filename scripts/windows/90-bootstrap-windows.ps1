[CmdletBinding()]
param(
    [switch]$SkipHostname,
    [switch]$SkipBloatware,
    [switch]$SkipWsl
)

$ErrorActionPreference = "Stop"

Write-Host "PaTech Windows bootstrap for patech-wsa-01"

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
