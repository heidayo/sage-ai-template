#!/usr/bin/env bash
# =============================================================================
# TASK-0039: session-start.sh
# Purpose:  SessionStart hook (no stdin) — display project context summary
# Profile:  minimal+ (runs for all profiles except "none")
# Behavior: Prints to stdout:
#           1. Latest 3 RUN logs from .sage/runs/ (status, task_id, error_log)
#           2. In-progress/blocked TASKs from tasks/*.md
#           3. Latest 5 entries from sage/failures.md
#           Always exit 0
# =============================================================================
set -euo pipefail

# --- Profile gating ---
PROFILE="minimal"
if [ -f ".sage/config.yaml" ]; then
  PROFILE=$(grep -A1 'hooks:' .sage/config.yaml 2>/dev/null | grep 'profile:' | awk '{print $2}' | tr -d '"' || echo "minimal")
  [ -z "$PROFILE" ] && PROFILE="minimal"
fi

# minimal+ means all profiles run this hook (minimal, standard, strict)
if [ "$PROFILE" = "none" ]; then
  exit 0
fi

task_status() {
  awk -F'|' '/^\|[[:space:]]*ステータス[[:space:]]*\|/ {gsub(/^[[:space:]]+|[[:space:]]+$/, "", $3); print $3; exit}' "$1" 2>/dev/null || true
}

echo "=== SAGE Session Context ==="
echo ""

# --- 0. Lane Detection ---
echo "--- Current Lane ---"
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
LANE="standard"
LANE_EMOJI="🔵"
LANE_DESC="Full SAGE lifecycle: SPEC + PLAN + TASK required. Gates 1-4."

if [[ "$CURRENT_BRANCH" == vibe/* ]]; then
  LANE="explore"
  LANE_EMOJI="🟢"
  LANE_DESC="Free exploration. No SPEC, no TASK-ID, no gates required. To promote: bash scripts/sage-promote.sh $CURRENT_BRANCH"
elif [[ "$CURRENT_BRANCH" == fix/* || "$CURRENT_BRANCH" == chore/* || "$CURRENT_BRANCH" == docs/* ]]; then
  LANE="lite"
  LANE_EMOJI="🟡"
  LANE_DESC="Lightweight changes. TASK-ID required, SPEC not required. Gates 1+3. Max 3 files, no contract changes."
elif [[ "$CURRENT_BRANCH" == promote/* ]]; then
  LANE="promotion"
  LANE_EMOJI="🔴"
  LANE_DESC="Promotion from explore. Retro-SPEC + TASK-ID required. Gates 1-4."
fi

echo "  Branch: $CURRENT_BRANCH"
echo "  Lane:   $LANE_EMOJI $LANE"
echo "  Rules:  $LANE_DESC"
echo ""

# --- 1. Latest 3 RUN logs ---
echo "--- Recent RUN Logs ---"
if [ -d ".sage/runs" ] && ls .sage/runs/*.json &>/dev/null 2>&1; then
  # Get latest 3 files by modification time
  LATEST_RUNS=$(ls -t .sage/runs/*.json 2>/dev/null | head -3)

  for run_file in $LATEST_RUNS; do
    [ -f "$run_file" ] || continue
    RUN_NAME=$(basename "$run_file")

    if command -v jq &>/dev/null; then
      STATUS=$(jq -r '.status // "unknown"' "$run_file" 2>/dev/null || echo "unknown")
      TASK_ID=$(jq -r '.task_id // "N/A"' "$run_file" 2>/dev/null || echo "N/A")
      ERROR_LOG=$(jq -r '.error_log // empty' "$run_file" 2>/dev/null | head -1 || true)
    else
      STATUS=$(grep -o '"status"[[:space:]]*:[[:space:]]*"[^"]*"' "$run_file" 2>/dev/null | head -1 | sed 's/.*"status"[[:space:]]*:[[:space:]]*"//;s/"$//' || echo "unknown")
      TASK_ID=$(grep -o '"task_id"[[:space:]]*:[[:space:]]*"[^"]*"' "$run_file" 2>/dev/null | head -1 | sed 's/.*"task_id"[[:space:]]*:[[:space:]]*"//;s/"$//' || echo "N/A")
      ERROR_LOG=$(grep -o '"error_log"[[:space:]]*:[[:space:]]*"[^"]*"' "$run_file" 2>/dev/null | head -1 | sed 's/.*"error_log"[[:space:]]*:[[:space:]]*"//;s/"$//' | head -1 || true)
    fi

    echo "  $RUN_NAME: status=$STATUS task=$TASK_ID${ERROR_LOG:+ error=$ERROR_LOG}"
  done
elif [ -d ".sage/runs" ] && ls .sage/runs/*.yaml &>/dev/null 2>&1; then
  LATEST_RUNS=$(ls -t .sage/runs/*.yaml 2>/dev/null | head -3)
  for run_file in $LATEST_RUNS; do
    [ -f "$run_file" ] || continue
    RUN_NAME=$(basename "$run_file")
    STATUS=$(grep 'status:' "$run_file" 2>/dev/null | head -1 | awk '{print $2}' || echo "unknown")
    TASK_ID=$(grep 'task_id:' "$run_file" 2>/dev/null | head -1 | awk '{print $2}' || echo "N/A")
    echo "  $RUN_NAME: status=$STATUS task=$TASK_ID"
  done
else
  echo "  No RUN logs found."
fi
echo ""

# --- 2. In-progress / Blocked TASKs ---
echo "--- Active TASKs ---"
FOUND_TASKS=false
if [ -d "tasks" ]; then
  for task_file in tasks/*.md; do
    [ -f "$task_file" ] || continue

    TASK_NAME=$(basename "$task_file" .md)

    STATUS=$(task_status "$task_file")
    case "$STATUS" in
      "In Progress"|"実行中")
        echo "  [$TASK_NAME] Status: In Progress"
        FOUND_TASKS=true
        ;;
      "Blocked"|"ブロック中")
        echo "  [$TASK_NAME] Status: Blocked"
        FOUND_TASKS=true
        ;;
    esac
  done
fi

if [ "$FOUND_TASKS" = false ]; then
  echo "  No active TASKs."
fi
echo ""

# --- 3. Latest 5 entries from sage/failures.md ---
echo "--- Recent Failures ---"
if [ -f "sage/failures.md" ]; then
  # Extract failure entries (lines starting with ## or ### as entry headers)
  # Show last 5 entry headers with their first detail line
  ENTRIES=$(grep -n '^##' "sage/failures.md" 2>/dev/null | tail -5)

  if [ -n "$ENTRIES" ]; then
    while IFS= read -r entry; do
      LINE_NUM=$(echo "$entry" | cut -d: -f1)
      HEADER=$(echo "$entry" | cut -d: -f2-)
      # Get next non-empty line as detail
      DETAIL=$(sed -n "$((LINE_NUM + 1)),$((LINE_NUM + 3))p" "sage/failures.md" 2>/dev/null | grep -v '^$' | head -1 || true)
      echo "  $HEADER"
      [ -n "$DETAIL" ] && echo "    $DETAIL"
    done <<< "$ENTRIES"
  else
    echo "  No failure entries found."
  fi
else
  echo "  sage/failures.md not found."
fi

echo ""
echo "=== End Session Context ==="

exit 0
