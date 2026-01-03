#!/usr/bin/env bash
set -euo pipefail
cd ~/Buddy-OS 2>/dev/null || cd ~/Buddy-os
python3 scripts/dev/policy_edit.py set-consent "${1:?missing action}" "${2:?missing rule}"
