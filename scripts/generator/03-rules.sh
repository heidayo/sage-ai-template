# shellcheck shell=bash
# Module 03: rules + skills + base scripts (SPEC-0014)
# Sourced by scripts/generate-installer.sh — depends on embed_file function.
# Do not chmod +x; do not run standalone.

embed_file "TMPL_RULES_SPECS" "$ROOT/templates/rules/specs-rules.md"
echo ""
embed_file "TMPL_RULES_PLANS" "$ROOT/templates/rules/plans-rules.md"
echo ""
embed_file "TMPL_RULES_TASKS" "$ROOT/templates/rules/tasks-rules.md"
echo ""
embed_file "TMPL_RULES_SRC" "$ROOT/templates/rules/src-rules.md"
echo ""
embed_file "TMPL_RULES_GOVERNANCE" "$ROOT/templates/rules/sage-governance-rules.md"
echo ""

# Skills
embed_file "TMPL_SKILL_SPEC" "$ROOT/templates/skills/sage-spec/SKILL.md"
echo ""
embed_file "TMPL_SKILL_PLAN" "$ROOT/templates/skills/sage-plan/SKILL.md"
echo ""
embed_file "TMPL_SKILL_REVIEW" "$ROOT/templates/skills/sage-review/SKILL.md"
echo ""
embed_file "TMPL_SKILL_REVIEW_RUBRIC" "$ROOT/templates/skills/sage-review/references/review-scoring-rubric.md"
echo ""
embed_file "TMPL_SKILL_HARNESS" "$ROOT/templates/skills/sage-harness/SKILL.md"
echo ""
embed_file "TMPL_SKILL_EVALUATE" "$ROOT/templates/skills/sage-evaluate/SKILL.md"
echo ""
embed_file "TMPL_SKILL_EVALUATE_RUBRIC" "$ROOT/templates/skills/sage-evaluate/references/scoring-rubric.md"
echo ""
embed_file "TMPL_SKILL_EVALUATE_KB" "$ROOT/templates/skills/sage-evaluate/references/knowledge-base.md"
echo ""
# SPEC-0006: Promotion skill
embed_file "TMPL_SKILL_PROMOTE" "$ROOT/templates/skills/sage-promote/SKILL.md"
echo ""

# Base SAGE scripts
embed_file "TMPL_VALIDATE" "$ROOT/scripts/sage-validate.sh"
echo ""
embed_file "TMPL_ID_GEN" "$ROOT/scripts/sage-id-gen.sh"
echo ""
embed_file "TMPL_TRACE_CHECK" "$ROOT/scripts/sage-trace-check.sh"
echo ""
embed_file "TMPL_UPDATE_CHECK" "$ROOT/scripts/sage-update-check.sh"
echo ""
# SPEC-0006: Promotion scripts
embed_file "TMPL_PROMOTE" "$ROOT/scripts/sage-promote.sh"
echo ""
embed_file "TMPL_RETRO_SPEC" "$ROOT/scripts/sage-retro-spec.sh"
echo ""
# SPEC-0022: Codex delegation packet
embed_file "TMPL_CODEX_DELEGATION_PACKET" "$ROOT/docs/codex-delegation-packet.md"
echo ""
