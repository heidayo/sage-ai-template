#!/usr/bin/env bash
# =============================================================================
# TASK-0109 (SPEC-0012 Phase 2B): security-filter.sh
# Purpose:  SessionStop hook — redact API keys / tokens / JWTs in the most
#           recently written .sage/runs/RUN-*.yaml so that RUN logs do not
#           themselves become a secret-leak vector. Prerequisite for the
#           future RUN-log indexing work (Codex review R5: redaction first,
#           SQLite/FTS later).
#
# Profile:  standard+ (skipped if profile is "minimal" or "none")
# Behavior: Reads JSON from stdin (SessionStop payload). Picks the newest
#           RUN-*.yaml under .sage/runs/. Replaces matched secret values
#           with "***REDACTED***" via atomic write (mktemp + mv). Failure
#           preserves the original file. Idempotent.
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

# Drain stdin (SessionStop payload — we don't actually need it, but
# read it to avoid SIGPIPE from the caller).
if read -r -t 1 _input 2>/dev/null; then :; fi

RUNS_DIR=".sage/runs"
[ -d "$RUNS_DIR" ] || exit 0

# Find the most recently modified RUN-*.yaml.
# Use find with -newer chained against /tmp/.sage-filter-marker if it
# exists, else fall back to ls -t. Keep portable across BSD/GNU tools.
NEWEST=""
if command -v find &>/dev/null; then
  # POSIX-portable: list candidates, sort by mtime via stat, take newest.
  NEWEST=$(find "$RUNS_DIR" -maxdepth 1 -type f -name 'RUN-*.yaml' -print 2>/dev/null \
    | while IFS= read -r f; do
        # Try GNU stat then BSD stat for mtime epoch.
        ts=$(stat -c '%Y' "$f" 2>/dev/null || stat -f '%m' "$f" 2>/dev/null || echo 0)
        printf '%s\t%s\n' "$ts" "$f"
      done \
    | sort -nr \
    | head -1 \
    | cut -f2-)
fi

[ -z "$NEWEST" ] && exit 0
[ -f "$NEWEST" ] || exit 0

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

TMP=""
cleanup() {
  if [ -n "$TMP" ] && [ -f "$TMP" ]; then
    rm -f "$TMP"
  fi
}
trap cleanup EXIT

TMP=$(mktemp "${NEWEST}.redact.XXXXXX") || exit 0

# Use awk for atomic-ish processing: read original line by line, apply
# substitutions, write to TMP. Failure on stat or awk preserves NEWEST.
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
' "$NEWEST" > "$TMP" 2>/dev/null; then
  # awk failed — keep original.
  exit 0
fi

# Atomic replace.
mv "$TMP" "$NEWEST" 2>/dev/null || exit 0
TMP=""  # successfully consumed

exit 0
