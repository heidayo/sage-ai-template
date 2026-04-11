#!/bin/bash
# SAGE pre-commit hook: Require TASK-ID in commit messages
# Installed by sage-adopt.sh
# Lanes: explore (vibe/*) = exempt, lite/standard/promotion = required

COMMIT_MSG_FILE="$1"
COMMIT_MSG=$(cat "$COMMIT_MSG_FILE")

# Allow merge commits, rebases, and amends
if echo "$COMMIT_MSG" | grep -qE "^(Merge|Revert|fixup!|squash!)"; then
  exit 0
fi

# Detect current branch
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)

# --- Lane: explore (vibe/*) — TASK-ID not required ---
if echo "$BRANCH" | grep -qE "^vibe/"; then
  exit 0
fi

# --- Lane: lite (fix/*, chore/*, docs/*) — TASK-ID required + constraints ---
if echo "$BRANCH" | grep -qE "^(fix|chore|docs)/"; then
  # Enforce max file count (default 3)
  MAX_FILES=3
  if [ -f ".sage/config.yaml" ]; then
    CONFIG_MAX=$(grep -A5 'lite:' .sage/config.yaml 2>/dev/null | grep 'max_files:' | awk '{print $2}' || echo "")
    [ -n "$CONFIG_MAX" ] && MAX_FILES="$CONFIG_MAX"
  fi

  CHANGED_FILE_COUNT=$(git diff --cached --name-only | wc -l | tr -d ' ')
  if [ "$CHANGED_FILE_COUNT" -gt "$MAX_FILES" ]; then
    echo ""
    echo "  SAGE: lite lane allows max $MAX_FILES files, but $CHANGED_FILE_COUNT staged"
    echo "  Switch to a feature/* branch for larger changes."
    echo ""
    exit 1
  fi

  # Enforce no contract changes (API/DB/event schema)
  CONTRACT_CHANGES=$(git diff --cached --name-only | grep -cE "(openapi|swagger|schema|migration|\.proto|\.graphql|\.avsc)" || echo "0")
  if [ "$CONTRACT_CHANGES" -gt 0 ]; then
    echo ""
    echo "  SAGE: lite lane prohibits contract changes (API/DB/event schema)"
    echo "  Detected $CONTRACT_CHANGES contract file(s) in staging."
    echo "  Switch to a feature/* branch for contract changes."
    echo ""
    exit 1
  fi
fi

# --- Lane: promotion (promote/*) — TASK-ID required ---
# --- Lane: standard (feature/*, others) — TASK-ID required ---

# All non-explore lanes require TASK-ID
if ! echo "$COMMIT_MSG" | grep -qE "TASK-[0-9]{4}"; then
  # Determine lane for helpful error message
  LANE="standard"
  if echo "$BRANCH" | grep -qE "^(fix|chore|docs)/"; then
    LANE="lite"
  elif echo "$BRANCH" | grep -qE "^promote/"; then
    LANE="promotion"
  fi

  echo ""
  echo "  SAGE: commit message must include a TASK-ID"
  echo "  Current lane: $LANE (branch: $BRANCH)"
  echo "  Example: TASK-0001: add login endpoint"
  echo ""
  if [ "$LANE" = "lite" ]; then
    echo "  Lite lane still requires TASK-ID for traceability."
    echo "  Generate one with: bash scripts/sage-id-gen.sh task"
  elif [ "$LANE" = "promotion" ]; then
    echo "  Promotion lane requires TASK-ID + Retro-SPEC."
    echo "  Run: bash scripts/sage-promote.sh <vibe-branch>"
  else
    echo "  If this is a prototype, use a vibe/* branch."
  fi
  echo ""
  exit 1
fi
