#!/bin/bash
# SAGE pre-commit hook: Require TASK-ID in commit messages
# Installed by sage-adopt.sh
# Lanes: explore (vibe/*) = exempt, lite/standard/promotion = required

COMMIT_MSG_FILE="$1"
COMMIT_MSG=$(cat "$COMMIT_MSG_FILE")

# Allow merge commits, rebases, and amends
if echo "$COMMIT_MSG" | grep -qE "^(Merge|Revert|fixup!|squash!)"; then
  exit 0
fi

# Detect current branch
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)

# --- Lane: explore (vibe/*) — TASK-ID not required ---
if echo "$BRANCH" | grep -qE "^vibe/"; then
  exit 0
fi

# --- Lane: lite (fix/*, chore/*, docs/*) — TASK-ID required + constraints ---
if echo "$BRANCH" | grep -qE "^(fix|chore|docs)/"; then
  # Enforce max file count (default 3)
  MAX_FILES=3
  if [ -f ".sage/config.yaml" ]; then
    CONFIG_MAX=$(grep -A5 'lite:' .sage/config.yaml 2>/dev/null | grep 'max_files:' | awk '{print $2}' || echo "")
    [ -n "$CONFIG_MAX" ] && MAX_FILES="$CONFIG_MAX"
  fi

  CHANGED_FILE_COUNT=$(git diff --cached --name-only | wc -l | tr -d ' ')
  if [ "$CHANGED_FILE_COUNT" -gt "$MAX_FILES" ]; then
    echo ""
    echo "  SAGE: lite lane allows max $MAX_FILES files, but $CHANGED_FILE_COUNT staged"
    echo "  Switch to a feature/* branch for larger changes."
    echo ""
    exit 1
  fi

  # Enforce no contract changes (API/DB/event schema)
  CONTRACT_CHANGES=$(git diff --cached --name-only | grep -cE "(openapi|swagger|schema|migration|\.proto|\.graphql|\.avsc)" || echo "0")
  if [ "$CONTRACT_CHANGES" -gt 0 ]; then
    echo ""
    echo "  SAGE: lite lane prohibits contract changes (API/DB/event schema)"
    echo "  Detected $CONTRACT_CHANGES contract file(s) in staging."
    echo "  Switch to a feature/* branch for contract changes."
    echo ""
    exit 1
  fi
fi

# --- Lane: promotion (promote/*) — TASK-ID required ---
# --- Lane: standard (feature/*, others) — TASK-ID required ---

# --- SPEC-0027: TASK-ID acceptance pattern (config-first, embedded fallback) ---
# This hook is a standalone distribution artifact: it must work without
# scripts/sage-id-pattern.sh. The embedded fallback below must stay identical
# to the loader's fallback definition (INV-03). If .sage/id-patterns.json is
# readable, its task.accept patterns take precedence (FR-06). Config values
# are only ever used as grep -E pattern arguments — never evaluated (SEC-01).
TASK_ID_PATTERN="TASK-[0-9]{4}"
ID_PATTERNS_FILE=".sage/id-patterns.json"
if [ -f "$ID_PATTERNS_FILE" ]; then
  CFG_JOINED=""
  CFG_COUNT=0
  while IFS= read -r CFG_PAT; do
    [ -n "$CFG_PAT" ] || continue
    # Skip invalid EREs so a broken pattern cannot disable validation (SEC-03)
    printf '' | grep -E -- "$CFG_PAT" > /dev/null 2>&1
    if [ $? -ge 2 ]; then
      echo "WARN: pre-commit-task-id: invalid ERE in $ID_PATTERNS_FILE ignored: $CFG_PAT" >&2
      continue
    fi
    if [ -z "$CFG_JOINED" ]; then
      CFG_JOINED="$CFG_PAT"
    else
      CFG_JOINED="$CFG_JOINED|$CFG_PAT"
    fi
    CFG_COUNT=$((CFG_COUNT + 1))
  done <<EOF_ID_PATTERNS
$(awk -v type="task" '
    intype == 0 && $0 ~ ("\"" type "\"[[:space:]]*:") { intype = 1 }
    intype == 1 && $0 ~ /"accept"[[:space:]]*:/ { inaccept = 1 }
    inaccept == 1 {
      line = $0
      sub(/.*"accept"[[:space:]]*:/, "", line)
      while (match(line, /"[^"]*"/)) {
        printf "%s\n", substr(line, RSTART + 1, RLENGTH - 2)
        line = substr(line, RSTART + RLENGTH)
      }
      if (line ~ /\]/) { intype = 0; inaccept = 0 }
    }
  ' "$ID_PATTERNS_FILE" 2>/dev/null)
EOF_ID_PATTERNS
  if [ "$CFG_COUNT" -eq 1 ]; then
    TASK_ID_PATTERN="$CFG_JOINED"
  elif [ "$CFG_COUNT" -gt 1 ]; then
    TASK_ID_PATTERN="($CFG_JOINED)"
  fi
  # CFG_COUNT=0 (unparsable/missing/empty accept) => keep embedded fallback
fi

# All non-explore lanes require TASK-ID
if ! echo "$COMMIT_MSG" | grep -qE "$TASK_ID_PATTERN"; then
  # Determine lane for helpful error message
  LANE="standard"
  if echo "$BRANCH" | grep -qE "^(fix|chore|docs)/"; then
    LANE="lite"
  elif echo "$BRANCH" | grep -qE "^promote/"; then
    LANE="promotion"
  fi

  echo ""
  echo "  SAGE: commit message must include a TASK-ID"
  echo "  Current lane: $LANE (branch: $BRANCH)"
  echo "  Example: TASK-0001: add login endpoint"
  echo ""
  if [ "$LANE" = "lite" ]; then
    echo "  Lite lane still requires TASK-ID for traceability."
    echo "  Generate one with: bash scripts/sage-id-gen.sh task"
  elif [ "$LANE" = "promotion" ]; then
    echo "  Promotion lane requires TASK-ID + Retro-SPEC."
    echo "  Run: bash scripts/sage-promote.sh <vibe-branch>"
  else
    echo "  If this is a prototype, use a vibe/* branch."
  fi
  echo ""
  exit 1
fi
