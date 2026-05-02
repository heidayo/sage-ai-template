#!/usr/bin/env bash
# =============================================================================
# TASK-0128: test-agent-inventory-validator.sh (SPEC-0017 AC-04)
# Purpose:  Test sage-runlog-validate.sh inventory drift detection.
#           6+ scenarios: inventory absent / runtime missing / runtime
#           mismatch / approval mismatch / network mismatch / backward compat.
# =============================================================================
set -uo pipefail

PASS=0
FAIL=0

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
VALIDATOR="${REPO_ROOT}/scripts/sage-runlog-validate.sh"

write_inventory() {
  local sandbox="$1"
  cat > "${sandbox}/.sage/agent-inventory.yaml" <<'YAML'
version: "1.0"
agents:
  - agent_id: implementation
    expected_runtime: ["claude-code", "codex-cli"]
    expected_approval_policy: "on-request"
    expected_network_mode: "off"
YAML
}

write_run_log() {
  local path="$1"
  local extra_fields="$2"
  cat > "$path" <<YAML
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
${extra_fields}
YAML
}

assert_validator() {
  local label="$1"
  local sandbox="$2"
  local expect_warn="$3"  # "yes" or "no"
  local rc out
  out="$(cd "$sandbox" && bash "$VALIDATOR" "${sandbox}/.sage/runs/RUN-9001.yaml" 2>&1 || true)"
  rc=$?
  # Validator should always exit 0 (warnings are non-blocking)
  if [ "$rc" -ne 0 ]; then
    FAIL=$((FAIL + 1))
    echo "  not ok ${label}: validator exit $rc (expected 0)" >&2
    echo "    output: $out" >&2
    return
  fi
  if [ "$expect_warn" = "yes" ]; then
    if echo "$out" | grep -q "WARN:"; then
      PASS=$((PASS + 1))
      echo "  ok   ${label} (warn detected)"
    else
      FAIL=$((FAIL + 1))
      echo "  not ok ${label}: expected WARN, got none" >&2
      echo "    output: $out" >&2
    fi
  else
    if echo "$out" | grep -q "WARN:"; then
      FAIL=$((FAIL + 1))
      echo "  not ok ${label}: unexpected WARN" >&2
      echo "    output: $out" >&2
    else
      PASS=$((PASS + 1))
      echo "  ok   ${label} (no warn, as expected)"
    fi
  fi
}

setup_sandbox() {
  local s
  s="$(mktemp -d -t sage-inv-test-XXXXXX)"
  mkdir -p "${s}/.sage/runs"
  echo "$s"
}

echo "# agent inventory validator (SPEC-0017)"

# --- Scenario 1: inventory absent → no warn (backward compat) ---
sandbox="$(setup_sandbox)"; trap "rm -rf $sandbox" EXIT
write_run_log "${sandbox}/.sage/runs/RUN-9001.yaml" ""
assert_validator "inventory absent" "$sandbox" "no"
rm -rf "$sandbox"

# --- Scenario 2: inventory present, RUN log lacks runtime → warn ---
sandbox="$(setup_sandbox)"; trap "rm -rf $sandbox" EXIT
write_inventory "$sandbox"
write_run_log "${sandbox}/.sage/runs/RUN-9001.yaml" ""
assert_validator "RUN log lacks runtime field" "$sandbox" "yes"
rm -rf "$sandbox"

# --- Scenario 3: runtime mismatch → warn ---
sandbox="$(setup_sandbox)"; trap "rm -rf $sandbox" EXIT
write_inventory "$sandbox"
write_run_log "${sandbox}/.sage/runs/RUN-9001.yaml" 'runtime: codex-cloud'
assert_validator "runtime not in expected" "$sandbox" "yes"
rm -rf "$sandbox"

# --- Scenario 4: runtime match → no warn ---
sandbox="$(setup_sandbox)"; trap "rm -rf $sandbox" EXIT
write_inventory "$sandbox"
write_run_log "${sandbox}/.sage/runs/RUN-9001.yaml" 'runtime: claude-code
approval_policy: on-request
network_mode: "off"'
assert_validator "all fields match expected" "$sandbox" "no"
rm -rf "$sandbox"

# --- Scenario 5: approval_policy mismatch → warn ---
sandbox="$(setup_sandbox)"; trap "rm -rf $sandbox" EXIT
write_inventory "$sandbox"
write_run_log "${sandbox}/.sage/runs/RUN-9001.yaml" 'runtime: claude-code
approval_policy: never'
assert_validator "approval_policy mismatch" "$sandbox" "yes"
rm -rf "$sandbox"

# --- Scenario 6: network_mode mismatch → warn ---
sandbox="$(setup_sandbox)"; trap "rm -rf $sandbox" EXIT
write_inventory "$sandbox"
write_run_log "${sandbox}/.sage/runs/RUN-9001.yaml" 'runtime: claude-code
network_mode: unrestricted'
assert_validator "network_mode mismatch" "$sandbox" "yes"
rm -rf "$sandbox"

# --- Scenario 7: existing RUN log without 4 new fields → no warn (backward compat) ---
# (Same as scenario 2 but agent_id is NOT in inventory → silent)
sandbox="$(setup_sandbox)"; trap "rm -rf $sandbox" EXIT
cat > "${sandbox}/.sage/agent-inventory.yaml" <<'YAML'
version: "1.0"
agents:
  - agent_id: spec
    expected_runtime: ["claude-code"]
    expected_approval_policy: "on-request"
    expected_network_mode: "off"
YAML
# RUN log has agent_id: implementation, NOT in inventory → silent
write_run_log "${sandbox}/.sage/runs/RUN-9001.yaml" ""
assert_validator "agent_id not in inventory (silent)" "$sandbox" "no"
rm -rf "$sandbox"

echo ""
echo "SUMMARY pass=$PASS fail=$FAIL"
[ "$FAIL" -eq 0 ]
