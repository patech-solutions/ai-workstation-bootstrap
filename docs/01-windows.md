# Windows 11 inrichting voor patech-wsa-01

## Doel

Windows 11 blijft de primaire hostlaag voor:

- drivers
- GPU ondersteuning
- Docker Desktop
- WSL2
- zakelijke desktop tooling
- lokale beheeracties

## Eerste stappen

```text
[ ] Windows setup afronden
[ ] Microsoft account overslaan indien gewenst
[ ] Windows Update volledig afronden
[ ] Reboot
[ ] Nogmaals Windows Update controleren
[ ] Vendor firmware updates uitvoeren
[ ] NVIDIA Studio Driver installeren
```

## Repository clonen

```powershell
mkdir C:\git
cd C:\git
git clone http://ugreendxp2800.local:3000/Paikke/ai-workstation-bootstrap.git
cd ai-workstation-bootstrap
```

## Windows bootstrap runner

Open PowerShell als Administrator:

```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
.\scripts\windows\90-bootstrap-windows.ps1
```

Na reboot hetzelfde commando opnieuw uitvoeren. Het script gebruikt marker files en slaat afgeronde stappen over.

## Handmatige losse fases

```powershell
.\scripts\windows\00-set-hostname.ps1
.\scripts\windows\01-enable-wsl.ps1
.\scripts\windows\02-install-winget-packages.ps1
.\scripts\windows\03-windows-security-baseline.ps1
.\scripts\windows\04-remove-windows-bloatware.ps1 -WhatIfOnly
.\scripts\windows\04-remove-windows-bloatware.ps1
.\scripts\windows\99-verify-windows.ps1
```

## Bloatware/RGB baseline

Het cleanup-script doet bewust geen agressieve driver- of firmwareverwijdering.

Wel:

- consumer AppX packages verwijderen
- Xbox/Game Bar/Game DVR uitschakelen
- Widgets/Chat/Search highlights verminderen
- consumer suggestions uitschakelen
- MSI/SteelSeries/Nahimic autostart-noise beperken
- geplande taken voor overlays waar mogelijk uitschakelen
- manual note aanmaken voor keyboard RGB

Keyboard RGB:

```text
SteelSeries GG / MSI Center
Keyboard illumination = Off
of Static White, Low brightness
Startup/idle effects = Off
```

Waarom handmatig: MSI/SteelSeries RGB wordt vaak via embedded controller/vendor app geregeld en heeft geen stabiele publieke CLI voor alle modellen.
