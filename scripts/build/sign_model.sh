#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MODEL_FILE="${ROOT_DIR}/snaps/model/buddy-os.model"
OUT_DIR="${ROOT_DIR}/build/model"
OUT_FILE="${OUT_DIR}/buddy-os.model.assert"

mkdir -p "${OUT_DIR}"

if ! command -v snapcraft >/dev/null 2>&1; then
  echo "ERROR: snapcraft not found in PATH"
  exit 1
fi

snapcraft sign-model "${MODEL_FILE}" > "${OUT_FILE}"
echo "OK: wrote ${OUT_FILE}"
