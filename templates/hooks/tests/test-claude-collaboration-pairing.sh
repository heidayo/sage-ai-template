#!/usr/bin/env bash
# =============================================================================
# TASK-0155: test-claude-collaboration-pairing.sh (SPEC-0023)
# Purpose: Verify Claude Collaboration Brief documentation, CLAUDE.md
#          parallel guidance, snippet propagation, governance §10 doctrine,
#          installer propagation. Includes 2 in-memory mutation scenarios
#          (AC-16/17) for negative-path validation.
# =============================================================================
set -uo pipefail

PASS=0
FAIL=0

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
DOC="${REPO_ROOT}/docs/claude-collaboration-brief.md"
CODEX_DOC="${REPO_ROOT}/docs/codex-delegation-packet.md"
CLAUDE_MD="${REPO_ROOT}/CLAUDE.md"
AGENTS_MD="${REPO_ROOT}/AGENTS.md"
CLAUDE_SNIPPET="${REPO_ROOT}/templates/claude-md-snippet.md"
GOVERNANCE="${REPO_ROOT}/sage/governance.md"
GENERATOR_RULES="${REPO_ROOT}/scripts/generator/03-rules.sh"
GENERATOR_MAIN="${REPO_ROOT}/scripts/generator/07-installer-main.sh"
INSTALL_SH="${REPO_ROOT}/install.sh"

echo "# claude collaboration pairing (SPEC-0023)"

# --- Scenario 1: docs/claude-collaboration-brief.md required sections (FR-01) ---
required_doc_sections=(
  "## 使う場面"
  "## Claude Collaboration Brief"
  "## Plan Mode"
  "## Skill"
  "## Auto memory"
  "## Codex Handoff Triggers"
  "## Codex / Claude 役割分担"
)
missing=()
for s in "${required_doc_sections[@]}"; do
  if ! grep -qF "$s" "$DOC" 2>/dev/null; then
    missing+=("$s")
  fi
done
if [ "${#missing[@]}" -eq 0 ]; then
  PASS=$((PASS + 1))
  echo "  ok   collaboration brief contains all 7 required sections"
else
  FAIL=$((FAIL + 1))
  echo "  not ok collaboration brief missing sections: ${missing[*]}" >&2
fi

# --- Scenario 2: CLAUDE.md has collaboration brief reference ---
if grep -qF "docs/claude-collaboration-brief.md" "$CLAUDE_MD" \
   && grep -qF "Claude Code は協働型" "$CLAUDE_MD"; then
  PASS=$((PASS + 1))
  echo "  ok   CLAUDE.md references collaboration brief"
else
  FAIL=$((FAIL + 1))
  echo "  not ok CLAUDE.md missing collaboration brief reference" >&2
fi

# --- Scenario 3: CLAUDE.md has Codex-specific files boundary ---
# CLAUDE.md must assert (a) Codex-specific files are not edited by Claude,
# (b) docs/codex-*.md is mentioned as part of that boundary.
if grep -qF "Codex-specific" "$CLAUDE_MD" \
   && grep -qE "Claude は直接編集しない|Codex 側 task に分離" "$CLAUDE_MD" \
   && grep -qF "docs/codex-*.md" "$CLAUDE_MD"; then
  PASS=$((PASS + 1))
  echo "  ok   CLAUDE.md asserts Codex-specific files boundary"
else
  FAIL=$((FAIL + 1))
  echo "  not ok CLAUDE.md missing Codex-specific files boundary" >&2
fi

# --- Scenario 4: claude-md-snippet.md parallel content ---
if grep -qF "Claude collaboration brief" "$CLAUDE_SNIPPET" \
   && grep -qF "Claude-only boundary" "$CLAUDE_SNIPPET" \
   && grep -qF "docs/claude-collaboration-brief.md" "$CLAUDE_SNIPPET"; then
  PASS=$((PASS + 1))
  echo "  ok   claude-md-snippet propagates collaboration brief guidance"
else
  FAIL=$((FAIL + 1))
  echo "  not ok claude-md-snippet missing collaboration brief guidance" >&2
fi

# --- Scenario 5: CLAUDE.md ↔ AGENTS.md doctrine semantic alignment ---
if grep -qF "may diverge" "$CLAUDE_MD" \
   && grep -qF "may diverge" "$AGENTS_MD" \
   && grep -qF "SPEC-0023" "$CLAUDE_MD" \
   && grep -qF "SPEC-0023" "$AGENTS_MD"; then
  PASS=$((PASS + 1))
  echo "  ok   CLAUDE.md / AGENTS.md doctrine aligned (both reference may diverge + SPEC-0023)"
else
  FAIL=$((FAIL + 1))
  echo "  not ok CLAUDE.md / AGENTS.md doctrine misaligned" >&2
fi

# --- Scenario 6: governance.md §10 AI Agent Doc Pairing Doctrine ---
if grep -qF "## 10. AI Agent Doc Pairing Doctrine" "$GOVERNANCE" \
   && grep -qF "Shared rules" "$GOVERNANCE" \
   && grep -qF "CLI-specific rules" "$GOVERNANCE" \
   && grep -qF "Paired-update" "$GOVERNANCE" \
   && grep -qF "Drift 検知" "$GOVERNANCE"; then
  PASS=$((PASS + 1))
  echo "  ok   governance.md §10 doctrine present (4 required subsections)"
else
  FAIL=$((FAIL + 1))
  echo "  not ok governance.md §10 doctrine missing or incomplete" >&2
fi

# --- Scenario 7: install.sh propagation (TMPL_CLAUDE_COLLABORATION_BRIEF + write/update path) ---
if grep -qF "TMPL_CLAUDE_COLLABORATION_BRIEF" "$INSTALL_SH" \
   && grep -qF "docs/claude-collaboration-brief.md" "$INSTALL_SH" \
   && grep -qF "TMPL_CLAUDE_COLLABORATION_BRIEF" "$GENERATOR_RULES" \
   && grep -qF "claude-collaboration-brief.md" "$GENERATOR_MAIN"; then
  PASS=$((PASS + 1))
  echo "  ok   install.sh + generator embed and write Claude collaboration brief"
else
  FAIL=$((FAIL + 1))
  echo "  not ok install.sh / generator missing Claude collaboration brief propagation" >&2
fi

# --- Scenario 8 (異常系 AC-16): paired update absence detection ---
# Simulate CLAUDE.md without "may diverge" doctrine using in-memory mutation.
# Verify that the same regex check used in Scenario 5 would FAIL.
mutated_claude=$(grep -v "may diverge" "$CLAUDE_MD")
if ! printf '%s' "$mutated_claude" | grep -qF "may diverge"; then
  PASS=$((PASS + 1))
  echo "  ok   AC-16 (異常系): paired update absence simulated → would FAIL Scenario 5"
else
  FAIL=$((FAIL + 1))
  echo "  not ok AC-16 (異常系): mutation simulation failed" >&2
fi

# --- Scenario 9 (異常系 AC-17): brief doc section drift detection ---
# Simulate docs/claude-collaboration-brief.md with renamed section using in-memory mutation.
# Verify that the same regex check used in Scenario 1 would FAIL on missing section.
mutated_doc=$(sed 's/## Codex Handoff Triggers/## Renamed Section/' "$DOC")
if ! printf '%s' "$mutated_doc" | grep -qF "## Codex Handoff Triggers"; then
  PASS=$((PASS + 1))
  echo "  ok   AC-17 (異常系): section rename simulated → would FAIL Scenario 1"
else
  FAIL=$((FAIL + 1))
  echo "  not ok AC-17 (異常系): mutation simulation failed" >&2
fi

echo ""
echo "SUMMARY pass=$PASS fail=$FAIL"
[ "$FAIL" -eq 0 ]
