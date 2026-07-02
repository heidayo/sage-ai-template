# shellcheck shell=bash
# Module 01: SPEC/PLAN/TASK + sage governance templates (SPEC-0014)
# Sourced by scripts/generate-installer.sh — depends on embed_file function.
# Do not chmod +x; do not run standalone.
#
# SPEC-0025 (FR-05 / AC-10): the CLAUDE.md SAGE managed section — including
# the rules/local/ overlay reading convention — is sourced from
# templates/claude-md-snippet.md, embedded as TMPL_CLAUDE_SNIPPET in
# module 02-config.sh and injected by upsert_sage_section() in module 07.

embed_file "TMPL_SPEC" "$ROOT/specs/_template.md"
echo ""
embed_file "TMPL_PLAN" "$ROOT/plans/_template.md"
echo ""
embed_file "TMPL_TASK" "$ROOT/tasks/_template.md"
echo ""
embed_file "TMPL_CHARTER" "$ROOT/sage/charter.md"
echo ""
embed_file "TMPL_GOVERNANCE" "$ROOT/sage/governance.md"
echo ""
embed_file "TMPL_FAILURES" "$ROOT/sage/failures.md"
echo ""
embed_file "TMPL_ANTIPATTERNS" "$ROOT/sage/anti-patterns.md"
echo ""
embed_file "TMPL_QUALITY_GATES" "$ROOT/sage/quality-gates.md"
echo ""
embed_file "TMPL_ADOPTION" "$ROOT/sage/adoption-phases.md"
echo ""
embed_file "TMPL_TRACEABILITY" "$ROOT/sage/traceability.md"
echo ""
