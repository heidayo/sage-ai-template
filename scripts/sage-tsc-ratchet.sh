#!/bin/bash
# sage-tsc-ratchet.sh — tsc error-count ratchet against a committed baseline
# SPEC-0030: TypeScript Enforcement preset
#
# Usage: bash scripts/sage-tsc-ratchet.sh [--update|--init] [--tsc-command "<cmd>"]
#
# Modes:
#   (default)  Check mode: run tsc, count 'error TS<n>' lines, compare with
#              .tsc-baseline.json. Increase -> exit 1. Equal -> exit 0.
#              Decrease -> exit 0 + INFO recommending --update.
#   --update   Overwrite the baseline with the current error count.
#              This is the ONLY legitimate way to update the baseline.
#   --init     Create the baseline (fails if one already exists).
#
# tsc command resolution (highest priority first):
#   1. Environment variable SAGE_TSC_COMMAND
#   2. Argument --tsc-command "<cmd>"
#   3. Default: npx tsc --noEmit
#
# Baseline file contract (.tsc-baseline.json):
#   {"errors": <non-negative integer>, "updated_at": "<ISO8601>"}
#   Written only by this script (--update / --init). Manual edits are
#   forbidden; malformed content fails closed with exit 1.
#
# Exit codes: 0 = at/below baseline or write success,
#             1 = increase / invalid baseline / missing baseline /
#                 tsc execution failure / argument error.
#
# POSIX tools only. No external JSON tooling, no dynamic command construction.

set -euo pipefail

BASELINE_FILE=".tsc-baseline.json"
DEFAULT_TSC_COMMAND="npx tsc --noEmit"

usage() {
  echo ""
  echo "  Usage: bash scripts/sage-tsc-ratchet.sh [--update|--init] [--tsc-command \"<cmd>\"]"
  echo ""
  echo "  Modes:"
  echo "    (no mode)   check current tsc error count against $BASELINE_FILE"
  echo "    --update    overwrite baseline with current error count"
  echo "    --init      create baseline (fails if it already exists)"
  echo ""
  echo "  tsc command priority: SAGE_TSC_COMMAND > --tsc-command > $DEFAULT_TSC_COMMAND"
  echo ""
}

# --- Argument parsing ---
MODE="check"
ARG_TSC_COMMAND=""

while [ $# -gt 0 ]; do
  case "$1" in
    --update)
      MODE="update"
      ;;
    --init)
      MODE="init"
      ;;
    --tsc-command)
      if [ $# -lt 2 ]; then
        echo "ERROR: --tsc-command requires a value" >&2
        usage >&2
        exit 1
      fi
      ARG_TSC_COMMAND="$2"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "ERROR: Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
  shift
done

# --- tsc command resolution (FR-03: env > arg > default) ---
if [ -n "${SAGE_TSC_COMMAND:-}" ]; then
  TSC_CMD="$SAGE_TSC_COMMAND"
elif [ -n "$ARG_TSC_COMMAND" ]; then
  TSC_CMD="$ARG_TSC_COMMAND"
else
  TSC_CMD="$DEFAULT_TSC_COMMAND"
fi

# --- Run tsc and count errors ---
# tsc exits non-zero on type errors, so the exit code alone cannot
# distinguish "type errors found" from "command failed". We count
# 'error TS<n>' lines instead; a non-zero exit with zero matching lines
# means the command itself failed (e.g. command not found).
run_tsc_and_count() {
  local output tsc_exit count
  tsc_exit=0
  output=$(sh -c "$TSC_CMD" 2>&1) || tsc_exit=$?
  count=$(printf '%s\n' "$output" | grep -cE 'error TS[0-9]+' || true)
  if [ "$count" -eq 0 ] && [ "$tsc_exit" -ne 0 ]; then
    echo "ERROR: tsc command failed without reporting any 'error TS' lines (exit $tsc_exit)" >&2
    echo "ERROR: command: $TSC_CMD" >&2
    printf '%s\n' "$output" >&2
    exit 1
  fi
  CURRENT_ERRORS="$count"
}

# --- Baseline read + integrity validation (FR-04, fail-closed) ---
# Extracts the "errors" value with sed and validates it is a non-negative
# integer before any numeric comparison. Malformed baseline -> exit 1,
# baseline left untouched.
read_baseline() {
  local raw
  if [ ! -f "$BASELINE_FILE" ]; then
    echo "ERROR: Baseline file not found: $BASELINE_FILE" >&2
    echo "ERROR: Run 'bash scripts/sage-tsc-ratchet.sh --init' to create it" >&2
    exit 1
  fi
  raw=$(sed -n 's/.*"errors"[[:space:]]*:[[:space:]]*\(-\{0,1\}[0-9][0-9]*\).*/\1/p' "$BASELINE_FILE" | head -n 1)
  if [ -z "$raw" ]; then
    echo "ERROR: Invalid baseline: $BASELINE_FILE has no numeric \"errors\" field (missing, non-numeric, or unparseable)" >&2
    echo "ERROR: Baseline must be written via --update / --init only (manual edits are forbidden)" >&2
    exit 1
  fi
  if ! printf '%s' "$raw" | grep -qE '^[0-9]+$'; then
    echo "ERROR: Invalid baseline: \"errors\" must be a non-negative integer, got: $raw" >&2
    echo "ERROR: Baseline must be written via --update / --init only (manual edits are forbidden)" >&2
    exit 1
  fi
  BASELINE_ERRORS="$raw"
}

# --- Baseline write (SEC-02: static schema, count + timestamp only) ---
write_baseline() {
  local timestamp
  timestamp=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
  printf '{"errors": %d, "updated_at": "%s"}\n' "$CURRENT_ERRORS" "$timestamp" > "$BASELINE_FILE"
}

# --- Mode dispatch ---
case "$MODE" in
  init)
    if [ -f "$BASELINE_FILE" ]; then
      echo "ERROR: Baseline already exists: $BASELINE_FILE" >&2
      echo "ERROR: Use --update to refresh it" >&2
      exit 1
    fi
    run_tsc_and_count
    write_baseline
    echo "INFO: Baseline created: $BASELINE_FILE (errors: $CURRENT_ERRORS)"
    exit 0
    ;;
  update)
    run_tsc_and_count
    write_baseline
    echo "INFO: Baseline updated: $BASELINE_FILE (errors: $CURRENT_ERRORS)"
    exit 0
    ;;
  check)
    read_baseline
    run_tsc_and_count
    if [ "$CURRENT_ERRORS" -gt "$BASELINE_ERRORS" ]; then
      DELTA=$((CURRENT_ERRORS - BASELINE_ERRORS))
      echo "ERROR: tsc error count increased: current $CURRENT_ERRORS, baseline $BASELINE_ERRORS, delta +$DELTA" >&2
      echo "ERROR: Fix the new type errors before merging (the ratchet only moves down)" >&2
      exit 1
    fi
    if [ "$CURRENT_ERRORS" -lt "$BASELINE_ERRORS" ]; then
      echo "INFO: tsc error count decreased: current $CURRENT_ERRORS, baseline $BASELINE_ERRORS"
      echo "INFO: Run 'bash scripts/sage-tsc-ratchet.sh --update' to lower the baseline"
      exit 0
    fi
    echo "INFO: tsc error count unchanged: current $CURRENT_ERRORS, baseline $BASELINE_ERRORS"
    exit 0
    ;;
esac
