#!/usr/bin/env bash
set -euo pipefail
umask 022
cd ~/Buddy-OS 2>/dev/null || cd ~/Buddy-os
exec python3 broker/buddy_actionsd.py
