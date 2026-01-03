#!/usr/bin/env bash
set -euo pipefail

# Buddy-OS ISO Remix: Phase A
# - Extract ISO into build/iso_work/iso
# - Unsquash live rootfs into build/iso_work/squashfs-root
# - Apply repo overlay rootfs (images/rootfs) into squashfs-root
#
# IMPORTANT:
# - If ISO_PATH is set and points to an ISO, we use it (no download).
# - Otherwise we fall back to Ubuntu URL/cache behavior.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
WORK_DIR="${REPO_ROOT}/build/iso_work"
ISO_DIR="${WORK_DIR}/iso"
SQUASH_DIR="${WORK_DIR}/squashfs-root"
OVERLAY_ROOTFS="${REPO_ROOT}/images/rootfs"
ISO_CACHE_DIR="${REPO_ROOT}/build/iso_cache"

# Default Ubuntu fallback (only used if ISO_PATH is not provided)
DEFAULT_ISO_URL="${ISO_URL:-https://releases.ubuntu.com/24.04/ubuntu-24.04.3-desktop-amd64.iso}"
DEFAULT_ISO_NAME="$(basename "$DEFAULT_ISO_URL")"
DEFAULT_ISO_CACHE_PATH="${ISO_CACHE_DIR}/${DEFAULT_ISO_NAME}"

# If user provided ISO_PATH, use it (absolute path)
INPUT_ISO_PATH="${ISO_PATH:-}"

if [[ -n "$INPUT_ISO_PATH" ]]; then
  # Expand ~ and resolve absolute
  INPUT_ISO_PATH="$(python3 - <<'PY'
import os,sys
p=os.path.expanduser(os.environ.get("ISO_PATH",""))
print(os.path.abspath(p))
PY
)"
fi

need_root=0
if [[ $EUID -ne 0 ]]; then
  need_root=1
fi

# We can extract without root, but unsquash + device nodes/xattrs and overlay chowns are cleaner as root.
if [[ $need_root -eq 1 ]]; then
  echo "== Phase A needs root for unsquashfs/xattrs/device nodes. Re-running with sudo... =="
  exec sudo -E ISO_PATH="${ISO_PATH:-}" ISO_URL="${ISO_URL:-}" bash "$0"
fi

mkdir -p "$ISO_CACHE_DIR"

echo "== Buddy-OS ISO Remix: Phase A =="
echo "REPO_ROOT:        $REPO_ROOT"
echo "WORK_DIR:         $WORK_DIR"
echo "Overlay rootfs:   $OVERLAY_ROOTFS"
echo

ISO_USED=""
ISO_URL_PRINT=""
ISO_CACHE_PRINT=""

if [[ -n "$INPUT_ISO_PATH" ]]; then
  if [[ ! -f "$INPUT_ISO_PATH" ]]; then
    echo "ERROR: ISO_PATH was set but file does not exist:"
    echo "  ISO_PATH=$INPUT_ISO_PATH"
    exit 1
  fi
  ISO_USED="$INPUT_ISO_PATH"
  ISO_URL_PRINT="(using ISO_PATH)"
  ISO_CACHE_PRINT="$ISO_USED"
else
  ISO_URL_PRINT="$DEFAULT_ISO_URL"
  ISO_CACHE_PRINT="$DEFAULT_ISO_CACHE_PATH"
  ISO_USED="$DEFAULT_ISO_CACHE_PATH"

  echo "ISO URL:          $ISO_URL_PRINT"
  echo "ISO cache path:   $ISO_CACHE_PRINT"
  echo

  if [[ -f "$ISO_USED" ]]; then
    echo "==> ISO already cached: $ISO_USED"
  else
    echo "==> Downloading ISO..."
    curl -L --fail --retry 3 --retry-delay 2 -o "$ISO_USED" "$DEFAULT_ISO_URL"
  fi
fi

if [[ -n "$INPUT_ISO_PATH" ]]; then
  echo "ISO PATH:         $ISO_USED"
else
  echo "ISO URL:          $ISO_URL_PRINT"
  echo "ISO cache path:   $ISO_CACHE_PRINT"
fi
echo

echo "==> Cleaning previous extracted ISO + squashfs..."
rm -rf "$ISO_DIR" "$SQUASH_DIR"
mkdir -p "$ISO_DIR"

echo
echo "==> Extracting ISO to $ISO_DIR ..."
# Use xorriso to extract, preserving as much as possible
xorriso -osirrox on -indev "$ISO_USED" -extract / "$ISO_DIR"

# Make extracted tree writable (some ISO extractions end up 0444)
chmod -R u+w "$ISO_DIR" || true

echo
echo "==> Locating squashfs..."
# Pop/Ubuntu can differ; be flexible.
CANDIDATES=(
  "$ISO_DIR/casper/filesystem.squashfs"
  "$ISO_DIR/live/filesystem.squashfs"
  "$ISO_DIR/casper/minimal.squashfs"
  "$ISO_DIR/casper/minimal.standard.live.squashfs"
  "$ISO_DIR/casper/minimal.standard.squashfs"
  "$ISO_DIR/casper/ubuntu-desktop-minimal.squashfs"
  "$ISO_DIR/casper/ubuntu-server-minimal.squashfs"
)

SQUASHFS_PATH=""
for p in "${CANDIDATES[@]}"; do
  if [[ -f "$p" ]]; then
    SQUASHFS_PATH="$p"
    break
  fi
done

if [[ -z "$SQUASHFS_PATH" ]]; then
  echo "ERROR: could not find a known squashfs under casper/ or live/"
  echo "Looked for:"
  for p in "${CANDIDATES[@]}"; do echo " - $p"; done
  echo
  echo "Found squashfs files:"
  find "$ISO_DIR" -maxdepth 5 -type f \( -name "*.squashfs" -o -name "*.sfs" \) -print || true
  exit 1
fi

echo "Using squashfs: $SQUASHFS_PATH"

echo
echo "==> Unsquashing live filesystem..."
unsquashfs -f -d "$SQUASH_DIR" "$SQUASHFS_PATH" >/dev/null

echo
echo "==> Applying rootfs overlay from repo: $OVERLAY_ROOTFS"
if [[ -d "$OVERLAY_ROOTFS" ]]; then
  # Preserve symlinks and permissions, but avoid copying device nodes from overlay
  rsync -aHAX --no-devices --no-specials "$OVERLAY_ROOTFS"/ "$SQUASH_DIR"/
fi

# Normalize ownership inside the image to root:root (critical for a sane installed system)
chown -R root:root "$SQUASH_DIR" || true

echo
echo "==> Done (Phase A)."
echo "Extracted ISO:      $ISO_DIR"
echo "Unsquashed rootfs:  $SQUASH_DIR"
