# Run as Administrator
[CmdletBinding()]
param(
    [string]$Hostname
)

$ConfigFile = Join-Path $PSScriptRoot "..\..\config\bootstrap.ps1"
if (-not $Hostname) {
    if (Test-Path $ConfigFile) {
        . $ConfigFile
        $Hostname = $BOOTSTRAP_HOSTNAME
    } else {
        Write-Error "Geen hostname opgegeven en config\bootstrap.ps1 niet gevonden. Kopieer bootstrap.ps1.example en vul in."
        exit 1
    }
}

$current = $env:COMPUTERNAME.ToLower()
if ($current -eq $Hostname.ToLower()) {
    Write-Host "Hostname is al $Hostname"
} else {
    Write-Host "Hostnaam wijzigen van $current naar $Hostname"
    Rename-Computer -NewName $Hostname -Force
    Write-Host "Herstart vereist. Voer uit: Restart-Computer"
}
