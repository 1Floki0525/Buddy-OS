#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MODEL_FILE="${ROOT_DIR}/snaps/model/buddy-os.model"
OUT_DIR="${ROOT_DIR}/build/model-host"
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

python3 - <<'PY' > "${OUT_DIR}/buddy-os.model.json"
import json

model_path = "${MODEL_FILE}"

def parse_value(raw):
    raw = raw.strip()
    if raw.startswith('"') and raw.endswith('"'):
        return raw[1:-1]
    if raw in ("true", "false"):
        return raw == "true"
    try:
        return int(raw)
    except ValueError:
        return raw

data = {}
snaps = []
current = None
in_snaps = False

with open(model_path, "r", encoding="utf-8") as f:
    for line in f:
        if not line.strip() or line.strip().startswith("#"):
            continue
        if not line.startswith(" "):
            key, value = line.split(":", 1)
            key = key.strip()
            value = value.strip()
            if key == "snaps":
                in_snaps = True
                continue
            data[key] = parse_value(value)
            in_snaps = False
            continue
        if in_snaps:
            if line.lstrip().startswith("- "):
                current = {}
                snaps.append(current)
                line = line.lstrip()[2:]
                if line:
                    k, v = line.split(":", 1)
                    current[k.strip()] = parse_value(v)
            else:
                k, v = line.strip().split(":", 1)
                current[k.strip()] = parse_value(v)

data["snaps"] = snaps
json.dump(data, fp=open("${OUT_DIR}/buddy-os.model.json", "w", encoding="utf-8"), indent=2)
PY

snap sign -k "${KEY_NAME}" --update-timestamp --chain "${OUT_DIR}/buddy-os.model.json" > "${OUT_FILE}"
echo "OK: wrote ${OUT_FILE}"
