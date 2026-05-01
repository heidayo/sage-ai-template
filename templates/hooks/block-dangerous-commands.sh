#!/usr/bin/env bash
# =============================================================================
# TASK-0036: block-dangerous-commands.sh
# Purpose:  PreToolUse hook (Bash matcher) — block dangerous shell commands
# Profile:  standard+ (skipped if profile is "minimal" or "none")
# Behavior: Reads JSON from stdin with tool_name and tool_input.command.
#           Blocks patterns: --no-verify, git push --force/-f, rm -rf /|~|.
#           Exit 0 = allow/warn, Exit 2 = block
# =============================================================================
set -euo pipefail

# --- Profile gating ---
PROFILE="standard"
if [ -f ".sage/config.yaml" ]; then
  PROFILE=$(grep -A1 'hooks:' .sage/config.yaml 2>/dev/null | grep 'profile:' | awk '{print $2}' | tr -d '"' || echo "standard")
  [ -z "$PROFILE" ] && PROFILE="standard"
fi

if [ "$PROFILE" = "minimal" ] || [ "$PROFILE" = "none" ]; then
  exit 0
fi

# --- Read stdin (JSON) ---
INPUT=""
if ! read -r -t 1 INPUT; then
  # Empty stdin or read timeout — never block
  exit 0
fi

if [ -z "$INPUT" ]; then
  exit 0
fi

# --- Parse command from JSON ---
COMMAND=""
if command -v jq &>/dev/null; then
  COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null || true)
else
  # grep fallback: extract command value from JSON
  COMMAND=$(echo "$INPUT" | grep -o '"command"[[:space:]]*:[[:space:]]*"[^"]*"' 2>/dev/null | head -1 | sed 's/.*"command"[[:space:]]*:[[:space:]]*"//;s/"$//' || true)
fi

if [ -z "$COMMAND" ]; then
  # Could not parse command — never block
  exit 0
fi

# --- Check for dangerous patterns ---

# Pattern: --no-verify (bypasses git hooks)
if echo "$COMMAND" | grep -qE '\-\-no-verify'; then
  echo "BLOCKED: Command contains --no-verify which bypasses git hooks." >&2
  echo "Suggestion: Remove --no-verify to ensure quality gates are enforced." >&2
  exit 2
fi

# Pattern: git push --force or git push -f (destructive force push)
if echo "$COMMAND" | grep -qE 'git[[:space:]]+push' && echo "$COMMAND" | grep -qE '(^|[[:space:]])(--force|-f)($|[[:space:]])'; then
  echo "BLOCKED: Force push detected (git push --force/-f)." >&2
  echo "Suggestion: Use 'git push --force-with-lease' for safer force pushing." >&2
  exit 2
fi

# Pattern: rm -rf / (wipe root)
if echo "$COMMAND" | grep -qE 'rm\s+(-[a-zA-Z]*r[a-zA-Z]*f[a-zA-Z]*|(-[a-zA-Z]*f[a-zA-Z]*r[a-zA-Z]*))\s+/\s*$'; then
  echo "BLOCKED: 'rm -rf /' would destroy the entire filesystem." >&2
  echo "Suggestion: Specify a safe, scoped path instead." >&2
  exit 2
fi

# Pattern: rm -rf ~ (wipe home directory)
if echo "$COMMAND" | grep -qE 'rm\s+(-[a-zA-Z]*r[a-zA-Z]*f[a-zA-Z]*|(-[a-zA-Z]*f[a-zA-Z]*r[a-zA-Z]*))\s+~'; then
  echo "BLOCKED: 'rm -rf ~' would destroy your home directory." >&2
  echo "Suggestion: Specify a safe, scoped path instead." >&2
  exit 2
fi

# Pattern: rm -rf . (wipe current directory)
if echo "$COMMAND" | grep -qE 'rm\s+(-[a-zA-Z]*r[a-zA-Z]*f[a-zA-Z]*|(-[a-zA-Z]*f[a-zA-Z]*r[a-zA-Z]*))\s+\.\s*$'; then
  echo "BLOCKED: 'rm -rf .' would destroy the current directory." >&2
  echo "Suggestion: Specify a safe, scoped path instead." >&2
  exit 2
fi

# Pattern: git add -f .DS_Store (re-track an ignored macOS metadata file)
# .DS_Store is in .gitignore; force-adding it reintroduces the ignored/tracked
# contradiction TASK-0086 removed. Accepts -f, --force, and bundled short flags
# like -af where f is part of a short-option cluster.
if echo "$COMMAND" | grep -qE 'git[[:space:]]+add[^|;&]*\.DS_Store' && \
   echo "$COMMAND" | grep -qE '(-[a-zA-Z]*f[a-zA-Z]*|--force)'; then
  echo "BLOCKED: force-adding .DS_Store would re-track an ignored macOS metadata file." >&2
  echo "Suggestion: .DS_Store is in .gitignore. Do not force-add it." >&2
  exit 2
fi

# --- TASK-0089: expanded destructive command patterns ---

# Pattern: find targeting root/home/cwd with -delete (mass file removal)
if echo "$COMMAND" | grep -qE 'find[[:space:]]+(/|~|\.)[^|]*-delete\b'; then
  echo "BLOCKED: 'find ... -delete' on root/home/cwd causes mass file removal." >&2
  echo "Suggestion: Scope the find path narrowly and review matches first." >&2
  exit 2
fi

# Pattern: curl piped directly to shell (remote code execution)
if echo "$COMMAND" | grep -qE 'curl[[:space:]][^|]*\|[[:space:]]*(ba)?sh\b'; then
  echo "BLOCKED: 'curl ... | bash/sh' executes remote code without inspection." >&2
  echo "Suggestion: Download the script, review it, then run locally." >&2
  exit 2
fi

# Pattern: wget piped directly to shell (remote code execution)
if echo "$COMMAND" | grep -qE 'wget[[:space:]][^|]*\|[[:space:]]*(ba)?sh\b'; then
  echo "BLOCKED: 'wget ... | bash/sh' executes remote code without inspection." >&2
  echo "Suggestion: Download the script, review it, then run locally." >&2
  exit 2
fi

# Pattern: python shutil.rmtree (programmatic equivalent of rm -rf)
# Use .* (not [^;&]) because python -c bodies legitimately contain ; to
# chain statements inside a single quoted -c argument.
if echo "$COMMAND" | grep -qE 'python[23]?[[:space:]].*shutil\.rmtree'; then
  echo "BLOCKED: 'python -c ... shutil.rmtree' is the programmatic rm -rf." >&2
  echo "Suggestion: Use a scripted approach with explicit path review." >&2
  exit 2
fi

# Pattern: dd writing to a block device (disk wipe / bootloader overwrite)
if echo "$COMMAND" | grep -qE 'dd[[:space:]][^;&]*of=/dev/[a-z]+[0-9]*'; then
  echo "BLOCKED: 'dd ... of=/dev/<device>' can destroy a disk or partition." >&2
  echo "Suggestion: If intentional, run outside this automated session." >&2
  exit 2
fi

# Pattern: mkfs (filesystem creation wipes the target device)
if echo "$COMMAND" | grep -qE '(^|[[:space:];&|])mkfs(\.[a-z0-9]+)?[[:space:]]'; then
  echo "BLOCKED: 'mkfs' destroys all data on the target device." >&2
  echo "Suggestion: Filesystem creation is not a reversible operation; confirm manually." >&2
  exit 2
fi

# Pattern: recursive chmod with a world-writable mode on a root-like path
if echo "$COMMAND" | grep -qE 'chmod[[:space:]]+(-R|--recursive)[[:space:]][0-7]{0,2}7[0-7]{0,1}[[:space:]]+(/|/[a-zA-Z])'; then
  echo "BLOCKED: 'chmod -R <world-writable> /...' opens filesystem-wide permissions." >&2
  echo "Suggestion: Narrow the target path or pick a safer mode." >&2
  exit 2
fi

# --- TASK-0103 (SPEC-0011): expanded patterns for Phase 2A hardening ---

# Pattern: long subcommand chain (Adversa AI 50+subcommands deny-rule bypass).
# We fail-closed at >= 30 separators (;/&&/||/|), well under the 50 boundary
# in the published research. Counts ALL separators, including backgrounding (&)
# is intentionally excluded to allow benign 'cmd &' usage.
SEPCOUNT=$(printf '%s' "$COMMAND" | tr -cd ';|&' | wc -c | tr -d ' ')
if [ "$SEPCOUNT" -ge 30 ]; then
  echo "BLOCKED: command contains $SEPCOUNT shell separators (;|&), exceeding the chain-length limit of 30." >&2
  echo "Suggestion: Break the command into smaller, reviewable pieces." >&2
  echo "Reference: Adversa AI deny-rule bypass via 50+ subcommands" >&2
  exit 2
fi

# Pattern: redirection write to AI control-plane files.
# Mirrors the CVE-2026-25723 piped-sed bypass class. Catches >, >>, and tee
# variants targeting .claude/, .mcp.json, .codex/, .sage/config.yaml, .git/,
# .github/workflows/.
#
# TASK-0106 (Codex review P1 #2): the previous regex required whitespace
# between the redirect operator and the path AND the leading dot was eaten
# by `\.?`, so common variants slipped through:
#   echo x>.claude/settings.json        (no space)
#   echo x > ./.claude/settings.json    (./ prefix)
#   echo x >./.mcp.json                 (mixed)
#
# Approach: split into two checks — operator-and-target with optional
# whitespace, then the path matcher accepts an optional `./` prefix and
# requires the literal leading `.` of the control-plane filename.
if echo "$COMMAND" | grep -qE '(>>?|tee([[:space:]]+-a)?)[[:space:]]*(\./)?\.(claude/|mcp\.json|codex/config\.toml|sage/config\.yaml|git/|github/workflows/)'; then
  echo "BLOCKED: redirection write to a SAGE / AI control-plane file detected." >&2
  echo "Targets: .claude/, .mcp.json, .codex/config.toml, .sage/config.yaml, .git/, .github/workflows/" >&2
  echo "Reference: NVD CVE-2026-25723 (Claude Code piped-sed bypass class)" >&2
  echo "Suggestion: Edit these files via the Edit/Write tool so protect-sage-files.sh can audit." >&2
  exit 2
fi

# Pattern: interpreter -c / -e with file write to disk.
# Catches python/python3 -c, node -e, ruby -e, perl -e patterns that open a
# file in write/append mode, which would bypass the Edit/Write tool path
# entirely. Conservative regex — only flags explicit 'w' or '>>' modes.
#
# TASK-0106 (Codex review P2 #4): the previous regex used `[\x27"]` which
# in grep -E does NOT expand \x27 to apostrophe — the class became literal
# [\x27"] matching only \, x, 2, 7, ". Single-quoted variants were therefore
# missed:
#   python -c "open('foo','w').write('x')"
#   ruby -e "File.open('foo','w')..."
#   perl -e "open(..., '>foo')"
# The fix uses a literal apostrophe inside a bracket class via `'\''`
# shell-escape pattern, so grep -E sees `['"]`.
SQ="'\''"
if echo "$COMMAND" | grep -qE "python[23]?[[:space:]]+-c[[:space:]].*open\([^)]*[${SQ}\"]w"; then
  echo "BLOCKED: 'python -c ... open(..., \"w\"|'w')' writes a file outside the audited Edit/Write path." >&2
  echo "Suggestion: Use the Edit or Write tool, or run a reviewed script file." >&2
  exit 2
fi
if echo "$COMMAND" | grep -qE 'node[[:space:]]+-e[[:space:]].*(writeFile|createWriteStream|appendFile)'; then
  echo "BLOCKED: 'node -e ... writeFile/createWriteStream/appendFile' writes a file outside the audited path." >&2
  echo "Suggestion: Use the Edit or Write tool, or run a reviewed script file." >&2
  exit 2
fi
if echo "$COMMAND" | grep -qE "ruby[[:space:]]+-e[[:space:]].*File\.open\([^)]*[${SQ}\"](w|a)"; then
  echo "BLOCKED: 'ruby -e ... File.open(..., \"w\"|\"a\"|'w'|'a')' writes a file outside the audited path." >&2
  echo "Suggestion: Use the Edit or Write tool, or run a reviewed script file." >&2
  exit 2
fi
if echo "$COMMAND" | grep -qE "perl[[:space:]]+-e[[:space:]].*open\([^)]*,[[:space:]]*[${SQ}\"]>+"; then
  echo "BLOCKED: 'perl -e ... open(..., \">\"|\">>\"|'>'|'>>')' writes a file outside the audited path." >&2
  echo "Suggestion: Use the Edit or Write tool, or run a reviewed script file." >&2
  exit 2
fi

# Pattern: Unicode obfuscation warning (warn-only, never block).
# BeyondTrust's Codex branch-name-injection report demonstrated that an
# Ideographic Space (U+3000) or zero-width characters can hide payloads in
# what visually looks like 'main'. We warn only because false positives in
# legitimate filenames (e.g. JP project paths) would block real work.
# grep -P with \x notation; falls back to grep silently if -P is unavailable.
if printf '%s' "$COMMAND" | LC_ALL=C grep -qP '[\x{3000}\x{200B}-\x{200F}\x{202A}-\x{202E}\x{2066}-\x{2069}]' 2>/dev/null; then
  echo "WARN: suspicious unicode whitespace / zero-width / bidi character detected in command." >&2
  echo "Reference: BeyondTrust Codex branch-name injection (Unicode obfuscation)" >&2
  # No exit — warning only.
fi

# All checks passed
exit 0
