#!/usr/bin/env bash
set -euo pipefail

FIRECRAWL_PORT="${FIRECRAWL_PORT:-3002}"

echo "== Firecrawl verification =="

if curl -fsS "http://localhost:${FIRECRAWL_PORT}" >/dev/null 2>&1; then
  echo "OK: Firecrawl root endpoint reachable at http://localhost:${FIRECRAWL_PORT}"
else
  echo "WARN: Firecrawl root endpoint not reachable at http://localhost:${FIRECRAWL_PORT}"
fi

echo
echo "Testing scrape endpoint against example.com..."
curl -sS -X POST "http://localhost:${FIRECRAWL_PORT}/v1/scrape" \
  -H 'Content-Type: application/json' \
  -d '{"url":"https://example.com"}' | head -c 1000

echo
echo
echo "Firecrawl verification complete."
