#!/usr/bin/env bash
# =============================================================================
# SPEC-0008 TASK-0071/0072: sage-architecture-check.sh
# Purpose:  Check PR diff (or full src tree) for architecture violations
#           declared in .sage/architecture.yaml:
#             - forbidden:      (from, to) layer-crossing imports
#             - forbidden_deps: banned package name substrings
# Usage:    bash scripts/sage-architecture-check.sh [--base=REF]
#           --base defaults to origin/main; when unavailable, scans src/ fully.
# Exit:     0 no violations (or architecture.yaml absent)
#           1 at least one violation
#           2 bad invocation / parse error
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(dirname "$SCRIPT_DIR")"
cd "$ROOT"

ARCH_FILE=".sage/architecture.yaml"
BASE_REF="${GITHUB_BASE_REF:-}"
[ -z "$BASE_REF" ] && BASE_REF="main"

for arg in "$@"; do
  case "$arg" in
    --base=*) BASE_REF="${arg#--base=}" ;;
  esac
done

if [ ! -f "$ARCH_FILE" ]; then
  echo "SKIPPED: $ARCH_FILE not found — architecture check unconfigured"
  exit 0
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "ERROR: python3 required for YAML parsing" >&2
  exit 2
fi

# Parse architecture.yaml into environment-friendly form (python does
# the YAML, shell does the scanning).
RULES_JSON=$(python3 - <<PY
import json, sys
try:
    import yaml
except ImportError:
    print("ERROR: python yaml module required", file=sys.stderr)
    sys.exit(2)
try:
    with open(".sage/architecture.yaml") as f:
        doc = yaml.safe_load(f) or {}
except Exception as e:
    print(f"ERROR: parse failure: {e}", file=sys.stderr)
    sys.exit(2)
out = {
    "forbidden":      doc.get("forbidden") or [],
    "forbidden_deps": doc.get("forbidden_deps") or [],
}
print(json.dumps(out))
PY
)
RC=$?
if [ "$RC" -ne 0 ]; then
  exit 2
fi

# Resolve diff source. If we can compute origin/REF..HEAD we use it;
# otherwise we scan the current src/ tree as a best effort.
DIFF_CMD=""
if git rev-parse --verify "origin/${BASE_REF}" >/dev/null 2>&1; then
  DIFF_CMD="git diff origin/${BASE_REF}...HEAD --unified=0"
elif git rev-parse --verify "${BASE_REF}" >/dev/null 2>&1; then
  DIFF_CMD="git diff ${BASE_REF}...HEAD --unified=0"
fi

VIOLATIONS=0

# --- forbidden (layer boundary) ---
FORBIDDEN_COUNT=$(printf '%s' "$RULES_JSON" | python3 -c "import sys,json;d=json.loads(sys.stdin.read());print(len(d['forbidden']))")
if [ "$FORBIDDEN_COUNT" -eq 0 ]; then
  echo "  forbidden:      no rules declared (SKIPPED)"
else
  echo "  forbidden:      $FORBIDDEN_COUNT rule(s) declared"
  for i in $(seq 0 $((FORBIDDEN_COUNT - 1))); do
    RULE=$(printf '%s' "$RULES_JSON" | python3 -c "import sys,json;d=json.loads(sys.stdin.read());r=d['forbidden'][$i];print(r['from']+'|'+r['to']+'|'+r.get('reason',''))")
    FROM="${RULE%%|*}"; REST="${RULE#*|}"; TO="${REST%%|*}"; REASON="${REST#*|}"
    # Extract last path segment of TO globs for fuzzy match (e.g., src/infra/** -> infra)
    TO_TOKEN=$(echo "$TO" | sed -E 's:^.*/([^/*]+)/.*$:\1:;s:^([^/*]+)/.*$:\1:')
    # Files changed under FROM
    FILES=""
    if [ -n "$DIFF_CMD" ]; then
      FILES=$($DIFF_CMD --name-only -- "$FROM" 2>/dev/null || true)
    fi
    # Fallback / initial-commit case: scan the full tracked tree when diff
    # returned empty (base == HEAD or no base ref available).
    if [ -z "$FILES" ]; then
      FILES=$(git ls-files "$FROM" 2>/dev/null || true)
    fi
    [ -z "$FILES" ] && continue
    while IFS= read -r f; do
      [ -z "$f" ] && continue
      [ -f "$f" ] || continue
      # Search added lines (diff) or file content (fallback) for TO_TOKEN
      HITS=""
      if [ -n "$DIFF_CMD" ]; then
        HITS=$($DIFF_CMD -- "$f" 2>/dev/null | grep -E '^\+[^+]' | grep -F "$TO_TOKEN" || true)
      fi
      if [ -z "$HITS" ]; then
        HITS=$(grep -F "$TO_TOKEN" "$f" 2>/dev/null || true)
      fi
      if [ -n "$HITS" ]; then
        echo "  VIOLATION: $f imports from ${TO} (reason: ${REASON:-unspecified})"
        printf '%s\n' "$HITS" | sed 's/^/    /'
        VIOLATIONS=$((VIOLATIONS + 1))
      fi
    done <<EOF
$FILES
EOF
  done
fi

# --- forbidden_deps (banned package names) ---
DEPS_COUNT=$(printf '%s' "$RULES_JSON" | python3 -c "import sys,json;d=json.loads(sys.stdin.read());print(len(d['forbidden_deps']))")
if [ "$DEPS_COUNT" -eq 0 ]; then
  echo "  forbidden_deps: no rules declared (SKIPPED)"
else
  echo "  forbidden_deps: $DEPS_COUNT rule(s) declared"
  for i in $(seq 0 $((DEPS_COUNT - 1))); do
    RULE=$(printf '%s' "$RULES_JSON" | python3 -c "import sys,json;d=json.loads(sys.stdin.read());r=d['forbidden_deps'][$i];print(r['name']+'|'+r.get('reason',''))")
    NAME="${RULE%%|*}"; REASON="${RULE#*|}"
    HITS=""
    if [ -n "$DIFF_CMD" ]; then
      HITS=$($DIFF_CMD 2>/dev/null | grep -E '^\+[^+]' | grep -F "$NAME" || true)
    fi
    if [ -z "$HITS" ]; then
      HITS=$(git grep -F "$NAME" -- 'src/*' 2>/dev/null || true)
    fi
    if [ -n "$HITS" ]; then
      echo "  VIOLATION: forbidden dep '$NAME' present (reason: ${REASON:-unspecified})"
      printf '%s\n' "$HITS" | head -5 | sed 's/^/    /'
      VIOLATIONS=$((VIOLATIONS + 1))
    fi
  done
fi

if [ "$VIOLATIONS" -eq 0 ]; then
  echo "OK: no architecture violations detected"
  exit 0
fi
echo "FAIL: ${VIOLATIONS} architecture violation(s) detected"
exit 1
