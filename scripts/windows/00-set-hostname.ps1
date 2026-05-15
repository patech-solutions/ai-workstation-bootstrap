# Run as Administrator
$TargetName = "patech-wsa-01"
$current = $env:COMPUTERNAME.ToLower()

if ($current -eq $TargetName) {
    Write-Host "Hostname is already $TargetName"
} else {
    Write-Host "Renaming computer from $current to $TargetName"
    Rename-Computer -NewName $TargetName -Force
    Write-Host "Restart required. Run: Restart-Computer"
}
