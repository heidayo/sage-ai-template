#!/usr/bin/env bash
# =============================================================================
# TASK-0107 (SPEC-0012 Phase 2B): lethal-trifecta-detect.sh
# Purpose:  PreToolUse hook (Bash + Read matcher) — warn when Simon Willison's
#           Lethal Trifecta surfaces:
#             1. Private data was read recently (TTL 5 min via state file)
#             2. Current input cites untrusted external content
#             3. Current input has an exfiltration vector
#           If >= 2 of 3 conditions hold, emit WARN to stderr. Exit code is
#           ALWAYS 0 — this hook MUST NOT block (Codex review R3).
#
# Profile:  standard+ (skipped if profile is "minimal" or "none")
# Behavior: Reads JSON from stdin. Updates .sage/runtime/lethal-trifecta-state.json
#           when private-data read is detected, with 5-minute TTL.
#
# Reference: https://airia.com/ai-security-in-2026-prompt-injection-the-lethal-trifecta-and-how-to-defend/
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

# --- Parse tool_name / tool_input ---
TOOL_NAME=""
COMMAND=""
FILE_PATH=""
if command -v jq &>/dev/null; then
  TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null || true)
  COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null || true)
  FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null || true)
else
  # Best-effort grep fallback (skip detection rather than risk a false WARN).
  exit 0
fi

# --- State file: last_private_read timestamp (epoch seconds) ---
STATE_DIR=".sage/runtime"
STATE_FILE="${STATE_DIR}/lethal-trifecta-state.json"
TTL_SECONDS=300  # 5 minutes

now_epoch() { date -u +%s; }

read_last_private_epoch() {
  if [ ! -f "$STATE_FILE" ]; then
    echo "0"; return
  fi
  if command -v jq &>/dev/null; then
    jq -r '.last_private_read_epoch // 0' "$STATE_FILE" 2>/dev/null || echo "0"
  else
    echo "0"
  fi
}

write_last_private_epoch() {
  local ts="$1"
  mkdir -p "$STATE_DIR" 2>/dev/null || return 0
  # Atomic write via mktemp + mv. Failure is non-fatal (hook still exits 0).
  local tmp
  tmp=$(mktemp "${STATE_DIR}/lethal-trifecta-state.XXXXXX" 2>/dev/null) || return 0
  printf '{"last_private_read_epoch": %s}\n' "$ts" > "$tmp" 2>/dev/null && mv "$tmp" "$STATE_FILE" 2>/dev/null || rm -f "$tmp" 2>/dev/null
}

# --- Detection: did the current operation read private data? ---
PRIVATE_PATH_RE='(\.env(\.[a-z]+)?$|/\.env(\.[a-z]+)?$|~/\.ssh/|~/\.aws/|/secrets/|\.pem$|\.key$|id_rsa|\.aws/credentials|gcloud.*credentials.*\.json)'

current_reads_private=false
case "$TOOL_NAME" in
  Read)
    if echo "$FILE_PATH" | grep -qE "$PRIVATE_PATH_RE"; then
      current_reads_private=true
    fi
    ;;
  Bash)
    # cat/less/head/tail/grep/printenv|env on private targets
    if echo "$COMMAND" | grep -qE "(cat|less|more|head|tail|grep|rg|ag|view|nl)[[:space:]][^|;&]*$PRIVATE_PATH_RE"; then
      current_reads_private=true
    elif echo "$COMMAND" | grep -qE '(printenv|env|set)[[:space:]]*\|[[:space:]]*(grep|rg|ag)[[:space:]][^|;&]*(KEY|TOKEN|SECRET|API_KEY|PASSWORD|PASSWD)'; then
      current_reads_private=true
    fi
    ;;
esac

if [ "$current_reads_private" = "true" ]; then
  write_last_private_epoch "$(now_epoch)"
fi

# --- Condition 1: T_PRIVATE — was private data read in the last TTL window? ---
T_PRIVATE=false
last_private=$(read_last_private_epoch)
if [ "$last_private" -gt 0 ] 2>/dev/null; then
  age=$(( $(now_epoch) - last_private ))
  if [ "$age" -ge 0 ] && [ "$age" -le "$TTL_SECONDS" ]; then
    T_PRIVATE=true
  fi
fi

# --- Condition 2: T_UNTRUSTED — current input cites untrusted external content ---
T_UNTRUSTED=false
case "$TOOL_NAME" in
  WebFetch|WebSearch)
    T_UNTRUSTED=true
    ;;
  Bash)
    if echo "$COMMAND" | grep -qE '(https?://|gh[[:space:]]+(issue|pr)[[:space:]]+view|gh[[:space:]]+issue[[:space:]]+list|gh[[:space:]]+pr[[:space:]]+list|curl[[:space:]]+https?://)'; then
      T_UNTRUSTED=true
    fi
    ;;
esac

# --- Condition 3: T_EXFIL — current command has an exfiltration vector ---
T_EXFIL=false
if [ "$TOOL_NAME" = "Bash" ]; then
  if echo "$COMMAND" | grep -qE '(curl[[:space:]]+([^|;&]*-X[[:space:]]+(POST|PUT|PATCH|DELETE)|[^|;&]*--data|[^|;&]*-d[[:space:]])|wget[[:space:]]+[^|;&]*--post-data|webhook\.site|(^|[[:space:];&|])nc[[:space:]]+[a-zA-Z0-9.-]+[[:space:]]+[0-9]+|(^|[[:space:];&|])(mail|mailx|sendmail)[[:space:]]|aws[[:space:]]+sns[[:space:]]+publish|slack-send)'; then
    T_EXFIL=true
  fi
fi

# --- Tally and warn ---
trifecta_count=0
[ "$T_PRIVATE"   = "true" ] && trifecta_count=$((trifecta_count + 1))
[ "$T_UNTRUSTED" = "true" ] && trifecta_count=$((trifecta_count + 1))
[ "$T_EXFIL"     = "true" ] && trifecta_count=$((trifecta_count + 1))

if [ "$trifecta_count" -ge 2 ]; then
  echo "WARN: lethal trifecta condition detected (${trifecta_count}/3)" >&2
  [ "$T_PRIVATE"   = "true" ] && echo "  - private-data read within last ${TTL_SECONDS}s" >&2
  [ "$T_UNTRUSTED" = "true" ] && echo "  - untrusted external content cited in this input" >&2
  [ "$T_EXFIL"     = "true" ] && echo "  - exfiltration vector present in this command" >&2
  echo "Reference: https://airia.com/ai-security-in-2026-prompt-injection-the-lethal-trifecta-and-how-to-defend/" >&2
  echo "This is a WARN — the operation is NOT blocked. Review before proceeding." >&2
fi

# Always allow — this hook never blocks (Codex review R3).
exit 0
