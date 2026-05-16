# Modellen

De initiële modellen staan in:

```text
config/ollama-models.txt
```

Pull uitvoeren:

```bash
./scripts/wsl/06-models-ollama.sh
```

Aanbevolen startset:

- Qwen voor algemene lokale taken
- Mistral voor Europese positionering/demo's
- Nomic embed model voor lokale embeddings

Let op: modelnamen kunnen wijzigen. Controleer bij twijfel met:

```bash
ollama search qwen
ollama search mistral
```
