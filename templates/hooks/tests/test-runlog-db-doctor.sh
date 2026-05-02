#!/usr/bin/env bash
# =============================================================================
# TASK-0133: test-runlog-db-doctor.sh (SPEC-0016 AC-04 / AC-05)
# Purpose:  Test sage-runlog-db-audit.sh: 2 scenarios (DB missing / DB healthy)
# =============================================================================
set -uo pipefail

PASS=0
FAIL=0

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
INDEXER="${REPO_ROOT}/scripts/sage-runlog-index.sh"
AUDITOR="${REPO_ROOT}/scripts/sage-runlog-db-audit.sh"

setup_sandbox() {
  local s
  s="$(mktemp -d -t sage-doc-test-XXXXXX)"
  mkdir -p "${s}/.sage/runs" "${s}/.sage/audit"
  echo "$s"
}

write_run() {
  cat > "$1" <<YAML
run_id: RUN-9001
task_id: TASK-9001
agent_id: implementation
started_at: "2026-05-02T00:00:00Z"
completed_at: "2026-05-02T00:01:00Z"
status: pass
files_changed: []
gate_results:
  structural: pass
  functional: pass
  security: pass
  architecture: pass
  release: pass
YAML
}

echo "# RUN log DB doctor (SPEC-0016)"

# --- Scenario 1: DB missing → WARN ---
sandbox="$(setup_sandbox)"; trap "rm -rf $sandbox" EXIT
out=$(cd "$sandbox" && bash "$AUDITOR" 2>&1)
if echo "$out" | grep -q "^WARN	runlog_db_present"; then
  PASS=$((PASS + 1))
  echo "  ok   DB missing → WARN"
else
  FAIL=$((FAIL + 1))
  echo "  not ok DB missing should WARN" >&2
  echo "    output: $out" >&2
fi
rm -rf "$sandbox"

# --- Scenario 2: DB healthy → 4+ OK lines ---
sandbox="$(setup_sandbox)"; trap "rm -rf $sandbox" EXIT
write_run "${sandbox}/.sage/runs/RUN-9001.yaml"
( cd "$sandbox" && bash "$INDEXER" --full ) >/dev/null 2>&1
out=$(cd "$sandbox" && bash "$AUDITOR" 2>&1)
ok_count=$(echo "$out" | grep -c "^OK")
if [ "$ok_count" -ge 4 ]; then
  PASS=$((PASS + 1))
  echo "  ok   DB healthy → ${ok_count} OK checks (>= 4 expected)"
else
  FAIL=$((FAIL + 1))
  echo "  not ok DB healthy: only ${ok_count} OK lines" >&2
  echo "    output: $out" >&2
fi
rm -rf "$sandbox"

echo ""
echo "SUMMARY pass=$PASS fail=$FAIL"
[ "$FAIL" -eq 0 ]
