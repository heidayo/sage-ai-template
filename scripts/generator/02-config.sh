# shellcheck shell=bash
# Module 02: .sage/config.yaml + claude/agents snippets + commit hook (SPEC-0014)
# Sourced by scripts/generate-installer.sh — depends on embed_file function.
# Do not chmod +x; do not run standalone.

# SPEC-0018 FR-04: NEW install default installer_url is GitHub Releases (immutable per tag).
# Existing installs keep their URL (NFR-01 backward compat — install.sh --update never overwrites
# user's .sage/config.yaml installer_url). The substitution below only affects the TMPL_CONFIG
# embedded into install.sh; this repo's own .sage/config.yaml is untouched (avoids chicken-and-egg
# during the v1.5.0 → v1.6.0 transition window).
SAGE_RELEASES_INSTALL_URL="https://github.com/heidayo/sage-ai-template/releases/latest/download/install.sh"
TMP_CONFIG=$(mktemp -t sage-config-XXXXXX)
sed -E "s|installer_url: \"https://gist\\.githubusercontent\\.com/[^\"]*\"|installer_url: \"${SAGE_RELEASES_INSTALL_URL}\"|" \
  "$ROOT/.sage/config.yaml" > "$TMP_CONFIG"
embed_file "TMPL_CONFIG" "$TMP_CONFIG"
rm -f "$TMP_CONFIG"
echo ""
embed_file "TMPL_CLAUDE_SNIPPET" "$ROOT/templates/claude-md-snippet.md"
echo ""
embed_file "TMPL_AGENTS_SNIPPET" "$ROOT/templates/agents-md-snippet.md"
echo ""
embed_file "TMPL_COMMIT_HOOK" "$ROOT/templates/pre-commit-task-id.sh"
echo ""
# SPEC-0027: shared ID pattern loader + default pattern config.
# The loader must ship with sage-validate.sh / sage-id-gen.sh / sage-trace-check.sh
# (they source it); id-patterns.json is distributed preserve-if-exists (AC-12).
embed_file "TMPL_ID_PATTERN_LOADER" "$ROOT/scripts/sage-id-pattern.sh"
echo ""
embed_file "TMPL_ID_PATTERNS" "$ROOT/.sage/id-patterns.json"
echo ""
# SPEC-0028: stack presets for project_checks. The single source of truth is
# templates/project-checks/ (INV-06); the variables below are generator-derived
# static strings — the installer never reads target-project files into
# config.yaml (SEC-02/INV-04).
# Unlike embed_file, presets are read with IFS= so the leading indentation of
# the first fragment line (YAML section body is indented) survives `read`.
embed_preset_file() {
  local var_name="$1"
  local file_path="$2"
  local delimiter="__EOF_${var_name}__"
  if [ ! -f "$file_path" ]; then
    echo "ERROR: preset $file_path not found (SPEC-0028 INV-06)" >&2
    exit 1
  fi
  echo "IFS= read -r -d '' ${var_name} <<'${delimiter}' || true"
  cat "$file_path"
  echo ""
  echo "${delimiter}"
}
embed_preset_file "TMPL_STACK_GO" "$ROOT/templates/project-checks/go.yaml"
echo ""
embed_preset_file "TMPL_STACK_TS_PNPM" "$ROOT/templates/project-checks/ts-pnpm.yaml"
echo ""
embed_preset_file "TMPL_STACK_NODE_NPM" "$ROOT/templates/project-checks/node-npm.yaml"
echo ""
embed_preset_file "TMPL_STACK_PYTHON" "$ROOT/templates/project-checks/python.yaml"
echo ""
# SPEC-0028: installer-side helper that swaps only the project_checks: section
# of TMPL_CONFIG for a preset body. Replacement is bounded to the section
# (from the top-level 'project_checks:' line up to, but excluding, the first
# blank or column-0 line) so no other line of the config drifts (POST-01).
cat <<'STACK_PRESET_HELPER'
# === SPEC-0028: project_checks stack preset section replacement ===
replace_project_checks_section() {
  local config_content="$1"
  local preset_body="$2"
  # Preset is handed over via ENVIRON: BSD awk rejects newlines in -v values.
  printf '%s\n' "$config_content" | SAGE_STACK_PRESET_BODY="$preset_body" awk '
    BEGIN {
      preset = ENVIRON["SAGE_STACK_PRESET_BODY"]
      sub(/\n+$/, "", preset); replaced = 0; in_pc = 0
    }
    !replaced && /^project_checks:[[:space:]]*$/ {
      print
      print preset
      in_pc = 1; replaced = 1; next
    }
    in_pc {
      # Section ends at the first blank or column-0 line, which is kept as-is.
      if ($0 == "" || $0 !~ /^[[:space:]]/) { in_pc = 0; print }
      next
    }
    { print }
  '
}
STACK_PRESET_HELPER
echo ""
