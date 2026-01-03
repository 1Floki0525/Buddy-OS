#!/usr/bin/env bash
set -euo pipefail

# Exports your local Ollama model store into a tarball for seeding Buddy-OS.
# Default: pulls and exports qwen3:4b.

MODELS=("${@:-qwen3:4b}")

log() { printf "\n==> %s\n" "$*"; }
die() { echo "ERROR: $*" >&2; exit 1; }

command -v ollama >/dev/null 2>&1 || die "ollama is not installed on this host."

log "Pulling models (if missing)..."
for m in "${MODELS[@]}"; do
  echo "  - ollama pull $m"
  ollama pull "$m"
done

# Try to locate the model store
CANDIDATES=()
if [[ -n "${OLLAMA_MODELS:-}" ]]; then
  CANDIDATES+=("$OLLAMA_MODELS")
fi
CANDIDATES+=(
  "$HOME/.ollama/models"
  "/var/lib/ollama/.ollama/models"
  "/usr/share/ollama/.ollama/models"
  "/root/.ollama/models"
)

MODEL_DIR=""
for p in "${CANDIDATES[@]}"; do
  if [[ -d "$p/manifests" && -d "$p/blobs" ]]; then
    MODEL_DIR="$p"
    break
  fi
done

if [[ -z "$MODEL_DIR" ]]; then
  die "Could not find Ollama model store. Checked: ${CANDIDATES[*]}"
fi

log "Found Ollama model store: $MODEL_DIR"
log "NOTE: This bundles the entire store (all pulled models in this store)."

OUT_DIR="$(pwd)/build"
mkdir -p "$OUT_DIR"
STAMP="$(date +%Y%m%d_%H%M%S)"
OUT_TAR="$OUT_DIR/buddyos_ollama_models_${STAMP}.tar.gz"

log "Creating tarball: $OUT_TAR"
tar -C "$(dirname "$MODEL_DIR")" -czf "$OUT_TAR" "$(basename "$MODEL_DIR")"

log "Done."
echo "Tarball created:"
echo "  $OUT_TAR"
echo
echo "To seed another system: extract to the target model store path, then ensure permissions match the ollama service user."
