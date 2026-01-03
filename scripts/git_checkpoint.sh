#!/usr/bin/env bash
set -euo pipefail
umask 022

MSG="${1:-checkpoint $(date -u +'%Y-%m-%dT%H:%M:%SZ')}"

# Ensure we're in a git repo
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "ERROR: Not inside a git repo."
  exit 1
fi

git add -A

# If nothing to commit, exit cleanly
if git diff --cached --quiet; then
  echo "Nothing to commit."
  exit 0
fi

git commit -m "$MSG"

# Push only if origin exists
if git remote get-url origin >/dev/null 2>&1; then
  BRANCH="$(git branch --show-current || true)"
  BRANCH="${BRANCH:-main}"
  echo "Pushing to origin/$BRANCH ..."
  git push -u origin "$BRANCH"
else
  echo "No remote 'origin' set. Commit created locally."
  echo "To add a remote later, run:"
  echo "  bash scripts/git_set_remote.sh <REMOTE_URL>"
fi
