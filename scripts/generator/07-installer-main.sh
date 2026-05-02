# --- メインロジックを埋め込む ---
cat <<'MAIN_LOGIC'
# === Main Logic ===

SAGE_START_MARKER="<!-- === SAGE Development System (auto-injected) === -->"
SAGE_END_MARKER="<!-- === End SAGE === -->"

show_version() {
  echo "SAGE Development System v${SAGE_VERSION}"
}

check_installed_version() {
  if [ -f ".sage/version" ]; then
    cat ".sage/version"
  else
    echo ""
  fi
}

# --- SPEC-0010 / TASK-0097: provenance and integrity verification ---
_sha256_cmd() {
  if command -v sha256sum >/dev/null 2>&1; then
    echo "sha256sum"
  elif command -v shasum >/dev/null 2>&1; then
    echo "shasum -a 256"
  else
    echo ""
  fi
}

do_print_provenance() {
  local sha_cmd
  sha_cmd=$(_sha256_cmd)
  local sha
  if [ -n "$sha_cmd" ]; then
    sha=$($sha_cmd "$0" 2>/dev/null | awk '{print $1}')
  else
    sha="unavailable (no sha256sum/shasum)"
  fi
  # TASK-0112 (Codex review bonus): compute size dynamically from $0
  # rather than hardcoding ~213KB. The installer keeps growing across
  # phases (Phase 1: 213KB, Phase 2A: 235KB, Phase 2B: 262KB) and a
  # stale label undermines provenance trust.
  local size_bytes size_kb
  size_bytes=$(wc -c < "$0" 2>/dev/null | tr -d ' ' || echo 0)
  size_kb=$(( size_bytes / 1024 ))
  cat <<EOF
SAGE Development System — Installer Provenance
==============================================
SAGE_VERSION:     ${SAGE_VERSION}
Installer SHA256: ${sha}
Installer size:   ${size_bytes} bytes (~${size_kb}KB)
Source:           https://github.com/heidayo/sage-ai-template
License:          Apache-2.0 (see LICENSE)
Generated:        $(date -u '+%Y-%m-%dT%H:%M:%SZ')

This installer is a self-contained shell script.
It writes templates, hooks, scripts, and CI workflows under the
current directory. Run with --dry-run to preview without writing.
Run with --verify-checksum after install to detect drift against
.sage/install-state.yaml.

Template-trust note: cloned project files (.claude/settings.json,
.mcp.json, AGENTS.md, CLAUDE.md, templates/hooks/) influence AI
agent behavior. See SECURITY.md and sage/governance.md §9 (Scope
Boundary) before adoption.
EOF
}

do_verify_checksum() {
  local state_file=".sage/install-state.yaml"
  if [ ! -f "$state_file" ]; then
    echo "ERROR: state file not found at $state_file."
    echo "       Cannot verify integrity. Either:"
    echo "         (a) Run 'bash $0' to install (and generate state), then re-run --verify-checksum, or"
    echo "         (b) You are running --verify-checksum from a directory where SAGE is not installed."
    echo "       Treating absence as verification failure (rc=2) per SPEC-0010 / TASK-0100 (Codex review P2 #3)."
    return 2
  fi
  local sha_cmd
  sha_cmd=$(_sha256_cmd)
  if [ -z "$sha_cmd" ]; then
    echo "ERROR: sha256sum/shasum not found, cannot verify."
    return 1
  fi
  local drift=0 missing=0 checked=0 invalid=0
  local current_path="" current_sha=""
  while IFS= read -r line; do
    if [[ "$line" =~ ^[[:space:]]*-[[:space:]]*path:[[:space:]]*\"(.*)\"[[:space:]]*$ ]]; then
      current_path="${BASH_REMATCH[1]}"
      # Reject suspicious paths early (P3 #5: option-like / absolute / parent-traversal).
      case "$current_path" in
        -*|/*|*..*)
          echo "INVALID-PATH: $current_path (rejected by allowlist)"
          invalid=$((invalid + 1))
          current_path=""
          continue
          ;;
      esac
    elif [[ "$line" =~ ^[[:space:]]*sha256:[[:space:]]*\"(.*)\"[[:space:]]*$ ]]; then
      current_sha="${BASH_REMATCH[1]}"
      if [ -n "$current_path" ] && [ -f "$current_path" ]; then
        # Use -- to terminate options so paths cannot be misinterpreted (P3 #5).
        local actual
        actual=$($sha_cmd -- "$current_path" 2>/dev/null | awk '{print $1}')
        checked=$((checked + 1))
        if [ "$actual" != "$current_sha" ]; then
          echo "DRIFT:   $current_path"
          echo "  recorded: $current_sha"
          echo "  actual:   $actual"
          drift=$((drift + 1))
        fi
      elif [ -n "$current_path" ]; then
        echo "MISSING: $current_path"
        missing=$((missing + 1))
      fi
      current_path=""; current_sha=""
    fi
  done < "$state_file"
  echo ""
  echo "Verified: ${checked} files. Drift: ${drift}. Missing: ${missing}. Invalid-path: ${invalid}."
  if [ "$drift" -gt 0 ] || [ "$missing" -gt 0 ] || [ "$invalid" -gt 0 ]; then
    return 1
  fi
  return 0
}

write_file_if_new() {
  local path="$1"
  local content="$2"
  local dir
  dir=$(dirname "$path")
  if [ "${DRY_RUN:-false}" = "true" ]; then
    if [ -f "$path" ]; then
      echo "  WOULD-SKIP:   $path (already exists)"
    else
      echo "  WOULD-CREATE: $path"
    fi
    return 0
  fi
  mkdir -p "$dir"

  if [ -f "$path" ]; then
    echo "  SKIP: $path (already exists)"
    return 0
  else
    echo "$content" > "$path"
    echo "  CREATE: $path"
    return 0
  fi
}

update_file() {
  local path="$1"
  local content="$2"
  local dir
  dir=$(dirname "$path")
  if [ "${DRY_RUN:-false}" = "true" ]; then
    echo "  WOULD-UPDATE: $path"
    return 0
  fi
  mkdir -p "$dir"
  echo "$content" > "$path"
  echo "  UPDATE: $path"
}

upsert_sage_section() {
  local file="$1"
  local snippet="$2"

  if [ "${DRY_RUN:-false}" = "true" ]; then
    if [ ! -f "$file" ]; then
      echo "  WOULD-CREATE: $file"
    elif grep -qF "$SAGE_START_MARKER" "$file" 2>/dev/null; then
      echo "  WOULD-UPDATE: $file (SAGE section)"
    else
      echo "  WOULD-APPEND: $file (SAGE section)"
    fi
    return 0
  fi

  if [ ! -f "$file" ]; then
    echo "$snippet" > "$file"
    echo "  CREATE: $file"
    return
  fi

  if grep -qF "$SAGE_START_MARKER" "$file"; then
    # SAGEセクションが既にある → マーカー間を置換
    local tmp_before=$(mktemp)
    local tmp_after=$(mktemp)
    local tmp_result=$(mktemp)

    # マーカーの行番号を取得
    local start_line=$(grep -nF "$SAGE_START_MARKER" "$file" | head -1 | cut -d: -f1)
    local end_line=$(grep -nF "$SAGE_END_MARKER" "$file" | tail -1 | cut -d: -f1)

    # マーカー前の部分
    if [ "$start_line" -gt 1 ]; then
      sed -n "1,$((start_line - 1))p" "$file" > "$tmp_before"
    else
      : > "$tmp_before"
    fi

    # マーカー後の部分
    local total_lines=$(wc -l < "$file" | tr -d ' ')
    if [ "$end_line" -lt "$total_lines" ]; then
      sed -n "$((end_line + 1)),\$p" "$file" > "$tmp_after"
    else
      : > "$tmp_after"
    fi

    # 結合: before + new snippet + after
    cat "$tmp_before" > "$tmp_result"
    echo "$snippet" >> "$tmp_result"
    cat "$tmp_after" >> "$tmp_result"

    mv "$tmp_result" "$file"
    rm -f "$tmp_before" "$tmp_after"
    echo "  UPDATE: $file (SAGE section replaced)"
  else
    echo "" >> "$file"
    echo "$snippet" >> "$file"
    echo "  APPEND: $file (SAGE section added)"
  fi
}

setup_commit_hook() {
  if [ ! -d .git ]; then
    echo "  SKIP: not a git repository"
    return
  fi

  local hook_dir=".git/hooks"
  if [ -d .husky ]; then
    hook_dir=".husky"
  fi

  local hook_file="$hook_dir/commit-msg"

  if [ "${DRY_RUN:-false}" = "true" ]; then
    if [ -f "$hook_file" ] && grep -qF "SAGE" "$hook_file" 2>/dev/null; then
      echo "  WOULD-SKIP:   $hook_file (SAGE hook already present)"
    elif [ -f "$hook_file" ]; then
      echo "  WOULD-APPEND: $hook_file"
    else
      echo "  WOULD-CREATE: $hook_file"
    fi
    return
  fi

  if [ -f "$hook_file" ] && grep -qF "SAGE" "$hook_file"; then
    echo "  SKIP: $hook_file (SAGE hook already present)"
  elif [ -f "$hook_file" ]; then
    echo "" >> "$hook_file"
    echo "# --- SAGE: TASK-ID check ---" >> "$hook_file"
    echo "$TMPL_COMMIT_HOOK" >> "$hook_file"
    echo "  APPEND: $hook_file"
  else
    mkdir -p "$hook_dir"
    echo "$TMPL_COMMIT_HOOK" > "$hook_file"
    chmod +x "$hook_file"
    echo "  CREATE: $hook_file"
  fi
}

audit_existing_claude_md() {
  local file="$1"
  local report=".sage/adoption-audit.md"

  if [ "${DRY_RUN:-false}" = "true" ]; then
    echo "  WOULD-WRITE: $report (adoption audit for existing CLAUDE.md)"
    return
  fi

  echo "# SAGE Adoption Audit" > "$report"
  echo "Generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$report"
  echo "" >> "$report"

  local rules=$(grep -E "^[\t ]*[-*]" "$file" | grep -v "^#" | grep -v '^\s*$')

  echo "## Analysis" >> "$report"
  echo "" >> "$report"

  echo "### SAFE_AUTO_APPLY" >> "$report"
  echo "These rules do not conflict with SAGE. No action needed." >> "$report"
  echo "$rules" | while IFS= read -r line; do
    if [ -n "$line" ] && ! echo "$line" | grep -qiE "commit|task|spec|todo|fixme|test|scope|review"; then
      echo "- $line" >> "$report"
    fi
  done
  echo "" >> "$report"

  echo "### NEEDS_REVIEW" >> "$report"
  echo "These rules may overlap with SAGE. Review recommended." >> "$report"
  echo "$rules" | while IFS= read -r line; do
    if [ -n "$line" ] && echo "$line" | grep -qiE "spec|scope|review|test|coverage"; then
      if ! echo "$line" | grep -qiE "commit.*id|task.*id|no commit|skip test"; then
        echo "- $line" >> "$report"
      fi
    fi
  done
  echo "" >> "$report"

  echo "### CONFLICT" >> "$report"
  echo "These rules may conflict with SAGE. Do NOT auto-merge." >> "$report"
  echo "$rules" | while IFS= read -r line; do
    if [ -n "$line" ] && echo "$line" | grep -qiE "commit.*message|commit.*format|task.*id|ticket.*id|todo.*ok|fixme.*allow|skip.*test"; then
      echo "- $line (conflicts with SAGE commit/test rules)" >> "$report"
    fi
  done
  echo "" >> "$report"

  echo "## Recommendation" >> "$report"
  echo "- SAFE_AUTO_APPLY items: no action needed" >> "$report"
  echo "- NEEDS_REVIEW items: check if your project rules and SAGE rules overlap. Remove duplicates." >> "$report"
  echo "- CONFLICT items: resolve manually before relying on SAGE enforcement." >> "$report"

  echo "  AUDIT: Report written to $report"
}

setup_gitignore() {
  # Note: .sage/runs/ is intentionally NOT added to .gitignore — RUN logs
  # are SAGE's audit trail and must be tracked. Only .sage/metrics/ (raw
  # numeric counters) is ignored. See TASK-0100 / Codex review P1 #1.
  if [ "${DRY_RUN:-false}" = "true" ]; then
    if [ ! -f .gitignore ]; then
      echo "  WOULD-CREATE: .gitignore (with .sage/metrics/)"
    else
      grep -qxF '.sage/metrics/' .gitignore 2>/dev/null || echo "  WOULD-APPEND: .gitignore += .sage/metrics/"
    fi
    return
  fi
  if [ ! -f .gitignore ]; then
    touch .gitignore
  fi
  grep -qxF '.sage/metrics/' .gitignore 2>/dev/null || echo '.sage/metrics/' >> .gitignore
  echo "  OK"
}

# --- Parse arguments ---
MODE="install"
DRY_RUN=false
for arg in "$@"; do
  case "$arg" in
    --update) MODE="update" ;;
    --version) show_version; exit 0 ;;
    --print-provenance) do_print_provenance; exit 0 ;;
    --verify-checksum) do_verify_checksum; exit $? ;;
    --dry-run) DRY_RUN=true ;;
    --help)
      cat <<HELP_EOF
Usage: bash install.sh [OPTIONS]

  (no args)              First-time installation (auto-updates if installed)
  --update               Force update mode
  --version              Show SAGE version
  --dry-run              Preview without writing any files (SPEC-0010)
  --verify-checksum      Verify installed files against .sage/install-state.yaml
  --print-provenance     Print installer SHA256, version, and license info
  --help                 Show this help

License: Apache-2.0 (see LICENSE)
Source:  https://github.com/heidayo/sage-ai-template
Trust:   See SECURITY.md and sage/governance.md §9 (Scope Boundary)
HELP_EOF
      exit 0
      ;;
  esac
done

# Announce dry-run mode prominently
if [ "$DRY_RUN" = "true" ]; then
  echo "========================================="
  echo "  SAGE v${SAGE_VERSION} — DRY RUN (no writes will occur)"
  echo "========================================="
  echo ""
  # Override chmod as no-op so chained "write_file_if_new && chmod +x" stays safe
  # (the file is not created in dry-run, so chmod would fail under set -e).
  chmod() { return 0; }
fi

INSTALLED_VERSION=$(check_installed_version)

# Auto-detect: if already installed, switch to update mode
if [ -n "$INSTALLED_VERSION" ] && [ "$MODE" = "install" ]; then
  echo "SAGE v${INSTALLED_VERSION} is already installed."
  echo "Updating to v${SAGE_VERSION}..."
  echo ""
  MODE="update"
fi

if [ "$MODE" = "update" ] && [ "$INSTALLED_VERSION" = "$SAGE_VERSION" ]; then
  echo "Already at v${SAGE_VERSION}. No update needed."
  exit 0
fi

echo "========================================="
if [ "$MODE" = "install" ]; then
  echo "  SAGE v${SAGE_VERSION} — New Installation"
else
  echo "  SAGE v${INSTALLED_VERSION:-?} → v${SAGE_VERSION} — Update"
fi
echo "========================================="
echo ""

# --- [1/9] Directories ---
echo "[1/9] ディレクトリ..."
if [ "${DRY_RUN:-false}" = "true" ]; then
  echo "  WOULD-MKDIR: specs plans tasks sage .sage/runs .sage/metrics docs scripts .claude/rules .claude/skills/{sage-spec,sage-plan,sage-review,sage-review/references,sage-evaluate/references,sage-harness,sage-promote}"
else
  mkdir -p specs plans tasks sage .sage/runs .sage/metrics docs scripts .claude/rules .claude/skills/sage-spec .claude/skills/sage-plan .claude/skills/sage-review .claude/skills/sage-review/references .claude/skills/sage-evaluate/references .claude/skills/sage-harness .claude/skills/sage-promote
fi
echo "  OK"

# --- [2/9] Templates & governance ---
echo ""
echo "[2/9] テンプレート & ガバナンス文書..."
if [ "$MODE" = "install" ]; then
  write_file_if_new "specs/_template.md" "$TMPL_SPEC"
  write_file_if_new "plans/_template.md" "$TMPL_PLAN"
  write_file_if_new "tasks/_template.md" "$TMPL_TASK"
  write_file_if_new "sage/charter.md" "$TMPL_CHARTER"
  write_file_if_new "sage/governance.md" "$TMPL_GOVERNANCE"
  write_file_if_new "sage/failures.md" "$TMPL_FAILURES"
  write_file_if_new "sage/anti-patterns.md" "$TMPL_ANTIPATTERNS"
  write_file_if_new "sage/quality-gates.md" "$TMPL_QUALITY_GATES"
  write_file_if_new "sage/adoption-phases.md" "$TMPL_ADOPTION"
  write_file_if_new "sage/traceability.md" "$TMPL_TRACEABILITY"
  write_file_if_new ".sage/config.yaml" "$TMPL_CONFIG"
  write_file_if_new "scripts/sage-validate.sh" "$TMPL_VALIDATE" && chmod +x "scripts/sage-validate.sh"
  write_file_if_new "scripts/sage-id-gen.sh" "$TMPL_ID_GEN" && chmod +x "scripts/sage-id-gen.sh"
  write_file_if_new "scripts/sage-trace-check.sh" "$TMPL_TRACE_CHECK" && chmod +x "scripts/sage-trace-check.sh"
  write_file_if_new "scripts/sage-update-check.sh" "$TMPL_UPDATE_CHECK" && chmod +x "scripts/sage-update-check.sh"
  write_file_if_new "scripts/sage-promote.sh" "$TMPL_PROMOTE" && chmod +x "scripts/sage-promote.sh"
  write_file_if_new "scripts/sage-retro-spec.sh" "$TMPL_RETRO_SPEC" && chmod +x "scripts/sage-retro-spec.sh"
else
  # Update mode: テンプレートとガバナンスはSAGE管理なので上書き
  update_file "specs/_template.md" "$TMPL_SPEC"
  update_file "plans/_template.md" "$TMPL_PLAN"
  update_file "tasks/_template.md" "$TMPL_TASK"
  update_file "sage/charter.md" "$TMPL_CHARTER"
  update_file "sage/governance.md" "$TMPL_GOVERNANCE"
  update_file "sage/anti-patterns.md" "$TMPL_ANTIPATTERNS"
  update_file "sage/quality-gates.md" "$TMPL_QUALITY_GATES"
  update_file "sage/adoption-phases.md" "$TMPL_ADOPTION"
  update_file "sage/traceability.md" "$TMPL_TRACEABILITY"
  update_file "scripts/sage-validate.sh" "$TMPL_VALIDATE" && chmod +x "scripts/sage-validate.sh"
  update_file "scripts/sage-id-gen.sh" "$TMPL_ID_GEN" && chmod +x "scripts/sage-id-gen.sh"
  update_file "scripts/sage-trace-check.sh" "$TMPL_TRACE_CHECK" && chmod +x "scripts/sage-trace-check.sh"
  update_file "scripts/sage-update-check.sh" "$TMPL_UPDATE_CHECK" && chmod +x "scripts/sage-update-check.sh"
  update_file "scripts/sage-promote.sh" "$TMPL_PROMOTE" && chmod +x "scripts/sage-promote.sh"
  update_file "scripts/sage-retro-spec.sh" "$TMPL_RETRO_SPEC" && chmod +x "scripts/sage-retro-spec.sh"
  # failures.md, config.yaml はプロジェクト固有データが入るので更新しない
  echo "  KEEP: sage/failures.md (project data)"
  echo "  KEEP: .sage/config.yaml (project settings)"
fi

# --- [3/9] .claude/rules/ ---
echo ""
echo "[3/9] .claude/rules/..."
if [ "$MODE" = "install" ]; then
  write_file_if_new ".claude/rules/specs-rules.md" "$TMPL_RULES_SPECS"
  write_file_if_new ".claude/rules/plans-rules.md" "$TMPL_RULES_PLANS"
  write_file_if_new ".claude/rules/tasks-rules.md" "$TMPL_RULES_TASKS"
  write_file_if_new ".claude/rules/src-rules.md" "$TMPL_RULES_SRC"
  write_file_if_new ".claude/rules/sage-governance-rules.md" "$TMPL_RULES_GOVERNANCE"
else
  update_file ".claude/rules/specs-rules.md" "$TMPL_RULES_SPECS"
  update_file ".claude/rules/plans-rules.md" "$TMPL_RULES_PLANS"
  update_file ".claude/rules/tasks-rules.md" "$TMPL_RULES_TASKS"
  update_file ".claude/rules/src-rules.md" "$TMPL_RULES_SRC"
  update_file ".claude/rules/sage-governance-rules.md" "$TMPL_RULES_GOVERNANCE"
fi

# --- [4/9] .claude/skills/ ---
echo ""
echo "[4/9] .claude/skills/..."
if [ "$MODE" = "install" ]; then
  write_file_if_new ".claude/skills/sage-spec/SKILL.md" "$TMPL_SKILL_SPEC"
  write_file_if_new ".claude/skills/sage-plan/SKILL.md" "$TMPL_SKILL_PLAN"
  write_file_if_new ".claude/skills/sage-review/SKILL.md" "$TMPL_SKILL_REVIEW"
  write_file_if_new ".claude/skills/sage-review/references/review-scoring-rubric.md" "$TMPL_SKILL_REVIEW_RUBRIC"
  write_file_if_new ".claude/skills/sage-harness/SKILL.md" "$TMPL_SKILL_HARNESS"
  write_file_if_new ".claude/skills/sage-evaluate/SKILL.md" "$TMPL_SKILL_EVALUATE"
  write_file_if_new ".claude/skills/sage-evaluate/references/scoring-rubric.md" "$TMPL_SKILL_EVALUATE_RUBRIC"
  write_file_if_new ".claude/skills/sage-evaluate/references/knowledge-base.md" "$TMPL_SKILL_EVALUATE_KB"
  write_file_if_new ".claude/skills/sage-promote/SKILL.md" "$TMPL_SKILL_PROMOTE"
else
  update_file ".claude/skills/sage-spec/SKILL.md" "$TMPL_SKILL_SPEC"
  update_file ".claude/skills/sage-plan/SKILL.md" "$TMPL_SKILL_PLAN"
  update_file ".claude/skills/sage-review/SKILL.md" "$TMPL_SKILL_REVIEW"
  update_file ".claude/skills/sage-review/references/review-scoring-rubric.md" "$TMPL_SKILL_REVIEW_RUBRIC"
  update_file ".claude/skills/sage-harness/SKILL.md" "$TMPL_SKILL_HARNESS"
  update_file ".claude/skills/sage-evaluate/SKILL.md" "$TMPL_SKILL_EVALUATE"
  update_file ".claude/skills/sage-evaluate/references/scoring-rubric.md" "$TMPL_SKILL_EVALUATE_RUBRIC"
  update_file ".claude/skills/sage-evaluate/references/knowledge-base.md" "$TMPL_SKILL_EVALUATE_KB"
  update_file ".claude/skills/sage-promote/SKILL.md" "$TMPL_SKILL_PROMOTE"
fi

# --- [5/9] CLAUDE.md ---
echo ""
echo "[5/9] CLAUDE.md..."
# Audit existing CLAUDE.md before first SAGE injection
AUDIT_GENERATED=""
if [ -f CLAUDE.md ] && [ -s CLAUDE.md ] && ! grep -qF "$SAGE_START_MARKER" CLAUDE.md; then
  audit_existing_claude_md CLAUDE.md
  AUDIT_GENERATED="true"
fi
upsert_sage_section "CLAUDE.md" "$TMPL_CLAUDE_SNIPPET"

# --- [6/9] AGENTS.md ---
echo ""
echo "[6/9] AGENTS.md (Codex)..."
upsert_sage_section "AGENTS.md" "$TMPL_AGENTS_SNIPPET"

# --- [7/9] Hooks ---
echo ""
echo "[7/9] Claude Code hooks..."
if [ "${DRY_RUN:-false}" != "true" ]; then
  mkdir -p templates/hooks
fi
if [ "$MODE" = "install" ]; then
  write_file_if_new "templates/hooks/block-dangerous-commands.sh" "$TMPL_HOOK_BLOCK_DANGEROUS" && chmod +x "templates/hooks/block-dangerous-commands.sh"
  write_file_if_new "templates/hooks/protect-sage-files.sh" "$TMPL_HOOK_PROTECT_SAGE" && chmod +x "templates/hooks/protect-sage-files.sh"
  write_file_if_new "templates/hooks/check-file-scope.sh" "$TMPL_HOOK_CHECK_SCOPE" && chmod +x "templates/hooks/check-file-scope.sh"
  write_file_if_new "templates/hooks/session-start.sh" "$TMPL_HOOK_SESSION_START" && chmod +x "templates/hooks/session-start.sh"
  write_file_if_new "templates/hooks/session-stop.sh" "$TMPL_HOOK_SESSION_STOP" && chmod +x "templates/hooks/session-stop.sh"
  write_file_if_new "templates/hooks/lethal-trifecta-detect.sh" "$TMPL_HOOK_LETHAL_TRIFECTA" && chmod +x "templates/hooks/lethal-trifecta-detect.sh"
  write_file_if_new "templates/hooks/secret-read-multi-layer.sh" "$TMPL_HOOK_SECRET_READ" && chmod +x "templates/hooks/secret-read-multi-layer.sh"
  write_file_if_new "templates/hooks/security-filter.sh" "$TMPL_HOOK_SECURITY_FILTER" && chmod +x "templates/hooks/security-filter.sh"
  write_file_if_new "templates/hooks/mcp-allowlist-audit.sh" "$TMPL_HOOK_MCP_ALLOWLIST_AUDIT" && chmod +x "templates/hooks/mcp-allowlist-audit.sh"
  mkdir -p templates/sage
  write_file_if_new "templates/sage/mcp-allowlist-template.json" "$TMPL_SAGE_MCP_ALLOWLIST_TEMPLATE"
  write_file_if_new "templates/sage/README.md" "$TMPL_SAGE_README"
  mkdir -p templates/hooks/tests
  write_file_if_new "templates/hooks/tests/test-mcp-allowlist-audit.sh" "$TMPL_TEST_MCP_ALLOWLIST" && chmod +x "templates/hooks/tests/test-mcp-allowlist-audit.sh"
  write_file_if_new "templates/hooks/tests/test-detection-only-behavior.sh" "$TMPL_TEST_DETECTION_ONLY" && chmod +x "templates/hooks/tests/test-detection-only-behavior.sh"
  write_file_if_new "templates/hooks/tests/measure-hook-time.py" "$TMPL_MEASURE_HOOK_TIME" && chmod +x "templates/hooks/tests/measure-hook-time.py"
  write_file_if_new "scripts/sage-mcp-allowlist-audit.sh" "$TMPL_SCRIPT_MCP_ALLOWLIST_AUDIT" && chmod +x "scripts/sage-mcp-allowlist-audit.sh"
  write_file_if_new "templates/sage/agent-inventory-template.yaml" "$TMPL_SAGE_AGENT_INVENTORY"
  write_file_if_new "templates/hooks/tests/test-agent-inventory-validator.sh" "$TMPL_TEST_AGENT_INVENTORY" && chmod +x "templates/hooks/tests/test-agent-inventory-validator.sh"
  write_file_if_new "scripts/sage-agent-inventory-audit.sh" "$TMPL_SCRIPT_AGENT_INVENTORY" && chmod +x "scripts/sage-agent-inventory-audit.sh"
  write_file_if_new "scripts/sage-runlog-index.sh" "$TMPL_SCRIPT_RUNLOG_INDEX" && chmod +x "scripts/sage-runlog-index.sh"
  write_file_if_new "scripts/sage-runlog-search.sh" "$TMPL_SCRIPT_RUNLOG_SEARCH" && chmod +x "scripts/sage-runlog-search.sh"
  write_file_if_new "scripts/sage-runlog-db-audit.sh" "$TMPL_SCRIPT_RUNLOG_DB_AUDIT" && chmod +x "scripts/sage-runlog-db-audit.sh"
  write_file_if_new "templates/hooks/tests/test-runlog-index.sh" "$TMPL_TEST_RUNLOG_INDEX" && chmod +x "templates/hooks/tests/test-runlog-index.sh"
  write_file_if_new "templates/hooks/tests/test-runlog-search.sh" "$TMPL_TEST_RUNLOG_SEARCH" && chmod +x "templates/hooks/tests/test-runlog-search.sh"
  write_file_if_new "templates/hooks/tests/test-runlog-db-doctor.sh" "$TMPL_TEST_RUNLOG_DB_DOCTOR" && chmod +x "templates/hooks/tests/test-runlog-db-doctor.sh"
  write_file_if_new "templates/settings/sandbox.json" "$TMPL_SETTINGS_SANDBOX"
  write_file_if_new "templates/settings/README.md" "$TMPL_SETTINGS_README"
else
  update_file "templates/hooks/block-dangerous-commands.sh" "$TMPL_HOOK_BLOCK_DANGEROUS" && chmod +x "templates/hooks/block-dangerous-commands.sh"
  update_file "templates/hooks/protect-sage-files.sh" "$TMPL_HOOK_PROTECT_SAGE" && chmod +x "templates/hooks/protect-sage-files.sh"
  update_file "templates/hooks/check-file-scope.sh" "$TMPL_HOOK_CHECK_SCOPE" && chmod +x "templates/hooks/check-file-scope.sh"
  update_file "templates/hooks/session-start.sh" "$TMPL_HOOK_SESSION_START" && chmod +x "templates/hooks/session-start.sh"
  update_file "templates/hooks/session-stop.sh" "$TMPL_HOOK_SESSION_STOP" && chmod +x "templates/hooks/session-stop.sh"
  update_file "templates/hooks/lethal-trifecta-detect.sh" "$TMPL_HOOK_LETHAL_TRIFECTA" && chmod +x "templates/hooks/lethal-trifecta-detect.sh"
  update_file "templates/hooks/secret-read-multi-layer.sh" "$TMPL_HOOK_SECRET_READ" && chmod +x "templates/hooks/secret-read-multi-layer.sh"
  update_file "templates/hooks/security-filter.sh" "$TMPL_HOOK_SECURITY_FILTER" && chmod +x "templates/hooks/security-filter.sh"
  update_file "templates/hooks/mcp-allowlist-audit.sh" "$TMPL_HOOK_MCP_ALLOWLIST_AUDIT" && chmod +x "templates/hooks/mcp-allowlist-audit.sh"
  mkdir -p templates/sage
  update_file "templates/sage/mcp-allowlist-template.json" "$TMPL_SAGE_MCP_ALLOWLIST_TEMPLATE"
  update_file "templates/sage/README.md" "$TMPL_SAGE_README"
  mkdir -p templates/hooks/tests
  update_file "templates/hooks/tests/test-mcp-allowlist-audit.sh" "$TMPL_TEST_MCP_ALLOWLIST" && chmod +x "templates/hooks/tests/test-mcp-allowlist-audit.sh"
  update_file "templates/hooks/tests/test-detection-only-behavior.sh" "$TMPL_TEST_DETECTION_ONLY" && chmod +x "templates/hooks/tests/test-detection-only-behavior.sh"
  update_file "templates/hooks/tests/measure-hook-time.py" "$TMPL_MEASURE_HOOK_TIME" && chmod +x "templates/hooks/tests/measure-hook-time.py"
  update_file "scripts/sage-mcp-allowlist-audit.sh" "$TMPL_SCRIPT_MCP_ALLOWLIST_AUDIT" && chmod +x "scripts/sage-mcp-allowlist-audit.sh"
  update_file "templates/sage/agent-inventory-template.yaml" "$TMPL_SAGE_AGENT_INVENTORY"
  update_file "templates/hooks/tests/test-agent-inventory-validator.sh" "$TMPL_TEST_AGENT_INVENTORY" && chmod +x "templates/hooks/tests/test-agent-inventory-validator.sh"
  update_file "scripts/sage-agent-inventory-audit.sh" "$TMPL_SCRIPT_AGENT_INVENTORY" && chmod +x "scripts/sage-agent-inventory-audit.sh"
  update_file "scripts/sage-runlog-index.sh" "$TMPL_SCRIPT_RUNLOG_INDEX" && chmod +x "scripts/sage-runlog-index.sh"
  update_file "scripts/sage-runlog-search.sh" "$TMPL_SCRIPT_RUNLOG_SEARCH" && chmod +x "scripts/sage-runlog-search.sh"
  update_file "scripts/sage-runlog-db-audit.sh" "$TMPL_SCRIPT_RUNLOG_DB_AUDIT" && chmod +x "scripts/sage-runlog-db-audit.sh"
  update_file "templates/hooks/tests/test-runlog-index.sh" "$TMPL_TEST_RUNLOG_INDEX" && chmod +x "templates/hooks/tests/test-runlog-index.sh"
  update_file "templates/hooks/tests/test-runlog-search.sh" "$TMPL_TEST_RUNLOG_SEARCH" && chmod +x "templates/hooks/tests/test-runlog-search.sh"
  update_file "templates/hooks/tests/test-runlog-db-doctor.sh" "$TMPL_TEST_RUNLOG_DB_DOCTOR" && chmod +x "templates/hooks/tests/test-runlog-db-doctor.sh"
  update_file "templates/settings/sandbox.json" "$TMPL_SETTINGS_SANDBOX"
  update_file "templates/settings/README.md" "$TMPL_SETTINGS_README"
fi
# Deploy settings.json with hook definitions
if [ "${DRY_RUN:-false}" = "true" ]; then
  if [ ! -f ".claude/settings.json" ] || ! grep -qF "block-dangerous-commands" ".claude/settings.json" 2>/dev/null; then
    echo "  WOULD-CREATE: .claude/settings.json (with hooks)"
  else
    echo "  WOULD-SKIP:   .claude/settings.json (hooks already configured)"
  fi
elif [ ! -f ".claude/settings.json" ] || ! grep -qF "block-dangerous-commands" ".claude/settings.json" 2>/dev/null; then
  mkdir -p .claude
  echo "$TMPL_SETTINGS_JSON" > ".claude/settings.json"
  echo "  CREATE: .claude/settings.json (with hooks)"
else
  echo "  SKIP: .claude/settings.json (hooks already configured)"
fi

# --- [8/9] Commit hook ---
echo ""
echo "[8/9] Pre-commit hook..."
setup_commit_hook

# --- [9/9] .gitignore ---
echo ""
echo "[9/9] .gitignore..."
setup_gitignore

# --- Save installed version ---
if [ "${DRY_RUN:-false}" = "true" ]; then
  echo "  WOULD-WRITE: .sage/version (${SAGE_VERSION})"
else
  echo "$SAGE_VERSION" > .sage/version
fi

# --- Generate install-state.yaml (SPEC-0004) ---
echo ""
echo "Generating install-state.yaml..."
generate_install_state() {
  local state_file=".sage/install-state.yaml"
  local sha_cmd=""

  if [ "${DRY_RUN:-false}" = "true" ]; then
    echo "  WOULD-WRITE: $state_file"
    return
  fi

  # Cross-platform SHA256
  if command -v sha256sum &>/dev/null; then
    sha_cmd="sha256sum"
  elif command -v shasum &>/dev/null; then
    sha_cmd="shasum -a 256"
  else
    echo "  WARN: No sha256 command found. Skipping install-state generation."
    return
  fi

  cat > "$state_file" <<STATEHEADER
version: "${SAGE_VERSION}"
installed_at: "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
files:
STATEHEADER

  # SAGE-managed files (update_file targets — overwritten on update)
  local managed_files=(
    "specs/_template.md"
    "plans/_template.md"
    "tasks/_template.md"
    "sage/charter.md"
    "sage/governance.md"
    "sage/anti-patterns.md"
    "sage/quality-gates.md"
    "sage/adoption-phases.md"
    "sage/traceability.md"
    "scripts/sage-validate.sh"
    "scripts/sage-id-gen.sh"
    "scripts/sage-trace-check.sh"
    "scripts/sage-update-check.sh"
    "scripts/sage-promote.sh"
    "scripts/sage-retro-spec.sh"
    ".claude/rules/specs-rules.md"
    ".claude/rules/plans-rules.md"
    ".claude/rules/tasks-rules.md"
    ".claude/rules/src-rules.md"
    ".claude/rules/sage-governance-rules.md"
    ".claude/skills/sage-spec/SKILL.md"
    ".claude/skills/sage-plan/SKILL.md"
    ".claude/skills/sage-review/SKILL.md"
    ".claude/skills/sage-review/references/review-scoring-rubric.md"
    ".claude/skills/sage-harness/SKILL.md"
    ".claude/skills/sage-evaluate/SKILL.md"
    ".claude/skills/sage-evaluate/references/scoring-rubric.md"
    ".claude/skills/sage-evaluate/references/knowledge-base.md"
    ".claude/skills/sage-promote/SKILL.md"
    "templates/hooks/block-dangerous-commands.sh"
    "templates/hooks/protect-sage-files.sh"
    "templates/hooks/check-file-scope.sh"
    "templates/hooks/session-start.sh"
    "templates/hooks/session-stop.sh"
  )

  # User-customizable files (write_file_if_new targets — NOT overwritten)
  local user_files=(
    "CLAUDE.md"
    "AGENTS.md"
    ".sage/config.yaml"
    "sage/failures.md"
    ".claude/settings.json"
  )

  for f in "${managed_files[@]}"; do
    if [ -f "$f" ]; then
      local hash=$($sha_cmd "$f" | awk '{print $1}')
      echo "  - path: \"$f\"" >> "$state_file"
      echo "    sha256: \"$hash\"" >> "$state_file"
      echo "    source: \"embedded\"" >> "$state_file"
      echo "    managed: true" >> "$state_file"
    fi
  done

  for f in "${user_files[@]}"; do
    if [ -f "$f" ]; then
      local hash=$($sha_cmd "$f" | awk '{print $1}')
      echo "  - path: \"$f\"" >> "$state_file"
      echo "    sha256: \"$hash\"" >> "$state_file"
      echo "    source: \"embedded\"" >> "$state_file"
      echo "    managed: false" >> "$state_file"
    fi
  done

  echo "  OK: .sage/install-state.yaml"
}
generate_install_state

echo ""
echo "========================================="
echo "  SAGE v${SAGE_VERSION} — Complete"
echo "========================================="
echo ""
if [ "$MODE" = "install" ]; then
  echo "AI エージェントは次のセッションから自動的にSAGEに従います。"
  echo ""
  echo "次のステップ:"
  if [ "$AUDIT_GENERATED" = "true" ]; then
    echo "  ⚠ 既存の CLAUDE.md にルールが検出されました。"
    echo "    まず監査レポートを確認してください："
    echo "      cat .sage/adoption-audit.md"
    echo ""
    echo "    - SAFE_AUTO_APPLY → 対応不要"
    echo "    - NEEDS_REVIEW    → SAGEと重複していないか確認、重複は削除"
    echo "    - CONFLICT        → 手動で解決してからSAGEを利用"
    echo ""
  fi
  echo "  1. 次の機能開発で SPEC を書いてみる"
  echo "     bash scripts/sage-id-gen.sh spec"
  echo ""
  echo "カスタマイズ:"
  echo "  CLAUDE.md     → SAGEマーカーの上に自由に追記OK"
  echo "  .claude/rules/ → 自分用ルールは別名で追加（例: my-api-rules.md）"
  echo "                   ※ SAGE管理ファイル（specs-rules.md 等）は更新時に上書きされます"
else
  echo "更新内容:"
  echo "  - テンプレート・ガバナンス文書を v${SAGE_VERSION} に更新"
  echo "  - CLAUDE.md / AGENTS.md の SAGE セクションを更新"
  echo "  - プロジェクト固有の設定 (config.yaml, failures.md) はそのまま"
fi
echo ""
MAIN_LOGIC
