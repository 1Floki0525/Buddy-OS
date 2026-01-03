#!/usr/bin/env bash
set -euo pipefail
umask 022

REMOTE_URL="${1:-}"

if [[ -z "$REMOTE_URL" ]]; then
  echo "Usage:"
  echo "  bash scripts/git_set_remote.sh <REMOTE_URL>"
  echo
  echo "Examples:"
  echo "  bash scripts/git_set_remote.sh git@github.com:YOURUSER/Buddy-OS.git"
  echo "  bash scripts/git_set_remote.sh https://github.com/YOURUSER/Buddy-OS.git"
  exit 2
fi

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "ERROR: Not inside a git repo."
  exit 1
fi

if git remote get-url origin >/dev/null 2>&1; then
  git remote set-url origin "$REMOTE_URL"
else
  git remote add origin "$REMOTE_URL"
fi

BRANCH="$(git branch --show-current || true)"
BRANCH="${BRANCH:-main}"

echo "Remote set to: $REMOTE_URL"
echo "Pushing to origin/$BRANCH ..."
git push -u origin "$BRANCH"
