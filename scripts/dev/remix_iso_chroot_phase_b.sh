#!/usr/bin/env bash
set -euo pipefail

# Self-elevate (so you can run it as normal user)
if [[ "${EUID}" -ne 0 ]]; then
  exec sudo -E bash "$0" "$@"
fi

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SQUASH_DIR="${SQUASH_DIR:-$REPO_ROOT/build/iso_work/squashfs-root}"

echo "== Buddy-OS ISO Remix: Phase B (chroot customize) =="
echo "SQUASH_DIR: $SQUASH_DIR"
echo

if [[ ! -d "$SQUASH_DIR" ]]; then
  echo "ERROR: squashfs root not found at: $SQUASH_DIR"
  echo "Run: scripts/dev/remix_iso_prepare.sh first."
  exit 1
fi

echo "==> Ensuring critical paths are root-owned (prevents dpkg/systemd weirdness)..."
chown -R root:root "$SQUASH_DIR/var" "$SQUASH_DIR/etc" || true

echo
echo "==> Mounting /dev, /dev/pts, /proc, /sys, /run..."
mountpoint -q "$SQUASH_DIR/dev"      || mount --bind /dev "$SQUASH_DIR/dev"
mkdir -p "$SQUASH_DIR/dev/pts"
mountpoint -q "$SQUASH_DIR/dev/pts"  || mount -t devpts devpts "$SQUASH_DIR/dev/pts"
mountpoint -q "$SQUASH_DIR/proc"     || mount -t proc proc "$SQUASH_DIR/proc"
mountpoint -q "$SQUASH_DIR/sys"      || mount -t sysfs sys "$SQUASH_DIR/sys"
mountpoint -q "$SQUASH_DIR/run"      || mount --bind /run "$SQUASH_DIR/run"

cleanup() {
  echo
  echo "==> Unmounting chroot mounts..."
  umount -lf "$SQUASH_DIR/dev/pts" 2>/dev/null || true
  umount -lf "$SQUASH_DIR/dev"     2>/dev/null || true
  umount -lf "$SQUASH_DIR/proc"    2>/dev/null || true
  umount -lf "$SQUASH_DIR/sys"     2>/dev/null || true
  umount -lf "$SQUASH_DIR/run"     2>/dev/null || true
}
trap cleanup EXIT

echo
echo "==> Preparing chroot environment (DNS)..."
# Some live roots have resolv.conf as a symlink; make it a real file
if [[ -L "$SQUASH_DIR/etc/resolv.conf" ]]; then
  rm -f "$SQUASH_DIR/etc/resolv.conf"
fi
cp -f /etc/resolv.conf "$SQUASH_DIR/etc/resolv.conf"

echo
echo "==> Entering chroot..."
chroot "$SQUASH_DIR" /usr/bin/env -i \
  HOME=/root \
  TERM="${TERM:-xterm-256color}" \
  PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
  DEBIAN_FRONTEND=noninteractive \
  bash -lc '
set -euo pipefail

echo "Inside chroot: $(uname -a)"
if command -v lsb_release >/dev/null 2>&1; then lsb_release -a || true; fi
if [[ -r /etc/os-release ]]; then . /etc/os-release; echo "Ubuntu: ${PRETTY_NAME:-unknown}"; fi

# Run Buddy-OS hooks before any apt operations
if [[ -d /usr/share/buddy-os/hooks ]]; then
  echo
  echo "==> Running Buddy-OS hooks..."
  for hook in /usr/share/buddy-os/hooks/*.chroot; do
    if [[ -f "$hook" ]] && [[ -x "$hook" ]]; then
      echo "Running hook: $(basename "$hook")"
      "$hook"
    fi
  done
fi

echo
echo "==> APT update (in chroot)..."
apt-get update

echo
echo "==> Baseline packages we rely on..."
apt-get install -y --no-install-recommends \
  ca-certificates curl jq sudo dbus git

echo
echo "==> Buddy firstboot seed service presence check..."
if [[ -f /etc/systemd/system/buddy-firstboot-seed-ollama.service ]]; then
  echo "OK: /etc/systemd/system/buddy-firstboot-seed-ollama.service exists"
else
  echo "WARN: buddy-firstboot-seed-ollama.service missing in chroot"
fi

echo
echo "==> Phase B baseline complete (no COSMIC yet)."
'

echo
echo "==> Phase B complete."
