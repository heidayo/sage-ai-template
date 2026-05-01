#!/usr/bin/env bash
# Smoke tests for templates/hooks/security-filter.sh
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=_helpers.sh
source "${SCRIPT_DIR}/_helpers.sh"

SANDBOX="$(create_sandbox)"
trap 'rm -rf "${SANDBOX}"' EXIT

mkdir -p "${SANDBOX}/.sage/runs"

# --- Helper: write a RUN log with seeded secrets ---
write_run_log() {
  local file="$1"
  cat > "$file" <<'YAML'
run_id: RUN-9999
status: pass
note: hello world
api_key: "sk-abcdef0123456789abcdef0123456789abcd"
token: "ghp_abcdefghijklmnopqrstuvwxyz0123456789"
github_classic: ghp_abcdefghijklmnopqrstuvwxyz9876543210
slack_token: xoxb-12345-67890-abcdefghijklmnop
aws_key: AKIAABCDEFGHIJKLMNOP
jwt_field: "eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c"
secret: "MyTotallyUnsafeSecretValueLongerThanTwentyChars"
password: "ShouldBeRedactedExampleStringValue"
benign_path: /usr/local/bin/foo
short_value: ok
YAML
}

LOGFILE="${SANDBOX}/.sage/runs/RUN-9999.yaml"
write_run_log "$LOGFILE"

# Run hook
run_hook "security-filter.sh" '{"hook_event_name":"SessionStop"}' "${SANDBOX}"
assert_eq "${HOOK_RC}" "0" "security-filter exits 0"

# Verify file still exists and has content
if [ -s "$LOGFILE" ]; then
  HELPER_PASS=$((HELPER_PASS + 1))
  echo "  ok   security-filter: file still exists with content"
else
  HELPER_FAIL=$((HELPER_FAIL + 1))
  echo "  not ok security-filter: file empty or missing!" >&2
fi

# Each known secret should be redacted
content=$(cat "$LOGFILE")

assert_not_contains "${content}" "sk-abcdef0123456789abcdef0123456789abcd" "redact: sk-* pattern"
assert_not_contains "${content}" "xoxb-12345-67890-abcdefghijklmnop" "redact: Slack xoxb token"
assert_not_contains "${content}" "AKIAABCDEFGHIJKLMNOP" "redact: AWS Access Key"
assert_not_contains "${content}" "eyJhbGciOiJIUzI1NiJ9" "redact: JWT header"
assert_not_contains "${content}" "MyTotallyUnsafeSecretValueLongerThanTwentyChars" "redact: secret field"
assert_not_contains "${content}" "ShouldBeRedactedExampleStringValue" "redact: password field"

# Should contain placeholder
assert_contains "${content}" "***REDACTED***" "placeholder present"

# Benign content preserved
assert_contains "${content}" "/usr/local/bin/foo" "benign path preserved"
assert_contains "${content}" "hello world" "benign text preserved"
assert_contains "${content}" "short_value: ok" "short_value preserved (under 20 chars)"

# YAML structure preserved (each key still followed by colon)
assert_contains "${content}" "api_key:" "yaml key 'api_key:' preserved"
assert_contains "${content}" "token:" "yaml key 'token:' preserved"

# --- Idempotency: run again, content should not change ---
content_before=$(cat "$LOGFILE")
run_hook "security-filter.sh" '{"hook_event_name":"SessionStop"}' "${SANDBOX}"
content_after=$(cat "$LOGFILE")
if [ "$content_before" = "$content_after" ]; then
  HELPER_PASS=$((HELPER_PASS + 1))
  echo "  ok   security-filter: idempotent (2nd run produces identical output)"
else
  HELPER_FAIL=$((HELPER_FAIL + 1))
  echo "  not ok security-filter: NOT idempotent" >&2
fi

# --- profile=minimal: no redaction, file unchanged ---
write_run_log "$LOGFILE"
cat > "${SANDBOX}/.sage/config.yaml" <<EOF
hooks:
  profile: minimal
EOF
content_before=$(cat "$LOGFILE")
run_hook "security-filter.sh" '{"hook_event_name":"SessionStop"}' "${SANDBOX}"
content_after=$(cat "$LOGFILE")
if [ "$content_before" = "$content_after" ]; then
  HELPER_PASS=$((HELPER_PASS + 1))
  echo "  ok   minimal profile: no redaction"
else
  HELPER_FAIL=$((HELPER_FAIL + 1))
  echo "  not ok minimal profile: file changed unexpectedly" >&2
fi
# Restore standard
cat > "${SANDBOX}/.sage/config.yaml" <<EOF
hooks:
  profile: standard
EOF

# --- No RUN logs at all: graceful exit ---
rm -rf "${SANDBOX}/.sage/runs"
run_hook "security-filter.sh" '{"hook_event_name":"SessionStop"}' "${SANDBOX}"
assert_eq "${HOOK_RC}" "0" "no runs dir: exits 0"

summary_line
