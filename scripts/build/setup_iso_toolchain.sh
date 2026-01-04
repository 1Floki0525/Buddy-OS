#!/usr/bin/env bash
set -euo pipefail

# Install ISO build tooling inside the build container.
# Run this from inside the LXD container.

apt-get update
apt-get install -y --no-install-recommends \
  livecd-rootfs \
  germinate \
  xorriso \
  squashfs-tools \
  grub-pc-bin \
  grub-efi-amd64-bin \
  casper \
  debootstrap \
  rsync \
  jq \
  git \
  ca-certificates \
  python3 \
  make

if [[ ! -d /opt/ubuntu-cdimage/.git ]]; then
  git clone https://git.launchpad.net/ubuntu-cdimage /opt/ubuntu-cdimage
else
  git -C /opt/ubuntu-cdimage pull --ff-only
fi

echo "OK: ISO toolchain installed"
