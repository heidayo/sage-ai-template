#!/bin/bash
# sage-doctor.sh — SAGE Health Check (TASK-0046 / TASK-0047 / TASK-0048)
# File existence, integrity, AI Control Plane security, failures.md candidate output
set -euo pipefail

# --- Options ---
JSON_OUTPUT=false
CHECK_ONLY=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) JSON_OUTPUT=true; shift ;;
    --check-only) CHECK_ONLY=true; shift ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

# --- Cross-platform SHA256 ---
sha256_hash() {
  local file="$1"
  if command -v sha256sum &>/dev/null; then
    sha256sum "$file" | awk '{print $1}'
  elif command -v shasum &>/dev/null; then
    shasum -a 256 "$file" | awk '{print $1}'
  else
    echo "ERROR: No SHA256 tool found (sha256sum or shasum)" >&2
    exit 1
  fi
}

# --- Prereq: install-state.yaml ---
INSTALL_STATE=".sage/install-state.yaml"
if [ ! -f "$INSTALL_STATE" ]; then
  echo "install-state.yaml not found. Run 'bash install.sh' first."
  exit 1
fi

# --- State ---
FAIL_COUNT=0
WARN_COUNT=0
OK_COUNT=0
RESULTS=()

json_escape() {
  if command -v python3 &>/dev/null; then
    python3 -c 'import json, sys; print(json.dumps(sys.argv[1]))' "$1"
  else
    printf '"%s"' "$(printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g')"
  fi
}

add_result() {
  local level="$1" check="$2" message="$3"
  local level_json check_json message_json
  level_json=$(json_escape "$level")
  check_json=$(json_escape "$check")
  message_json=$(json_escape "$message")
  RESULTS+=("{\"level\":${level_json},\"check\":${check_json},\"message\":${message_json}}")
  case "$level" in
    FAIL|MISSING) FAIL_COUNT=$((FAIL_COUNT + 1)) ;;
    WARN) WARN_COUNT=$((WARN_COUNT + 1)) ;;
    OK|INFO) OK_COUNT=$((OK_COUNT + 1)) ;;
  esac
}

emit() {
  local level="$1" message="$2"
  if [ "$JSON_OUTPUT" = false ]; then
    echo "  $level: $message"
  fi
}

# ============================================================
# [1/5] File Existence & Integrity Check (TASK-0046)
# ============================================================
if [ "$JSON_OUTPUT" = false ]; then
  echo "=== SAGE Doctor ==="
  echo ""
  echo "[1/5] File existence & integrity check..."
fi

# Parse install-state.yaml (lightweight: grep-based)
# Expected format:
#   files:
#     - path: <path>
#       managed: true|false
#       sha256: <hash>
IN_FILES=false
CURRENT_PATH=""
CURRENT_MANAGED=""
CURRENT_SHA256=""

process_entry() {
  if [ -z "$CURRENT_PATH" ]; then return; fi

  if [ ! -f "$CURRENT_PATH" ]; then
    emit "MISSING" "$CURRENT_PATH"
    add_result "MISSING" "file_existence" "$CURRENT_PATH does not exist"
  elif [ "$CURRENT_MANAGED" = "true" ] && [ -n "$CURRENT_SHA256" ]; then
    ACTUAL_HASH=$(sha256_hash "$CURRENT_PATH")
    if [ "$ACTUAL_HASH" != "$CURRENT_SHA256" ]; then
      emit "FAIL" "$CURRENT_PATH (hash mismatch)"
      add_result "FAIL" "file_integrity" "$CURRENT_PATH hash MISMATCH (expected: ${CURRENT_SHA256:0:12}... got: ${ACTUAL_HASH:0:12}...)"
    else
      emit "OK" "$CURRENT_PATH"
      add_result "OK" "file_integrity" "$CURRENT_PATH"
    fi
  elif [ "$CURRENT_MANAGED" = "false" ]; then
    emit "INFO" "$CURRENT_PATH (unmanaged, skip integrity)"
    add_result "INFO" "file_integrity" "$CURRENT_PATH (unmanaged)"
  else
    emit "OK" "$CURRENT_PATH"
    add_result "OK" "file_existence" "$CURRENT_PATH"
  fi
}

while IFS= read -r line; do
  # Detect files: section
  if echo "$line" | grep -qE '^files:'; then
    IN_FILES=true
    continue
  fi
  # Exit files section on non-indented non-empty line
  if [ "$IN_FILES" = true ] && echo "$line" | grep -qE '^[^ ]' && [ -n "$line" ]; then
    process_entry
    IN_FILES=false
    continue
  fi
  if [ "$IN_FILES" = false ]; then continue; fi

  # New entry
  if echo "$line" | grep -qE '^\s*- path:'; then
    process_entry
    CURRENT_PATH=$(echo "$line" | sed 's/.*- path:[[:space:]]*//' | tr -d '"' | tr -d "'" | sed 's/^[[:space:]]*//')
    CURRENT_MANAGED=""
    CURRENT_SHA256=""
  elif echo "$line" | grep -qE '^\s*managed:'; then
    CURRENT_MANAGED=$(echo "$line" | sed 's/.*managed:[[:space:]]*//' | tr -d ' ')
  elif echo "$line" | grep -qE '^\s*sha256:'; then
    CURRENT_SHA256=$(echo "$line" | sed 's/.*sha256:[[:space:]]*//' | tr -d ' "'"'"'')
  fi
done < "$INSTALL_STATE"
# Process last entry
process_entry

if [ "$JSON_OUTPUT" = false ]; then echo ""; fi

# ============================================================
# [2/5] AI Control Plane Security Check (TASK-0047)
# ============================================================
if [ "$JSON_OUTPUT" = false ]; then
  echo "[2/5] AI Control Plane security check..."
fi

# Secret patterns
SECRET_PATTERN='(api[_-]?key|secret[_-]?key|access[_-]?token|password|credential)\s*[:=]\s*["'"'"']?[A-Za-z0-9+/=_-]{8,}'
AWS_PATTERN='(AKIA|ASIA)[A-Z0-9]{16}'
JWT_PATTERN='eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.'
GITHUB_TOKEN_PATTERN='gh[pousr]_[A-Za-z0-9_]{20,}'

# Files to scan for secrets
SECRET_SCAN_FILES=()
[ -f "CLAUDE.md" ] && SECRET_SCAN_FILES+=("CLAUDE.md")
if [ -d ".claude/prompts" ]; then
  while IFS= read -r f; do
    SECRET_SCAN_FILES+=("$f")
  done < <(find .claude/prompts -type f 2>/dev/null)
fi
if [ -d "templates" ]; then
  while IFS= read -r f; do
    SECRET_SCAN_FILES+=("$f")
  done < <(find templates -type f 2>/dev/null)
fi

# SPEC-0012 / TASK-0111: allowlist hooks whose entire purpose is to define
# or test secret detection patterns. Without this, the scanner trips on
# its own future-collaborators (security-filter.sh embeds the redaction
# regex; secret-read-multi-layer.sh embeds the deny regex; their test
# files contain intentionally-fake fixture values).
SECRET_SCAN_ALLOWLIST=(
  "templates/hooks/security-filter.sh"
  "templates/hooks/tests/test-security-filter.sh"
  "templates/hooks/secret-read-multi-layer.sh"
  "templates/hooks/tests/test-secret-read-multi-layer.sh"
)

is_secret_scan_allowlisted() {
  local f="$1"
  for allowed in "${SECRET_SCAN_ALLOWLIST[@]}"; do
    if [ "$f" = "$allowed" ] || [ "$f" = "./$allowed" ]; then
      return 0
    fi
  done
  return 1
}

SECRET_FOUND=false
for file in "${SECRET_SCAN_FILES[@]}"; do
  if is_secret_scan_allowlisted "$file"; then
    continue
  fi
  for pattern in "$SECRET_PATTERN" "$AWS_PATTERN" "$JWT_PATTERN" "$GITHUB_TOKEN_PATTERN"; do
    if grep -qEi "$pattern" "$file" 2>/dev/null; then
      emit "FAIL" "Secret pattern detected in $file"
      add_result "FAIL" "secret_scan" "Secret pattern detected in $file"
      SECRET_FOUND=true
      break
    fi
  done
done
if [ "$SECRET_FOUND" = false ]; then
  emit "OK" "No secrets detected in AI control plane files"
  add_result "OK" "secret_scan" "No secrets detected"
fi

# Permission check: .claude/settings.json overly permissive
if [ -f ".claude/settings.json" ]; then
  # Check for overly permissive allow (handles both single-line and multi-line JSON)
  if python3 -c "import json,sys; d=json.load(open('.claude/settings.json')); sys.exit(0 if '*' in d.get('permissions',{}).get('allow',[]) else 1)" 2>/dev/null; then
    emit "FAIL" ".claude/settings.json has overly permissive allow: [\"*\"]"
    add_result "FAIL" "permission_check" ".claude/settings.json allow: [*] is overly permissive"
  else
    emit "OK" ".claude/settings.json permissions are scoped"
    add_result "OK" "permission_check" ".claude/settings.json permissions OK"
  fi
else
  emit "INFO" ".claude/settings.json not found (skipped)"
  add_result "INFO" "permission_check" ".claude/settings.json not found"
fi

# Hook safety: check for dangerous patterns in hook scripts
HOOK_DANGER_PATTERN='curl.*\|.*bash|eval.*\$|wget.*\|.*sh'
HOOK_ISSUE=false
if [ -d "templates/hooks" ]; then
  while IFS= read -r hookfile; do
    if grep -qE "$HOOK_DANGER_PATTERN" "$hookfile" 2>/dev/null; then
      emit "WARN" "Dangerous pattern in $hookfile"
      add_result "WARN" "hook_safety" "Dangerous pattern in $hookfile (curl|bash, eval, wget|sh)"
      HOOK_ISSUE=true
    fi
  done < <(find templates/hooks -name '*.sh' -type f 2>/dev/null)
fi
if [ "$HOOK_ISSUE" = false ]; then
  emit "OK" "Hook scripts are safe"
  add_result "OK" "hook_safety" "No dangerous patterns in hooks"
fi

if [ "$JSON_OUTPUT" = false ]; then echo ""; fi

# ============================================================
# [3/5] MCP allowlist health check (TASK-0124 / SPEC-0015)
# ============================================================
if [ "$JSON_OUTPUT" = false ]; then
  echo "[3/5] MCP allowlist check..."
fi

MCP_REGISTRY=".sage/mcp-allowlist.json"

# (a) registry existence
if [ ! -f "$MCP_REGISTRY" ]; then
  emit "WARN" "MCP allowlist registry not found ($MCP_REGISTRY) — initial setup recommended (SPEC-0015)"
  add_result "WARN" "mcp_allowlist_registry" "Registry $MCP_REGISTRY not present"
else
  # (b) registry validity + secret hygiene (drift7) — delegate to companion script
  if command -v python3 &>/dev/null; then
    MCP_DOCTOR_OUT="$(bash scripts/sage-mcp-allowlist-audit.sh "$MCP_REGISTRY" 2>&1)"
    while IFS=$'\t' read -r level check msg; do
      [ -z "$level" ] && continue
      emit "$level" "$msg"
      add_result "$level" "$check" "$msg"
    done <<< "$MCP_DOCTOR_OUT"
  else
    emit "WARN" "python3 unavailable — MCP allowlist check skipped"
    add_result "WARN" "mcp_allowlist_python" "python3 not in PATH"
  fi
fi

if [ "$JSON_OUTPUT" = false ]; then echo ""; fi

# ============================================================
# [4/5] Agent inventory drift check (TASK-0129 / SPEC-0017)
# ============================================================
if [ "$JSON_OUTPUT" = false ]; then
  echo "[4/5] Agent inventory check..."
fi

if command -v python3 &>/dev/null; then
  AGENT_INV_OUT="$(bash scripts/sage-agent-inventory-audit.sh 2>&1)"
  while IFS=$'\t' read -r level check msg; do
    [ -z "$level" ] && continue
    emit "$level" "$msg"
    add_result "$level" "$check" "$msg"
  done <<< "$AGENT_INV_OUT"
else
  emit "WARN" "python3 unavailable — agent inventory check skipped"
  add_result "WARN" "agent_inventory_python" "python3 not in PATH"
fi

if [ "$JSON_OUTPUT" = false ]; then echo ""; fi

# ============================================================
# [5/5] Summary & Failure Candidate Output (TASK-0048)
# ============================================================
TOTAL=$((FAIL_COUNT + WARN_COUNT + OK_COUNT))

if [ "$JSON_OUTPUT" = false ]; then
  echo "[5/5] Summary..."
  echo "  OK: $OK_COUNT  WARN: $WARN_COUNT  FAIL: $FAIL_COUNT  (Total: $TOTAL)"
  echo ""
fi

# Output failures.md candidate to stderr when WARN or FAIL detected
if [ $((FAIL_COUNT + WARN_COUNT)) -gt 0 ] && [ "$CHECK_ONLY" = false ]; then
  FAIL_ID="FAIL-DOCTOR-$(date +%Y%m%d%H%M%S)"
  cat >&2 <<EOF
--- failures.md candidate ---
## $FAIL_ID

- **detected_at**: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
- **source**: sage-doctor.sh
- **severity**: $([ $FAIL_COUNT -gt 0 ] && echo "FAIL" || echo "WARN")
- **summary**: $FAIL_COUNT failure(s), $WARN_COUNT warning(s) detected
- **details**: Run \`make doctor\` for full output
- **resolution**: Run \`make repair\` or fix manually
---
EOF
fi

# Record to doctor-history.jsonl
if [ "$CHECK_ONLY" = false ]; then
  mkdir -p .sage/metrics
  HISTORY_ENTRY=$(cat <<EOF
{"timestamp":"$(date -u +"%Y-%m-%dT%H:%M:%SZ")","ok":$OK_COUNT,"warn":$WARN_COUNT,"fail":$FAIL_COUNT,"total":$TOTAL}
EOF
)
  echo "$HISTORY_ENTRY" >> .sage/metrics/doctor-history.jsonl
fi

# JSON output
if [ "$JSON_OUTPUT" = true ]; then
  echo "{"
  echo "  \"timestamp\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\","
  echo "  \"ok\": $OK_COUNT,"
  echo "  \"warn\": $WARN_COUNT,"
  echo "  \"fail\": $FAIL_COUNT,"
  echo "  \"total\": $TOTAL,"
  echo "  \"results\": ["
  for i in "${!RESULTS[@]}"; do
    if [ "$i" -lt $((${#RESULTS[@]} - 1)) ]; then
      echo "    ${RESULTS[$i]},"
    else
      echo "    ${RESULTS[$i]}"
    fi
  done
  echo "  ]"
  echo "}"
else
  if [ $FAIL_COUNT -eq 0 ]; then
    echo "=== SAGE Doctor: ALL OK ==="
  else
    echo "=== SAGE Doctor: $FAIL_COUNT FAILURE(S) FOUND ==="
  fi
fi

# Exit code: 1 only for FAIL (not WARN)
if [ $FAIL_COUNT -gt 0 ]; then
  exit 1
fi
exit 0
