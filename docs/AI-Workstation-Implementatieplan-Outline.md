# AI Workstation Implementatieplan

## Workstation

| Onderdeel | Waarde |
|---|---|
| Hostname | zie `BOOTSTRAP_HOSTNAME` in `config/bootstrap.env` |
| OS | Windows 11 Pro |
| Linux laag | WSL2 Ubuntu |
| AI runtime | Ollama native in WSL |
| Windows Ollama | Niet gebruiken / verwijderd |
| Repository | `ai-workstation-bootstrap` |
| Gitea | zie `BOOTSTRAP_GITEA_HOST` in `config/bootstrap.env` |

## Belangrijkste wijziging

Ollama draait native in WSL.

De eerdere optie om Ollama op Windows te draaien is verlaten omdat WSL de Windows-hosted Ollama endpoint niet betrouwbaar kon bereiken. De werkende configuratie is nu:

```bash
curl http://localhost:11434/api/tags
```

binnen WSL.

## Bootstrap volgorde

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

## Relevante WSL scripts

| Script | Doel |
|---|---|
| `00-bootstrap-ubuntu.sh` | Basispackages inclusief `zstd` |
| `01-dev-tools.sh` | uv, NodeSource NodeJS, npm |
| `02-install-ollama.sh` | Ollama native in WSL installeren/starten |
| `03-models-ollama.sh` | Modellen uit `config/ollama-models.txt` pullen |
| `99-verify-wsl.sh` | Verificatie |

## `zstd`

`zstd` is opgenomen in de basisbootstrap omdat AI/model tooling en installatielagen dit nodig kunnen hebben.

```bash
sudo apt install -y zstd
```

## Ollama verificatie

```bash
ollama --version
curl http://localhost:11434/api/tags
ollama list
```

## Windows verificatie

Windows hoort geen Ollama meer te hebben:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\99-verify-windows.ps1
```

Als Windows-Ollama toch aanwezig is, meldt het verify-script dit als waarschuwing.

## Architectuurkeuze

Deze opzet houdt de AI-runtime in dezelfde laag als:

- Hermes Agent
- Honcho Memory
- Docker CLI
- Open WebUI integratie
- model scripts
- AI development tooling

Dat voorkomt Windows/WSL NAT-, firewall- en localhost-forwardingproblemen.
