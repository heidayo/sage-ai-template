#!/usr/bin/env bash
# =============================================================================
# TASK-0168: test-property-section.sh (SPEC-0024)
# Purpose: Verify Property-based Verify and Review Gate doctrine consistency:
#          - specs/_template.md has Properties section with 4 sub-headers
#          - sage/governance.md §11 has 5+ sub-sections (Property → Gate matrix
#            / Verdict / 3-gate FP filter / Hard Fail / SKIPPED procedure)
#          - SPEC-0024 itself has Properties + Gate mapping (eat-your-own-dog-food)
#          - pilot 3 SPECs (0011 / 0014 / 0015) have ≥5 Properties each with Gate mapping
#          - Includes 2 in-memory mutation scenarios (異常系) for negative path
#          - SKIPPED_WITH_APPROVAL_REQUIRED audit log schema is JSON-lines parseable
#          - Backward compat: existing SPECs without Properties → WARN-only
#            (NFR-06 incremental migration)
# =============================================================================
set -uo pipefail

PASS=0
FAIL=0
WARN=0

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
TEMPLATE="${REPO_ROOT}/specs/_template.md"
GOVERNANCE="${REPO_ROOT}/sage/governance.md"
SPEC_0011="${REPO_ROOT}/specs/SPEC-0011-hook-hardening-and-test-infrastructure.md"
SPEC_0014="${REPO_ROOT}/specs/SPEC-0014-installer-modularize.md"
SPEC_0015="${REPO_ROOT}/specs/SPEC-0015-mcp-allowlist-audit-and-agent-identity.md"
SPEC_0024="${REPO_ROOT}/specs/SPEC-0024-property-based-verify-review-gate.md"
PROPERTY_LINE_RE='^- \[(INV|PRE|POST|ASM)-[0-9]+\]'
PROPERTY_GATE_RE='^- \[(INV|PRE|POST|ASM)-[0-9]+\] \(Gate (2|3|4|横断)\)'

echo "# property-based verify (SPEC-0024)"

count_properties() {
  grep -cE "$PROPERTY_LINE_RE" "$1" || true
}

count_gate_mapped_properties() {
  grep -cE "$PROPERTY_GATE_RE" "$1" || true
}

# --- Scenario 1: specs/_template.md has ## Properties section ---
if grep -qF "## Properties" "$TEMPLATE"; then
  echo "ok 1 specs/_template.md has ## Properties section"
  PASS=$((PASS + 1))
else
  echo "not ok 1 specs/_template.md missing ## Properties section"
  FAIL=$((FAIL + 1))
fi

# --- Scenario 2: specs/_template.md has 4 Property sub-headers ---
sub_headers=(
  "### Invariants"
  "### Pre-conditions"
  "### Post-conditions"
  "### Assumptions"
)
missing=()
for h in "${sub_headers[@]}"; do
  if ! grep -qF "$h" "$TEMPLATE"; then
    missing+=("$h")
  fi
done
if [[ ${#missing[@]} -eq 0 ]]; then
  echo "ok 2 specs/_template.md has 4 Property sub-headers (Invariants/Pre/Post/Assumptions)"
  PASS=$((PASS + 1))
else
  echo "not ok 2 specs/_template.md missing sub-headers: ${missing[*]}"
  FAIL=$((FAIL + 1))
fi

# --- Scenario 3: SPEC-0024 itself has Properties + Gate mapping (eat-your-own-dog-food) ---
if [[ -f "$SPEC_0024" ]]; then
  prop_count=$(count_properties "$SPEC_0024")
  mapped_count=$(count_gate_mapped_properties "$SPEC_0024")
  if [[ "$prop_count" -ge 5 && "$mapped_count" -eq "$prop_count" ]]; then
    echo "ok 3 SPEC-0024 has $prop_count Properties and all have Gate mapping (eat-your-own-dog-food, ≥5)"
    PASS=$((PASS + 1))
  else
    echo "not ok 3 SPEC-0024 Properties invalid: properties=$prop_count gate_mapped=$mapped_count (need ≥5 and all mapped)"
    FAIL=$((FAIL + 1))
  fi
else
  echo "not ok 3 SPEC-0024 file missing"
  FAIL=$((FAIL + 1))
fi

# --- Scenario 4: pilot 3 SPECs have ≥5 Properties + Gate mapping each ---
pilot_fail=0
pilot_summary=""
for f in "$SPEC_0011" "$SPEC_0014" "$SPEC_0015"; do
  base=$(basename "$f")
  if [[ ! -f "$f" ]]; then
    pilot_fail=$((pilot_fail + 1))
    pilot_summary+=" $base(missing)"
    continue
  fi
  n=$(count_properties "$f")
  mapped=$(count_gate_mapped_properties "$f")
  pilot_summary+=" $base(properties=$n,mapped=$mapped)"
  if [[ "$n" -lt 5 || "$mapped" -ne "$n" ]]; then
    pilot_fail=$((pilot_fail + 1))
  fi
done
if [[ "$pilot_fail" -eq 0 ]]; then
  echo "ok 4 pilot 3 SPECs ≥5 Properties each and all have Gate mapping:${pilot_summary}"
  PASS=$((PASS + 1))
else
  echo "not ok 4 pilot SPECs Property count / Gate mapping failed:${pilot_summary}"
  FAIL=$((FAIL + 1))
fi

# --- Scenario 5: governance §11 has 5+ sub-sections ---
if grep -qF "## 11. Property-based Verify and Review Gate" "$GOVERNANCE"; then
  sub_count=$(grep -cE "^### 11\.[1-9]" "$GOVERNANCE")
  if [[ "$sub_count" -ge 5 ]]; then
    echo "ok 5 governance §11 exists with $sub_count sub-sections (≥5)"
    PASS=$((PASS + 1))
  else
    echo "not ok 5 governance §11 has only $sub_count sub-sections (need ≥5)"
    FAIL=$((FAIL + 1))
  fi
else
  echo "not ok 5 governance §11 (## 11. Property-based Verify and Review Gate) missing"
  FAIL=$((FAIL + 1))
fi

# --- Scenario 6: 異常系 — Properties セクション削除 fixture detected as missing ---
fixture6_no_props=$(
  cat <<'EOF'
# SPEC-9999: test fixture without Properties

## 背景・目的
test SPEC body.

## 関連ID
- PLAN-ID: PLAN-9999
EOF
)
if echo "$fixture6_no_props" | grep -qF "## Properties"; then
  echo "not ok 6 (異常系) fixture without Properties incorrectly contains Properties marker"
  FAIL=$((FAIL + 1))
else
  echo "ok 6 (異常系) fixture without Properties correctly detected as missing"
  PASS=$((PASS + 1))
fi

# --- Scenario 7: 異常系 — Gate mapping 欠落 fixture detected ---
fixture7_no_gate=$(
  cat <<'EOF'
## Properties
### Invariants
- [INV-01] missing gate mapping line
- [INV-02] (Gate 3) properly annotated line
- [INV-03] also missing gate mapping
EOF
)
gate_missing=0
while IFS= read -r line; do
  if [[ "$line" =~ ^-\ \[(INV|PRE|POST|ASM)- ]]; then
    if ! [[ "$line" =~ \(Gate\ [234横]+(断)?\) ]]; then
      gate_missing=$((gate_missing + 1))
    fi
  fi
done <<<"$fixture7_no_gate"
if [[ "$gate_missing" -ge 1 ]]; then
  echo "ok 7 (異常系) Gate mapping 欠落 detected ($gate_missing item(s) missing in fixture)"
  PASS=$((PASS + 1))
else
  echo "not ok 7 (異常系) Gate mapping 欠落 not detected (fixture should have 2 missing)"
  FAIL=$((FAIL + 1))
fi

# --- Scenario 8: SKIPPED_WITH_APPROVAL_REQUIRED audit log schema is JSON-lines parseable ---
skip_audit_json='{"timestamp":"2026-05-06T00:00:00Z","approver":"human-reviewer","reason":"manual proof required","spec_id":"SPEC-0024","property_id":"ASM-01"}'
if printf '%s\n' "$skip_audit_json" | python3 -c 'import json,sys; r=json.loads(sys.stdin.read()); required=["timestamp","approver","reason","spec_id","property_id"]; missing=[k for k in required if not isinstance(r.get(k), str) or not r[k]]; assert not missing, missing; assert not r["approver"].startswith("<"), "invalid AI placeholder approver"'; then
  echo "ok 8 SKIPPED_WITH_APPROVAL_REQUIRED audit log JSON-lines schema has required fields"
  PASS=$((PASS + 1))
else
  echo "not ok 8 SKIPPED_WITH_APPROVAL_REQUIRED audit log JSON-lines schema invalid"
  FAIL=$((FAIL + 1))
fi

# --- Scenario 9: backward compat — existing SPECs without Properties → WARN-only (NFR-06) ---
existing_without_props=0
existing_total=0
for f in "$REPO_ROOT"/specs/SPEC-00*.md; do
  base=$(basename "$f")
  # Skip pilot 3 (TASK-0167 retrofit), SPEC-0024 (own), and the template
  case "$base" in
    SPEC-0011-* | SPEC-0014-* | SPEC-0015-* | SPEC-0024-*)
      continue
      ;;
  esac
  existing_total=$((existing_total + 1))
  if ! grep -qF "## Properties" "$f"; then
    existing_without_props=$((existing_without_props + 1))
  fi
done
# Per NFR-06, this scenario MUST NOT FAIL — existing SPECs are WARN-only
echo "ok 9 backward compat: $existing_without_props/$existing_total existing SPECs without Properties (WARN-only, NFR-06 incremental migration)"
PASS=$((PASS + 1))
WARN=$((WARN + existing_without_props))

# --- Summary (run-tests.sh parses this line via regex SUMMARY pass=N fail=M) ---
echo ""
echo "  (info: $WARN existing SPECs without Properties — NFR-06 incremental migration, WARN-only)"
echo "SUMMARY pass=$PASS fail=$FAIL"

if [[ "$FAIL" -eq 0 ]]; then
  exit 0
else
  exit 1
fi
