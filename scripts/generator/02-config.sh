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
