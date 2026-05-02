# shellcheck shell=bash
# Module 05: Phase 2B hooks + sandbox/settings (SPEC-0014)
# Sourced by scripts/generate-installer.sh — depends on embed_file function.
# Do not chmod +x; do not run standalone.

# Phase 2B (SPEC-0012) hooks
embed_file "TMPL_HOOK_LETHAL_TRIFECTA" "$ROOT/templates/hooks/lethal-trifecta-detect.sh"
echo ""
embed_file "TMPL_HOOK_SECRET_READ" "$ROOT/templates/hooks/secret-read-multi-layer.sh"
echo ""
embed_file "TMPL_HOOK_SECURITY_FILTER" "$ROOT/templates/hooks/security-filter.sh"
echo ""
