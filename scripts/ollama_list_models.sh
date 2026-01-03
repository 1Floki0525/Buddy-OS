#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-local}" # local|cloud
PYBIN="${PYBIN:-python3}"

if [[ "$MODE" == "local" ]]; then
  URL="http://localhost:11434/api/tags"
  echo "== Ollama Local Models =="
  echo "GET $URL"
  JSON="$(curl -fsSL "$URL")"
elif [[ "$MODE" == "cloud" ]]; then
  : "${OLLAMA_API_KEY:?Set OLLAMA_API_KEY to list cloud models (export OLLAMA_API_KEY=...)}"
  URL="https://ollama.com/api/tags"
  echo "== Ollama Cloud Models =="
  echo "GET $URL"
  JSON="$(curl -fsSL -H "Authorization: Bearer ${OLLAMA_API_KEY}" "$URL" || true)"
  if [[ -z "$JSON" ]]; then
    # Some setups rely on OLLAMA_API_KEY without explicit header; keep raw fallback:
    JSON="$(curl -fsSL "$URL")"
  fi
else
  echo "Usage: $0 [local|cloud]"
  exit 2
fi

echo
echo "$JSON" | "$PYBIN" - <<'PY'
import json, sys
data = json.load(sys.stdin)
models = data.get("models", [])
names = [m.get("name") for m in models if isinstance(m, dict) and m.get("name")]
if not names:
    print("(no models found or unexpected response)")
else:
    for n in names:
        print(n)
PY
