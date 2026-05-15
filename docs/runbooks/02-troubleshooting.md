# Troubleshooting

## Docker not visible in WSL

Open Docker Desktop:

Settings → Resources → WSL Integration → Enable integration with Ubuntu.

Then restart WSL:

```powershell
wsl --shutdown
```

## NVIDIA not visible in WSL

Check Windows first:

```powershell
nvidia-smi
```

Then in WSL:

```bash
nvidia-smi
```

If WSL does not see NVIDIA, update the NVIDIA Windows driver and restart.

## Ollama not reachable

Check on Windows:

```powershell
ollama list
```

Check from WSL:

```bash
curl http://localhost:11434/api/tags
```

## npm not found

Run:

```bash
./scripts/wsl/01-dev-tools.sh
source ~/.bashrc
```

## Codex login issue

Try:

```bash
codex login
```

If OAuth fails, check OpenAI account and billing/access status.

## Claude login issue

Run:

```bash
claude
```

If login works but model use fails, check Anthropic billing/usage requirements.
