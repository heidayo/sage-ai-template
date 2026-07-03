#!/bin/bash
# sage-id-pattern.sh — shared ID acceptance pattern loader (SPEC-0027)
#
# Usage (source only — direct execution is unsupported):
#   . scripts/sage-id-pattern.sh
#   sage_id_accept_regex task    # -> acceptance ERE (config-aware, e.g. "(TASK-[0-9]{4}|TASK-[a-z]+-[0-9a-f]{4})")
#   sage_id_default_regex task   # -> default-format ERE for ID generation scans (never config-extended)
#
# Config: .sage/id-patterns.json — {"<type>": {"accept": ["<ERE>", ...]}}
#   type ∈ spec/plan/task/run/fail. Parsed with POSIX tools only (no jq).
#   Missing file / unparsable JSON / missing type / empty accept => fallback
#   to the built-in default regex (WARN to stderr on anomaly, always exit 0).
# Security: config values are used only as grep -E pattern arguments,
#   never evaluated as shell code (SEC-01/INV-02).

SAGE_ID_PATTERNS_FILE="${SAGE_ID_PATTERNS_FILE:-.sage/id-patterns.json}"

# Built-in fallback definitions — must stay identical to the embedded
# fallback in templates/pre-commit-task-id.sh (INV-03).
_sage_id_fallback_regex() {
  case "$1" in
    spec) printf 'SPEC-[0-9]{4}\n' ;;
    plan) printf 'PLAN-[0-9]{4}\n' ;;
    task) printf 'TASK-[0-9]{4}\n' ;;
    run)  printf 'RUN-[0-9]{4}\n' ;;
    fail) printf 'FAIL-[0-9]{4}\n' ;;
    *)    return 1 ;;
  esac
}

# Extract the "accept" array entries for a type from the config file.
# Supported format is the documented subset (one pattern per line or a
# single-line array). Anything unparsable simply yields no output, which
# resolves to the safe fallback in the caller (PRE-01).
_sage_id_extract_accept() {
  awk -v type="$1" '
    intype == 0 && $0 ~ ("\"" type "\"[[:space:]]*:") { intype = 1 }
    intype == 1 && $0 ~ /"accept"[[:space:]]*:/ { inaccept = 1 }
    inaccept == 1 {
      line = $0
      # Strip up to the accept key on its own line so the key itself is not
      # captured as a pattern.
      sub(/.*"accept"[[:space:]]*:/, "", line)
      while (match(line, /"[^"]*"/)) {
        printf "%s\n", substr(line, RSTART + 1, RLENGTH - 2)
        line = substr(line, RSTART + RLENGTH)
      }
      # Close only on a "]" outside quoted strings ("]" may appear inside
      # an ERE pattern such as TASK-[0-9]{4}).
      if (line ~ /\]/) { intype = 0; inaccept = 0 }
    }
  ' "$2" 2>/dev/null
}

# sage_id_accept_regex <type> — acceptance ERE. Multiple accept patterns are
# combined into (p1|p2|...). Always prints a non-empty valid ERE and returns 0
# for known types (POST-01).
sage_id_accept_regex() {
  local _type="$1" _fallback _file _joined _count _pat
  if ! _fallback="$(_sage_id_fallback_regex "$_type")"; then
    echo "WARN: sage-id-pattern: unknown id type '$_type'" >&2
    return 1
  fi
  _file="$SAGE_ID_PATTERNS_FILE"
  if [ ! -f "$_file" ]; then
    # Absent config is the documented default state — silent fallback (AC-01).
    printf '%s\n' "$_fallback"
    return 0
  fi
  _joined=""
  _count=0
  local _grep_status
  while IFS= read -r _pat; do
    [ -n "$_pat" ] || continue
    # Reject invalid EREs so a broken pattern cannot disable validation.
    # grep exits 2 on a bad pattern; 0/1 both mean the pattern is valid.
    _grep_status=0
    printf '' | grep -E -- "$_pat" > /dev/null 2>&1 || _grep_status=$?
    if [ "$_grep_status" -ge 2 ]; then
      echo "WARN: sage-id-pattern: invalid ERE for type '$_type' ignored: $_pat" >&2
      continue
    fi
    if [ -z "$_joined" ]; then
      _joined="$_pat"
    else
      _joined="$_joined|$_pat"
    fi
    _count=$((_count + 1))
  done <<EOF_PATTERNS
$(_sage_id_extract_accept "$_type" "$_file")
EOF_PATTERNS
  if [ "$_count" -eq 0 ]; then
    # Unparsable JSON / missing type / empty accept — safe fallback (FR-04, SEC-03).
    echo "WARN: sage-id-pattern: no usable accept patterns for type '$_type' in $_file — using default '$_fallback'" >&2
    printf '%s\n' "$_fallback"
    return 0
  fi
  if [ "$_count" -eq 1 ]; then
    printf '%s\n' "$_joined"
  else
    printf '(%s)\n' "$_joined"
  fi
  return 0
}

# sage_id_default_regex <type> — default-format ERE for sequential-number
# scans in sage-id-gen.sh. Custom accept patterns never extend generation
# (FR-07/PRE-02), so this is always the built-in default.
sage_id_default_regex() {
  local _fallback
  if ! _fallback="$(_sage_id_fallback_regex "$1")"; then
    echo "WARN: sage-id-pattern: unknown id type '$1'" >&2
    return 1
  fi
  printf '%s\n' "$_fallback"
  return 0
}
