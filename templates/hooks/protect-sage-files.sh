#!/usr/bin/env bash
# =============================================================================
# TASK-0037: protect-sage-files.sh
# Purpose:  PreToolUse hook (Edit|Write matcher) — protect SAGE-managed files
# Profile:  standard+ (skipped if profile is "minimal" or "none")
# Behavior: Reads JSON from stdin with tool_name and tool_input.file_path.
#           Protected: CLAUDE.md, sage/*, .sage/config.yaml, .claude/settings.json
#           If a TASK with sage-managed: true AND status In Progress / 実行中 exists, allow.
#           Otherwise block (exit 2).
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

# --- Check if file is protected ---
IS_PROTECTED=false

# Normalize: strip leading ./ if present
NORM_PATH="${FILE_PATH#./}"

case "$NORM_PATH" in
  CLAUDE.md)
    IS_PROTECTED=true
    ;;
  sage/*)
    IS_PROTECTED=true
    ;;
  .sage/config.yaml)
    IS_PROTECTED=true
    ;;
  .claude/settings.json)
    IS_PROTECTED=true
    ;;
esac

# Also check if the path ends with these (for absolute paths)
if [ "$IS_PROTECTED" = false ]; then
  case "$FILE_PATH" in
    */CLAUDE.md)
      IS_PROTECTED=true
      ;;
    */sage/*)
      IS_PROTECTED=true
      ;;
    */.sage/config.yaml)
      IS_PROTECTED=true
      ;;
    */.claude/settings.json)
      IS_PROTECTED=true
      ;;
  esac
fi

if [ "$IS_PROTECTED" = false ]; then
  # Not a protected file — allow
  exit 0
fi

# --- Check for active sage-managed TASK ---
if [ -d "tasks" ]; then
  for task_file in tasks/*.md; do
    [ -f "$task_file" ] || continue

    # Check if task has sage-managed: true AND active status
    HAS_SAGE_MANAGED=false
    HAS_ACTIVE_STATUS=false

    if grep -q 'sage-managed:[[:space:]]*true' "$task_file" 2>/dev/null; then
      HAS_SAGE_MANAGED=true
    fi

    if task_is_active "$task_file"; then
      HAS_ACTIVE_STATUS=true
    fi

    if [ "$HAS_SAGE_MANAGED" = true ] && [ "$HAS_ACTIVE_STATUS" = true ]; then
      # Active sage-managed task found — allow edit
      exit 0
    fi
  done
fi

# --- Block: no active sage-managed task ---
echo "BLOCKED: '$NORM_PATH' is a SAGE-protected file." >&2
echo "Protected files: CLAUDE.md, sage/*, .sage/config.yaml, .claude/settings.json" >&2
echo "To modify, ensure a TASK in tasks/ has 'sage-managed: true' and status 'In Progress' (or '実行中')." >&2
exit 2
