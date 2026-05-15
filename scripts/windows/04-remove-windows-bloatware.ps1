<#
.SYNOPSIS
  Removes obvious Windows 11 consumer/OEM bloatware from patech-wsa-01.

.DESCRIPTION
  Conservative debloat script for an AI/dev workstation.
  It removes known consumer apps and trialware appx packages, disables consumer suggestions,
  and leaves critical platform components intact: Store, App Installer, Terminal, WSL,
  NVIDIA/OEM drivers, Defender, Edge WebView2 and framework packages.

.PARAMETER WhatIfOnly
  Show what would be removed without removing packages.

.PARAMETER RemoveOneDrive
  Also attempt to uninstall OneDrive. Disabled by default because OneDrive may be desired for
  user profile backup or Microsoft 365 workflows.

.EXAMPLE
  .\04-remove-windows-bloatware.ps1

.EXAMPLE
  .\04-remove-windows-bloatware.ps1 -WhatIfOnly

.EXAMPLE
  .\04-remove-windows-bloatware.ps1 -RemoveOneDrive
#>

param(
  [switch]$WhatIfOnly,
  [switch]$RemoveOneDrive
)

$ErrorActionPreference = "Continue"

Write-Host "PaTech Windows 11 workstation debloat" -ForegroundColor Cyan
Write-Host "Target profile: patech-wsa-01" -ForegroundColor Cyan

# Explicit consumer/trial packages. Keep this list boring and predictable.
$AppxNamePatterns = @(
  "*Microsoft.BingNews*",
  "*Microsoft.BingWeather*",
  "*Microsoft.GetHelp*",
  "*Microsoft.Getstarted*",
  "*Microsoft.MicrosoftSolitaireCollection*",
  "*Microsoft.People*",
  "*Microsoft.Todos*",
  "*Microsoft.WindowsFeedbackHub*",
  "*Microsoft.Xbox*",
  "*Microsoft.GamingApp*",
  "*Microsoft.ZuneMusic*",
  "*Microsoft.ZuneVideo*",
  "*MicrosoftTeams*",
  "*Clipchamp.Clipchamp*",
  "*Disney*",
  "*Spotify*",
  "*TikTok*",
  "*Facebook*",
  "*Instagram*",
  "*LinkedIn*",
  "*PrimeVideo*",
  "*Netflix*"
)

# Never remove platform/framework packages, even if a pattern would accidentally match.
$ProtectedNamePatterns = @(
  "*Microsoft.DesktopAppInstaller*",
  "*Microsoft.StorePurchaseApp*",
  "*Microsoft.WindowsStore*",
  "*Microsoft.WindowsTerminal*",
  "*Microsoft.VCLibs*",
  "*Microsoft.UI.Xaml*",
  "*Microsoft.NET.Native*",
  "*Microsoft.WindowsCalculator*",
  "*Microsoft.Paint*",
  "*Microsoft.ScreenSketch*",
  "*Microsoft.WebMediaExtensions*",
  "*Microsoft.HEIFImageExtension*",
  "*Microsoft.HEVCVideoExtension*",
  "*Microsoft.WebpImageExtension*",
  "*Microsoft.RawImageExtension*",
  "*Microsoft.AV1VideoExtension*"
)

function Test-ProtectedPackage {
  param([string]$Name)
  foreach ($pattern in $ProtectedNamePatterns) {
    if ($Name -like $pattern) { return $true }
  }
  return $false
}

function Remove-MatchingAppxPackage {
  param([string]$Pattern)

  $packages = Get-AppxPackage -AllUsers -Name $Pattern -ErrorAction SilentlyContinue
  foreach ($pkg in $packages) {
    if (Test-ProtectedPackage -Name $pkg.Name) {
      Write-Host "Skipping protected package: $($pkg.Name)" -ForegroundColor Yellow
      continue
    }

    if ($WhatIfOnly) {
      Write-Host "Would remove Appx package: $($pkg.Name)" -ForegroundColor Gray
    } else {
      Write-Host "Removing Appx package: $($pkg.Name)" -ForegroundColor Green
      Remove-AppxPackage -Package $pkg.PackageFullName -AllUsers -ErrorAction SilentlyContinue
    }
  }

  $provisioned = Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -like $Pattern }
  foreach ($pkg in $provisioned) {
    if (Test-ProtectedPackage -Name $pkg.DisplayName) {
      Write-Host "Skipping protected provisioned package: $($pkg.DisplayName)" -ForegroundColor Yellow
      continue
    }

    if ($WhatIfOnly) {
      Write-Host "Would remove provisioned package: $($pkg.DisplayName)" -ForegroundColor Gray
    } else {
      Write-Host "Removing provisioned package: $($pkg.DisplayName)" -ForegroundColor Green
      Remove-AppxProvisionedPackage -Online -PackageName $pkg.PackageName -ErrorAction SilentlyContinue | Out-Null
    }
  }
}

foreach ($pattern in $AppxNamePatterns) {
  Remove-MatchingAppxPackage -Pattern $pattern
}

# Disable consumer suggestions and noisy first-run content for the current user.
$ContentDeliveryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
if (Test-Path $ContentDeliveryPath) {
  $values = @{
    "ContentDeliveryAllowed" = 0
    "FeatureManagementEnabled" = 0
    "OemPreInstalledAppsEnabled" = 0
    "PreInstalledAppsEnabled" = 0
    "PreInstalledAppsEverEnabled" = 0
    "SilentInstalledAppsEnabled" = 0
    "SoftLandingEnabled" = 0
    "SubscribedContent-310093Enabled" = 0
    "SubscribedContent-338388Enabled" = 0
    "SubscribedContent-338389Enabled" = 0
    "SubscribedContent-338393Enabled" = 0
    "SubscribedContent-353694Enabled" = 0
    "SubscribedContent-353696Enabled" = 0
    "SystemPaneSuggestionsEnabled" = 0
  }

  foreach ($entry in $values.GetEnumerator()) {
    if ($WhatIfOnly) {
      Write-Host "Would set $($entry.Key)=$($entry.Value)" -ForegroundColor Gray
    } else {
      Set-ItemProperty -Path $ContentDeliveryPath -Name $entry.Key -Value $entry.Value -Type DWord -ErrorAction SilentlyContinue
    }
  }
}

# Hide consumer chat/taskbar noise where present.
$ExplorerAdvancedPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
if (Test-Path $ExplorerAdvancedPath) {
  if (-not $WhatIfOnly) {
    Set-ItemProperty -Path $ExplorerAdvancedPath -Name "TaskbarMn" -Value 0 -Type DWord -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $ExplorerAdvancedPath -Name "ShowTaskViewButton" -Value 0 -Type DWord -ErrorAction SilentlyContinue
  } else {
    Write-Host "Would hide consumer taskbar buttons" -ForegroundColor Gray
  }
}

# Optional OneDrive removal. Off by default.
if ($RemoveOneDrive) {
  $oneDriveSetup = "$env:SystemRoot\SysWOW64\OneDriveSetup.exe"
  if (-not (Test-Path $oneDriveSetup)) {
    $oneDriveSetup = "$env:SystemRoot\System32\OneDriveSetup.exe"
  }

  if (Test-Path $oneDriveSetup) {
    if ($WhatIfOnly) {
      Write-Host "Would uninstall OneDrive using $oneDriveSetup" -ForegroundColor Gray
    } else {
      Write-Host "Uninstalling OneDrive" -ForegroundColor Green
      Start-Process -FilePath $oneDriveSetup -ArgumentList "/uninstall" -Wait -ErrorAction SilentlyContinue
    }
  }
}

Write-Host "Debloat pass completed. Reboot is recommended." -ForegroundColor Cyan
