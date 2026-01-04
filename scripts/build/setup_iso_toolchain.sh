#!/usr/bin/env bash
set -euo pipefail

# Install ISO build tooling inside the build container.
# Run this from inside the LXD container.

apt-get update
apt-get install -y --no-install-recommends \
  livecd-rootfs \
  ubuntu-cdimage \
  germinate \
  xorriso \
  squashfs-tools \
  grub-pc-bin \
  grub-efi-amd64-bin \
  casper \
  debootstrap \
  rsync \
  jq

echo "OK: ISO toolchain installed"
