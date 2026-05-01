#!/usr/bin/env bash
# Smoke tests for templates/hooks/session-stop.sh
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=test-helpers.sh
source "${SCRIPT_DIR}/_helpers.sh"

SANDBOX="$(create_sandbox)"
trap 'rm -rf "${SANDBOX}"' EXIT

# session-stop should not fail and should not crash on minimal stdin.
run_hook "session-stop.sh" '{}' "${SANDBOX}"
assert_eq "${HOOK_RC}" "0" "session-stop exits 0 on minimal stdin"

# Empty stdin is also tolerable.
run_hook "session-stop.sh" '' "${SANDBOX}"
assert_eq "${HOOK_RC}" "0" "session-stop exits 0 on empty stdin"

summary_line
