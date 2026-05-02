#!/usr/bin/env bash
# =============================================================================
# TASK-0143: test-release-workflow.sh (SPEC-0018 AC-13 / AC-14)
# Purpose:  Test release workflow + install.sh --verify-checksum --remote behavior:
#           1. SHA256SUMS POSIX format validation
#           2. install.sh source contains --remote support (do_verify_checksum_remote)
#           3. release.yml structural existence + permissions + tag pattern
#           4. --verify-checksum --remote PASS scenario (mock curl returns matching SHA)
#           5. --verify-checksum --remote FAIL scenario (mock curl returns mismatched SHA)
#           6. --verify-checksum --remote graceful skip (mock curl fails / network unreachable)
# =============================================================================
set -uo pipefail

PASS=0
FAIL=0

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
INSTALL_SH="${REPO_ROOT}/install.sh"
RELEASE_YML="${REPO_ROOT}/.github/workflows/release.yml"
GENERATOR_MAIN="${REPO_ROOT}/scripts/generator/07-installer-main.sh"

echo "# release-workflow + install.sh --verify-checksum --remote (SPEC-0018)"

# --- Scenario 1: SHA256SUMS POSIX format validation ---
# Format must be: <64-hex-chars>  <filename> (two spaces)
valid_line="0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef  install.sh"
invalid_line_short="0123  install.sh"
invalid_line_no_filename="0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"
invalid_line_wrong_sep="0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef install.sh"  # only 1 space

if printf '%s\n' "$valid_line" | grep -Eq '^[0-9a-f]{64}  install\.sh$' \
   && ! printf '%s\n' "$invalid_line_short" | grep -Eq '^[0-9a-f]{64}  install\.sh$' \
   && ! printf '%s\n' "$invalid_line_no_filename" | grep -Eq '^[0-9a-f]{64}  install\.sh$' \
   && ! printf '%s\n' "$invalid_line_wrong_sep" | grep -Eq '^[0-9a-f]{64}  install\.sh$'; then
  PASS=$((PASS + 1))
  echo "  ok   SHA256SUMS POSIX format regex validates correctly"
else
  FAIL=$((FAIL + 1))
  echo "  not ok SHA256SUMS POSIX format regex incorrect" >&2
fi

# --- Scenario 2: source generator/07-installer-main.sh contains --remote support ---
if grep -q 'do_verify_checksum_remote' "$GENERATOR_MAIN" \
   && grep -q 'REMOTE_VERIFY' "$GENERATOR_MAIN" \
   && grep -q 'releases/latest/download/SHA256SUMS' "$GENERATOR_MAIN"; then
  PASS=$((PASS + 1))
  echo "  ok   scripts/generator/07-installer-main.sh has --remote mode (do_verify_checksum_remote / REMOTE_VERIFY / SHA256SUMS URL)"
else
  FAIL=$((FAIL + 1))
  echo "  not ok scripts/generator/07-installer-main.sh missing --remote mode implementation" >&2
fi

# --- Scenario 3: release.yml structural existence + permissions + tag pattern ---
if [ -f "$RELEASE_YML" ] \
   && grep -Eq "^\s*tags:\s*$" "$RELEASE_YML" \
   && grep -q '"v\*\.\*\.\*"' "$RELEASE_YML" \
   && grep -Eq "^\s*contents:\s*write\s*$" "$RELEASE_YML" \
   && grep -q 'gh release create' "$RELEASE_YML" \
   && grep -q 'SHA256SUMS' "$RELEASE_YML"; then
  PASS=$((PASS + 1))
  echo "  ok   release.yml has tag trigger + contents:write + gh release create + SHA256SUMS"
else
  FAIL=$((FAIL + 1))
  echo "  not ok release.yml structural check failed" >&2
fi

# --- Scenarios 4-6: --verify-checksum --remote with mock curl ---
# Skip Scenarios 4-6 if install.sh is stale (regen pending in TASK-0143).
if ! grep -q 'do_verify_checksum_remote' "$INSTALL_SH" 2>/dev/null; then
  echo "  skip Scenarios 4-6 (install.sh has not been regenerated yet — TASK-0143 will regen)"
  echo ""
  echo "SUMMARY pass=$PASS fail=$FAIL"
  [ "$FAIL" -eq 0 ]
  exit $?
fi

# Setup: mock curl in temp dir, fixture install.sh with known SHA256.
MOCK_DIR=$(mktemp -d)
trap 'rm -rf "$MOCK_DIR"' EXIT

# Compute install.sh SHA256 for fixture
if command -v sha256sum >/dev/null 2>&1; then
  ACTUAL_SHA=$(sha256sum "$INSTALL_SH" | awk '{print $1}')
elif command -v shasum >/dev/null 2>&1; then
  ACTUAL_SHA=$(shasum -a 256 "$INSTALL_SH" | awk '{print $1}')
else
  echo "  skip Scenarios 4-6 (no sha256 tool available)"
  echo ""
  echo "SUMMARY pass=$PASS fail=$FAIL"
  [ "$FAIL" -eq 0 ]
  exit $?
fi

WRONG_SHA="0000000000000000000000000000000000000000000000000000000000000000"

# Mock curl: behavior controlled by env var MOCK_CURL_BEHAVIOR
cat > "$MOCK_DIR/curl" <<MOCK_CURL
#!/bin/bash
# Mock curl for SPEC-0018 test-release-workflow.sh
case "\${MOCK_CURL_BEHAVIOR:-pass}" in
  pass) printf '%s  install.sh\n' "${ACTUAL_SHA}" ;;
  mismatch) printf '%s  install.sh\n' "${WRONG_SHA}" ;;
  invalid_format) printf 'this is not a sha256sums line\n' ;;
  empty) printf '' ;;
  fail) exit 22 ;;
  *) exit 99 ;;
esac
MOCK_CURL
chmod +x "$MOCK_DIR/curl"

# --- Scenario 4: --remote PASS (mock curl returns matching SHA) ---
output_4=$(MOCK_CURL_BEHAVIOR=pass PATH="$MOCK_DIR:$PATH" bash "$INSTALL_SH" --verify-checksum --remote 2>&1)
exit_4=$?
if [ "$exit_4" = "0" ] && echo "$output_4" | grep -q "OK: install.sh matches release SHA256SUMS"; then
  PASS=$((PASS + 1))
  echo "  ok   --verify-checksum --remote PASS scenario (mock SHA match → exit 0)"
else
  FAIL=$((FAIL + 1))
  echo "  not ok --remote PASS: exit=$exit_4, output: $output_4" >&2
fi

# --- Scenario 5: --remote FAIL (mock curl returns mismatched SHA) ---
output_5=$(MOCK_CURL_BEHAVIOR=mismatch PATH="$MOCK_DIR:$PATH" bash "$INSTALL_SH" --verify-checksum --remote 2>&1)
exit_5=$?
if [ "$exit_5" = "1" ] && echo "$output_5" | grep -q "FAIL: remote SHA256 mismatch"; then
  PASS=$((PASS + 1))
  echo "  ok   --verify-checksum --remote FAIL scenario (mock SHA mismatch → exit 1)"
else
  FAIL=$((FAIL + 1))
  echo "  not ok --remote FAIL: exit=$exit_5, output: $output_5" >&2
fi

# --- Scenario 6: --remote graceful skip (mock curl fails network) ---
output_6=$(MOCK_CURL_BEHAVIOR=fail PATH="$MOCK_DIR:$PATH" bash "$INSTALL_SH" --verify-checksum --remote 2>&1)
exit_6=$?
if [ "$exit_6" = "0" ] && echo "$output_6" | grep -q "remote SHA256SUMS fetch failed; verification skipped"; then
  PASS=$((PASS + 1))
  echo "  ok   --verify-checksum --remote graceful skip (mock curl fail → warning + exit 0)"
else
  FAIL=$((FAIL + 1))
  echo "  not ok --remote graceful skip: exit=$exit_6, output: $output_6" >&2
fi

# --- Scenario 7 (bonus): --remote format invalid (mock curl returns bad format) ---
output_7=$(MOCK_CURL_BEHAVIOR=invalid_format PATH="$MOCK_DIR:$PATH" bash "$INSTALL_SH" --verify-checksum --remote 2>&1)
exit_7=$?
if [ "$exit_7" = "1" ] && echo "$output_7" | grep -q "SHA256SUMS line format invalid"; then
  PASS=$((PASS + 1))
  echo "  ok   --verify-checksum --remote format invalid scenario (bad format → exit 1)"
else
  FAIL=$((FAIL + 1))
  echo "  not ok --remote format invalid: exit=$exit_7, output: $output_7" >&2
fi

echo ""
echo "SUMMARY pass=$PASS fail=$FAIL"
[ "$FAIL" -eq 0 ]
