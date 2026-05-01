#!/usr/bin/env bash
# Smoke tests for templates/hooks/protect-sage-files.sh
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=test-helpers.sh
source "${SCRIPT_DIR}/_helpers.sh"

SANDBOX="$(create_sandbox)"
trap 'rm -rf "${SANDBOX}"' EXIT

# --- Allow case: edit a regular project file (not protected) ---
run_hook "protect-sage-files.sh" '{"tool_name":"Edit","tool_input":{"file_path":"src/main.go","content":"package main"}}' "${SANDBOX}"
assert_eq "${HOOK_RC}" "0" "allow: edit src/main.go"

# --- Allow case: empty stdin ---
run_hook "protect-sage-files.sh" '' "${SANDBOX}"
assert_eq "${HOOK_RC}" "0" "allow: empty stdin"

# --- Block case: edit CLAUDE.md without an active sage-managed task ---
# (Sandbox has no tasks/ directory at all, so no active sage-managed task exists.)
run_hook "protect-sage-files.sh" '{"tool_name":"Edit","tool_input":{"file_path":"CLAUDE.md","content":"# changed"}}' "${SANDBOX}"
assert_eq "${HOOK_RC}" "2" "block: CLAUDE.md without active task"
assert_contains "${HOOK_STDERR}" "BLOCKED" "block: stderr has BLOCKED prefix"

# --- Block case: edit a sage/* file without active task ---
run_hook "protect-sage-files.sh" '{"tool_name":"Edit","tool_input":{"file_path":"sage/governance.md","content":"# changed"}}' "${SANDBOX}"
assert_eq "${HOOK_RC}" "2" "block: sage/governance.md without active task"

# --- Allow case: with an active sage-managed task in tasks/ ---
mkdir -p "${SANDBOX}/tasks"
cat > "${SANDBOX}/tasks/TASK-0099-active.md" <<'EOF'
# TASK-0099: active sage-managed sample
| ステータス | In Progress |
sage-managed: true
EOF
run_hook "protect-sage-files.sh" '{"tool_name":"Edit","tool_input":{"file_path":"CLAUDE.md","content":"# changed"}}' "${SANDBOX}"
assert_eq "${HOOK_RC}" "0" "allow: CLAUDE.md with active sage-managed task"

summary_line
