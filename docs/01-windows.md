# Windows 11 basisinrichting

## Hostname

De workstation heet:

```text
patech-wsa-01
```

Instellen:

```powershell
Rename-Computer -NewName "patech-wsa-01" -Restart
```

## Beveiligingsbaseline

Aanbevolen minimum:

- BitLocker aan
- Windows Defender actief
- Windows Firewall actief
- RDP uit tenzij nodig
- Developer Mode alleen aan wanneer bewust nodig
- Lokale admin-account beperken
- Herstelcodes opslaan in een veilige kluis

## Winget tooling

De basisinstallatie gebruikt `config/winget-packages.txt`.

Uitvoeren:

```powershell
.\scripts\windows\02-install-winget-packages.ps1
```
