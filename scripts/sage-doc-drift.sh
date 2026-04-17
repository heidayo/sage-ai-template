#!/usr/bin/env bash
# =============================================================================
# SPEC-0008 TASK-0077: sage-doc-drift.sh
# Purpose:  Verify CLAUDE.md and AGENTS.md stay semantically aligned.
#           Compares the set of H2/H3 section headers in the pre-marker
#           region of both files, after normalizing intentional diffs:
#             - "Claude Code" <-> "Codex" naming pair
#             - "Claude Code Hooks" <-> "Hooks" variant in section 9.1
#           Everything after the auto-injected marker is ignored.
# Usage:    bash scripts/sage-doc-drift.sh
# Exit:     0 when aligned, 1 on drift (section-only-in-one or mismatch).
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(dirname "$SCRIPT_DIR")"

CLAUDE_FILE="${SAGE_DOC_DRIFT_CLAUDE:-$ROOT/CLAUDE.md}"
AGENTS_FILE="${SAGE_DOC_DRIFT_AGENTS:-$ROOT/AGENTS.md}"
MARKER='<!-- === SAGE Development System (auto-injected) === -->'

for f in "$CLAUDE_FILE" "$AGENTS_FILE"; do
  if [ ! -f "$f" ]; then
    echo "ERROR: $f not found" >&2
    exit 1
  fi
done

# Extract H2/H3 headers from the pre-marker region and normalize.
extract_headers() {
  local file="$1"
  # sed -n '/MARKER/q;p' prints lines until (not including) the marker.
  # Then grep H2/H3 headings.
  sed "/$MARKER/q" "$file" \
    | grep -E '^#{2,3} ' \
    | sed \
      -e 's/Claude Code/AGENT/g' \
      -e 's/Codex/AGENT/g' \
      -e 's/^## 9\.1 AGENT Hooks$/## 9.1 Hooks/' \
      -e 's/^## 9\.1 Hooks$/## 9.1 Hooks/'
}

CLAUDE_HEADERS=$(extract_headers "$CLAUDE_FILE" | sort -u)
AGENTS_HEADERS=$(extract_headers "$AGENTS_FILE" | sort -u)

ONLY_CLAUDE=$(comm -23 <(printf '%s\n' "$CLAUDE_HEADERS") <(printf '%s\n' "$AGENTS_HEADERS"))
ONLY_AGENTS=$(comm -13 <(printf '%s\n' "$CLAUDE_HEADERS") <(printf '%s\n' "$AGENTS_HEADERS"))

if [ -z "$ONLY_CLAUDE" ] && [ -z "$ONLY_AGENTS" ]; then
  echo "OK: CLAUDE.md and AGENTS.md section headers are aligned (pre-marker)"
  exit 0
fi

echo "FAIL: documentation drift detected between CLAUDE.md and AGENTS.md"
if [ -n "$ONLY_CLAUDE" ]; then
  echo ""
  echo "Sections only in CLAUDE.md:"
  printf '%s\n' "$ONLY_CLAUDE" | sed 's/^/  /'
fi
if [ -n "$ONLY_AGENTS" ]; then
  echo ""
  echo "Sections only in AGENTS.md:"
  printf '%s\n' "$ONLY_AGENTS" | sed 's/^/  /'
fi
echo ""
echo "Fix: add the missing section(s) to the other file or update TASK-0085"
echo "equivalent normalization in this script if the difference is intentional."
exit 1
