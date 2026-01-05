#!/usr/bin/env bash
set -euo pipefail

# Container ISO build setup script
# Run this inside the LXD container before building the ISO

echo "=== Buddy-OS ISO Build Setup ==="

# Update package lists
echo "Updating package lists..."
apt-get update -y

# Install ISO build dependencies
echo "Installing ISO build dependencies..."
apt-get install -y \
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
    make \
    coreutils

# Clone ubuntu-cdimage if not exists
echo "Setting up ubuntu-cdimage..."
if [[ ! -d /opt/ubuntu-cdimage/.git ]]; then
  echo "Cloning ubuntu-cdimage repository..."
  git clone https://git.launchpad.net/ubuntu-cdimage /opt/ubuntu-cdimage
else
  echo "Updating ubuntu-cdimage repository..."
  git -C /opt/ubuntu-cdimage pull --ff-only
fi

# Fix git safe directory
echo "Fixing git safe directory..."
git config --global --add safe.directory /opt/ubuntu-cdimage

echo "=== Setup complete ==="
echo "Now run: bash /workspace/scripts/build/build_iso.sh"