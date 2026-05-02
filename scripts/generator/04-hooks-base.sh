# Module 04: Phase 1-2A hooks (block-dangerous / protect-sage / check-file-scope / session-*) (SPEC-0014)
# Sourced by scripts/generate-installer.sh — depends on embed_file function.
# Do not chmod +x; do not run standalone.

embed_file "TMPL_HOOK_BLOCK_DANGEROUS" "$ROOT/templates/hooks/block-dangerous-commands.sh"
echo ""
embed_file "TMPL_HOOK_PROTECT_SAGE" "$ROOT/templates/hooks/protect-sage-files.sh"
echo ""
embed_file "TMPL_HOOK_CHECK_SCOPE" "$ROOT/templates/hooks/check-file-scope.sh"
echo ""
embed_file "TMPL_HOOK_SESSION_START" "$ROOT/templates/hooks/session-start.sh"
echo ""
embed_file "TMPL_HOOK_SESSION_STOP" "$ROOT/templates/hooks/session-stop.sh"
echo ""
