#!/usr/bin/env bash
set -euo pipefail

# Manual ISO Build Commands for Buddy-OS Container
# Run these commands manually in your container

echo "=== Buddy-OS ISO Build Commands ==="
echo ""
echo "Run these commands in your container (root@buddy-os-builder:/workspace):"
echo ""
echo "1. Install dependencies:"
echo "apt-get update"
echo "apt-get install -y livecd-rootfs germinate xorriso squashfs-tools grub-pc-bin grub-efi-amd64-bin casper debootstrap rsync jq git ca-certificates python3 make coreutils"
echo ""
echo "2. Fix git safe directory:"
echo "git config --global --add safe.directory /opt/ubuntu-cdimage"
echo ""
echo "3. Build the ISO:"
echo "bash /workspace/scripts/build/build_iso.sh"
echo ""
echo "4. Check the output:"
echo "ls -la /workspace/build/iso/"
echo ""
echo "=== Commands Complete ==="