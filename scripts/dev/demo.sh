#!/usr/bin/env bash
set -euo pipefail
umask 022

cd ~/Buddy-OS 2>/dev/null || cd ~/Buddy-os

python3 buddy/buddy_cli.py health

ROOT="$(pwd)"
TEST_DIR="$ROOT/notes/demo_dir"
python3 buddy/buddy_cli.py mkdir "$TEST_DIR"
python3 buddy/buddy_cli.py mkdir "$TEST_DIR" --yes
python3 buddy/buddy_cli.py ls "$ROOT/notes"

python3 buddy/buddy_cli.py ollama-models || true
