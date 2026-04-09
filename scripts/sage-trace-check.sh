#!/bin/bash
# sage-trace-check.sh — トレーサビリティチェーン検証
# 直近のコミットにTASK-IDが含まれているか確認
set -euo pipefail

echo "=== SAGE Traceability Check ==="
echo ""

ERRORS=0
LIMIT=${1:-10}

echo "直近 $LIMIT コミットのTASK-ID検証..."
echo ""

while IFS= read -r line; do
  HASH=$(echo "$line" | cut -d' ' -f1)
  MSG=$(echo "$line" | cut -d' ' -f2-)

  if echo "$MSG" | grep -qE 'TASK-[0-9]{4}'; then
    echo "  OK: $HASH — $MSG"
  elif echo "$MSG" | grep -qE '^(initial commit|merge|Merge)'; then
    echo "  SKIP: $HASH — $MSG (merge/initial)"
  else
    echo "  WARN: $HASH — $MSG (TASK-ID missing)"
    ERRORS=$((ERRORS + 1))
  fi
done < <(git log --oneline -n "$LIMIT" 2>/dev/null || echo "")

echo ""

if [ $ERRORS -eq 0 ]; then
  echo "=== Traceability: ALL PASSED ==="
else
  echo "=== Traceability: $ERRORS WARNING(S) ==="
fi
