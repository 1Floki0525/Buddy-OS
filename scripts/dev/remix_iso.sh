#!/usr/bin/env bash
set -euo pipefail

# Buddy-OS ISO Remix Wrapper
# This script runs the remix process inside the container environment

# Check if we're in the container (workspace should be mounted at /workspace)
if [[ ! -d "/workspace" ]]; then
    echo "ERROR: This script must run inside the container where /workspace is mounted"
    echo "Please run: lxc exec buddy-os-builder -- bash"
    echo "Then run this script from inside the container"
    exit 1
fi

cd /workspace

echo "== Buddy-OS ISO Remix Process =="
echo "Running from container workspace: /workspace"

# Phase A: Extract ISO and prepare chroot
echo -e "\n=== Phase A: Extracting ISO ==="
bash scripts/dev/remix_iso_prepare.sh

# Phase B: Enter chroot and customize
echo -e "\n=== Phase B: Customizing Chroot ==="
bash scripts/dev/remix_iso_chroot_phase_b.sh

# Phase C: Repack the ISO
echo -e "\n=== Phase C: Repacking ISO ==="
bash scripts/dev/remix_iso_repack_phase_c.sh

echo -e "\n=== Buddy-OS ISO Build Complete ==="
echo "ISO should be available at: /workspace/build/iso/Buddy-OS-0.0.0.iso"