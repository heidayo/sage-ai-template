#!/usr/bin/env bash
# =============================================================================
# TASK-0210: test-gate-fp-idgen.sh (SPEC-0031)
# Purpose:  Integration test for the gate-fp ID type in sage-id-gen.sh:
#           failures.md GATE-FP template presence, escalation rules,
#           numbering (first / next / gap-no-reuse), existing-type
#           non-regression, missing-file behavior, unknown-type rejection,
#           and FAIL vs GATE-FP number-space independence.
# Style:    Follows test-id-patterns.sh (tmpdir sandboxes + fixture
#           failures.md, scripts copied into the sandbox).
# Note:     Expected values are derived from SPEC-0031 AC-01..AC-07 and the
#           異常系/境界ケース sections only, never from script internals
#           (AP-07 prevention). Behavior is observed via the public CLI
#           contract: `bash scripts/sage-id-gen.sh <type>`.
# =============================================================================
set -uo pipefail

PASS=0
FAIL=0

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${TEST_DIR}/../../.." && pwd)"
IDGEN="${REPO_ROOT}/scripts/sage-id-gen.sh"
LOADER="${REPO_ROOT}/scripts/sage-id-pattern.sh"
FIXTURES="${TEST_DIR}/fixtures"
FAILURES_MD="${REPO_ROOT}/sage/failures.md"

ok() { PASS=$((PASS + 1)); echo "  ok   $1"; }
not_ok() { FAIL=$((FAIL + 1)); echo "  not ok $1" >&2; }

# idgen_sandbox — tmpdir with scripts/sage-id-gen.sh + loader; caller adds
# the failures.md fixture / directories per case (test-id-patterns.sh style).
idgen_sandbox() {
  local dir
  dir="$(mktemp -d -t sage-gatefp-XXXXXX)"
  mkdir -p "${dir}/scripts" "${dir}/sage"
  cp "$IDGEN" "${dir}/scripts/"
  cp "$LOADER" "${dir}/scripts/"
  echo "$dir"
}

# run_idgen <sandbox> <args...> — run the public CLI contract from the
# sandbox cwd. Sets GEN_OUT / GEN_RC (stdout+stderr combined in GEN_ALL).
run_idgen() {
  local dir="$1"; shift
  local out_file err_file
  out_file="$(mktemp -t sage-gatefp-out-XXXXXX)"
  err_file="$(mktemp -t sage-gatefp-err-XXXXXX)"
  ( cd "$dir" && bash scripts/sage-id-gen.sh "$@" >"$out_file" 2>"$err_file" )
  GEN_RC=$?
  GEN_OUT="$(cat "$out_file")"
  GEN_ALL="$(cat "$out_file" "$err_file")"
  rm -f "$out_file" "$err_file"
}

echo "# gate-fp id-gen (SPEC-0031)"

if [ ! -f "$IDGEN" ] || [ ! -f "$LOADER" ]; then
  not_ok "scripts/sage-id-gen.sh or scripts/sage-id-pattern.sh not found — cannot run gate-fp tests"
  echo ""
  echo "SUMMARY pass=${PASS} fail=${FAIL}"
  exit 1
fi

# =============================================================================
# ケース1: template_fields_present — AC-01
# sage/failures.md に GATE-FP-XXXX テンプレート節と必須 7 フィールドが存在する
# =============================================================================
if grep -qF 'GATE-FP-XXXX' "$FAILURES_MD"; then
  ok "template_fields_present: GATE-FP-XXXX template section exists in sage/failures.md (AC-01)"
else
  not_ok "template_fields_present: 'GATE-FP-XXXX' not found in sage/failures.md (AC-01)"
fi
missing_fields=""
for kw in '発生日' '誤検知した Gate' 'TASK-ID' '誤検知の根拠' '一時対応' '恒久対応' '再発回数'; do
  grep -qF "$kw" "$FAILURES_MD" || missing_fields="${missing_fields} ${kw}"
done
if [ -z "$missing_fields" ]; then
  ok "template_fields_present: all 7 required fields present (AC-01)"
else
  not_ok "template_fields_present: missing fields:${missing_fields} (AC-01)"
fi

# =============================================================================
# ケース2: escalation_rule_present — AC-02
# 使い分け (FAIL vs GATE-FP) と 3 回エスカレーションルールが記載されている
# =============================================================================
if grep -qF 'GATE-FP' "$FAILURES_MD" && grep -qE '3\s*回' "$FAILURES_MD" \
    && grep -qF 'gate 設定の見直し' "$FAILURES_MD"; then
  ok "escalation_rule_present: 3-strike gate-review escalation rule present (AC-02)"
else
  not_ok "escalation_rule_present: escalation rule (3回 / gate 設定の見直し) missing (AC-02)"
fi
if grep -qF 'FAIL-XXXX' "$FAILURES_MD" && grep -qF 'GATE-FP-XXXX' "$FAILURES_MD"; then
  ok "escalation_rule_present: FAIL-XXXX vs GATE-FP-XXXX usage distinction documented (AC-02)"
else
  not_ok "escalation_rule_present: FAIL-XXXX / GATE-FP-XXXX distinction missing (AC-02)"
fi

# =============================================================================
# ケース3: idgen_first — AC-03
# GATE-FP エントリ 0 件の fixture で gate-fp 採番が GATE-FP-0001
# =============================================================================
SB1="$(idgen_sandbox)"
cp "${FIXTURES}/failures-gate-fp-none.md" "$SB1/sage/failures.md"
run_idgen "$SB1" gate-fp
if [ "$GEN_RC" = "0" ] && [ "$GEN_OUT" = "GATE-FP-0001" ]; then
  ok "idgen_first: 0 entries -> GATE-FP-0001, exit 0 (AC-03)"
else
  not_ok "idgen_first: expected 'GATE-FP-0001' rc=0, got '${GEN_OUT}' rc=${GEN_RC} (AC-03)"
fi

# =============================================================================
# ケース4: idgen_next — AC-04 (境界ケース1: 欠番不詰め)
# GATE-FP-0001 / GATE-FP-0003 (0002 欠番) の fixture で次番号が GATE-FP-0004
# =============================================================================
SB2="$(idgen_sandbox)"
cp "${FIXTURES}/failures-gate-fp-multi.md" "$SB2/sage/failures.md"
run_idgen "$SB2" gate-fp
if [ "$GEN_RC" = "0" ] && [ "$GEN_OUT" = "GATE-FP-0004" ]; then
  ok "idgen_next: max 0003 + 1 -> GATE-FP-0004, gap 0002 not reused (AC-04)"
else
  not_ok "idgen_next: expected 'GATE-FP-0004' rc=0, got '${GEN_OUT}' rc=${GEN_RC} (AC-04)"
fi

# =============================================================================
# ケース5: existing_types_unchanged — AC-05 (+ 境界ケース3: 番号空間独立)
# spec/plan/task/run/fail の採番ロジックが従来どおり、引数なしは exit 1 + usage
# =============================================================================
SB3="$(idgen_sandbox)"
mkdir -p "$SB3/specs" "$SB3/plans" "$SB3/tasks" "$SB3/.sage/runs"
printf '# fixture\n' > "$SB3/specs/SPEC-0002-fixture.md"
printf '# fixture\n' > "$SB3/plans/PLAN-0005-fixture.md"
printf '# fixture\n' > "$SB3/tasks/TASK-0010-fixture.md"
printf '# fixture\n' > "$SB3/.sage/runs/RUN-0007-fixture.md"
# fail scans failures.md: fixture has FAIL-0001 + GATE-FP-0001/0003.
# 境界ケース3: FAIL の ERE は GATE-FP- にマッチしないため次番号は FAIL-0002。
cp "${FIXTURES}/failures-gate-fp-multi.md" "$SB3/sage/failures.md"
declare_expected="SPEC-0003 PLAN-0006 TASK-0011 RUN-0008 FAIL-0002"
i=0
for t in spec plan task run fail; do
  i=$((i + 1))
  expected="$(echo "$declare_expected" | cut -d' ' -f"$i")"
  run_idgen "$SB3" "$t"
  if [ "$GEN_RC" = "0" ] && [ "$GEN_OUT" = "$expected" ]; then
    ok "existing_types_unchanged: '$t' -> ${expected} (max + 1, unchanged logic) (AC-05)"
  else
    not_ok "existing_types_unchanged: '$t' expected '${expected}' rc=0, got '${GEN_OUT}' rc=${GEN_RC} (AC-05)"
  fi
done
# 境界ケース3 明示: GATE-FP-0003 が存在しても fail は FAIL-0002 (上で検証済みの
# 値が GATE-FP の存在に影響されていないことをラベルとして固定)
if [ "$GEN_OUT" = "FAIL-0002" ]; then
  ok "existing_types_unchanged: FAIL number space independent of GATE-FP entries (境界ケース3 / INV-02)"
else
  not_ok "existing_types_unchanged: FAIL numbering affected by GATE-FP entries, got '${GEN_OUT}' (境界ケース3 / INV-02)"
fi
# 引数なし: 従来どおり exit 1 + usage
run_idgen "$SB3"
if [ "$GEN_RC" = "1" ] && echo "$GEN_ALL" | grep -qF 'Usage:'; then
  ok "existing_types_unchanged: no-arg exits 1 with usage (AC-05)"
else
  not_ok "existing_types_unchanged: no-arg expected rc=1 + usage, got rc=${GEN_RC} out='${GEN_ALL}' (AC-05)"
fi

# =============================================================================
# ケース6: idgen_missing_file — AC-06 (想定エラー1)
# sage/failures.md 不在で gate-fp が GATE-FP-0001 を出力し exit 0
# =============================================================================
SB4="$(idgen_sandbox)"
rm -f "$SB4/sage/failures.md"
run_idgen "$SB4" gate-fp
if [ "$GEN_RC" = "0" ] && [ "$GEN_OUT" = "GATE-FP-0001" ]; then
  ok "idgen_missing_file: missing failures.md -> GATE-FP-0001, exit 0 (AC-06)"
else
  not_ok "idgen_missing_file: expected 'GATE-FP-0001' rc=0, got '${GEN_OUT}' rc=${GEN_RC} (AC-06)"
fi

# =============================================================================
# ケース7: unknown_type_rejected — AC-07 (想定エラー2)
# typo 種別 (gatefp) は exit 非 0 で、usage に gate-fp を含む種別一覧を出す
# =============================================================================
SB5="$(idgen_sandbox)"
run_idgen "$SB5" gatefp
if [ "$GEN_RC" != "0" ]; then
  ok "unknown_type_rejected: 'gatefp' (typo) exits non-zero (AC-07)"
else
  not_ok "unknown_type_rejected: 'gatefp' accepted, expected rejection (AC-07)"
fi
if echo "$GEN_ALL" | grep -qF 'gate-fp'; then
  ok "unknown_type_rejected: usage lists 'gate-fp' among valid types (AC-07)"
else
  not_ok "unknown_type_rejected: usage does not mention 'gate-fp': '${GEN_ALL}' (AC-07)"
fi

# Cleanup: only mktemp-created sandboxes (rm -r without -f on unique tmpdirs).
for d in "${SB1:-}" "${SB2:-}" "${SB3:-}" "${SB4:-}" "${SB5:-}"; do
  case "$d" in
    */sage-gatefp-*) rm -r "$d" 2>/dev/null || true ;;
  esac
done

echo ""
echo "SUMMARY pass=${PASS} fail=${FAIL}"
[ "$FAIL" -eq 0 ]
