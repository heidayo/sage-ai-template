#!/usr/bin/env bash
# =============================================================================
# TASK-0036: block-dangerous-commands.sh
# Purpose:  PreToolUse hook (Bash matcher) — block dangerous shell commands
# Profile:  standard+ (skipped if profile is "minimal")
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

if [ "$PROFILE" = "minimal" ]; then
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
if echo "$COMMAND" | grep -qE 'git\s+push\s+.*(\-\-force|\-f)'; then
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

# All checks passed
exit 0
