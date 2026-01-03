#!/usr/bin/env bash
set -euo pipefail

# Self-elevate
if [[ "${EUID}" -ne 0 ]]; then
  exec sudo -E bash "$0" "$@"
fi

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
WORK_DIR="${WORK_DIR:-$REPO_ROOT/build/iso_work}"
ISO_DIR="${ISO_DIR:-$WORK_DIR/iso}"
SQUASH_DIR="${SQUASH_DIR:-$WORK_DIR/squashfs-root}"
OVERLAY_ROOTFS="${OVERLAY_ROOTFS:-$REPO_ROOT/images/rootfs}"
ISO_CACHE_DIR="${ISO_CACHE_DIR:-$REPO_ROOT/build/iso_cache}"

# Pick the newest ISO in cache if ISO_PATH not provided
ISO_PATH="${ISO_PATH:-}"
if [[ -z "$ISO_PATH" ]]; then
  ISO_PATH="$(ls -1t "$ISO_CACHE_DIR"/*.iso 2>/dev/null | head -n 1 || true)"
fi

OUT_ISO="${OUT_ISO:-$REPO_ROOT/build/Buddy-OS-24.04.3-amd64.iso}"
VOLID="${VOLID:-Buddy-OS 24.04.3 amd64}"

echo "== Buddy-OS ISO Remix: Phase C (repack + build ISO) =="
echo "REPO_ROOT:      $REPO_ROOT"
echo "WORK_DIR:       $WORK_DIR"
echo "ISO_DIR:        $ISO_DIR"
echo "SQUASH_DIR:     $SQUASH_DIR"
echo "OVERLAY_ROOTFS: $OVERLAY_ROOTFS"
echo "ISO_PATH:       $ISO_PATH"
echo "OUT_ISO:        $OUT_ISO"
echo "VOLID:          $VOLID"
echo

[[ -d "$ISO_DIR" ]] || { echo "ERROR: ISO_DIR missing: $ISO_DIR"; exit 1; }
[[ -d "$SQUASH_DIR" ]] || { echo "ERROR: SQUASH_DIR missing: $SQUASH_DIR"; exit 1; }
[[ -f "$ISO_PATH" ]] || { echo "ERROR: ISO_PATH not found (no ISO in cache?): $ISO_PATH"; exit 1; }

# Locate which squashfs file we are replacing
SQUASH_IN=""
CANDIDATES=(
  "$ISO_DIR/casper/minimal.squashfs"
  "$ISO_DIR/casper/filesystem.squashfs"
  "$ISO_DIR/live/filesystem.squashfs"
)
for p in "${CANDIDATES[@]}"; do
  if [[ -f "$p" ]]; then
    SQUASH_IN="$p"
    break
  fi
done
[[ -n "$SQUASH_IN" ]] || { echo "ERROR: Could not locate target squashfs in ISO tree."; exit 1; }

echo "==> Target squashfs: $SQUASH_IN"
echo

echo "==> Making extracted ISO tree writable (Ubuntu ISOs often extract read-only)..."
chmod -R u+rwX "$ISO_DIR"

echo
if [[ -d "$OVERLAY_ROOTFS" ]]; then
  echo "==> Applying overlay rootfs into squashfs-root..."
  # Preserve ownership/perms; do NOT delete anything from base rootfs
  rsync -aHAX --numeric-ids "$OVERLAY_ROOTFS/." "$SQUASH_DIR/."
else
  echo "==> Overlay rootfs not found (skipping): $OVERLAY_ROOTFS"
fi

echo
echo "==> Rebuilding squashfs (this can take a while)..."
TMP_SQ="$(mktemp -p "$WORK_DIR" minimal.squashfs.XXXXXX)"
rm -f "$TMP_SQ"
mksquashfs "$SQUASH_DIR" "$TMP_SQ" -noappend -comp xz -b 1M

echo
echo "==> Replacing squashfs in ISO tree..."
cp -f "$TMP_SQ" "$SQUASH_IN"
rm -f "$TMP_SQ"
chmod 444 "$SQUASH_IN" || true

echo
echo "==> Updating size markers (best-effort)..."
ROOTFS_SIZE_BYTES="$(du -sb "$SQUASH_DIR" | awk '{print $1}')"
# Common Ubuntu markers (harmless if not used by boot flow)
if [[ -d "$ISO_DIR/casper" ]]; then
  echo "$ROOTFS_SIZE_BYTES" > "$ISO_DIR/casper/minimal.size" || true
  if [[ -f "$ISO_DIR/casper/filesystem.size" ]]; then
    echo "$ROOTFS_SIZE_BYTES" > "$ISO_DIR/casper/filesystem.size" || true
  fi
fi

echo
echo "==> Regenerating md5sum.txt..."
(
  cd "$ISO_DIR"
  # Exclude md5sum.txt itself to avoid self-reference
  find . -type f ! -name 'md5sum.txt' -print0 \
    | LC_ALL=C sort -z \
    | xargs -0 md5sum > md5sum.txt.new
  mv -f md5sum.txt.new md5sum.txt
)

echo
echo "==> Building new ISO (replay bootloader from original)..."
mkdir -p "$(dirname "$OUT_ISO")"
rm -f "$OUT_ISO"

xorriso \
  -indev "$ISO_PATH" \
  -outdev "$OUT_ISO" \
  -map "$ISO_DIR" / \
  -boot_image any replay \
  -volid "$VOLID"

echo
echo "==> Done:"
ls -lah "$OUT_ISO"
sha256sum "$OUT_ISO" | tee "$OUT_ISO.sha256"
