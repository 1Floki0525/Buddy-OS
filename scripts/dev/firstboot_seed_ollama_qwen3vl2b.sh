#!/usr/bin/env bash
set -euo pipefail

# Buddy-OS first-boot: seed the default offline model into Ollama's store.
# Idempotent: safe to run multiple times.

SEED_TAR="/opt/buddy-os/seeds/ollama_seed_qwen3vl_2b_only.tar.gz"
SEED_SHA_EXPECT="2e6ff565c7b637e3d7331f931d7f1a5dc62c5e4ed0cc39f98cd6b6be275bf26f"

# Default store location for the ollama service user on your curl-installed setup.
# In Buddy-OS we’ll keep this configurable later, but hardcoding is fine for v0.
DEST_STORE="/usr/share/ollama/.ollama/models"

log(){ printf "\n==> %s\n" "$*"; }
die(){ echo "ERROR: $*" >&2; exit 1; }

[[ -f "$SEED_TAR" ]] || die "Seed tar not found at $SEED_TAR (image must include it)."

log "Verifying seed tar sha256..."
ACTUAL="$(sha256sum "$SEED_TAR" | awk '{print $1}')"
[[ "$ACTUAL" == "$SEED_SHA_EXPECT" ]] || die "SHA mismatch. expected=$SEED_SHA_EXPECT actual=$ACTUAL"

log "Stopping ollama..."
systemctl stop ollama || true

log "Ensuring store exists: $DEST_STORE"
mkdir -p "$DEST_STORE"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

log "Extracting seed pack..."
tar -C "$TMP" -xzf "$SEED_TAR"
[[ -d "$TMP/models/blobs" && -d "$TMP/models/manifests" ]] || die "Seed tar missing models/ layout"

log "Sync into store..."
rsync -a "$TMP/models/" "$DEST_STORE/"

log "Fix ownership for ollama service user..."
chown -R ollama:ollama "$DEST_STORE" || true

log "Starting ollama..."
systemctl start ollama || true

log "Done. Tags:"
curl -s http://127.0.0.1:11434/api/tags | head -n 80 || true
