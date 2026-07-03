#!/bin/bash
# sage-report.sh — SAGE Status Report (TASK-0050)
# Reads session and doctor metrics to determine system health
set -euo pipefail

# SPEC-0027: ID acceptance patterns come from the shared loader (config-aware).
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/sage-id-pattern.sh
. "$SCRIPT_DIR/sage-id-pattern.sh"
TASK_ACCEPT_RE="$(sage_id_accept_regex task)"

SESSIONS_FILE=".sage/metrics/sessions.jsonl"
DOCTOR_FILE=".sage/metrics/doctor-history.jsonl"

# --- Cross-platform date arithmetic ---
# Returns epoch seconds for N days ago
date_n_days_ago() {
  local days="$1"
  if date -v -1d +%s &>/dev/null 2>&1; then
    # macOS
    date -v "-${days}d" +%s
  else
    # Linux
    date -d "$days days ago" +%s
  fi
}

# Parse ISO timestamp to epoch
iso_to_epoch() {
  local ts="$1"
  if date -j -f "%Y-%m-%dT%H:%M:%SZ" "$ts" +%s &>/dev/null 2>&1; then
    # macOS
    date -j -f "%Y-%m-%dT%H:%M:%SZ" "$ts" +%s 2>/dev/null || echo "0"
  else
    # Linux
    date -d "$ts" +%s 2>/dev/null || echo "0"
  fi
}

# --- Count sessions ---
SESSION_COUNT=0
if [ -f "$SESSIONS_FILE" ]; then
  SESSION_COUNT=$(wc -l < "$SESSIONS_FILE" | tr -d ' ')
fi

# --- Count FAIL events ---
TOTAL_FAIL=0
RECENT_FAIL=0
CUTOFF_EPOCH=$(date_n_days_ago 14)

if [ -f "$DOCTOR_FILE" ]; then
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    # Extract fail count from JSON line
    fail_val=$(echo "$line" | sed -n 's/.*"fail"\s*:\s*\([0-9]*\).*/\1/p')
    if [ -z "$fail_val" ]; then fail_val=0; fi

    if [ "$fail_val" -gt 0 ]; then
      TOTAL_FAIL=$((TOTAL_FAIL + 1))

      # Check if within 14-day window
      ts=$(echo "$line" | sed -n 's/.*"timestamp"\s*:\s*"\([^"]*\)".*/\1/p')
      if [ -n "$ts" ]; then
        ts_epoch=$(iso_to_epoch "$ts")
        if [ "$ts_epoch" -ge "$CUTOFF_EPOCH" ] 2>/dev/null; then
          RECENT_FAIL=$((RECENT_FAIL + 1))
        fi
      fi
    fi
  done < "$DOCTOR_FILE"
fi

# --- Report ---
echo "=== SAGE Status Report ==="
echo ""
echo "  Sessions recorded: $SESSION_COUNT"
echo "  Total FAIL events: $TOTAL_FAIL"
echo "  FAIL events (last 14 days): $RECENT_FAIL"
echo ""

# --- Status logic ---
if [ "$SESSION_COUNT" -lt 10 ]; then
  echo "  Status: INSUFFICIENT DATA"
  echo "  (Need at least 10 sessions for health assessment)"
  echo "  Historical FAIL events are recorded, but strict-mode readiness is not assessed yet."
  exit 0
fi

if [ "$TOTAL_FAIL" -eq 0 ]; then
  echo "  Status: HEALTHY"
  echo ""
  # 14-day window check for strict readiness
  if [ "$SESSION_COUNT" -ge 10 ] && [ "$RECENT_FAIL" -eq 0 ]; then
    echo "  READY FOR STRICT"
    echo "  (No failures in last 14 days with >= 10 sessions)"
  fi
  exit 0
fi

if [ "$RECENT_FAIL" -eq 0 ]; then
  echo "  Status: WARN (historical failures only)"
  echo ""
  echo "  READY FOR STRICT"
  echo "  (No failures in last 14 days with >= 10 sessions)"
  exit 0
fi

if [ "$TOTAL_FAIL" -gt 0 ]; then
  echo "  Status: WARN (recurring failures)"
  echo ""
fi

# -----------------------------------------------------------------------------
# SPEC-0008 TASK-0075: extended metrics (cycle_time / gate_pass_rate / rework_rate)
# -----------------------------------------------------------------------------
# Added below the original status block so existing output format is preserved.
# Each metric prints SKIPPED when its data source is unavailable (fail-soft).

echo ""
echo "=== Extended Metrics (SPEC-0008) ==="
echo ""

# --- rework_rate: TASK-ID 再コミット率 ---
# rework_rate = (total_task_id_commits - unique_task_ids) / total_task_id_commits
echo "  rework_rate:"
REWORK_TOTAL=0
REWORK_UNIQUE=0
if git rev-parse --git-dir > /dev/null 2>&1; then
  # SPEC-0027: git log --grep is BRE-only and cannot take the combined ERE from
  # the loader, so filter --format output with grep -E instead. TASK-IDs are
  # extracted from commit subjects (the SAGE commit convention).
  REWORK_TOTAL=$(git log --format='%s' 2>/dev/null | grep -cE "$TASK_ACCEPT_RE" || true)
  REWORK_TOTAL=$(echo "$REWORK_TOTAL" | tr -d ' ')
  REWORK_UNIQUE=$(git log --format='%s' 2>/dev/null \
    | { grep -oE "$TASK_ACCEPT_RE" 2>/dev/null || true; } \
    | sort -u | wc -l | tr -d ' ')
fi
if [ "$REWORK_TOTAL" -gt 0 ]; then
  RATE=$(python3 -c "print(f'{(${REWORK_TOTAL} - ${REWORK_UNIQUE}) / ${REWORK_TOTAL}:.3f}')" 2>/dev/null || echo "?")
  echo "    commits_with_task_id: $REWORK_TOTAL"
  echo "    unique_task_ids:      $REWORK_UNIQUE"
  echo "    rework_rate:          $RATE  (target <= 0.2)"
else
  echo "    SKIPPED (no TASK-ID commits in history)"
fi
echo ""

# --- cycle_time: SPEC 初コミット → 最新 merge commit p50 (時間単位) ---
# Temporarily relax pipefail: git log | awk terminates early on match and
# raises SIGPIPE on git log, which set -o pipefail would promote to an
# exit-killing failure. Scope the relaxation just to this metric.
echo "  cycle_time:"
CYCLE_SAMPLES=""
set +o pipefail
if git rev-parse --git-dir > /dev/null 2>&1 && [ -d specs ]; then
  for spec in specs/SPEC-[0-9]*.md; do
    [ -f "$spec" ] || continue
    SPEC_ID=$(basename "$spec" | grep -oE 'SPEC-[0-9]{4}' | head -1)
    [ -z "$SPEC_ID" ] && continue
    SPEC_EPOCH=$(git log --follow --format='%at' --reverse -- "$spec" 2>/dev/null | head -1)
    [ -z "$SPEC_EPOCH" ] && continue
    MERGE_EPOCH=$(git log --merges --format='%at%n%s%n%b' 2>/dev/null \
      | awk -v id="$SPEC_ID" 'BEGIN{epoch=""} /^[0-9]+$/ {epoch=$0; next} $0 ~ id {print epoch; exit}')
    [ -z "$MERGE_EPOCH" ] && continue
    DELTA_H=$(python3 -c "print(f'{(${MERGE_EPOCH} - ${SPEC_EPOCH}) / 3600:.1f}')" 2>/dev/null)
    [ -z "$DELTA_H" ] && continue
    CYCLE_SAMPLES="$CYCLE_SAMPLES $DELTA_H"
  done
fi
set -o pipefail

CYCLE_COUNT=0
if [ -n "$CYCLE_SAMPLES" ]; then
  CYCLE_COUNT=$(printf '%s' "$CYCLE_SAMPLES" | tr ' ' '\n' | grep -c . 2>/dev/null || echo 0)
fi
if [ "${CYCLE_COUNT:-0}" -gt 0 ]; then
  P50=$(printf '%s\n' $CYCLE_SAMPLES | sort -n | awk -v n="$CYCLE_COUNT" 'NR == int((n+1)/2) {print; exit}')
  echo "    spec_to_merge_samples: $CYCLE_COUNT"
  echo "    p50 (hours):           $P50  (target p50 <= 24h)"
else
  echo "    SKIPPED (no merged SPECs found in history)"
fi
echo ""

# --- gate_pass_rate: gh CLI で workflow run の conclusion 集計 ---
echo "  gate_pass_rate:"
if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
  # fetch last 30 runs of sage-*-gate workflows
  RUN_JSON=$(gh run list --limit 30 --json name,conclusion 2>/dev/null || echo "[]")
  # filter to sage-*-gate, count success vs total
  COUNTS=$(printf '%s' "$RUN_JSON" | python3 -c "
import json, sys
try:
    data = json.loads(sys.stdin.read() or '[]')
except Exception:
    data = []
runs = [r for r in data if isinstance(r, dict) and 'sage-' in (r.get('name') or '') and '-gate' in (r.get('name') or '')]
total = len(runs)
pas   = sum(1 for r in runs if (r.get('conclusion') or '') == 'success')
print(f'{pas} {total}')
" 2>/dev/null || echo "0 0")
  read -r GATE_PASS GATE_TOTAL <<< "$COUNTS"
  if [ "${GATE_TOTAL:-0}" -gt 0 ]; then
    RATE=$(python3 -c "print(f'{${GATE_PASS} / ${GATE_TOTAL}:.3f}')" 2>/dev/null || echo "?")
    echo "    samples (last 30 runs): $GATE_TOTAL"
    echo "    success:                $GATE_PASS"
    echo "    pass_rate:              $RATE  (target >= 0.8)"
  else
    echo "    SKIPPED (no sage-*-gate workflow runs found)"
  fi
else
  echo "    SKIPPED (gh CLI unavailable or not authenticated)"
fi
echo ""

if [ "$TOTAL_FAIL" -gt 0 ] && [ "$RECENT_FAIL" -gt 0 ]; then
  exit 1
fi
exit 0
