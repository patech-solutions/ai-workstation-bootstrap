<# 
.SYNOPSIS
  Windows 11 bloatware cleanup script for AI workstation baseline.

.DESCRIPTION
  Removes common consumer/OEM bloatware and specifically targets Norton/Symantec/Norton 360 for Gamers.
  Designed for a Windows 11 AI/dev workstation baseline.

  Safe defaults:
  - Does NOT disable Windows Defender
  - Does NOT disable Windows Firewall
  - Does NOT remove Microsoft Store framework packages
  - Does NOT remove WSL/Docker/Terminal tooling

.PARAMETER WhatIfOnly
  Shows what would be removed/changed without performing destructive actions.

.PARAMETER AggressiveNortonCleanup
  Also removes leftover Norton/Symantec folders when possible.

.EXAMPLE
  .\04-remove-windows-bloatware.ps1 -WhatIfOnly

.EXAMPLE
  .\04-remove-windows-bloatware.ps1

.EXAMPLE
  .\04-remove-windows-bloatware.ps1 -AggressiveNortonCleanup
#>

[CmdletBinding()]
param(
    [switch]$WhatIfOnly,
    [switch]$AggressiveNortonCleanup
)

$ErrorActionPreference = "Continue"

$LogDir = Join-Path $env:ProgramData "AIWorkstation\Bootstrap\Logs"
New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
$LogFile = Join-Path $LogDir ("bloatware-cleanup-{0}.log" -f (Get-Date -Format "yyyyMMdd-HHmmss"))

function Write-Log {
    param(
        [Parameter(Mandatory=$true)][string]$Message,
        [ValidateSet("INFO","WARN","ERROR","OK","DRYRUN")][string]$Level = "INFO"
    )
    $line = "[{0}] [{1}] {2}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Level, $Message
    Write-Host $line
    Add-Content -Path $LogFile -Value $line
}

function Invoke-Step {
    param(
        [Parameter(Mandatory=$true)][string]$Description,
        [Parameter(Mandatory=$true)][scriptblock]$Action
    )

    if ($WhatIfOnly) {
        Write-Log "Would run: $Description" "DRYRUN"
        return
    }

    Write-Log $Description "INFO"
    try {
        & $Action
        Write-Log "Completed: $Description" "OK"
    }
    catch {
        Write-Log "Failed: $Description :: $($_.Exception.Message)" "ERROR"
    }
}

function Test-IsAdmin {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-IsAdmin)) {
    Write-Log "This script should be run as Administrator. Some cleanup steps will fail otherwise." "WARN"
}

Write-Log "Starting Windows bloatware cleanup for AI workstation" "INFO"
Write-Log "Log file: $LogFile" "INFO"
Write-Log "WhatIfOnly=$WhatIfOnly; AggressiveNortonCleanup=$AggressiveNortonCleanup" "INFO"

# --------------------------------------------------------------------------------------
# 1. Kill known consumer/OEM/trialware processes
# --------------------------------------------------------------------------------------

$ProcessNamePatterns = @(
    "Norton",
    "N360",
    "NortonSecurity",
    "Symantec",
    "McAfee",
    "WebAdvisor",
    "SteelSeriesGG",
    "SteelSeries",
    "Nahimic",
    "Overwolf",
    "Xbox",
    "GameBar"
)

foreach ($pattern in $ProcessNamePatterns) {
    $matches = Get-Process -ErrorAction SilentlyContinue | Where-Object {
        $_.ProcessName -match $pattern -or $_.Path -match $pattern
    }

    foreach ($proc in $matches) {
        Invoke-Step "Stop process $($proc.ProcessName) [$($proc.Id)]" {
            Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
        }
    }
}

# --------------------------------------------------------------------------------------
# 2. Uninstall known bloatware using winget when available
# --------------------------------------------------------------------------------------

$WingetAvailable = [bool](Get-Command winget -ErrorAction SilentlyContinue)

$WingetUninstallNames = @(
    "Norton 360 for Gamers",
    "Norton 360",
    "Norton Security",
    "Norton Antivirus",
    "Norton Private Browser",
    "Norton Secure VPN",
    "Norton Password Manager",
    "Norton Utilities Ultimate",
    "McAfee LiveSafe",
    "McAfee Security",
    "McAfee WebAdvisor",
    "WildTangent Games",
    "Spotify",
    "Disney+",
    "TikTok",
    "Instagram",
    "WhatsApp",
    "Facebook",
    "Messenger",
    "LinkedIn",
    "Clipchamp",
    "Microsoft Teams",
    "Xbox",
    "Xbox Game Bar",
    "Xbox TCUI",
    "Xbox Identity Provider",
    "Xbox Game Speech Window"
)

if ($WingetAvailable) {
    foreach ($app in $WingetUninstallNames) {
        Invoke-Step "winget uninstall '$app'" {
            winget uninstall --name "$app" --silent --accept-source-agreements --source winget 2>$null
        }
    }
}
else {
    Write-Log "winget not found; skipping winget uninstall section" "WARN"
}

# --------------------------------------------------------------------------------------
# 3. Uninstall Norton/Symantec via registry uninstall entries
# --------------------------------------------------------------------------------------

$UninstallRegistryPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
)

$NortonUninstallEntries = foreach ($path in $UninstallRegistryPaths) {
    Get-ItemProperty $path -ErrorAction SilentlyContinue | Where-Object {
        $_.DisplayName -match "Norton|Symantec|LifeLock|NortonLifeLock"
    }
}

foreach ($entry in $NortonUninstallEntries) {
    $name = $entry.DisplayName
    $uninstall = $entry.UninstallString
    $quiet = $entry.QuietUninstallString

    if ([string]::IsNullOrWhiteSpace($uninstall) -and [string]::IsNullOrWhiteSpace($quiet)) {
        Write-Log "No uninstall string found for $name" "WARN"
        continue
    }

    $cmd = if (-not [string]::IsNullOrWhiteSpace($quiet)) { $quiet } else { $uninstall }

    Invoke-Step "Uninstall Norton/Symantec registry entry: $name" {
        if ($cmd -match "msiexec") {
            $msiArgs = $cmd -replace "MsiExec.exe", "" -replace "/I", "/X" -replace "/i", "/x"
            Start-Process -FilePath "msiexec.exe" -ArgumentList "$msiArgs /qn /norestart" -Wait -ErrorAction SilentlyContinue
        }
        else {
            Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$cmd`"" -Wait -ErrorAction SilentlyContinue
        }
    }
}

# --------------------------------------------------------------------------------------
# 4. Remove AppX consumer apps for current user and provisioned packages for new users
# --------------------------------------------------------------------------------------

$AppxPatterns = @(
    "*Clipchamp*",
    "*MicrosoftTeams*",
    "*Teams*",
    "*Xbox*",
    "*GamingApp*",
    "*ZuneMusic*",
    "*ZuneVideo*",
    "*BingNews*",
    "*BingWeather*",
    "*GetHelp*",
    "*Getstarted*",
    "*MicrosoftOfficeHub*",
    "*MicrosoftSolitaireCollection*",
    "*People*",
    "*Spotify*",
    "*TikTok*",
    "*Disney*",
    "*Facebook*",
    "*Instagram*",
    "*Messenger*",
    "*LinkedIn*"
)

foreach ($pattern in $AppxPatterns) {
    Invoke-Step "Remove AppX packages matching $pattern for current/all users" {
        Get-AppxPackage -AllUsers -Name $pattern -ErrorAction SilentlyContinue |
            Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
    }

    Invoke-Step "Remove provisioned AppX packages matching $pattern" {
        Get-AppxProvisionedPackage -Online |
            Where-Object { $_.DisplayName -like $pattern } |
            Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Out-Null
    }
}

# --------------------------------------------------------------------------------------
# 5. Disable consumer UX, widgets, chat, game bar, tips
# --------------------------------------------------------------------------------------

$RegistryTweaks = @(
    @{ Path="HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name="TaskbarDa"; Type="DWord"; Value=0; Description="Disable Widgets taskbar button" },
    @{ Path="HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name="TaskbarMn"; Type="DWord"; Value=0; Description="Disable Chat/Teams taskbar button" },
    @{ Path="HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR"; Name="AppCaptureEnabled"; Type="DWord"; Value=0; Description="Disable Game DVR capture" },
    @{ Path="HKCU:\System\GameConfigStore"; Name="GameDVR_Enabled"; Type="DWord"; Value=0; Description="Disable Game DVR" },
    @{ Path="HKCU:\Software\Microsoft\GameBar"; Name="ShowStartupPanel"; Type="DWord"; Value=0; Description="Disable Game Bar startup panel" },
    @{ Path="HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name="SubscribedContent-338388Enabled"; Type="DWord"; Value=0; Description="Disable suggested app content" },
    @{ Path="HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name="SubscribedContent-338389Enabled"; Type="DWord"; Value=0; Description="Disable Windows tips" },
    @{ Path="HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name="SilentInstalledAppsEnabled"; Type="DWord"; Value=0; Description="Disable silent installed suggested apps" }
)

foreach ($tweak in $RegistryTweaks) {
    Invoke-Step $tweak.Description {
        New-Item -Path $tweak.Path -Force | Out-Null
        New-ItemProperty -Path $tweak.Path -Name $tweak.Name -PropertyType $tweak.Type -Value $tweak.Value -Force | Out-Null
    }
}

# --------------------------------------------------------------------------------------
# 6. Disable selected startup commands
# --------------------------------------------------------------------------------------

$StartupPatterns = "Norton|Symantec|LifeLock|McAfee|SteelSeries|Nahimic|Overwolf|Xbox|GameBar|Spotify|Teams"

$StartupCommands = Get-CimInstance Win32_StartupCommand -ErrorAction SilentlyContinue |
    Where-Object {
        $_.Name -match $StartupPatterns -or
        $_.Command -match $StartupPatterns -or
        $_.Location -match $StartupPatterns
    }

foreach ($startup in $StartupCommands) {
    Write-Log "Found startup item: $($startup.Name) :: $($startup.Command)" "WARN"
}

$RunKeys = @(
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run",
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run",
    "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Run"
)

foreach ($key in $RunKeys) {
    if (-not (Test-Path $key)) { continue }

    $props = Get-ItemProperty -Path $key -ErrorAction SilentlyContinue
    $props.PSObject.Properties |
        Where-Object {
            $_.Name -notmatch "^PS" -and
            ($_.Name -match $StartupPatterns -or [string]$_.Value -match $StartupPatterns)
        } |
        ForEach-Object {
            $propName = $_.Name
            Invoke-Step "Remove startup registry item $propName from $key" {
                Remove-ItemProperty -Path $key -Name $propName -Force -ErrorAction SilentlyContinue
            }
        }
}

# --------------------------------------------------------------------------------------
# 7. Stop/disable leftover Norton/Symantec/McAfee services
# --------------------------------------------------------------------------------------

$ServicePatterns = "Norton|Symantec|LifeLock|McAfee|WebAdvisor"

$Services = Get-Service -ErrorAction SilentlyContinue | Where-Object {
    $_.Name -match $ServicePatterns -or $_.DisplayName -match $ServicePatterns
}

foreach ($svc in $Services) {
    Invoke-Step "Stop service $($svc.Name) / $($svc.DisplayName)" {
        Stop-Service -Name $svc.Name -Force -ErrorAction SilentlyContinue
    }

    Invoke-Step "Disable service $($svc.Name) / $($svc.DisplayName)" {
        Set-Service -Name $svc.Name -StartupType Disabled -ErrorAction SilentlyContinue
    }
}

# --------------------------------------------------------------------------------------
# 8. Disable selected scheduled tasks
# --------------------------------------------------------------------------------------

$TaskPatterns = "Norton|Symantec|LifeLock|McAfee|WebAdvisor|Xbox|GameBar|Spotify|Teams|Adobe.*Update"

$Tasks = Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object {
    $_.TaskName -match $TaskPatterns -or
    $_.TaskPath -match $TaskPatterns
}

foreach ($task in $Tasks) {
    Invoke-Step "Disable scheduled task $($task.TaskPath)$($task.TaskName)" {
        Disable-ScheduledTask -TaskName $task.TaskName -TaskPath $task.TaskPath -ErrorAction SilentlyContinue | Out-Null
    }
}

# --------------------------------------------------------------------------------------
# 9. Aggressive Norton/Symantec folder cleanup
# --------------------------------------------------------------------------------------

$NortonPaths = @(
    "$env:ProgramFiles\Norton",
    "$env:ProgramFiles\Norton 360",
    "$env:ProgramFiles\Norton Security",
    "$env:ProgramFiles\NortonInstaller",
    "$env:ProgramFiles\Symantec",
    "${env:ProgramFiles(x86)}\Norton",
    "${env:ProgramFiles(x86)}\Norton 360",
    "${env:ProgramFiles(x86)}\Norton Security",
    "${env:ProgramFiles(x86)}\NortonInstaller",
    "${env:ProgramFiles(x86)}\Symantec",
    "$env:ProgramData\Norton",
    "$env:ProgramData\NortonInstaller",
    "$env:ProgramData\Symantec",
    "$env:ProgramData\NortonLifeLock",
    "$env:LocalAppData\Norton",
    "$env:AppData\Norton",
    "$env:LocalAppData\Symantec",
    "$env:AppData\Symantec"
)

if ($AggressiveNortonCleanup) {
    foreach ($path in $NortonPaths) {
        if (Test-Path $path) {
            Invoke-Step "Remove leftover Norton/Symantec folder: $path" {
                Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}
else {
    foreach ($path in $NortonPaths) {
        if (Test-Path $path) {
            Write-Log "Leftover Norton/Symantec path found. Re-run with -AggressiveNortonCleanup to remove: $path" "WARN"
        }
    }
}

# --------------------------------------------------------------------------------------
# 10. Temp cleanup
# --------------------------------------------------------------------------------------

$TempPaths = @(
    "$env:TEMP\*",
    "$env:WINDIR\Temp\*"
)

foreach ($path in $TempPaths) {
    Invoke-Step "Clean temp path $path" {
        Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# --------------------------------------------------------------------------------------
# 11. Restart Explorer to apply taskbar/user shell tweaks
# --------------------------------------------------------------------------------------

Invoke-Step "Restart Explorer shell" {
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    Start-Process explorer.exe
}

# --------------------------------------------------------------------------------------
# 12. Summary
# --------------------------------------------------------------------------------------

Write-Log "Cleanup completed." "OK"
Write-Log "Recommended next step: reboot Windows." "INFO"
Write-Log "Recommended after reboot: run scripts/windows/99-verify-windows.ps1" "INFO"
Write-Log "If Norton still appears in Apps, use vendor removal tool manually as fallback." "WARN"
