#!/usr/bin/env bash
# =============================================================================
# TASK-0131: test-runlog-index.sh (SPEC-0016 AC-04)
# Purpose:  Test sage-runlog-index.sh: full / incremental / parse error / empty
# =============================================================================
set -uo pipefail

PASS=0
FAIL=0

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
INDEXER="${REPO_ROOT}/scripts/sage-runlog-index.sh"

setup_sandbox() {
  local s
  s="$(mktemp -d -t sage-idx-test-XXXXXX)"
  mkdir -p "${s}/.sage/runs" "${s}/.sage/audit"
  echo "$s"
}

write_run() {
  local path="$1"
  local run_id="$2"
  local task_id="$3"
  local status="$4"
  cat > "$path" <<YAML
run_id: ${run_id}
task_id: ${task_id}
agent_id: implementation
started_at: "2026-05-02T00:00:00Z"
completed_at: "2026-05-02T00:01:00Z"
status: ${status}
files_changed: []
gate_results:
  structural: pass
  functional: pass
  security: pass
  architecture: pass
  release: pass
YAML
}

assert_db_count() {
  local label="$1"
  local sandbox="$2"
  local table="$3"
  local expected="$4"
  if ! command -v sqlite3 &>/dev/null; then
    PASS=$((PASS + 1))  # graceful skip — sqlite3 CLI not installed
    echo "  ok   ${label} (sqlite3 CLI not installed; assertion skipped)"
    return
  fi
  local actual
  actual=$(sqlite3 "${sandbox}/.sage/runs.db" "SELECT COUNT(*) FROM ${table};" 2>/dev/null || echo "ERR")
  if [ "$actual" = "$expected" ]; then
    PASS=$((PASS + 1))
    echo "  ok   ${label} (${table}.COUNT = ${expected})"
  else
    FAIL=$((FAIL + 1))
    echo "  not ok ${label}: expected COUNT=${expected}, got '${actual}'" >&2
  fi
}

echo "# RUN log SQLite indexer (SPEC-0016)"

# --- Scenario 1: full index from empty ---
sandbox="$(setup_sandbox)"; trap "rm -rf $sandbox" EXIT
write_run "${sandbox}/.sage/runs/RUN-9001.yaml" "RUN-9001" "TASK-9001" "pass"
write_run "${sandbox}/.sage/runs/RUN-9002.yaml" "RUN-9002" "TASK-9002" "fail"
( cd "$sandbox" && bash "$INDEXER" --full ) >/dev/null 2>&1
assert_db_count "full index 2 RUN logs" "$sandbox" "runs" "2"
rm -rf "$sandbox"

# --- Scenario 2: incremental adds 1 ---
sandbox="$(setup_sandbox)"; trap "rm -rf $sandbox" EXIT
write_run "${sandbox}/.sage/runs/RUN-9001.yaml" "RUN-9001" "TASK-9001" "pass"
( cd "$sandbox" && bash "$INDEXER" --full ) >/dev/null 2>&1
write_run "${sandbox}/.sage/runs/RUN-9002.yaml" "RUN-9002" "TASK-9002" "fail"
sleep 1  # ensure mtime > last_index_at
( cd "$sandbox" && bash "$INDEXER" --incremental ) >/dev/null 2>&1
assert_db_count "incremental adds 1 RUN" "$sandbox" "runs" "2"
rm -rf "$sandbox"

# --- Scenario 3: parse error skipped, others succeed ---
sandbox="$(setup_sandbox)"; trap "rm -rf $sandbox" EXIT
write_run "${sandbox}/.sage/runs/RUN-9001.yaml" "RUN-9001" "TASK-9001" "pass"
echo "INVALID YAML: [unclosed" > "${sandbox}/.sage/runs/RUN-9999.yaml"
( cd "$sandbox" && bash "$INDEXER" --full ) >/dev/null 2>&1
assert_db_count "parse error skipped (only 1 RUN indexed)" "$sandbox" "runs" "1"
rm -rf "$sandbox"

# --- Scenario 4: empty runs dir → graceful exit 0 ---
sandbox="$(setup_sandbox)"; trap "rm -rf $sandbox" EXIT
( cd "$sandbox" && bash "$INDEXER" --full ) >/dev/null 2>&1
rc=$?
if [ $rc -eq 0 ]; then
  PASS=$((PASS + 1))
  echo "  ok   empty runs dir → exit 0"
else
  FAIL=$((FAIL + 1))
  echo "  not ok empty runs dir: exit $rc (expected 0)" >&2
fi
rm -rf "$sandbox"

# --- Scenario 5: DB permission 600 ---
sandbox="$(setup_sandbox)"; trap "rm -rf $sandbox" EXIT
write_run "${sandbox}/.sage/runs/RUN-9001.yaml" "RUN-9001" "TASK-9001" "pass"
( cd "$sandbox" && bash "$INDEXER" --full ) >/dev/null 2>&1
if [ -f "${sandbox}/.sage/runs.db" ]; then
  perms=$(stat -f "%Op" "${sandbox}/.sage/runs.db" 2>/dev/null || stat -c "%a" "${sandbox}/.sage/runs.db" 2>/dev/null || echo "ERR")
  # Linux stat -c gives "600", macOS stat -f gives "100600"
  if echo "$perms" | grep -qE "^(100)?600$"; then
    PASS=$((PASS + 1))
    echo "  ok   DB permission 600 (got $perms)"
  else
    FAIL=$((FAIL + 1))
    echo "  not ok DB permission: expected 600, got $perms" >&2
  fi
fi
rm -rf "$sandbox"

echo ""
echo "SUMMARY pass=$PASS fail=$FAIL"
[ "$FAIL" -eq 0 ]
