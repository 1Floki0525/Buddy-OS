#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
WORK_DIR="${REPO_ROOT}/build/iso_work"
ISO_DIR="${WORK_DIR}/iso"
SQUASH_DIR="${WORK_DIR}/squashfs-root"
ROOTFS_OVERLAY="${REPO_ROOT}/images/rootfs"

RELEASE_DIR_URL="${RELEASE_DIR_URL:-https://releases.ubuntu.com/24.04/}"
FALLBACK_ISO_URL="${FALLBACK_ISO_URL:-https://releases.ubuntu.com/24.04/ubuntu-24.04.3-desktop-amd64.iso}"
UBUNTU_ISO_URL="${UBUNTU_ISO_URL:-}"

ISO_CACHE_DIR="${REPO_ROOT}/build/iso_cache"

need() { command -v "$1" >/dev/null 2>&1 || { echo "ERROR: missing dependency: $1"; exit 1; }; }

pick_latest_iso_url() {
  local html iso
  html="$(curl -fsSL "${RELEASE_DIR_URL}" || true)"
  iso="$(printf "%s" "${html}" | grep -oE 'ubuntu-24\.04\.[0-9]+-desktop-amd64\.iso' | sort -V | tail -n 1 || true)"
  if [[ -n "${iso}" ]]; then
    echo "${RELEASE_DIR_URL}${iso}"
  else
    echo "${FALLBACK_ISO_URL}"
  fi
}

find_squashfs() {
  # Ubuntu 24.04.3 desktop layout uses casper/minimal.squashfs
  local candidates=(
    "${ISO_DIR}/casper/minimal.squashfs"
    "${ISO_DIR}/casper/filesystem.squashfs"
    "${ISO_DIR}/live/filesystem.squashfs"
    "${ISO_DIR}/casper/ubuntu-desktop.squashfs"
    "${ISO_DIR}/casper/ubuntu-desktop-minimal.squashfs"
    "${ISO_DIR}/casper/ubuntu-server-minimal.squashfs"
  )

  for p in "${candidates[@]}"; do
    if [[ -f "$p" ]]; then
      echo "$p"
      return 0
    fi
  done

  # Fallback: pick the largest *.squashfs under casper/, else under the whole ISO
  local best="" best_size=0 f sz

  if [[ -d "${ISO_DIR}/casper" ]]; then
    while IFS= read -r f; do
      sz="$(stat -c '%s' "$f" 2>/dev/null || echo 0)"
      if [[ "$sz" -gt "$best_size" ]]; then best="$f"; best_size="$sz"; fi
    done < <(find "${ISO_DIR}/casper" -type f -name "*.squashfs" 2>/dev/null)
  fi

  if [[ -z "$best" ]]; then
    while IFS= read -r f; do
      sz="$(stat -c '%s' "$f" 2>/dev/null || echo 0)"
      if [[ "$sz" -gt "$best_size" ]]; then best="$f"; best_size="$sz"; fi
    done < <(find "${ISO_DIR}" -type f -name "*.squashfs" 2>/dev/null)
  fi

  [[ -n "$best" ]] && { echo "$best"; return 0; }
  return 1
}

echo "== Buddy-OS ISO Remix: Phase A =="
echo "REPO_ROOT:        ${REPO_ROOT}"
echo "WORK_DIR:         ${WORK_DIR}"
echo "Overlay rootfs:   ${ROOTFS_OVERLAY}"
echo

need curl
need rsync
need unsquashfs
need xorriso
need grep
need sort
need tail
need find
need stat

mkdir -p "${ISO_CACHE_DIR}" "${WORK_DIR}"

if [[ -z "${UBUNTU_ISO_URL}" ]]; then
  UBUNTU_ISO_URL="$(pick_latest_iso_url)"
fi

ISO_PATH="${ISO_CACHE_DIR}/$(basename "${UBUNTU_ISO_URL}")"

echo "ISO URL:           ${UBUNTU_ISO_URL}"
echo "ISO cache path:    ${ISO_PATH}"
echo

if [[ ! -f "${ISO_PATH}" ]]; then
  echo "==> Downloading ISO..."
  curl -L --fail --progress-bar -o "${ISO_PATH}.partial" "${UBUNTU_ISO_URL}"
  mv "${ISO_PATH}.partial" "${ISO_PATH}"
else
  echo "==> ISO already cached: ${ISO_PATH}"
fi

echo
echo "==> Cleaning previous extracted ISO + squashfs..."
rm -rf "${ISO_DIR}" "${SQUASH_DIR}"
mkdir -p "${ISO_DIR}"

echo
echo "==> Extracting ISO to ${ISO_DIR} ..."
xorriso -osirrox on -indev "${ISO_PATH}" -extract / "${ISO_DIR}" >/dev/null

echo
echo "==> Locating squashfs..."
SQUASHFS_PATH="$(find_squashfs || true)"
if [[ -z "${SQUASHFS_PATH}" ]]; then
  echo "ERROR: could not find any *.squashfs in extracted ISO."
  exit 1
fi
echo "Using squashfs: ${SQUASHFS_PATH}"

echo
echo "==> Unsquashing live filesystem..."
unsquashfs -d "${SQUASH_DIR}" "${SQUASHFS_PATH}" >/dev/null

echo
echo "==> Applying rootfs overlay from repo: ${ROOTFS_OVERLAY}"
if [[ -d "${ROOTFS_OVERLAY}" ]]; then
  rsync -a "${ROOTFS_OVERLAY}/" "${SQUASH_DIR}/"
else
  echo "NOTE: overlay dir not found (skipping): ${ROOTFS_OVERLAY}"
fi

echo
echo "==> Done (Phase A)."
echo "Extracted ISO:      ${ISO_DIR}"
echo "Unsquashed rootfs:  ${SQUASH_DIR}"
