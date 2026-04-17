#!/usr/bin/env bash
# =============================================================================
# SPEC-0008 TASK-0078: sage-installer-reproduce.sh
# Purpose:  Verify that the committed install.sh matches what
#           scripts/generate-installer.sh currently produces. The installer
#           is a generated artifact; any divergence means someone edited
#           install.sh by hand or forgot to regenerate after a templates/
#           change.
# Usage:    bash scripts/sage-installer-reproduce.sh
# Exit:     0 when in sync, 1 when diff is non-empty.
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(dirname "$SCRIPT_DIR")"

INSTALLER="$ROOT/install.sh"
GENERATOR="$SCRIPT_DIR/generate-installer.sh"

for f in "$INSTALLER" "$GENERATOR"; do
  if [ ! -f "$f" ]; then
    echo "ERROR: $f not found" >&2
    exit 1
  fi
done

TMP=$(mktemp)
trap 'rm -f "$TMP"' EXIT

if ! bash "$GENERATOR" > "$TMP" 2> "$TMP.err"; then
  echo "ERROR: generate-installer.sh failed" >&2
  cat "$TMP.err" >&2
  rm -f "$TMP.err"
  exit 1
fi
rm -f "$TMP.err"

if diff -q "$TMP" "$INSTALLER" >/dev/null 2>&1; then
  echo "OK: install.sh matches generate-installer.sh output"
  exit 0
fi

echo "FAIL: install.sh drifted from generate-installer.sh output"
echo ""
echo "Fix: run 'bash scripts/generate-installer.sh > install.sh' and commit"
echo "     the result as part of the same change that touched templates/."
echo ""
echo "Summary diff (first 40 lines):"
diff "$INSTALLER" "$TMP" | head -40
exit 1
