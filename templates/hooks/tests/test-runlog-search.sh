#!/usr/bin/env bash
# =============================================================================
# TASK-0132: test-runlog-search.sh (SPEC-0016 AC-04)
# Purpose:  Test sage-runlog-search.sh: 6 filter / FTS / JSON / log redact
# =============================================================================
set -uo pipefail

PASS=0
FAIL=0

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
INDEXER="${REPO_ROOT}/scripts/sage-runlog-index.sh"
SEARCH="${REPO_ROOT}/scripts/sage-runlog-search.sh"

setup_sandbox_with_data() {
  local s
  s="$(mktemp -d -t sage-srch-test-XXXXXX)"
  mkdir -p "${s}/.sage/runs" "${s}/.sage/audit"
  # 3 RUN logs
  cat > "${s}/.sage/runs/RUN-9001.yaml" <<YAML
run_id: RUN-9001
task_id: TASK-9001
agent_id: implementation
started_at: "2026-05-01T00:00:00Z"
completed_at: "2026-05-01T00:01:00Z"
status: pass
files_changed: []
gate_results:
  structural: pass
  functional: pass
  security: pass
  architecture: pass
  release: pass
YAML
  cat > "${s}/.sage/runs/RUN-9002.yaml" <<YAML
run_id: RUN-9002
task_id: TASK-9002
agent_id: review
started_at: "2026-05-02T00:00:00Z"
completed_at: "2026-05-02T00:01:00Z"
status: fail
error_log: "redact pattern failed"
files_changed: []
gate_results:
  structural: pass
  functional: fail
  security: pass
  architecture: pass
  release: pass
YAML
  cat > "${s}/.sage/runs/RUN-9003.yaml" <<YAML
run_id: RUN-9003
task_id: TASK-9001
agent_id: implementation
started_at: "2026-05-03T00:00:00Z"
completed_at: "2026-05-03T00:01:00Z"
status: pass
files_changed: []
gate_results:
  structural: pass
  functional: pass
  security: pass
  architecture: pass
  release: pass
YAML
  # 1 audit event
  cat > "${s}/.sage/audit/mcp-allowlist-20260502.log" <<'JSON'
{"timestamp":"2026-05-02T01:00:00Z","runtime":"claude-code","drift_type":"drift1_stdio_unknown_server","severity":"warn","details":{"scope":"server","server_name":"unknown-server"}}
JSON
  ( cd "$s" && bash "$INDEXER" --full ) >/dev/null 2>&1
  echo "$s"
}

assert_search_contains() {
  local label="$1"
  local sandbox="$2"
  local expected="$3"
  shift 3
  local out
  out="$(cd "$sandbox" && bash "$SEARCH" "$@" 2>&1)"
  if echo "$out" | grep -qF "$expected"; then
    PASS=$((PASS + 1))
    echo "  ok   ${label}"
  else
    FAIL=$((FAIL + 1))
    echo "  not ok ${label}: missing '${expected}'" >&2
    echo "    output: $out" >&2
  fi
}

echo "# RUN log search CLI (SPEC-0016)"

sandbox="$(setup_sandbox_with_data)"; trap "rm -rf $sandbox" EXIT

# --- Scenario 1: --task-id ---
assert_search_contains "--task-id TASK-9001 returns RUN-9001 + RUN-9003" "$sandbox" "RUN-9001" --task-id TASK-9001

# --- Scenario 2: --agent-id ---
assert_search_contains "--agent-id implementation returns multiple" "$sandbox" "implementation" --agent-id implementation

# --- Scenario 3: --status fail ---
assert_search_contains "--status fail returns RUN-9002" "$sandbox" "RUN-9002" --status fail

# --- Scenario 4: --drift-type ---
assert_search_contains "--drift-type drift1 returns audit event" "$sandbox" "unknown-server" --drift-type drift1_stdio_unknown_server

# --- Scenario 5: --fts ---
assert_search_contains "--fts 'redact' finds RUN-9002 error_log" "$sandbox" "RUN-9002" --fts "redact"

# --- Scenario 6: --json valid ---
out=$(cd "$sandbox" && bash "$SEARCH" --task-id TASK-9001 --json 2>&1)
if echo "$out" | python3 -c "import sys,json; json.loads(sys.stdin.read())" 2>/dev/null; then
  PASS=$((PASS + 1))
  echo "  ok   --json output is valid JSON"
else
  FAIL=$((FAIL + 1))
  echo "  not ok --json: invalid JSON output" >&2
  echo "    output: $out" >&2
fi

# --- Scenario 7: search query log redaction ---
( cd "$sandbox" && bash "$SEARCH" --fts "sk-FAKE-LEAKED-TOKEN-12345-67890-abcdef" 2>&1 ) >/dev/null 2>&1 || true
search_log="$(ls "${sandbox}/.sage/audit/runlog-search-"*.log 2>/dev/null | head -1)"
if [ -n "$search_log" ] && grep -q "FAKE-LEAKED-TOKEN" "$search_log"; then
  FAIL=$((FAIL + 1))
  echo "  not ok search log redact: secret leaked" >&2
else
  PASS=$((PASS + 1))
  echo "  ok   search log redact (no secret leak)"
fi

rm -rf "$sandbox"

echo ""
echo "SUMMARY pass=$PASS fail=$FAIL"
[ "$FAIL" -eq 0 ]
