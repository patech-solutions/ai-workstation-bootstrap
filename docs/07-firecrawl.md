# Firecrawl self-hosted in WSL2

## Doel

Firecrawl lokaal draaien in WSL zodat Hermes Agent web scraping/crawling kan gebruiken zonder afhankelijk te zijn van de hosted Firecrawl cloud.

## Architectuur

```text
Windows 11
→ WSL2 Ubuntu
→ Docker Compose
→ Firecrawl API op http://localhost:3002
→ Hermes Agent gebruikt lokale Firecrawl endpoint
```

## Script

```bash
./scripts/wsl/07-firecrawl.sh
```

## Endpoint

```text
http://localhost:3002
```

## Test

```bash
curl http://localhost:3002
```

Scrape-test:

```bash
curl -X POST http://localhost:3002/v1/scrape \
  -H 'Content-Type: application/json' \
  -d '{"url":"https://example.com"}'
```

## Logs

```bash
cd ~/.local/share/patech/firecrawl
docker compose logs -f
```

## Waarom optioneel?

Firecrawl is zwaarder en complexer dan de basislaag. Daarom zit het bewust als `07-firecrawl.sh` buiten de verplichte basisbootstrap. Eerst Hermes + Ollama stabiel; daarna Firecrawl als tool-laag.
