#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MODEL_ASSERT="${ROOT_DIR}/build/model/buddy-os.model.assert"
OUT_DIR="${ROOT_DIR}/build/image"

if [[ ! -f "${MODEL_ASSERT}" ]]; then
  echo "ERROR: missing model assertion at ${MODEL_ASSERT}"
  echo "Run: scripts/build/sign_model.sh"
  exit 1
fi

mkdir -p "${OUT_DIR}"

echo "== Building Ubuntu Core image =="
ubuntu-image snap \
  --output-dir "${OUT_DIR}" \
  "${MODEL_ASSERT}"

echo "OK: image artifacts in ${OUT_DIR}"
