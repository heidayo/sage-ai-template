#!/usr/bin/env bash
# =============================================================================
# TASK-0148: test-codex-delegation-packet.sh (SPEC-0022)
# Purpose: Verify Codex Delegation Packet documentation, AGENTS guidance, and
#          installer propagation are wired without touching Claude-specific files.
# =============================================================================
set -uo pipefail

PASS=0
FAIL=0

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
DOC="${REPO_ROOT}/docs/codex-delegation-packet.md"
AGENTS="${REPO_ROOT}/AGENTS.md"
SNIPPET="${REPO_ROOT}/templates/agents-md-snippet.md"
GENERATOR_RULES="${REPO_ROOT}/scripts/generator/03-rules.sh"
GENERATOR_MAIN="${REPO_ROOT}/scripts/generator/07-installer-main.sh"
INSTALL_SH="${REPO_ROOT}/install.sh"

echo "# codex delegation packet (SPEC-0022)"

required_doc_terms=(
  "## Goal"
  "## Scope"
  "## Non-goals"
  "## File Scope"
  "## Constraints"
  "## Acceptance Criteria"
  "## Tests"
  "## Human Review Required"
  "## Example"
)

missing_terms=()
for term in "${required_doc_terms[@]}"; do
  if ! grep -qF "$term" "$DOC" 2>/dev/null; then
    missing_terms+=("$term")
  fi
done
if [ "${#missing_terms[@]}" -eq 0 ]; then
  PASS=$((PASS + 1))
  echo "  ok   delegation packet contains all required sections"
else
  FAIL=$((FAIL + 1))
  echo "  not ok delegation packet missing sections: ${missing_terms[*]}" >&2
fi

if grep -qF "Codex は委任型 agent" "$AGENTS" \
   && grep -qF "docs/codex-delegation-packet.md" "$AGENTS" \
   && grep -qF "Claude Code 固有ファイル" "$AGENTS"; then
  PASS=$((PASS + 1))
  echo "  ok   AGENTS.md has concise Codex-only delegation guidance"
else
  FAIL=$((FAIL + 1))
  echo "  not ok AGENTS.md missing Codex-only delegation guidance" >&2
fi

if grep -qF "Codex delegation packet" "$SNIPPET" \
   && grep -qF "Goal / Scope / Non-goals / File Scope / Acceptance Criteria / Tests" "$SNIPPET" \
   && grep -qF "Codex-only boundary" "$SNIPPET"; then
  PASS=$((PASS + 1))
  echo "  ok   agents snippet propagates Codex delegation guidance"
else
  FAIL=$((FAIL + 1))
  echo "  not ok agents snippet missing Codex delegation guidance" >&2
fi

if grep -qF 'TMPL_CODEX_DELEGATION_PACKET' "$GENERATOR_RULES" \
   && grep -qF 'docs/codex-delegation-packet.md' "$GENERATOR_MAIN"; then
  PASS=$((PASS + 1))
  echo "  ok   generator embeds and writes Codex delegation packet"
else
  FAIL=$((FAIL + 1))
  echo "  not ok generator does not propagate Codex delegation packet" >&2
fi

if grep -qF 'TMPL_CODEX_DELEGATION_PACKET' "$INSTALL_SH" \
   && grep -qF 'docs/codex-delegation-packet.md' "$INSTALL_SH"; then
  PASS=$((PASS + 1))
  echo "  ok   install.sh contains Codex delegation packet payload and write path"
else
  FAIL=$((FAIL + 1))
  echo "  not ok install.sh missing Codex delegation packet propagation" >&2
fi

BASE_REF=""
if git -C "$REPO_ROOT" rev-parse --verify origin/main >/dev/null 2>&1; then
  BASE_REF="$(git -C "$REPO_ROOT" merge-base HEAD origin/main)"
fi

if [ -n "$BASE_REF" ]; then
  CLAUDE_DIFF="$(git -C "$REPO_ROOT" diff --name-only "$BASE_REF" HEAD -- CLAUDE.md templates/claude-md-snippet.md .claude 2>/dev/null)"
else
  CLAUDE_DIFF="$(git -C "$REPO_ROOT" diff --name-only -- CLAUDE.md templates/claude-md-snippet.md .claude 2>/dev/null)"
fi

if [ -z "$CLAUDE_DIFF" ]; then
  PASS=$((PASS + 1))
  echo "  ok   Claude-specific files are untouched by this Codex branch"
else
  FAIL=$((FAIL + 1))
  echo "  not ok Claude-specific files changed in branch scope: $CLAUDE_DIFF" >&2
fi

echo ""
echo "SUMMARY pass=$PASS fail=$FAIL"
[ "$FAIL" -eq 0 ]
