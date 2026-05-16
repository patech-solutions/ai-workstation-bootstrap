<#
.SYNOPSIS
  One-shot Windows bootstrap runner for PaTech AI workstation patech-wsa-01.

.DESCRIPTION
  Runs Windows-side setup phases in a controlled order. Some phases require a reboot.
  Re-run this script after reboot; completed phases are skipped via marker files.

.PARAMETER SkipRename
  Skip hostname rename phase.

.PARAMETER SkipWSL
  Skip WSL installation phase.

.PARAMETER SkipPackages
  Skip winget package installation phase.

.PARAMETER SkipCleanup
  Skip bloatware cleanup phase.

.PARAMETER DryRunCleanup
  Runs the bloatware cleanup script in WhatIfOnly mode.
#>

param(
    [switch]$SkipRename,
    [switch]$SkipWSL,
    [switch]$SkipPackages,
    [switch]$SkipCleanup,
    [switch]$DryRunCleanup
)

$ErrorActionPreference = "Stop"

$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$StateDir = Join-Path $RepoRoot ".bootstrap-state"
New-Item -ItemType Directory -Path $StateDir -Force | Out-Null

function Test-Admin {
    $currentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentIdentity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Invoke-Phase {
    param(
        [string]$Name,
        [string]$Script,
        [string[]]$Arguments = @(),
        [switch]$RequiresAdmin,
        [switch]$MayNeedReboot
    )

    $marker = Join-Path $StateDir "$Name.done"
    if (Test-Path $marker) {
        Write-Host "==> Skipping $Name; marker exists" -ForegroundColor DarkGray
        return
    }

    if ($RequiresAdmin -and -not (Test-Admin)) {
        throw "Phase '$Name' requires PowerShell as Administrator."
    }

    $fullScript = Join-Path $PSScriptRoot $Script
    if (!(Test-Path $fullScript)) {
        throw "Script not found: $fullScript"
    }

    Write-Host "==> Running phase: $Name" -ForegroundColor Cyan
    & powershell -NoProfile -ExecutionPolicy Bypass -File $fullScript @Arguments

    New-Item -ItemType File -Path $marker -Force | Out-Null

    if ($MayNeedReboot) {
        Write-Host "Phase '$Name' may require reboot. Re-run 90-bootstrap-windows.ps1 after reboot." -ForegroundColor Yellow
    }
}

Write-Host "PaTech Windows bootstrap runner" -ForegroundColor Green
Write-Host "Repo root: $RepoRoot"
Write-Host "State dir : $StateDir"

if (-not $SkipRename) {
    Invoke-Phase -Name "00-set-hostname" -Script "00-set-hostname.ps1" -RequiresAdmin -MayNeedReboot
}

if (-not $SkipWSL) {
    Invoke-Phase -Name "01-enable-wsl" -Script "01-enable-wsl.ps1" -RequiresAdmin -MayNeedReboot
}

if (-not $SkipPackages) {
    Invoke-Phase -Name "02-install-winget-packages" -Script "02-install-winget-packages.ps1"
}

Invoke-Phase -Name "03-windows-security-baseline" -Script "03-windows-security-baseline.ps1" -RequiresAdmin

if (-not $SkipCleanup) {
    $cleanupArgs = @()
    if ($DryRunCleanup) { $cleanupArgs += "-WhatIfOnly" }
    Invoke-Phase -Name "04-remove-windows-bloatware" -Script "04-remove-windows-bloatware.ps1" -Arguments $cleanupArgs -RequiresAdmin
}

Write-Host "Windows bootstrap phases completed or marked. Run 99-verify-windows.ps1 after final reboot." -ForegroundColor Green
