#!/usr/bin/env bash
set -euo pipefail

echo "== Buildhost tool versions =="

if command -v python3 >/dev/null 2>&1; then
  python3 --version
else
  echo "python3: MISSING"
fi

if command -v xorriso >/dev/null 2>&1; then
  xorriso --version | head -n 2
else
  echo "xorriso: MISSING"
fi

if command -v qemu-img >/dev/null 2>&1; then
  qemu-img --version
else
  echo "qemu-img: MISSING"
fi

echo
echo "OK"
