# AI Workstation Bootstrap

Bootstrap repository voor een Windows 11 + WSL2 AI-workstation.

## Architectuurkeuze

Ollama draait **native in WSL**, niet meer op Windows.

Reden:

- WSL kon de Windows-hosted Ollama endpoint niet betrouwbaar bereiken.
- Windows Ollama is verwijderd.
- WSL-localhost werkt correct.
- Hermes, Honcho, Docker tooling en CLI-workflows draaien primair in de Linux-laag.

## Hoofdworkflow

### Windows

```powershell
cd C:\git\ai-workstation-bootstrap
powershell -ExecutionPolicy Bypass -File .\scripts\windows\90-bootstrap-windows.ps1
```

### WSL

```bash
cd /mnt/c/git/ai-workstation-bootstrap
chmod +x scripts/wsl/*.sh
./scripts/wsl/90-bootstrap-wsl.sh
```

### Verificatie

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\99-verify-windows.ps1
```

```bash
./scripts/wsl/99-verify-wsl.sh
```

## Opgenomen fixes

- `winget --source winget`
- `.gitattributes` voor LF/CRLF
- NodeSource in plaats van nvm
- `zstd` in WSL basisbootstrap
- Ollama native in WSL
- verify-script verwacht Ollama op WSL localhost
