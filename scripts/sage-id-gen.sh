#!/bin/bash
# sage-id-gen.sh — SPEC/PLAN/TASK ID生成
# Usage: bash scripts/sage-id-gen.sh spec|plan|task
set -euo pipefail

TYPE="${1:-}"

if [ -z "$TYPE" ]; then
  echo "Usage: bash scripts/sage-id-gen.sh <type>"
  echo "  type: spec | plan | task | run | fail"
  exit 1
fi

case "$TYPE" in
  spec)
    DIR="specs"
    PREFIX="SPEC"
    ;;
  plan)
    DIR="plans"
    PREFIX="PLAN"
    ;;
  task)
    DIR="tasks"
    PREFIX="TASK"
    ;;
  run)
    DIR=".sage/runs"
    PREFIX="RUN"
    ;;
  fail)
    DIR="sage"
    PREFIX="FAIL"
    ;;
  *)
    echo "Unknown type: $TYPE"
    echo "  Valid types: spec | plan | task | run | fail"
    exit 1
    ;;
esac

# Find the highest existing ID
LAST_NUM=0
if [ "$TYPE" = "fail" ]; then
  # Search in failures.md
  if [ -f "sage/failures.md" ]; then
    LAST_NUM=$(grep -oE "${PREFIX}-[0-9]{4}" sage/failures.md 2>/dev/null | sort -t'-' -k2 -n | tail -1 | grep -oE '[0-9]{4}' || echo 0)
  fi
else
  # Search in directory for files matching PREFIX-XXXX
  if [ -d "$DIR" ]; then
    LAST_NUM=$(ls "$DIR" 2>/dev/null | grep -oE "${PREFIX}-[0-9]{4}" | sort -t'-' -k2 -n | tail -1 | grep -oE '[0-9]{4}' || echo 0)
  fi
fi

# Remove leading zeros for arithmetic
LAST_NUM=$((10#$LAST_NUM))

# Generate next ID
NEXT_NUM=$((LAST_NUM + 1))
NEXT_ID=$(printf "${PREFIX}-%04d" "$NEXT_NUM")

echo "$NEXT_ID"
