# Run as Administrator
$ErrorActionPreference = "Stop"

Write-Host "Applying Windows security baseline..."

manage-bde -status C:

Set-MpPreference -DisableRealtimeMonitoring $false
Set-MpPreference -PUAProtection Enabled

Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name HideFileExt -Value 0

Disable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -NoRestart -ErrorAction SilentlyContinue

Write-Host "Security baseline applied. Review BitLocker manually if not enabled."
