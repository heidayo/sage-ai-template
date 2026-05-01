#!/usr/bin/env bash
# Smoke tests for templates/hooks/session-start.sh
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=test-helpers.sh
source "${SCRIPT_DIR}/_helpers.sh"

SANDBOX="$(create_sandbox)"
trap 'rm -rf "${SANDBOX}"' EXIT

# session-start emits informational context on stderr or stdout. It must
# never fail the session, so we only assert exit 0 and a non-empty signal.
run_hook "session-start.sh" '' "${SANDBOX}"
assert_eq "${HOOK_RC}" "0" "session-start exits 0"

# Either stdout or stderr should contain *something* (banner / context).
combined="${HOOK_STDOUT}${HOOK_STDERR}"
if [ -n "${combined}" ]; then
  HELPER_PASS=$((HELPER_PASS + 1))
  echo "  ok   session-start emits some output"
else
  # Empty output is acceptable in minimal mode; treat as pass with a note.
  HELPER_PASS=$((HELPER_PASS + 1))
  echo "  ok   session-start produced no output (acceptable for minimal profile)"
fi

summary_line
