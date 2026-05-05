# shellcheck shell=bash
# Module 06: Phase 5+ hooks + audit + scripts + tests (SPEC-0014)
# Sourced by scripts/generate-installer.sh — depends on embed_file function.
# Do not chmod +x; do not run standalone.

# Phase 5 (SPEC-0015) MCP allowlist audit hook + registry template + perf helper
embed_file "TMPL_HOOK_MCP_ALLOWLIST_AUDIT" "$ROOT/templates/hooks/mcp-allowlist-audit.sh"
echo ""
embed_file "TMPL_SAGE_MCP_ALLOWLIST_TEMPLATE" "$ROOT/templates/sage/mcp-allowlist-template.json"
echo ""
embed_file "TMPL_SAGE_README" "$ROOT/templates/sage/README.md"
echo ""
embed_file "TMPL_TEST_MCP_ALLOWLIST" "$ROOT/templates/hooks/tests/test-mcp-allowlist-audit.sh"
echo ""
embed_file "TMPL_TEST_DETECTION_ONLY" "$ROOT/templates/hooks/tests/test-detection-only-behavior.sh"
echo ""
embed_file "TMPL_MEASURE_HOOK_TIME" "$ROOT/templates/hooks/tests/measure-hook-time.py"
echo ""
embed_file "TMPL_SCRIPT_MCP_ALLOWLIST_AUDIT" "$ROOT/scripts/sage-mcp-allowlist-audit.sh"
echo ""
# Phase 5+ (SPEC-0017) agent identity inventory + validator extension + audit script
embed_file "TMPL_SAGE_AGENT_INVENTORY" "$ROOT/templates/sage/agent-inventory-template.yaml"
echo ""
embed_file "TMPL_TEST_AGENT_INVENTORY" "$ROOT/templates/hooks/tests/test-agent-inventory-validator.sh"
echo ""
embed_file "TMPL_SCRIPT_AGENT_INVENTORY" "$ROOT/scripts/sage-agent-inventory-audit.sh"
echo ""
# Phase 5+ (SPEC-0016) RUN log SQLite-FTS indexer + search + db audit + tests
embed_file "TMPL_SCRIPT_RUNLOG_INDEX" "$ROOT/scripts/sage-runlog-index.sh"
echo ""
embed_file "TMPL_SCRIPT_RUNLOG_SEARCH" "$ROOT/scripts/sage-runlog-search.sh"
echo ""
embed_file "TMPL_SCRIPT_RUNLOG_DB_AUDIT" "$ROOT/scripts/sage-runlog-db-audit.sh"
echo ""
embed_file "TMPL_TEST_RUNLOG_INDEX" "$ROOT/templates/hooks/tests/test-runlog-index.sh"
echo ""
embed_file "TMPL_TEST_RUNLOG_SEARCH" "$ROOT/templates/hooks/tests/test-runlog-search.sh"
echo ""
embed_file "TMPL_TEST_RUNLOG_DB_DOCTOR" "$ROOT/templates/hooks/tests/test-runlog-db-doctor.sh"
echo ""
# Phase 6.x (SPEC-0024) Property-based Verify hook test
embed_file "TMPL_TEST_PROPERTY_SECTION" "$ROOT/templates/hooks/tests/test-property-section.sh"
echo ""
# Phase 2B (SPEC-0012) settings template (Claude Code sandbox doctrine)
embed_file "TMPL_SETTINGS_SANDBOX" "$ROOT/templates/settings/sandbox.json"
echo ""
embed_file "TMPL_SETTINGS_README" "$ROOT/templates/settings/README.md"
echo ""
# Settings.json template with hooks
embed_file "TMPL_SETTINGS_JSON" "$ROOT/.claude/settings.json"
echo ""
