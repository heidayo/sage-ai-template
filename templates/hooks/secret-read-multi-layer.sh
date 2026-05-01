#!/usr/bin/env bash
# =============================================================================
# TASK-0108 (SPEC-0012 Phase 2B): secret-read-multi-layer.sh
# Purpose:  PreToolUse hook (Bash matcher) — close the gap that Phase 1
#           SECURITY.md disclosed: `Read(./.env)` deny does not stop a Bash
#           subprocess like `cat .env`. This hook blocks Bash-side reads of
#           secret-bearing files and environment variable filtering.
#
# Profile:  standard+ (skipped if profile is "minimal" or "none")
# Behavior: Reads JSON from stdin. Returns exit 2 with stderr message when
#           the command would expose secrets. Honors .env.example /
#           .env.sample / .env.template as a non-secret allowlist.
#
# Reference: Phase 1 SECURITY.md §3 ("Read deny does not cover Bash subprocess")
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

# --- Read stdin ---
INPUT=""
if ! read -r -t 1 INPUT; then
  exit 0
fi
[ -z "$INPUT" ] && exit 0

# --- Parse command ---
COMMAND=""
if command -v jq &>/dev/null; then
  COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null || true)
else
  COMMAND=$(echo "$INPUT" | grep -o '"command"[[:space:]]*:[[:space:]]*"[^"]*"' 2>/dev/null | head -1 | sed 's/.*"command"[[:space:]]*:[[:space:]]*"//;s/"$//' || true)
fi
[ -z "$COMMAND" ] && exit 0

# --- Allowlist: .env templates that contain placeholders, not real secrets ---
# If EVERY referenced .env-like path is a known template, allow.
ALLOWLIST_RE='\.env\.(example|sample|template)$'

# --- Block patterns ---

# Pattern A: read tools (cat/less/head/tail/grep/rg/ag/view/nl/od/xxd/more)
# whose argument matches a secret-bearing path. We exclude allowlisted
# .env templates by checking them first.
SECRET_PATH_RE='(\.env(\.local|\.production|\.prod|-prod)?|/\.env(\.local|\.production|\.prod|-prod)?|secrets/[^[:space:]]+|[^[:space:]]+\.pem|[^[:space:]]+\.key|id_rsa|\.aws/credentials|gcloud[^[:space:]]*credentials[^[:space:]]*\.json|\.ssh/id_[a-z]+)'

# Step 1: extract argument tokens that look like secret paths.
# Step 2: if at least one is NOT in the allowlist, block.
read_tool_re='(^|[[:space:];&|])(cat|less|more|head|tail|grep|rg|ag|view|nl|od|xxd)([[:space:]]+-[a-zA-Z0-9-]+)*[[:space:]]+'

if echo "$COMMAND" | grep -qE "${read_tool_re}[^|;&]*${SECRET_PATH_RE}"; then
  # Check allowlist: extract all secret-like path tokens. The previous
  # version used `[^[:space:]|;&]+(...)` which required >= 1 prefix char
  # and therefore failed for the common `cat .env` form (the path starts
  # right after a space). Use `[^[:space:]|;&]*` so 0 prefix chars are OK.
  matched_paths=$(echo "$COMMAND" | grep -oE "[^[:space:]|;&]*${SECRET_PATH_RE}[^[:space:]|;&]*" || true)
  any_real_secret=false
  while IFS= read -r path; do
    [ -z "$path" ] && continue
    if ! echo "$path" | grep -qE "$ALLOWLIST_RE"; then
      any_real_secret=true
      break
    fi
  done <<< "$matched_paths"

  if [ "$any_real_secret" = "true" ]; then
    echo "BLOCKED: Bash command reads a secret-bearing path." >&2
    echo "Matched paths: $(echo "$matched_paths" | tr '\n' ' ')" >&2
    echo "Reference: SECURITY.md §3 — Bash subprocess bypass of Read() deny" >&2
    echo "Allowlist exemption: .env.example / .env.sample / .env.template only." >&2
    exit 2
  fi
fi

# Pattern B: environment-variable filtering for secret keys.
# `printenv | grep KEY`, `env | grep TOKEN`, `set | grep SECRET`, etc.
if echo "$COMMAND" | grep -qE '(^|[[:space:];&|])(printenv|env|set)([[:space:]]+[^|]*)?[[:space:]]*\|[[:space:]]*(grep|rg|ag)[[:space:]][^|;&]*(KEY|TOKEN|SECRET|API_KEY|PASSWORD|PASSWD|CREDENTIAL)'; then
  echo "BLOCKED: Bash pipe filters environment variables for secret keys." >&2
  echo "Pattern: printenv|env|set | grep KEY|TOKEN|SECRET|API_KEY|PASSWORD|CREDENTIAL" >&2
  echo "Reference: SECURITY.md §3 — environment-variable secret read" >&2
  exit 2
fi

# All checks passed
exit 0
