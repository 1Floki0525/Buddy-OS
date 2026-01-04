#!/usr/bin/env bash
set -euo pipefail

# Build Buddy-OS ISO using Ubuntu livecd-rootfs + ubuntu-cdimage.
# Run this from inside the LXD container with /workspace mounted.

ROOT_DIR="/workspace"
OUT_DIR="${ROOT_DIR}/build/iso"
TS="$(date +%Y%m%d_%H%M%S)"
WORK_DIR="${ROOT_DIR}/build/iso_work_${TS}"

mkdir -p "${OUT_DIR}" "${WORK_DIR}"

export LIVE_BUILD=/usr/share/livecd-rootfs/live-build
export PROJECT=ubuntu
export ARCH=amd64
export SUITE=noble
export FLAVOUR=ubuntu
export SUBPROJECT=
export SNAP_NO_VALIDATE_SEED=1
export LOCALE_SUPPORT=none

cd "${WORK_DIR}"

echo "== livecd-rootfs auto/config =="
"${LIVE_BUILD}/auto/config"

# Avoid snap preseed validation in environments without loop/AppArmor features.
if [ -f config/lb_chroot_layered ]; then
  awk '{
    if ($0 ~ /^\tsnap_validate_seed chroot$/) {
      print "\tif [ -z \"${SNAP_NO_VALIDATE_SEED:-}\" ]; then";
      print "\t  snap_validate_seed chroot";
      print "\tfi";
      next;
    }
    print;
  }' config/lb_chroot_layered > config/lb_chroot_layered.tmp
  mv config/lb_chroot_layered.tmp config/lb_chroot_layered
  chmod +x config/lb_chroot_layered

  awk '{
    if ($0 ~ /^\t# Copying includes from pass subdirectory$/) {
      print;
      print "\t# Always apply generic includes if present";
      print "\tif [ -d config/includes.chroot ]; then";
      print "\t\tcd config/includes.chroot";
      print "\t\tfind . | cpio -dmpu --no-preserve-owner \"${OLDPWD}\"/chroot";
      print "\t\tcd \"${OLDPWD}\"";
      print "\tfi";
      next;
    }
    print;
  }' config/lb_chroot_layered > config/lb_chroot_layered.tmp
  mv config/lb_chroot_layered.tmp config/lb_chroot_layered
  chmod +x config/lb_chroot_layered
fi

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
LOCALE_SUPPORT=none
