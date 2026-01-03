#!/usr/bin/env bash
set -euo pipefail

MODEL_REF="${1:-qwen3-vl:2b}"
SEED_ROOT="${2:-$HOME/Buddy-OS/build/ollama_seed}"
SEED_MODELS_DIR="$SEED_ROOT/models"

log() { printf "\n==> %s\n" "$*"; }
die() { echo "ERROR: $*" >&2; exit 1; }

# Split model:name:tag
MODEL_NAME="${MODEL_REF%:*}"
MODEL_TAG="${MODEL_REF##*:}"
[[ -n "$MODEL_NAME" && -n "$MODEL_TAG" ]] || die "Bad MODEL_REF '$MODEL_REF' (expected name:tag)"

log "Model: $MODEL_NAME"
log "Tag:   $MODEL_TAG"

# Try to discover the *server* model store.
# The daemon stores models under the home of the user running ollama (or distro-specific paths).
CANDIDATES=(
  "/usr/share/ollama/.ollama/models"
  "/var/lib/ollama/.ollama/models"
  "/home/ollama/.ollama/models"
  "$HOME/.ollama/models"
)

# If systemd is present, check if it explicitly sets OLLAMA_MODELS
if command -v systemctl >/dev/null 2>&1; then
  ENV_LINE="$(systemctl show ollama --property=Environment 2>/dev/null || true)"
  if [[ "$ENV_LINE" == *"OLLAMA_MODELS="* ]]; then
    # Environment=OLLAMA_MODELS=/path ...
    FOUND_PATH="$(echo "$ENV_LINE" | sed -n 's/.*OLLAMA_MODELS=\([^ "]*\).*/\1/p' | head -n1)"
    if [[ -n "$FOUND_PATH" ]]; then
      CANDIDATES=("$FOUND_PATH" "${CANDIDATES[@]}")
    fi
  fi
fi

SRC=""
for p in "${CANDIDATES[@]}"; do
  if [[ -d "$p/manifests" && -d "$p/blobs" ]]; then
    SRC="$p"
    break
  fi
done

if [[ -z "$SRC" ]]; then
  die "Could not locate Ollama server model store. Tried: ${CANDIDATES[*]}"
fi

log "Detected Ollama server model store:"
echo "  $SRC"

# Find the manifest file for this model+tag
# Common layout: manifests/registry.ollama.ai/library/<model>/<tag>
MANIFEST_FILE="$(find "$SRC/manifests" -type f -path "*/$MODEL_NAME/$MODEL_TAG" -print -quit || true)"
if [[ -z "$MANIFEST_FILE" ]]; then
  die "Could not find manifest for $MODEL_REF under $SRC/manifests. (Maybe different registry path?)"
fi

log "Found manifest:"
echo "  $MANIFEST_FILE"

# Extract all sha256 digests referenced in the manifest, then map to blobs filenames (sha256-<hash>)
DIGESTS="$(grep -oE 'sha256:[0-9a-f]{64}' "$MANIFEST_FILE" | sort -u || true)"
if [[ -z "$DIGESTS" ]]; then
  die "No sha256 digests found in manifest (unexpected)."
fi

# Prepare destination
log "Preparing seed store at:"
echo "  $SEED_MODELS_DIR"
mkdir -p "$SEED_MODELS_DIR/manifests" "$SEED_MODELS_DIR/blobs"

# Copy manifest (preserve relative path under manifests/)
REL_MANIFEST="${MANIFEST_FILE#$SRC/}"
DEST_MANIFEST="$SEED_MODELS_DIR/${REL_MANIFEST#manifests/}"
mkdir -p "$(dirname "$DEST_MANIFEST")"
cp -a "$MANIFEST_FILE" "$DEST_MANIFEST"

log "Copied manifest to:"
echo "  $DEST_MANIFEST"

# Copy blobs
COPIED=0
MISSING=0

while read -r d; do
  [[ -n "$d" ]] || continue
  HASH="${d#sha256:}"
  SRC_BLOB="$SRC/blobs/sha256-$HASH"
  DEST_BLOB="$SEED_MODELS_DIR/blobs/sha256-$HASH"

  if [[ -f "$SRC_BLOB" ]]; then
    cp -a "$SRC_BLOB" "$DEST_BLOB"
    COPIED=$((COPIED+1))
  else
    echo "!! Missing blob file: $SRC_BLOB"
    MISSING=$((MISSING+1))
  fi
done <<<"$DIGESTS"

log "Blob copy done. Copied: $COPIED  Missing: $MISSING"
if [[ "$MISSING" -ne 0 ]]; then
  die "Some blobs were missing. The server store may be incomplete/corrupted."
fi

# Ensure the seed store has the expected top-level layout
# (manifests + blobs)
log "Seed store contents:"
find "$SEED_MODELS_DIR" -maxdepth 2 -type d -print | sed 's/^/  /'

# Create tarball
mkdir -p "$HOME/Buddy-OS/build"
STAMP="$(date +%Y%m%d_%H%M%S)"
OUT_TAR="$HOME/Buddy-OS/build/ollama_seed_${MODEL_NAME}_${MODEL_TAG}_${STAMP}.tar.gz"

log "Creating tarball:"
echo "  $OUT_TAR"
tar -C "$SEED_ROOT" -czf "$OUT_TAR" "models"

log "DONE."
echo
echo "Next sanity check (should show manifests/blobs now):"
echo "  ls -lah \"$SEED_MODELS_DIR\""
echo
echo "To verify the seed store works without touching your main daemon, you can start a temporary server on another port:"
echo "  OLLAMA_MODELS=\"$SEED_MODELS_DIR\" OLLAMA_HOST=127.0.0.1:11500 ollama serve"
echo "  (then in another terminal: OLLAMA_HOST=127.0.0.1:11500 ollama list)"
