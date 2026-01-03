#!/usr/bin/env bash
set -euo pipefail
cd ~/Buddy-OS 2>/dev/null || cd ~/Buddy-os
python3 scripts/dev/policy_edit.py add-black "${1:?missing path}"
