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

# SPEC-0025 (FR-04 / AC-05): append the local overlay reference notice to
# every managed rules template so all installed .claude/rules/*.md point
# project-specific rules to rules/local/. Defined once here to avoid drift
# across the five managed rules files.
cat <<'RULES_NOTICE'
# SPEC-0025: local overlay reference notice appended to all managed rules (FR-04).
RULES_LOCAL_NOTICE='
---

<!-- SAGE managed rules file (SPEC-0025): replaced entirely on install.sh update. Put project-specific rules under .claude/rules/local/ instead. -->
注記: このファイルは install.sh 更新で全置換されます。プロジェクト固有ルールは `.claude/rules/local/` に置いてください。'
TMPL_RULES_SPECS="${TMPL_RULES_SPECS}${RULES_LOCAL_NOTICE}"
TMPL_RULES_PLANS="${TMPL_RULES_PLANS}${RULES_LOCAL_NOTICE}"
TMPL_RULES_TASKS="${TMPL_RULES_TASKS}${RULES_LOCAL_NOTICE}"
TMPL_RULES_SRC="${TMPL_RULES_SRC}${RULES_LOCAL_NOTICE}"
TMPL_RULES_GOVERNANCE="${TMPL_RULES_GOVERNANCE}${RULES_LOCAL_NOTICE}"
RULES_NOTICE
echo ""

# SPEC-0025: rules writer with local overlay exclusion. References
# is_unmanaged_path (defined once in module 07's main logic — INV-03)
# so rules generation never creates, overwrites, or deletes anything
# under .claude/rules/local/ or .codex/rules/local/.
cat <<'RULES_LOGIC'
# SPEC-0025: overlay-safe rules writer (references is_unmanaged_path).
write_rules_file() {
  local path="$1"
  local content="$2"
  if is_unmanaged_path "$path"; then
    if [ "${DRY_RUN:-false}" = "true" ]; then
      echo "  WOULD-SKIP:   $path (unmanaged overlay path, SPEC-0025)"
    else
      echo "  SKIP: $path (unmanaged overlay path, SPEC-0025)"
    fi
    return 0
  fi
  if [ "$MODE" = "install" ]; then
    write_file_if_new "$path" "$content"
  else
    update_file "$path" "$content"
  fi
}
RULES_LOGIC
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
# SPEC-0023: Claude collaboration brief (paired with SPEC-0022 Codex delegation packet)
embed_file "TMPL_CLAUDE_COLLABORATION_BRIEF" "$ROOT/docs/claude-collaboration-brief.md"
echo ""
