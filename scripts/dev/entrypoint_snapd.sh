#!/usr/bin/env bash
set -euo pipefail

# Start snapd (systemd usually isn't PID 1 in containers, so we boot snapd ourselves)
mkdir -p /run/snapd /var/lib/snapd /snap

/usr/lib/snapd/snapd >/tmp/snapd.log 2>&1 &
SNAPD_PID=$!

# Wait for snapd to come up
for i in $(seq 1 60); do
  if snap version >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

if ! snap version >/dev/null 2>&1; then
  echo "ERROR: snapd did not start inside container. Tail /tmp/snapd.log:"
  tail -n 120 /tmp/snapd.log || true
  exit 1
fi

# Install tools if missing
if ! command -v snapcraft >/dev/null 2>&1; then
  (snap install snapcraft --classic) || (snap install snapcraft)
fi

if ! command -v ubuntu-image >/dev/null 2>&1; then
  (snap install ubuntu-image --classic) || (snap install ubuntu-image)
fi

# Hand off to whatever command was requested
exec "$@"
