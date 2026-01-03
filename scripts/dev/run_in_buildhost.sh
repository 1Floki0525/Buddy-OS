#!/usr/bin/env bash
set -euo pipefail

IMAGE_NAME="localhost/buddyos-buildhost:24.04"
DOCKER_BIN="${DOCKER_BIN:-docker}"

if ! command -v "$DOCKER_BIN" >/dev/null 2>&1; then
  echo "ERROR: '$DOCKER_BIN' not found. Install docker or set DOCKER_BIN=podman."
  exit 1
fi

# Everything after -- is the command to run in the container
if [[ "${1:-}" == "--" ]]; then
  shift
fi

if [[ $# -eq 0 ]]; then
  set -- bash
fi

exec "$DOCKER_BIN" run --rm -it \
  -v "$PWD":/workspace \
  -w /workspace \
  "$IMAGE_NAME" \
  "$@"
