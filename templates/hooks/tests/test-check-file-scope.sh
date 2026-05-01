#!/usr/bin/env bash
# Smoke tests for templates/hooks/check-file-scope.sh
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=test-helpers.sh
source "${SCRIPT_DIR}/_helpers.sh"

SANDBOX="$(create_sandbox)"
trap 'rm -rf "${SANDBOX}"' EXIT

# --- Allow case: empty stdin ---
run_hook "check-file-scope.sh" '' "${SANDBOX}"
assert_eq "${HOOK_RC}" "0" "allow: empty stdin"

# --- Allow case: edit a file with no tasks/ directory present ---
# (Without active TASK declaring File Scope, hook degrades to allow per
# fail-open semantics in standard profile to avoid blocking general work.)
run_hook "check-file-scope.sh" '{"tool_name":"Edit","tool_input":{"file_path":"src/main.go"}}' "${SANDBOX}"
assert_eq "${HOOK_RC}" "0" "allow: no tasks dir = pass-through"

summary_line
