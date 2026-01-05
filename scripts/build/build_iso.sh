#!/usr/bin/env bash
set -euo pipefail

# NOTE: This script uses livecd-rootfs to build from scratch.
# For remixing existing Ubuntu ISOs, use scripts/dev/remix_iso_*.sh instead.

# Build Buddy-OS ISO using Ubuntu livecd-rootfs + ubuntu-cdimage.
# This script runs inside the LXD container environment

# Use workspace directory (container mount point)
BUILD_ROOT="/workspace"

ROOT_DIR="${BUILD_ROOT}"
OUT_DIR="${ROOT_DIR}/build/iso"
TS="$(date +%Y%m%d_%H%M%S)"
WORK_DIR="${ROOT_DIR}/build/iso_work_${TS}"

mkdir -p "${OUT_DIR}" "${WORK_DIR}"

# Check if livecd-rootfs is available
if [ ! -d /usr/share/livecd-rootfs/live-build ]; then
    echo "ERROR: livecd-rootfs not installed. Please run:"
    echo "apt-get update && apt-get install -y livecd-rootfs germinate xorriso squashfs-tools grub-pc-bin grub-efi-amd64-bin casper debootstrap rsync jq git ca-certificates python3 make"
    exit 1
fi

export LIVE_BUILD=/usr/share/livecd-rootfs/live-build
export PROJECT=ubuntu
export ARCH=amd64
export SUITE=noble
export FLAVOUR=cosmic
export SUBPROJECT=
export SNAP_NO_VALIDATE_SEED=1
export LOCALE_SUPPORT=none

# Force full desktop build instead of minimal
export LIVE_BUILD_VARIANT=desktop
export LIVE_BUILD_TYPE=iso
export LIVE_BUILD_FULL=true

# Use desktop package selection instead of minimal
export LIVE_BUILD_PACKAGES="ubuntu-desktop cosmic-desktop"

cd "${WORK_DIR}"
# Copy hooks to chroot location
mkdir -p config/includes.chroot/usr/share/buddy-os/hooks
rsync -a "${ROOT_DIR}/scripts/build/iso/hooks/" config/includes.chroot/usr/share/buddy-os/hooks/
chmod +x config/includes.chroot/usr/share/buddy-os/hooks/*.chroot
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
  config/includes.chroot/usr/share/buddy-os/rootfs-overlay \
  config/includes.chroot/usr/share/buddy-os/package-lists \
  config/includes.chroot/etc/apt/sources.list.d \
  config/includes.chroot/etc/apt/trusted.gpg.d

rsync -a "${ROOT_DIR}/scripts/build/iso/package-lists/" \
  config/includes.chroot/usr/share/buddy-os/package-lists/

# Copy hooks to chroot location
mkdir -p config/includes.chroot/usr/share/buddy-os/hooks
rsync -a "${ROOT_DIR}/scripts/build/iso/hooks/" config/includes.chroot/usr/share/buddy-os/hooks/
chmod +x config/includes.chroot/usr/share/buddy-os/hooks/*.chroot

# Copy livecd-rootfs configuration
cp "${ROOT_DIR}/scripts/build/iso/livecd-rootfs.yaml" config/livecd-rootfs.yaml

# Create package list directory and symlink to use desktop packages
mkdir -p config/package-lists
ln -sf /usr/share/buddy-os/package-lists/desktop.list.chroot \
  config/package-lists/buddy-desktop.list.chroot

# Override livecd-rootfs package selection to use our desktop list
echo "buddy-desktop" > config/package-lists/livecd-rootfs.list.chroot

rsync -a "${ROOT_DIR}/images/rootfs/" \
  config/includes.chroot/usr/share/buddy-os/rootfs-overlay/

cp -f "${ROOT_DIR}/assets/apt/pop-os-release.sources" \
  config/includes.chroot/etc/apt/sources.list.d/pop-os-release.sources
cp -f "${ROOT_DIR}/assets/apt/pop-os-apps.sources" \
  config/includes.chroot/etc/apt/sources.list.d/pop-os-apps.sources
cp -f "${ROOT_DIR}/assets/apt/pop-keyring-2017-archive.gpg" \
  config/includes.chroot/etc/apt/trusted.gpg.d/pop-keyring-2017-archive.gpg

# -----------------------------------------------------------------
# Add Buddy‑OS systemd services and configuration files to the ISO
# -----------------------------------------------------------------
# Create directories for systemd units and Buddy‑OS config inside the chroot overlay
mkdir -p "config/includes.chroot/etc/systemd/system"
mkdir -p "config/includes.chroot/etc/buddy-os"

# Copy any unit files placed under scripts/systemd/ into the chroot
if [ -d "${ROOT_DIR}/scripts/systemd" ]; then
  cp -a "${ROOT_DIR}/scripts/systemd/"* "config/includes.chroot/etc/systemd/system/"
fi

# Copy Buddy‑OS JSON configuration files (agents, providers, UI settings)
if [ -f "${ROOT_DIR}/config/agents.json" ]; then
  cp "${ROOT_DIR}/config/agents.json" "config/includes.chroot/etc/buddy-os/"
fi
if [ -f "${ROOT_DIR}/config/providers.example.json" ]; then
  cp "${ROOT_DIR}/config/providers.example.json" "config/includes.chroot/etc/buddy-os/providers.json"
fi
if [ -f "${ROOT_DIR}/config/settings.json" ]; then
  cp "${ROOT_DIR}/config/settings.json" "config/includes.chroot/etc/buddy-os/settings.json"
fi

# Modify lb_chroot_apt to run essential hooks before apt operations
if [ -f config/lb_chroot_apt ]; then
  awk '{
    if ($0 ~ /^\tlb_chroot_apt_install$/) {
      print "\t# Run Buddy-OS essential setup hooks before apt operations";
      print "\t# Try hooks in chroot first, then includes location";
      print "\tif [ -d /usr/share/buddy-os/hooks ]; then";
      print "\t\tfor hook in /usr/share/buddy-os/hooks/*.chroot; do";
      print "\t\t\tif [ -f \"$hook\" ] \&\& [ -x \"$hook\" ]; then";
      print "\t\t\t\techo \"Running hook: $(basename \"$hook\")\"";
      print "\t\t\t\t\"$hook\"";
      print "\t\t\tfi";
      print "\t\tdone";
      print "\tfi";
      print "\t# Also try config/hooks/chroot location";
      print "\tif [ -d config/hooks/chroot ]; then";
      print "\t\tfor hook in config/hooks/chroot/*.chroot; do";
      print "\t\t\tif [ -f "$hook" ] \&\& [ -x "$hook" ]; then";
      print "\t\t\t\techo \"Running hook: $(basename "$hook")\"";
      print "\t\t\t\t\"$hook\"";
      print "\t\t\tfi";
      print "\t\tdone";
      print "\tfi";
      print;
      next;
    }
    print;
  }' config/lb_chroot_apt > config/lb_chroot_apt.tmp
  mv config/lb_chroot_apt.tmp config/lb_chroot_apt
  chmod +x config/lb_chroot_apt
fi

echo "== livecd-rootfs auto/build =="
"${LIVE_BUILD}/auto/build"

# Normalize ISO output name/location
if [ -f "livecd.${PROJECT}.iso" ]; then
  mv -f "livecd.${PROJECT}.iso" "${OUT_DIR}/Buddy-OS-0.0.0.iso"
fi

echo "OK: ISO build complete"
LOCALE_SUPPORT=none
