#!/usr/bin/env bash
# =============================================================================
# TASK-0038: check-file-scope.sh
# Purpose:  PreToolUse hook (Edit|Write matcher) — enforce TASK File Scope
# Profile:  standard+ (warn on stderr, exit 0), strict (block with exit 2)
# Behavior: Reads JSON from stdin with tool_input.file_path.
#           Finds active TASK (status 実行中 in tasks/*.md), extracts File Scope.
#           If file_path is outside scope: warn (standard) or block (strict).
#           If no active TASK found: skip check, exit 0.
#           On empty stdin or parse error: exit 0
# =============================================================================
set -euo pipefail

# --- Profile gating ---
PROFILE="standard"
if [ -f ".sage/config.yaml" ]; then
  PROFILE=$(grep -A1 'hooks:' .sage/config.yaml 2>/dev/null | grep 'profile:' | awk '{print $2}' | tr -d '"' || echo "standard")
  [ -z "$PROFILE" ] && PROFILE="standard"
fi

if [ "$PROFILE" = "minimal" ]; then
  exit 0
fi

# --- Read stdin (JSON) ---
INPUT=""
if ! read -r -t 1 INPUT; then
  exit 0
fi

if [ -z "$INPUT" ]; then
  exit 0
fi

# --- Parse file_path from JSON ---
FILE_PATH=""
if command -v jq &>/dev/null; then
  FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null || true)
else
  FILE_PATH=$(echo "$INPUT" | grep -o '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' 2>/dev/null | head -1 | sed 's/.*"file_path"[[:space:]]*:[[:space:]]*"//;s/"$//' || true)
fi

if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# --- Find active TASK (status 実行中) ---
ACTIVE_TASK=""
SCOPE_PATHS=""

if [ ! -d "tasks" ]; then
  echo "No active TASKs found, skipping scope check." >&2
  exit 0
fi

for task_file in tasks/*.md; do
  [ -f "$task_file" ] || continue

  if grep -q '実行中' "$task_file" 2>/dev/null; then
    ACTIVE_TASK="$task_file"
    break
  fi
done

if [ -z "$ACTIVE_TASK" ]; then
  echo "No active TASK found, skipping scope check." >&2
  exit 0
fi

# --- Extract File Scope from active TASK ---
# Look for "File Scope" or "file_scope" section and collect paths
# Typical format:
#   ## File Scope
#   - src/foo/bar.ts
#   - tests/foo/
IN_SCOPE=false
while IFS= read -r line; do
  # Detect File Scope header (various formats)
  if echo "$line" | grep -qiE '^#{1,3}\s+file.?scope'; then
    IN_SCOPE=true
    continue
  fi

  # Stop at next header
  if [ "$IN_SCOPE" = true ] && echo "$line" | grep -qE '^#{1,3}\s+'; then
    break
  fi

  if [ "$IN_SCOPE" = true ]; then
    # Extract path from list items: "- path" or "* path" or "  - path"
    EXTRACTED=$(echo "$line" | sed -n 's/^[[:space:]]*[-*][[:space:]]*\(`\?\)\([^`]*\)\(`\?\)$/\2/p' 2>/dev/null || true)
    if [ -n "$EXTRACTED" ]; then
      SCOPE_PATHS="$SCOPE_PATHS|$EXTRACTED"
    fi
  fi
done < "$ACTIVE_TASK"

if [ -z "$SCOPE_PATHS" ]; then
  # No File Scope defined in TASK — skip check
  exit 0
fi

# --- Check if file_path falls within any scope path ---
# Normalize file_path: strip leading ./
NORM_PATH="${FILE_PATH#./}"

# Also handle absolute paths by extracting relative portion
if [[ "$NORM_PATH" == /* ]]; then
  # Try to make it relative to PWD
  PWD_PREFIX="$(pwd)/"
  NORM_PATH="${NORM_PATH#$PWD_PREFIX}"
fi

IFS='|' read -ra PATHS <<< "$SCOPE_PATHS"
for scope_path in "${PATHS[@]}"; do
  [ -z "$scope_path" ] && continue
  # Strip backticks, leading/trailing whitespace
  scope_path=$(echo "$scope_path" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
  [ -z "$scope_path" ] && continue

  # Check if file_path starts with or matches the scope path
  if [[ "$NORM_PATH" == "$scope_path"* ]] || [[ "$NORM_PATH" == "$scope_path" ]]; then
    # Within scope
    exit 0
  fi
done

# --- Out of scope ---
TASK_ID=$(basename "$ACTIVE_TASK" .md)

if [ "$PROFILE" = "strict" ]; then
  echo "BLOCKED: '$NORM_PATH' is outside File Scope for $TASK_ID." >&2
  echo "Allowed paths: ${SCOPE_PATHS//|/, }" >&2
  exit 2
else
  echo "WARNING: '$NORM_PATH' is outside File Scope for $TASK_ID." >&2
  echo "Allowed paths: ${SCOPE_PATHS//|/, }" >&2
  exit 0
fi
