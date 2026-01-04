#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MODEL_FILE="${ROOT_DIR}/snaps/model/buddy-os.model"
OUT_DIR="${ROOT_DIR}/build/model"
OUT_FILE="${OUT_DIR}/buddy-os.model.assert"
KEY_NAME="${KEY_NAME:-buddy-os}"

mkdir -p "${OUT_DIR}"

if ! command -v snap >/dev/null 2>&1; then
  echo "ERROR: snap not found in PATH"
  exit 1
fi

if ! snap keys | rg -q "${KEY_NAME}"; then
  echo "ERROR: snap key '${KEY_NAME}' not found."
  echo "Run: snapcraft create-key ${KEY_NAME} && snapcraft register-key ${KEY_NAME}"
  exit 1
fi

snap sign -k "${KEY_NAME}" "${MODEL_FILE}" > "${OUT_FILE}"
echo "OK: wrote ${OUT_FILE}"
