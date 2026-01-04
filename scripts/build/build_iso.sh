#!/usr/bin/env bash
set -euo pipefail

# Build Buddy-OS ISO using Ubuntu livecd-rootfs + ubuntu-cdimage.
# Run this from inside the LXD container with /workspace mounted.

ROOT_DIR="/workspace"
OUT_DIR="${ROOT_DIR}/build/iso"
WORK_DIR="${ROOT_DIR}/build/iso_work"

mkdir -p "${OUT_DIR}"

if [ -d "${WORK_DIR}" ]; then
  echo "== Cleaning ISO work dir =="
  findmnt -rn -o TARGET | awk -v base="${WORK_DIR}" '$0 ~ "^" base {print}' | sort -r | while read -r m; do
    umount -lf "${m}" || true
  done
  rm -rf "${WORK_DIR}"
fi

mkdir -p "${WORK_DIR}"

export LIVE_BUILD=/usr/share/livecd-rootfs/live-build
export PROJECT=ubuntu
export ARCH=amd64
export SUITE=noble
export FLAVOUR=ubuntu
export SUBPROJECT=

cd "${WORK_DIR}"

echo "== livecd-rootfs auto/config =="
"${LIVE_BUILD}/auto/config"

# Inject Buddy-OS overlays into the generated config
mkdir -p \
  config/hooks \
  config/includes.chroot/usr/share/buddy-os/rootfs-overlay \
  config/includes.chroot/usr/share/buddy-os/package-lists \
  config/includes.chroot/etc/apt/sources.list.d \
  config/includes.chroot/etc/apt/trusted.gpg.d

rsync -a "${ROOT_DIR}/scripts/build/iso/hooks/" config/hooks/
rsync -a "${ROOT_DIR}/scripts/build/iso/package-lists/" \
  config/includes.chroot/usr/share/buddy-os/package-lists/
rsync -a "${ROOT_DIR}/images/rootfs/" \
  config/includes.chroot/usr/share/buddy-os/rootfs-overlay/

cp -f "${ROOT_DIR}/assets/apt/pop-os-release.sources" \
  config/includes.chroot/etc/apt/sources.list.d/pop-os-release.sources
cp -f "${ROOT_DIR}/assets/apt/pop-os-apps.sources" \
  config/includes.chroot/etc/apt/sources.list.d/pop-os-apps.sources
cp -f "${ROOT_DIR}/assets/apt/pop-keyring-2017-archive.gpg" \
  config/includes.chroot/etc/apt/trusted.gpg.d/pop-keyring-2017-archive.gpg

chmod +x config/hooks/*.chroot

echo "== livecd-rootfs auto/build =="
"${LIVE_BUILD}/auto/build"

# Normalize ISO output name/location
if [ -f "livecd.${PROJECT}.iso" ]; then
  mv -f "livecd.${PROJECT}.iso" "${OUT_DIR}/Buddy-OS-0.0.0.iso"
fi

echo "OK: ISO build complete"
