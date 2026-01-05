#!/usr/bin/env bash
set -euo pipefail

# Install ISO build tooling on local system.
# Modified to work without LXD container

ROOT_DIR="$(pwd)"

echo "This script requires sudo access to install ISO build dependencies"
echo "Please run: sudo apt-get update && sudo apt-get install -y livecd-rootfs germinate xorriso squashfs-tools grub-pc-bin grub-efi-amd64-bin casper debootstrap rsync jq git ca-certificates python3 make"

if [[ ! -d /opt/ubuntu-cdimage/.git ]]; then
  echo "Cloning ubuntu-cdimage repository..."
  sudo git clone https://git.launchpad.net/ubuntu-cdimage /opt/ubuntu-cdimage
else
  echo "Updating ubuntu-cdimage repository..."
  sudo git -C /opt/ubuntu-cdimage pull --ff-only
fi

echo "OK: ISO toolchain installation instructions printed"

# -----------------------------------------------------------------
#  Add Buddy‑OS systemd services and configuration files to the ISO overlay
# -----------------------------------------------------------------
# The build_iso.sh script copies files from scripts/build/iso/ into the ISO
# We need to ensure the hooks and package-lists directories exist

# Create the ISO build directory structure
mkdir -p "${ROOT_DIR}/scripts/build/iso/hooks"
mkdir -p "${ROOT_DIR}/scripts/build/iso/package-lists"

# Copy the systemd unit files to hooks directory for inclusion in ISO
if [ -d "${ROOT_DIR}/scripts/systemd" ]; then
  mkdir -p "${ROOT_DIR}/scripts/build/iso/hooks/systemd"
  cp -a "${ROOT_DIR}/scripts/systemd/"* "${ROOT_DIR}/scripts/build/iso/hooks/systemd/"
fi

# Copy Buddy‑OS configuration JSON files
if [ -f "${ROOT_DIR}/config/agents.json" ]; then
  mkdir -p "${ROOT_DIR}/scripts/build/iso/hooks/config"
  cp "${ROOT_DIR}/config/agents.json" "${ROOT_DIR}/scripts/build/iso/hooks/config/"
fi
if [ -f "${ROOT_DIR}/config/providers.example.json" ]; then
  mkdir -p "${ROOT_DIR}/scripts/build/iso/hooks/config"
  cp "${ROOT_DIR}/config/providers.example.json" "${ROOT_DIR}/scripts/build/iso/hooks/config/providers.json"
fi
if [ -f "${ROOT_DIR}/config/settings.json" ]; then
  mkdir -p "${ROOT_DIR}/scripts/build/iso/hooks/config"
  cp "${ROOT_DIR}/config/settings.json" "${ROOT_DIR}/scripts/build/iso/hooks/config/"
fi

echo "OK: ISO overlay structure prepared"
