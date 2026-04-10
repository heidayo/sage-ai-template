#!/bin/bash
# sage-report.sh — SAGE Status Report (TASK-0050)
# Reads session and doctor metrics to determine system health
set -euo pipefail

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
  exit 1
fi
