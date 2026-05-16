<#
.SYNOPSIS
  Removes or disables consumer/gaming/OEM noise for PaTech AI workstation.

.DESCRIPTION
  Safe-ish baseline for patech-wsa-01. Removes common Windows consumer apps,
  disables Xbox/Game Bar/Widgets/Copilot taskbar bits where possible, and disables
  auto-start entries for MSI/SteelSeries/Nahimic style tooling without uninstalling
  drivers or firmware utilities.

.PARAMETER WhatIfOnly
  Runs in dry-run mode. Shows what would be changed.

.NOTES
  Run as the target user after Windows setup. Some HKLM operations need Admin.
#>

param(
    [switch]$WhatIfOnly
)

$ErrorActionPreference = "Continue"

function Invoke-Change {
    param(
        [string]$Description,
        [scriptblock]$Action
    )

    Write-Host "==> $Description" -ForegroundColor Cyan
    if ($WhatIfOnly) {
        Write-Host "WHATIF: $Description" -ForegroundColor Yellow
        return
    }

    try {
        & $Action
    }
    catch {
        Write-Warning "Failed: $Description :: $($_.Exception.Message)"
    }
}

Write-Host "PaTech Windows cleanup baseline for patech-wsa-01" -ForegroundColor Green
if ($WhatIfOnly) { Write-Host "Running in WhatIfOnly mode" -ForegroundColor Yellow }

# Consumer/bloat AppX packages. Keep Microsoft Store, Terminal, Photos, Calculator, Winget/App Installer, NVIDIA/MSI driver packages.
$AppxRemovePatterns = @(
    "Microsoft.BingNews",
    "Microsoft.BingWeather",
    "Microsoft.GamingApp",
    "Microsoft.GetHelp",
    "Microsoft.Getstarted",
    "Microsoft.MicrosoftOfficeHub",
    "Microsoft.MicrosoftSolitaireCollection",
    "Microsoft.MixedReality.Portal",
    "Microsoft.People",
    "Microsoft.PowerAutomateDesktop",
    "Microsoft.Todos",
    "Microsoft.WindowsAlarms",
    "Microsoft.WindowsFeedbackHub",
    "Microsoft.WindowsMaps",
    "Microsoft.Xbox.TCUI",
    "Microsoft.XboxApp",
    "Microsoft.XboxGameOverlay",
    "Microsoft.XboxGamingOverlay",
    "Microsoft.XboxIdentityProvider",
    "Microsoft.XboxSpeechToTextOverlay",
    "Microsoft.YourPhone",
    "Microsoft.ZuneMusic",
    "Microsoft.ZuneVideo",
    "MicrosoftTeams",
    "Clipchamp.Clipchamp",
    "Disney",
    "Spotify",
    "TikTok",
    "Facebook",
    "Instagram",
    "LinkedIn"
)

foreach ($pattern in $AppxRemovePatterns) {
    Invoke-Change "Remove AppX package pattern: $pattern" {
        Get-AppxPackage -Name "*$pattern*" -AllUsers | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
        Get-AppxProvisionedPackage -Online |
            Where-Object { $_.DisplayName -like "*$pattern*" } |
            Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Out-Null
    }
}

# Disable Xbox/Game Bar capture stack.
Invoke-Change "Disable Xbox Game Bar and game captures" {
    New-Item -Path "HKCU:\Software\Microsoft\GameBar" -Force | Out-Null
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "ShowStartupPanel" -Type DWord -Value 0
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "UseNexusForGameBarEnabled" -Type DWord -Value 0
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "AutoGameModeEnabled" -Type DWord -Value 0

    New-Item -Path "HKCU:\System\GameConfigStore" -Force | Out-Null
    Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" -Type DWord -Value 0

    New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" -Force | Out-Null
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" -Name "AllowGameDVR" -Type DWord -Value 0
}

# Taskbar noise: widgets/chat/search/coplaner-like consumer bits. Some values differ by build; harmless if ignored.
Invoke-Change "Disable widgets/chat/search highlights on taskbar" {
    New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Force | Out-Null
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarDa" -Type DWord -Value 0
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarMn" -Type DWord -Value 0
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "SearchboxTaskbarMode" -Type DWord -Value 1 -ErrorAction SilentlyContinue

    New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Feeds" -Force | Out-Null
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Feeds" -Name "ShellFeedsTaskbarViewMode" -Type DWord -Value 2

    New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Force | Out-Null
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowCopilotButton" -Type DWord -Value 0 -ErrorAction SilentlyContinue
}

# Disable consumer content suggestions.
Invoke-Change "Disable Windows consumer suggestions" {
    New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Force | Out-Null
    $values = @(
        "ContentDeliveryAllowed",
        "FeatureManagementEnabled",
        "OemPreInstalledAppsEnabled",
        "PreInstalledAppsEnabled",
        "PreInstalledAppsEverEnabled",
        "SilentInstalledAppsEnabled",
        "SoftLandingEnabled",
        "SubscribedContent-310093Enabled",
        "SubscribedContent-338388Enabled",
        "SubscribedContent-338389Enabled",
        "SubscribedContent-338393Enabled",
        "SubscribedContent-353694Enabled",
        "SubscribedContent-353696Enabled",
        "SystemPaneSuggestionsEnabled"
    )
    foreach ($v in $values) {
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name $v -Type DWord -Value 0 -ErrorAction SilentlyContinue
    }
}

# Disable selected autostarts without uninstalling vendor tooling. Keeps drivers/firmware tools installed.
$StartupNamePatterns = "SteelSeries|GG|MSI Center|MSI Companion|Nahimic|Norton|McAfee|Xbox|Teams|OneDrive"
Invoke-Change "List and disable noisy startup commands where possible" {
    Write-Host "Startup entries matching: $StartupNamePatterns"
    Get-CimInstance Win32_StartupCommand |
        Where-Object { $_.Name -match $StartupNamePatterns -or $_.Command -match $StartupNamePatterns } |
        Select-Object Name, Command, Location, User | Format-Table -AutoSize

    $runPaths = @(
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run",
        "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run",
        "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Run"
    )

    foreach ($path in $runPaths) {
        if (Test-Path $path) {
            $props = Get-ItemProperty -Path $path
            $props.PSObject.Properties |
                Where-Object { $_.Name -notmatch "^PS" -and ($_.Name -match $StartupNamePatterns -or [string]$_.Value -match $StartupNamePatterns) } |
                ForEach-Object {
                    Write-Host "Removing startup value $($_.Name) from $path"
                    Remove-ItemProperty -Path $path -Name $_.Name -ErrorAction SilentlyContinue
                }
        }
    }
}

# Disable common scheduled tasks for consumer/game/vendor overlays when present.
$TaskPatterns = "Xbox|GameBar|MicrosoftEdgeUpdateTaskMachine|OneDrive|Teams|SteelSeries|Nahimic"
Invoke-Change "Disable noisy scheduled tasks where present" {
    Get-ScheduledTask |
        Where-Object { $_.TaskName -match $TaskPatterns -or $_.TaskPath -match $TaskPatterns } |
        ForEach-Object {
            Write-Host "Disabling task: $($_.TaskPath)$($_.TaskName)"
            Disable-ScheduledTask -TaskName $_.TaskName -TaskPath $_.TaskPath -ErrorAction SilentlyContinue | Out-Null
        }
}

# Keyboard RGB cannot be reliably turned off by public MSI/SteelSeries CLI on all models.
# This creates an explicit manual task marker so the setup checklist does not forget it.
Invoke-Change "Create manual RGB follow-up marker" {
    $markerDir = Join-Path $env:USERPROFILE "patech-setup-notes"
    New-Item -ItemType Directory -Path $markerDir -Force | Out-Null
    @"
Manual check required: Keyboard RGB

Preferred setting for patech-wsa-01:
- SteelSeries GG / MSI Center
- Keyboard illumination: Off, or static white at low brightness
- Disable startup/idle lighting effects

Reason:
MSI/SteelSeries RGB is commonly controlled via embedded controller/vendor app and has no stable public CLI across models.
"@ | Set-Content -Path (Join-Path $markerDir "keyboard-rgb-manual-check.txt") -Encoding UTF8
}

Write-Host "Cleanup baseline finished. Reboot recommended." -ForegroundColor Green
