#!/usr/bin/env bash
# =============================================================================
# TASK-0040: session-stop.sh
# Purpose:  Stop hook (no stdin) — record session metrics
# Profile:  minimal+ (runs for all profiles)
# Behavior: Appends 1 JSON line to .sage/metrics/sessions.jsonl
#           Schema: {"timestamp":"ISO8601","files_changed":N,"files":["path1",...]}
#           Gets changed files from: git diff --name-only HEAD
#           Creates .sage/metrics/ if not exists.
#           Always exit 0
# =============================================================================
set -euo pipefail

# --- Profile gating ---
PROFILE="minimal"
if [ -f ".sage/config.yaml" ]; then
  PROFILE=$(grep -A1 'hooks:' .sage/config.yaml 2>/dev/null | grep 'profile:' | awk '{print $2}' | tr -d '"' || echo "minimal")
  [ -z "$PROFILE" ] && PROFILE="minimal"
fi

# minimal+ means all profiles run this hook
# No profile skip needed.

# --- Ensure metrics directory exists ---
mkdir -p .sage/metrics 2>/dev/null || true

# --- Get changed files from git ---
CHANGED_FILES=""
CHANGED_FILES=$(git diff --name-only HEAD 2>/dev/null || true)

# --- Build JSON line ---
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date +"%Y-%m-%dT%H:%M:%SZ")

if command -v jq &>/dev/null; then
  # Use jq for proper JSON construction
  if [ -n "$CHANGED_FILES" ]; then
    FILES_JSON=$(echo "$CHANGED_FILES" | jq -R -s 'split("\n") | map(select(length > 0))' 2>/dev/null || echo "[]")
    FILES_COUNT=$(echo "$CHANGED_FILES" | grep -c '.' 2>/dev/null || echo "0")
  else
    FILES_JSON="[]"
    FILES_COUNT=0
  fi

  ENTRY=$(jq -n \
    --arg ts "$TIMESTAMP" \
    --argjson count "$FILES_COUNT" \
    --argjson files "$FILES_JSON" \
    '{"timestamp":$ts,"files_changed":$count,"files":$files}' 2>/dev/null || true)

  if [ -n "$ENTRY" ]; then
    echo "$ENTRY" >> .sage/metrics/sessions.jsonl
    exit 0
  fi
fi

# --- Fallback: manual JSON construction ---
FILES_COUNT=0
FILES_ARRAY=""

if [ -n "$CHANGED_FILES" ]; then
  while IFS= read -r file; do
    [ -z "$file" ] && continue
    FILES_COUNT=$((FILES_COUNT + 1))
    if [ -n "$FILES_ARRAY" ]; then
      FILES_ARRAY="$FILES_ARRAY,\"$file\""
    else
      FILES_ARRAY="\"$file\""
    fi
  done <<< "$CHANGED_FILES"
fi

echo "{\"timestamp\":\"$TIMESTAMP\",\"files_changed\":$FILES_COUNT,\"files\":[$FILES_ARRAY]}" >> .sage/metrics/sessions.jsonl

exit 0
