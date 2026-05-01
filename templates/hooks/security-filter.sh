#!/usr/bin/env bash
# =============================================================================
# TASK-0109 (SPEC-0012 Phase 2B): security-filter.sh
# Purpose:  Stop hook — redact API keys / tokens / JWTs in ALL .sage/runs/
#           RUN-*.yaml files so that RUN logs do not themselves become a
#           secret-leak vector. Prerequisite for the future RUN-log
#           indexing work (Codex review R5: redaction first, SQLite/FTS
#           later).
#
# Profile:  standard+ (skipped if profile is "minimal" or "none")
# Behavior: Reads JSON from stdin (Stop payload — Claude Code's official
#           hook event name is "Stop", not "SessionStop"). Iterates over
#           every RUN-*.yaml under .sage/runs/ and applies redaction via
#           atomic write (mktemp + mv). Failure on any single file
#           preserves that file; sibling files still get processed.
#           Idempotent: lines that already contain ***REDACTED*** are
#           not re-processed.
#
# TASK-0112 (Codex review P2 #5): originally only the newest RUN-*.yaml
#   was scanned. Multiple RUN logs in a single session left older ones
#   un-redacted. Now scans all of them.
# TASK-0112 (Codex review P3 #6): renamed comment from "SessionStop" to
#   "Stop" to match the Claude Code official hook event name.
#
# Reference: Codex review R5 / Cluster I (security-filter proposal)
# =============================================================================
set -uo pipefail

# --- Profile gating ---
PROFILE="standard"
if [ -f ".sage/config.yaml" ]; then
  PROFILE=$(grep -A1 'hooks:' .sage/config.yaml 2>/dev/null | grep 'profile:' | awk '{print $2}' | tr -d '"' || echo "standard")
  [ -z "$PROFILE" ] && PROFILE="standard"
fi
if [ "$PROFILE" = "minimal" ] || [ "$PROFILE" = "none" ]; then
  exit 0
fi

# Drain stdin (Stop payload — we don't actually need it, but read it to
# avoid SIGPIPE from the caller).
if read -r -t 1 _input 2>/dev/null; then :; fi

RUNS_DIR=".sage/runs"
[ -d "$RUNS_DIR" ] || exit 0

# TASK-0112 (Codex review P2 #5): redact ALL RUN-*.yaml files. The
# previous newest-only behavior left older files un-redacted when
# multiple runs happened in the same session.
TARGETS=$(find "$RUNS_DIR" -maxdepth 1 -type f -name 'RUN-*.yaml' -print 2>/dev/null)
[ -z "$TARGETS" ] && exit 0

# --- Build redaction sed expressions ---
# Patterns:
#   1. sk-[A-Za-z0-9_-]{32,}     OpenAI / Anthropic style
#   2. ghp_[A-Za-z0-9]{36}       GitHub PAT (classic)
#   3. gho_[A-Za-z0-9]{36}       GitHub OAuth
#   4. github_pat_[A-Za-z0-9_]{82}  GitHub fine-grained PAT
#   5. xox[abp]-[A-Za-z0-9-]+    Slack
#   6. AKIA[0-9A-Z]{16}          AWS Access Key
#   7. eyJ[...]\.[...]\.[...]    JWT 3-part
#   8. YAML field where key matches (api[_-]?key|token|secret|password|jwt)
#      with a 20+ char value: replace value only.
#
# All replacements use the literal placeholder ***REDACTED***.
PLACEHOLDER='***REDACTED***'

# Per-file temp tracker so trap cleans up whichever file we're in the
# middle of when an interrupt arrives.
CURRENT_TMP=""
cleanup() {
  if [ -n "$CURRENT_TMP" ] && [ -f "$CURRENT_TMP" ]; then
    rm -f "$CURRENT_TMP"
  fi
}
trap cleanup EXIT

# Loop over each target. Failure on a single file is logged-via-skip
# (we just leave that one alone) but does not block sibling files or
# cause the hook to fail (Stop hooks must always exit 0).
process_one() {
  local target="$1"
  CURRENT_TMP=$(mktemp "${target}.redact.XXXXXX") || return 0

  if ! awk -v PH="$PLACEHOLDER" '
  {
    line = $0

    # 1. sk-... (32+ chars, alphanumeric + _ -)
    while (match(line, /sk-[A-Za-z0-9_-]{32,}/)) {
      line = substr(line, 1, RSTART-1) PH substr(line, RSTART+RLENGTH)
    }

    # 2-3. GitHub PATs / OAuth (36 chars)
    while (match(line, /gh[po]_[A-Za-z0-9]{36}/)) {
      line = substr(line, 1, RSTART-1) PH substr(line, RSTART+RLENGTH)
    }

    # 4. GitHub fine-grained PAT (github_pat_ + ~82 chars)
    while (match(line, /github_pat_[A-Za-z0-9_]{20,}/)) {
      line = substr(line, 1, RSTART-1) PH substr(line, RSTART+RLENGTH)
    }

    # 5. Slack tokens
    while (match(line, /xox[abp]-[A-Za-z0-9-]{8,}/)) {
      line = substr(line, 1, RSTART-1) PH substr(line, RSTART+RLENGTH)
    }

    # 6. AWS Access Key
    while (match(line, /AKIA[0-9A-Z]{16}/)) {
      line = substr(line, 1, RSTART-1) PH substr(line, RSTART+RLENGTH)
    }

    # 7. JWT (3-part base64 separated by .)
    while (match(line, /eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}/)) {
      line = substr(line, 1, RSTART-1) PH substr(line, RSTART+RLENGTH)
    }

    # 8. YAML secret-bearing field. Examples:
    #     api_key: "abcdefghijklmnopqrst"
    #     token: VeryLongSecretValueAlphanumeric20
    #   Match key (case-insensitive) followed by colon and a value of
    #   20+ alphanumeric chars (with optional surrounding quotes).
    #   Skip lines already containing the placeholder (idempotency).
    if (line !~ /\*\*\*REDACTED\*\*\*/) {
      if (match(line, /^[[:space:]]*-?[[:space:]]*[Aa][Pp][Ii][_-]?[Kk][Ee][Yy][[:space:]]*:[[:space:]]*"?[A-Za-z0-9_+\/=.-]{20,}"?/)) {
        sub(/[A-Za-z0-9_+\/=.-]{20,}/, PH, line)
      } else if (match(line, /^[[:space:]]*-?[[:space:]]*[Tt][Oo][Kk][Ee][Nn][[:space:]]*:[[:space:]]*"?[A-Za-z0-9_+\/=.-]{20,}"?/)) {
        sub(/[A-Za-z0-9_+\/=.-]{20,}/, PH, line)
      } else if (match(line, /^[[:space:]]*-?[[:space:]]*[Ss][Ee][Cc][Rr][Ee][Tt][[:space:]]*:[[:space:]]*"?[A-Za-z0-9_+\/=.-]{20,}"?/)) {
        sub(/[A-Za-z0-9_+\/=.-]{20,}/, PH, line)
      } else if (match(line, /^[[:space:]]*-?[[:space:]]*[Pp][Aa][Ss][Ss][Ww][Oo]?[Rr]?[Dd][[:space:]]*:[[:space:]]*"?[A-Za-z0-9_+\/=.-]{20,}"?/)) {
        sub(/[A-Za-z0-9_+\/=.-]{20,}/, PH, line)
      } else if (match(line, /^[[:space:]]*-?[[:space:]]*[Jj][Ww][Tt][[:space:]]*:[[:space:]]*"?[A-Za-z0-9_+\/=.-]{20,}"?/)) {
        sub(/[A-Za-z0-9_+\/=.-]{20,}/, PH, line)
      }
    }

    print line
  }
' "$target" > "$CURRENT_TMP" 2>/dev/null; then
    # awk failed for this target — keep original, move on.
    rm -f "$CURRENT_TMP"
    CURRENT_TMP=""
    return 0
  fi

  # Atomic replace.
  mv "$CURRENT_TMP" "$target" 2>/dev/null || rm -f "$CURRENT_TMP"
  CURRENT_TMP=""
  return 0
}

while IFS= read -r target; do
  [ -z "$target" ] && continue
  [ -f "$target" ] || continue
  process_one "$target"
done <<< "$TARGETS"

exit 0
