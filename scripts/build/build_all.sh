#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LOG_DIR="${ROOT_DIR}/build/logs"
mkdir -p "${LOG_DIR}"
LOG_FILE="${LOG_DIR}/build_all_$(date +%Y%m%d_%H%M%S).log"

run_step() {
  local name="$1"
  shift
  echo "== ${name} ==" | tee -a "${LOG_FILE}"
  "$@" 2>&1 | tee -a "${LOG_FILE}"
  echo | tee -a "${LOG_FILE}"
}

run_step "Sync rootfs overlay" "${ROOT_DIR}/scripts/build/sync_rootfs_overlay.sh"
run_step "Prepare snap sources" "${ROOT_DIR}/scripts/build/prepare_snap_sources.sh"
run_step "Build snaps" "${ROOT_DIR}/scripts/build/build_snaps.sh"
run_step "Sign model" "${ROOT_DIR}/scripts/build/sign_model.sh"
run_step "Build Core image" "${ROOT_DIR}/scripts/build/build_core_image.sh"

echo "OK: build complete, log at ${LOG_FILE}" | tee -a "${LOG_FILE}"
