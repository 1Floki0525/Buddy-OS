#!/usr/bin/env bash
set -euo pipefail

# Simple wrapper to run the remix process from inside the container
# This script assumes the ISO is already cached in /workspace/build/iso_cache/

echo "== Buddy-OS ISO Remix (Container Edition) =="

# Set paths for container environment
ISO_CACHE="/workspace/build/iso_cache"
ISO_WORK="/workspace/build/iso_work"
SQUASH_DIR="$ISO_WORK/squashfs-root"
ISO_DIR="$ISO_WORK/iso"

# Use the cached Ubuntu 24.04.3 ISO
ISO_PATH="$ISO_CACHE/ubuntu-24.04.3-desktop-amd64.iso"

if [[ ! -f "$ISO_PATH" ]]; then
    echo "ERROR: ISO not found at $ISO_PATH"
    echo "Please ensure the ISO is cached in the container"
    exit 1
fi

echo "Using ISO: $ISO_PATH"

# Clean previous work
rm -rf "$ISO_DIR" "$SQUASH_DIR"
mkdir -p "$ISO_DIR" "$(dirname "$SQUASH_DIR")"

echo "==> Extracting ISO..."
xorriso -indev "$ISO_PATH" -extract / "$ISO_DIR" >/dev/null

echo "==> Locating squashfs..."
# Ubuntu 24.04.3 uses minimal.standard.live.squashfs
CASPER="$ISO_DIR/casper"
SQUASHFS_PATH="$(ls -1 "$CASPER"/*standard*live*.squashfs 2>/dev/null | head -n 1 || true)"

if [[ -z "$SQUASHFS_PATH" ]]; then
    echo "ERROR: No standard live squashfs found"
    echo "Found files:"
    ls -la "$CASPER"/*.squashfs 2>/dev/null || true
    exit 1
fi

echo "Using squashfs: $SQUASHFS_PATH"

echo "==> Unsquashing live filesystem..."
# Skip device nodes and trusted xattrs for unprivileged container
unsquashfs -f -d "$SQUASH_DIR" -no-devices -no-specials -xattrs-exclude '^trusted\.' "$SQUASHFS_PATH" >/dev/null

echo "==> Phase A complete"
echo "Extracted ISO: $ISO_DIR"
echo "Unsquashed rootfs: $SQUASH_DIR"