#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SRC_DIR="${ROOT_DIR}/snaps/_src"

rm -rf "${SRC_DIR}"
mkdir -p \
  "${SRC_DIR}/buddy-core" \
  "${SRC_DIR}/buddy-voice" \
  "${SRC_DIR}/buddy-settings" \
  "${SRC_DIR}/buddy-copilot"

mkdir -p "${SRC_DIR}/buddy-core/buddy" "${SRC_DIR}/buddy-core/broker"
cp -f "${ROOT_DIR}/buddy/buddy_cli.py" "${SRC_DIR}/buddy-core/buddy/"
cp -f "${ROOT_DIR}/broker/buddy_actionsd.py" "${SRC_DIR}/buddy-core/broker/"
cp -f "${ROOT_DIR}/broker/policy.json" "${SRC_DIR}/buddy-core/broker/"
mkdir -p "${SRC_DIR}/buddy-core/snaps/buddy-core/bin"
cp -f "${ROOT_DIR}/snaps/buddy-core/bin/"* "${SRC_DIR}/buddy-core/snaps/buddy-core/bin/"

mkdir -p "${SRC_DIR}/buddy-voice/snaps/buddy-voice/bin"
cp -f "${ROOT_DIR}/snaps/buddy-voice/bin/buddy-voice" "${SRC_DIR}/buddy-voice/snaps/buddy-voice/bin/"

mkdir -p "${SRC_DIR}/buddy-settings/snaps/buddy-settings/bin"
cp -f "${ROOT_DIR}/snaps/buddy-settings/bin/buddy-settings" "${SRC_DIR}/buddy-settings/snaps/buddy-settings/bin/"

mkdir -p "${SRC_DIR}/buddy-copilot/snaps/buddy-copilot/bin"
cp -f "${ROOT_DIR}/snaps/buddy-copilot/bin/buddy-copilot" "${SRC_DIR}/buddy-copilot/snaps/buddy-copilot/bin/"

echo "OK: prepared snap sources in ${SRC_DIR}"
