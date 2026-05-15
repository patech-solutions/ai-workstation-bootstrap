# Hermes, Honcho, Codex en Claude

## Hermes Agent

Hermes Agent is de primaire agentlaag. Deze repo maakt alvast:

```text
~/.hermes/
~/.hermes/config.yaml
~/.hermes/profiles/
```

De exacte Hermes-installatiebron kan verschillen per eigen setup. Vul daarom in `scripts/wsl/03-hermes-agent.sh` de juiste repo/packagebron in wanneer nodig.

## Honcho

Honcho wordt voorbereid als lokale memory-laag. Deze repo maakt:

```text
~/.honcho/
~/.honcho/config.yaml
```

Wanneer Honcho via Python package, Docker of eigen binary draait, kan de installatiestap in `scripts/wsl/04-honcho.sh` worden aangescherpt.

## Codex CLI

Codex wordt via npm geïnstalleerd:

```bash
npm install -g @openai/codex
```

Daarna inloggen via de CLI/OAuth-flow.

## Claude CLI / Claude Code

Claude wordt via npm geïnstalleerd wanneer beschikbaar:

```bash
npm install -g @anthropic-ai/claude-code
```

Let op: Anthropic kan aanvullende billing/usage voorwaarden hebben voordat OAuth of API-gebruik werkt.
