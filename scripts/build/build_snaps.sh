#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT_DIR="${ROOT_DIR}/build/snaps"

mkdir -p "${OUT_DIR}"

build_snap() {
  local snap_dir="$1"
  local name="$2"
  echo "== Building ${name} =="
  rm -rf "${snap_dir}/parts" "${snap_dir}/prime" "${snap_dir}/stage"
  (cd "${snap_dir}" && snapcraft clean)
  (cd "${snap_dir}" && snapcraft --destructive-mode)
  mv -f "${snap_dir}"/*.snap "${OUT_DIR}/"
}

build_snap "${ROOT_DIR}/snaps/buddy-gadget/snap" "buddy-gadget"
build_snap "${ROOT_DIR}/snaps/buddy-core/snap" "buddy-core"
build_snap "${ROOT_DIR}/snaps/buddy-voice/snap" "buddy-voice"
build_snap "${ROOT_DIR}/snaps/buddy-settings/snap" "buddy-settings"
build_snap "${ROOT_DIR}/snaps/buddy-copilot/snap" "buddy-copilot"

echo "OK: snaps in ${OUT_DIR}"
