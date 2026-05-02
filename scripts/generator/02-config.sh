# shellcheck shell=bash
# Module 02: .sage/config.yaml + claude/agents snippets + commit hook (SPEC-0014)
# Sourced by scripts/generate-installer.sh — depends on embed_file function.
# Do not chmod +x; do not run standalone.

embed_file "TMPL_CONFIG" "$ROOT/.sage/config.yaml"
echo ""
embed_file "TMPL_CLAUDE_SNIPPET" "$ROOT/templates/claude-md-snippet.md"
echo ""
embed_file "TMPL_AGENTS_SNIPPET" "$ROOT/templates/agents-md-snippet.md"
echo ""
embed_file "TMPL_COMMIT_HOOK" "$ROOT/templates/pre-commit-task-id.sh"
echo ""
