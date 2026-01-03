#!/usr/bin/env bash
set -euo pipefail
umask 022
MSG="${1:-checkpoint $(date -u +'%Y-%m-%dT%H:%M:%SZ')}"
git add -A
if git diff --cached --quiet; then
  echo "Nothing to commit"
  exit 0
fi
git commit -m "$MSG"
BRANCH="$(git branch --show-current || true)"
BRANCH="${BRANCH:-main}"
if git remote get-url origin >/dev/null 2>&1; then
  git push -u origin "$BRANCH"
else
  echo "Committed locally (no origin remote set)"
fi
