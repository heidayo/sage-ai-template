#!/bin/bash
# SAGE pre-commit hook: Require TASK-ID in commit messages
# Installed by sage-adopt.sh

COMMIT_MSG_FILE="$1"
COMMIT_MSG=$(cat "$COMMIT_MSG_FILE")

# Allow merge commits, rebases, and amends
if echo "$COMMIT_MSG" | grep -qE "^(Merge|Revert|fixup!|squash!)"; then
  exit 0
fi

# Allow vibe/* branch commits (no SPEC required for prototypes)
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
if echo "$BRANCH" | grep -qE "^vibe/"; then
  exit 0
fi

# Check for TASK-ID pattern
if ! echo "$COMMIT_MSG" | grep -qE "TASK-[0-9]{4}"; then
  echo ""
  echo "  SAGE: commit message must include a TASK-ID"
  echo "  Example: TASK-0001: add login endpoint"
  echo ""
  echo "  If this is a prototype, use a vibe/* branch."
  echo ""
  exit 1
fi
