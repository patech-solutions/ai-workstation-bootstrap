# Run as Administrator

Write-Host "Enabling Windows Firewall profiles"
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True

Write-Host "Checking BitLocker status"
manage-bde -status C:

Write-Host "Disabling RDP unless explicitly needed"
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name "fDenyTSConnections" -Value 1

Write-Host "Security baseline applied. Manually enable BitLocker if not already enabled."
