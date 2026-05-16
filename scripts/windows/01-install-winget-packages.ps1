$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path))
$packageFile = Join-Path $repoRoot "config\winget-packages.txt"

if (!(Test-Path $packageFile)) {
    throw "Package file not found: $packageFile"
}

$packages = Get-Content $packageFile | Where-Object { $_ -and -not $_.StartsWith("#") }

foreach ($pkg in $packages) {
    Write-Host "Installing $pkg..."
    winget install --id $pkg --exact --source winget --accept-package-agreements --accept-source-agreements
}

Write-Host "Winget package installation complete."
