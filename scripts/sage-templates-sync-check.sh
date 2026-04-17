#!/usr/bin/env bash
# =============================================================================
# SPEC-0008 TASK-0079: sage-templates-sync-check.sh
# Purpose:  Verify that .claude/rules/ and .claude/skills/ match the
#           templates/ sources they are copied from at install time. Intended
#           for local use; .claude/* is gitignored so CI cannot run this.
# Usage:    bash scripts/sage-templates-sync-check.sh
# Exit:     0 when in sync (or .claude not yet installed)
#           1 when any tracked template file differs from its .claude copy
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(dirname "$SCRIPT_DIR")"

cd "$ROOT"

# --- rules: flat mapping templates/rules/*.md -> .claude/rules/*.md ---
check_rules() {
  if [ ! -d .claude/rules ]; then
    echo "  WARN: .claude/rules/ not present (install.sh has not been run yet)"
    return 0
  fi
  local drift=0
  shopt -s nullglob
  for src in templates/rules/*.md; do
    local base
    base=$(basename "$src")
    local dst=".claude/rules/$base"
    if [ ! -f "$dst" ]; then
      echo "  MISSING: $dst (expected copy of $src)"
      drift=$((drift + 1))
      continue
    fi
    if ! diff -q "$src" "$dst" >/dev/null 2>&1; then
      echo "  DIFFER: $src <-> $dst"
      drift=$((drift + 1))
    fi
  done
  shopt -u nullglob
  return "$drift"
}

# --- skills: nested mapping templates/skills/<name>/** -> .claude/skills/<name>/** ---
check_skills() {
  if [ ! -d .claude/skills ]; then
    echo "  WARN: .claude/skills/ not present (install.sh has not been run yet)"
    return 0
  fi
  local drift=0
  shopt -s nullglob
  for src_dir in templates/skills/*/; do
    local name
    name=$(basename "$src_dir")
    local dst_dir=".claude/skills/$name"
    if [ ! -d "$dst_dir" ]; then
      echo "  MISSING: $dst_dir/ (expected copy of $src_dir)"
      drift=$((drift + 1))
      continue
    fi
    # Compare every file under src_dir recursively
    while IFS= read -r -d '' src_file; do
      local rel="${src_file#"$src_dir"}"
      local dst_file="$dst_dir/$rel"
      if [ ! -f "$dst_file" ]; then
        echo "  MISSING: $dst_file (expected copy of $src_file)"
        drift=$((drift + 1))
        continue
      fi
      if ! diff -q "$src_file" "$dst_file" >/dev/null 2>&1; then
        echo "  DIFFER: $src_file <-> $dst_file"
        drift=$((drift + 1))
      fi
    done < <(find "$src_dir" -type f -print0)
  done
  shopt -u nullglob
  return "$drift"
}

echo "=== templates/ <-> .claude/ sync check ==="
echo ""
echo "[rules]"
RULES_DRIFT=0
check_rules || RULES_DRIFT=$?
echo ""
echo "[skills]"
SKILLS_DRIFT=0
check_skills || SKILLS_DRIFT=$?
echo ""

TOTAL=$((RULES_DRIFT + SKILLS_DRIFT))
if [ "$TOTAL" -eq 0 ]; then
  echo "OK: no drift detected"
  exit 0
fi

echo "FAIL: $TOTAL file(s) drifted between templates/ and .claude/"
echo ""
echo "Fix: re-run 'bash install.sh --update' locally to restore .claude/ from"
echo "     templates/. If .claude/ changes were intentional, port them back to"
echo "     templates/ and re-run generate-installer.sh."
exit 1
