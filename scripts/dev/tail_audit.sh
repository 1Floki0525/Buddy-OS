#!/usr/bin/env bash
set -euo pipefail
cd ~/Buddy-OS 2>/dev/null || cd ~/Buddy-os
LOG="broker/audit.log.jsonl"
touch "$LOG"
tail -n 50 -f "$LOG"
