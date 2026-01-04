#!/usr/bin/env bash
set -euo pipefail

# Build Buddy-OS ISO using Ubuntu livecd-rootfs + ubuntu-cdimage.
# Run this from inside the LXD container with /workspace mounted.

ROOT_DIR="/workspace"
OUT_DIR="${ROOT_DIR}/build/iso"
WORK_DIR="${ROOT_DIR}/build/iso_work"

mkdir -p "${OUT_DIR}" "${WORK_DIR}"

echo "== TODO: wire livecd-rootfs build config =="
echo "This script will be completed after seed/casper config is added."

# Placeholder to make the flow explicit.
echo "OK: build_iso.sh placeholder"
