#!/usr/bin/env bash
# =============================================================================
# TASK-0038: check-file-scope.sh
# Purpose:  PreToolUse hook (Edit|Write matcher) — enforce TASK File Scope
# Profile:  standard+ (warn on stderr, exit 0), strict (block with exit 2)
# Behavior: Reads JSON from stdin with tool_input.file_path.
#           Finds active TASKs (status In Progress / 実行中 in tasks/*.md), extracts File Scope.
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

if [ "$PROFILE" = "minimal" ] || [ "$PROFILE" = "none" ]; then
  exit 0
fi

task_status() {
  awk -F'|' '/^\|[[:space:]]*ステータス[[:space:]]*\|/ {gsub(/^[[:space:]]+|[[:space:]]+$/, "", $3); print $3; exit}' "$1" 2>/dev/null || true
}

task_is_active() {
  local status
  status="$(task_status "$1")"
  case "$status" in
    "In Progress"|"実行中")
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

append_scope_from_task() {
  local task_file="$1"
  local in_scope=false

  while IFS= read -r line; do
    if echo "$line" | grep -qiE '^#{1,3}\s+file.?scope'; then
      in_scope=true
      continue
    fi

    if [ "$in_scope" = true ] && echo "$line" | grep -qE '^#{1,3}\s+'; then
      break
    fi

    if [ "$in_scope" = true ]; then
      local item extracted
      item=$(echo "$line" | sed -n 's/^[[:space:]]*[-*][[:space:]]*//p' 2>/dev/null || true)
      [ -z "$item" ] && continue

      extracted=$(echo "$item" | sed -E 's/^[^:]+:[[:space:]]*//' | tr -d '`' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' || true)
      case "$extracted" in
        ""|"[パス]"|"[path]")
          continue
          ;;
      esac
      SCOPE_PATHS+=("$extracted")
    fi
  done < "$task_file"
}

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

# --- Find active TASKs (status In Progress / 実行中) ---
ACTIVE_TASKS=()
SCOPE_PATHS=()

if [ ! -d "tasks" ]; then
  echo "No active TASKs found, skipping scope check." >&2
  exit 0
fi

for task_file in tasks/*.md; do
  [ -f "$task_file" ] || continue

  if task_is_active "$task_file"; then
    ACTIVE_TASKS+=("$task_file")
  fi
done

if [ "${#ACTIVE_TASKS[@]}" -eq 0 ]; then
  echo "No active TASK found, skipping scope check." >&2
  exit 0
fi

for active_task in "${ACTIVE_TASKS[@]}"; do
  append_scope_from_task "$active_task"
done

if [ "${#SCOPE_PATHS[@]}" -eq 0 ]; then
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

for scope_path in "${SCOPE_PATHS[@]}"; do
  [ -z "$scope_path" ] && continue

  if [[ "$scope_path" == */ ]]; then
    if [[ "$NORM_PATH" == "$scope_path"* ]]; then
      exit 0
    fi
  elif [[ "$NORM_PATH" == "$scope_path" ]] || [[ "$NORM_PATH" == "$scope_path/"* ]]; then
    exit 0
  fi
done

# --- Out of scope ---
TASK_IDS=()
for active_task in "${ACTIVE_TASKS[@]}"; do
  TASK_IDS+=("$(basename "$active_task" .md)")
done
TASK_LABEL=$(IFS=', '; echo "${TASK_IDS[*]}")
ALLOWED_PATHS=$(printf '%s\n' "${SCOPE_PATHS[@]}" | awk 'NF && !seen[$0]++' | paste -sd ', ' -)

if [ "$PROFILE" = "strict" ]; then
  echo "BLOCKED: '$NORM_PATH' is outside File Scope for ${TASK_LABEL}." >&2
  echo "Allowed paths: $ALLOWED_PATHS" >&2
  exit 2
else
  echo "WARNING: '$NORM_PATH' is outside File Scope for ${TASK_LABEL}." >&2
  echo "Allowed paths: $ALLOWED_PATHS" >&2
  exit 0
fi
