# AI-stack

## Lagen

1. Windows 11 host
2. WSL2 Ubuntu werklaag
3. Docker Desktop met WSL2-integratie
4. Ollama voor lokale modellen
5. Open WebUI voor lokale browserinterface
6. Hermes Agent voor agentische workflows
7. Honcho voor lokale memory
8. Codex en Claude CLI voor coding assistants

## Open WebUI starten

```bash
docker compose -f compose/open-webui.compose.yml up -d
```

Daarna openen:

```text
http://localhost:3000
```

## LiteLLM optioneel

LiteLLM kan later worden gebruikt als router/proxy tussen lokale modellen, OpenRouter, OpenAI en Anthropic.

```bash
docker compose -f compose/litellm.compose.yml up -d
```
