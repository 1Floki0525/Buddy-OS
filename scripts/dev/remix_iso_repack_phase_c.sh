#!/usr/bin/env bash
set -euo pipefail

# Buddy-OS ISO Remix: Phase C (repack + build ISO) for Pop/Ubuntu-like Desktop ISOs
# - Rebuilds the squashfs inside extracted ISO tree
# - Regenerates md5sums
# - Builds a hybrid BIOS+UEFI bootable ISO using detected boot files

if [[ $EUID -ne 0 ]]; then
  exec sudo -E bash "$0" "$@"
fi

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
WORK_DIR="${REPO_ROOT}/build/iso_work"
ISO_DIR="${WORK_DIR}/iso"
SQUASH_DIR="${WORK_DIR}/squashfs-root"
ISO_CACHE_DIR="${REPO_ROOT}/build/iso_cache"

# Original ISO: prefer ISO_PATH passed in; else try common Pop ISO; else error
ORIG_ISO="${ISO_PATH:-}"
if [[ -z "$ORIG_ISO" ]]; then
  # If you keep it cached here, this will usually exist:
  if [[ -f "${ISO_CACHE_DIR}/pop-os_24.04_amd64_generic_22.iso" ]]; then
    ORIG_ISO="${ISO_CACHE_DIR}/pop-os_24.04_amd64_generic_22.iso"
  fi
fi
if [[ -z "$ORIG_ISO" || ! -f "$ORIG_ISO" ]]; then
  echo "ERROR: Need original ISO path. Set ISO_PATH=/path/to/pop.iso"
  exit 1
fi

OUT_ISO="${REPO_ROOT}/build/Buddy-OS-pop24.04-amd64.iso"
VOLID="${VOLID:-BUDDY_OS_2404_AMD64}"   # ISO9660-safe (no spaces)

echo "== Buddy-OS ISO Remix: Phase C (repack + build ISO) =="
echo "REPO_ROOT:   $REPO_ROOT"
echo "WORK_DIR:    $WORK_DIR"
echo "ISO_DIR:     $ISO_DIR"
echo "SQUASH_DIR:  $SQUASH_DIR"
echo "ORIG_ISO:    $ORIG_ISO"
echo "OUT_ISO:     $OUT_ISO"
echo "VOLID:       $VOLID"
echo

if [[ ! -d "$ISO_DIR" || ! -d "$SQUASH_DIR" ]]; then
  echo "ERROR: Missing ISO_DIR or SQUASH_DIR. Run Phase A first."
  exit 1
fi

# Find which squashfs we should replace
TARGET_SQUASH=""
CANDIDATES=(
  "$ISO_DIR/casper/filesystem.squashfs"
  "$ISO_DIR/casper/minimal.squashfs"
  "$ISO_DIR/casper/minimal.standard.live.squashfs"
  "$ISO_DIR/live/filesystem.squashfs"
)
for p in "${CANDIDATES[@]}"; do
  if [[ -f "$p" ]]; then
    TARGET_SQUASH="$p"
    break
  fi
done
if [[ -z "$TARGET_SQUASH" ]]; then
  echo "ERROR: Could not find target squashfs to replace in extracted ISO."
  find "$ISO_DIR" -maxdepth 4 -type f \( -name "*.squashfs" -o -name "*.sfs" \) -print || true
  exit 1
fi
echo "==> Target squashfs: $TARGET_SQUASH"
echo

echo "==> Ensuring extracted ISO tree is writable..."
chmod -R u+w "$ISO_DIR" || true
echo

echo "==> Rebuilding squashfs (this can take a while)..."
TMP_SQ="$(mktemp -p "$WORK_DIR" -t filesystem.squashfs.XXXXXX)"
# Keep it compatible and reasonably small; Pop uses xz.
mksquashfs "$SQUASH_DIR" "$TMP_SQ" -noappend -comp xz -Xbcj x86 -b 1M -processors "$(nproc)"
echo

echo "==> Replacing squashfs in ISO tree..."
cp -av "$TMP_SQ" "$TARGET_SQUASH"
rm -f "$TMP_SQ"
echo

# Update filesystem.size if present (casper)
if [[ -f "$ISO_DIR/casper/filesystem.size" ]]; then
  echo "==> Updating casper/filesystem.size..."
  # size in bytes
  du -sb "$SQUASH_DIR" | awk '{print $1}' > "$ISO_DIR/casper/filesystem.size" || true
fi
echo

echo "==> Regenerating md5sum.txt (best-effort)..."
if [[ -f "$ISO_DIR/md5sum.txt" ]]; then
  ( cd "$ISO_DIR"
    # Some boot files may change timestamps; md5 list is used by check-media, not strictly required.
    # Exclude md5sum.txt itself.
    find . -type f -print0 \
      | sed -z 's#^\./##' \
      | grep -zv '^md5sum\.txt$' \
      | xargs -0 md5sum > md5sum.txt
  ) || true
fi
echo

# Detect boot assets
# BIOS boot (common)
ELTORITO_IMG=""
if [[ -f "$ISO_DIR/boot/grub/i386-pc/eltorito.img" ]]; then
  ELTORITO_IMG="boot/grub/i386-pc/eltorito.img"
fi

# ISOLINUX (some distros)
ISOLINUX_BIN=""
ISOLINUX_CAT=""
if [[ -f "$ISO_DIR/isolinux/isolinux.bin" ]]; then
  ISOLINUX_BIN="isolinux/isolinux.bin"
  ISOLINUX_CAT="isolinux/boot.cat"
fi

# UEFI boot image
EFI_IMG=""
for p in \
  "$ISO_DIR/boot/grub/efi.img" \
  "$ISO_DIR/efi.img" \
  "$ISO_DIR/boot/efi.img" \
  "$ISO_DIR/boot/grub/x86_64-efi/efi.img"
do
  if [[ -f "$p" ]]; then
    EFI_IMG="${p#$ISO_DIR/}"
    break
  fi
done

# Hybrid MBR blob (isohybrid)
ISOHYBRID_MBR=""
for p in \
  "$ISO_DIR/isolinux/isohdpfx.bin" \
  "$ISO_DIR/boot/grub/i386-pc/boot_hybrid.img"
do
  if [[ -f "$p" ]]; then
    ISOHYBRID_MBR="${p#$ISO_DIR/}"
    break
  fi
done

echo "==> Boot asset detection:"
echo "  ELTORITO_IMG:   ${ELTORITO_IMG:-<none>}"
echo "  ISOLINUX_BIN:   ${ISOLINUX_BIN:-<none>}"
echo "  EFI_IMG:        ${EFI_IMG:-<none>}"
echo "  ISOHYBRID_MBR:  ${ISOHYBRID_MBR:-<none>}"
echo

if [[ -z "$ELTORITO_IMG" && -z "$ISOLINUX_BIN" ]]; then
  echo "ERROR: Could not detect a BIOS boot entry (eltorito.img or isolinux.bin)."
  echo "Looked for:"
  echo " - $ISO_DIR/boot/grub/i386-pc/eltorito.img"
  echo " - $ISO_DIR/isolinux/isolinux.bin"
  exit 1
fi
if [[ -z "$EFI_IMG" ]]; then
  echo "WARNING: Could not find an EFI boot image (*.img). ISO will likely still BIOS boot, but may not UEFI boot."
  echo "If Pop stores EFI boot differently, we’ll adapt once we inspect ISO tree."
fi

echo "==> Building new ISO..."
rm -f "$OUT_ISO"

MKISO_ARGS=(
  -as mkisofs
  -r
  -V "$VOLID"
  -J
  -joliet-long
  -iso-level 3
  -full-iso9660-filenames
  -o "$OUT_ISO"
)

# Hybrid MBR if available
if [[ -n "$ISOHYBRID_MBR" ]]; then
  MKISO_ARGS+=( -isohybrid-mbr "$ISO_DIR/$ISOHYBRID_MBR" )
  # Helps for GPT/UEFI hybrid media
  MKISO_ARGS+=( -isohybrid-gpt-basdat )
fi

# BIOS boot entry (prefer isolinux if present; else grub eltorito)
if [[ -n "$ISOLINUX_BIN" ]]; then
  MKISO_ARGS+=( -c "$ISOLINUX_CAT" -b "$ISOLINUX_BIN" -no-emul-boot -boot-load-size 4 -boot-info-table )
else
  MKISO_ARGS+=( -b "$ELTORITO_IMG" -no-emul-boot -boot-load-size 4 -boot-info-table )
fi

# UEFI boot entry if we have an EFI image
if [[ -n "$EFI_IMG" ]]; then
  MKISO_ARGS+=( -eltorito-alt-boot -e "$EFI_IMG" -no-emul-boot )
fi

# Source tree
MKISO_ARGS+=( "$ISO_DIR" )

xorriso "${MKISO_ARGS[@]}"

echo
echo "==> ISO built:"
ls -lah "$OUT_ISO"
echo
echo "==> SHA256:"
sha256sum "$OUT_ISO" | tee "${OUT_ISO}.sha256"
echo
echo "Phase C complete."
