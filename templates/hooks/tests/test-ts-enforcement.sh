#!/usr/bin/env bash
# =============================================================================
# TASK-0207: test-ts-enforcement.sh (SPEC-0030)
# Purpose:  Integration test for scripts/sage-tsc-ratchet.sh + ESLint fragments:
#           init/check/update/increase detection, invalid/missing baseline
#           fail-closed, tsc command injection priority, fragment presence,
#           jq/eval absence, installer non-change, docs references.
# Style:    Follows test-stack-presets.sh (tmpdir sandbox + ok/not_ok + SUMMARY).
# Note:     Expected values are derived ONLY from SPEC-0030 AC-01..AC-12, the
#           CLI/exit-code contract and documented boundary cases — never from
#           sage-tsc-ratchet.sh internals (AP-07 prevention). tsc is mocked by
#           printf-only bash fixtures (fixtures/mock-tsc-*.sh); no Node/tsc
#           dependency (NFR-03).
# =============================================================================
set -uo pipefail

PASS=0
FAIL=0

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${TEST_DIR}/../../.." && pwd)"
RATCHET="${REPO_ROOT}/scripts/sage-tsc-ratchet.sh"
FIXTURES="${TEST_DIR}/fixtures"
# SPEC-0030 branch base/end: AC-09/AC-12 diff checks are scoped to the closed
# SPEC-0030 commit range so neither unrelated branch history nor later SPECs'
# legitimate changes (e.g. install.sh regeneration under SPEC-0031) pollute
# the check. END_COMMIT is the last SPEC-0030 commit (TASK-0204 RUN log).
BASE_COMMIT="d509a2a"
END_COMMIT="88a33fe"

MOCK0="bash ${FIXTURES}/mock-tsc-0.sh"
MOCK1="bash ${FIXTURES}/mock-tsc-1.sh"
MOCK3="bash ${FIXTURES}/mock-tsc-3.sh"
MOCK5="bash ${FIXTURES}/mock-tsc-5.sh"
MOCKFAIL="bash ${FIXTURES}/mock-tsc-fail.sh"

ok() { PASS=$((PASS + 1)); echo "  ok   $1"; }
not_ok() { FAIL=$((FAIL + 1)); echo "  not ok $1" >&2; }

# run_ratchet <sandbox-dir> <SAGE_TSC_COMMAND value or -> [args...]
# Runs the ratchet from the sandbox cwd. "-" means: do not set the env var.
# Captures RUN_RC / RUN_OUT / RUN_ERR / RUN_ALL (stdout+stderr combined).
run_ratchet() {
  local dir="$1" envcmd="$2"; shift 2
  local out_file err_file
  out_file="$(mktemp -t sage-ts-out-XXXXXX)"
  err_file="$(mktemp -t sage-ts-err-XXXXXX)"
  if [ "$envcmd" = "-" ]; then
    ( cd "$dir" && env -u SAGE_TSC_COMMAND bash "$RATCHET" "$@" \
        </dev/null >"$out_file" 2>"$err_file" )
  else
    ( cd "$dir" && SAGE_TSC_COMMAND="$envcmd" bash "$RATCHET" "$@" \
        </dev/null >"$out_file" 2>"$err_file" )
  fi
  RUN_RC=$?
  RUN_OUT="$(cat "$out_file")"
  RUN_ERR="$(cat "$err_file")"
  RUN_ALL="${RUN_OUT}
${RUN_ERR}"
  rm -f "$out_file" "$err_file"
}

new_sandbox() { mktemp -d -t sage-ts-enf-XXXXXX; }

echo "# ts enforcement — sage-tsc-ratchet.sh + ESLint fragments (SPEC-0030)"

if [ ! -f "$RATCHET" ]; then
  not_ok "scripts/sage-tsc-ratchet.sh not found — cannot run ratchet tests"
  echo ""
  echo "SUMMARY pass=${PASS} fail=${FAIL}"
  exit 1
fi

# =============================================================================
# ケース1: init_and_check_equal — AC-01 (CHECK-001)
# mock tsc (固定3エラー) を SAGE_TSC_COMMAND 注入し --init → baseline に
# "errors": 3、続く検査モード (同数) が exit 0。
# =============================================================================
SB="$(new_sandbox)"
run_ratchet "$SB" "$MOCK3" --init
if [ "$RUN_RC" = "0" ] && grep -qF '"errors": 3' "$SB/.tsc-baseline.json" 2>/dev/null; then
  ok "init_and_check_equal: --init creates baseline with \"errors\": 3 (AC-01)"
else
  not_ok "init_and_check_equal: rc=${RUN_RC} or baseline lacks \"errors\": 3 (AC-01)"
fi
run_ratchet "$SB" "$MOCK3"
if [ "$RUN_RC" = "0" ]; then
  ok "init_and_check_equal: check mode with equal count exits 0 (AC-01)"
else
  not_ok "init_and_check_equal: check mode rc=${RUN_RC}, expected 0 (AC-01)"
fi

# =============================================================================
# ケース2: increase_detected — AC-02 (CHECK-002)
# baseline 3 のまま 5 エラー版 mock で検査モード → exit 1、出力に
# 現在数 5・baseline 3・増分 2 が含まれる (POST-01)。
# =============================================================================
run_ratchet "$SB" "$MOCK5"
if [ "$RUN_RC" = "1" ]; then
  ok "increase_detected: check mode with 5 > baseline 3 exits 1 (AC-02)"
else
  not_ok "increase_detected: rc=${RUN_RC}, expected 1 (AC-02)"
fi
inc_missing=""
for n in 5 3 2; do
  echo "$RUN_ALL" | grep -qF "$n" || inc_missing="${inc_missing} ${n}"
done
if [ -z "$inc_missing" ]; then
  ok "increase_detected: output reports current 5 / baseline 3 / delta 2 (AC-02)"
else
  not_ok "increase_detected: output missing value(s):${inc_missing} (AC-02)"
fi
# AC-02 増加検出は baseline を変更しない (INV-01: 正規更新経路の一意性)
if grep -qF '"errors": 3' "$SB/.tsc-baseline.json"; then
  ok "increase_detected: baseline stays at 3 after failed check (INV-01)"
else
  not_ok "increase_detected: baseline changed by check mode (INV-01)"
fi

# =============================================================================
# ケース3: decrease_and_update — AC-03 (CHECK-003)
# baseline 3 + 1 エラー版 mock → exit 0 + --update 推奨 INFO。
# --update 実行後 baseline が "errors": 1 (POST-02/03)。
# =============================================================================
run_ratchet "$SB" "$MOCK1"
if [ "$RUN_RC" = "0" ]; then
  ok "decrease_and_update: check mode with 1 < baseline 3 exits 0 (AC-03)"
else
  not_ok "decrease_and_update: rc=${RUN_RC}, expected 0 (AC-03)"
fi
if echo "$RUN_ALL" | grep -qF -- '--update'; then
  ok "decrease_and_update: decrease emits --update recommendation INFO (AC-03)"
else
  not_ok "decrease_and_update: no --update recommendation in output (AC-03)"
fi
run_ratchet "$SB" "$MOCK1" --update
if [ "$RUN_RC" = "0" ] && grep -qF '"errors": 1' "$SB/.tsc-baseline.json"; then
  ok "decrease_and_update: --update rewrites baseline to \"errors\": 1 (AC-03)"
else
  not_ok "decrease_and_update: --update rc=${RUN_RC} or baseline not 1 (AC-03)"
fi
rm -r "$SB" 2>/dev/null || true

# =============================================================================
# ケース4: invalid_baseline_rejected — AC-04 (CHECK-004)
# 不正 baseline 3 変種 ({"errors": -1} / {"errors": "abc"} / not-json) で
# 検査モード → いずれも exit 1、stderr に理由、baseline バイト不変
# (FR-04, INV-01/02 fail-closed, 想定エラー1)。
# =============================================================================
for bad in '{"errors": -1}' '{"errors": "abc"}' 'not-json'; do
  SB="$(new_sandbox)"
  printf '%s' "$bad" > "$SB/.tsc-baseline.json"
  before="$(mktemp -t sage-ts-before-XXXXXX)"
  cp "$SB/.tsc-baseline.json" "$before"
  run_ratchet "$SB" "$MOCK3"
  if [ "$RUN_RC" = "1" ] && [ -n "$RUN_ERR" ]; then
    ok "invalid_baseline_rejected[${bad}]: exit 1 with reason on stderr (AC-04)"
  else
    not_ok "invalid_baseline_rejected[${bad}]: rc=${RUN_RC} stderr='${RUN_ERR}' (AC-04)"
  fi
  if cmp -s "$before" "$SB/.tsc-baseline.json"; then
    ok "invalid_baseline_rejected[${bad}]: baseline byte-identical (AC-04)"
  else
    not_ok "invalid_baseline_rejected[${bad}]: baseline modified (AC-04)"
  fi
  rm -f "$before"
  rm -r "$SB" 2>/dev/null || true
done

# =============================================================================
# ケース5: missing_baseline_guided — AC-05 (CHECK-005)
# baseline 不在で検査モード → exit 1 + stderr に --init 案内 (FR-05, 想定エラー2)。
# =============================================================================
SB="$(new_sandbox)"
run_ratchet "$SB" "$MOCK3"
if [ "$RUN_RC" = "1" ]; then
  ok "missing_baseline_guided: check without baseline exits 1 (AC-05)"
else
  not_ok "missing_baseline_guided: rc=${RUN_RC}, expected 1 (AC-05)"
fi
if echo "$RUN_ERR" | grep -qF -- '--init'; then
  ok "missing_baseline_guided: stderr mentions --init (AC-05)"
else
  not_ok "missing_baseline_guided: no --init guidance on stderr (AC-05)"
fi
rm -r "$SB" 2>/dev/null || true

# =============================================================================
# ケース6: tsc_injection_priority — AC-06 (CHECK-006)
# (a) --tsc-command 引数のみで動作 (env 未設定)。
# (b) SAGE_TSC_COMMAND(5err) と --tsc-command(1err) 併存 + baseline 3 →
#     環境変数優先なら増加検出 exit 1 + 現在数 5 (FR-03, PRE-03)。
# =============================================================================
SB="$(new_sandbox)"
run_ratchet "$SB" "-" --init --tsc-command "$MOCK3"
if [ "$RUN_RC" = "0" ] && grep -qF '"errors": 3' "$SB/.tsc-baseline.json" 2>/dev/null; then
  ok "tsc_injection_priority: --tsc-command alone drives --init to 3 (AC-06)"
else
  not_ok "tsc_injection_priority: arg-only injection failed rc=${RUN_RC} (AC-06)"
fi
run_ratchet "$SB" "$MOCK5" --tsc-command "$MOCK1"
if [ "$RUN_RC" = "1" ] && echo "$RUN_ALL" | grep -qF "5"; then
  ok "tsc_injection_priority: env var (5 errors) wins over --tsc-command (1) (AC-06)"
else
  not_ok "tsc_injection_priority: env priority not honored rc=${RUN_RC} (AC-06)"
fi
rm -r "$SB" 2>/dev/null || true

# =============================================================================
# ケース7: eslint_fragments_present — AC-07 (CHECK-007)
# 3 ファイル存在 + ban-ts-comment (flat) / no-explicit-any (transitional=warn)。
# =============================================================================
frag_missing=""
for f in eslint-flat.mjs eslint-flat-transitional.mjs eslintrc-fragment.json; do
  [ -f "${REPO_ROOT}/templates/ts-enforcement/$f" ] || frag_missing="${frag_missing} ${f}"
done
if [ -z "$frag_missing" ]; then
  ok "eslint_fragments_present: all 3 fragment files exist (AC-07)"
else
  not_ok "eslint_fragments_present: missing —${frag_missing} (AC-07)"
fi
if grep -qF 'ban-ts-comment' "${REPO_ROOT}/templates/ts-enforcement/eslint-flat.mjs" 2>/dev/null; then
  ok "eslint_fragments_present: eslint-flat.mjs contains ban-ts-comment (AC-07)"
else
  not_ok "eslint_fragments_present: ban-ts-comment absent from eslint-flat.mjs (AC-07)"
fi
if grep -F 'no-explicit-any' "${REPO_ROOT}/templates/ts-enforcement/eslint-flat-transitional.mjs" 2>/dev/null | grep -qF 'warn'; then
  ok "eslint_fragments_present: transitional no-explicit-any is warn (AC-07)"
else
  not_ok "eslint_fragments_present: transitional no-explicit-any not warn (AC-07)"
fi

# =============================================================================
# ケース8: no_jq_no_eval — AC-08 (CHECK-008)
# sage-tsc-ratchet.sh が jq / eval を使用しない (NFR-02, INV-03, SEC-01)。
# =============================================================================
if grep -E '\bjq\b|\beval\b' "$RATCHET" >/dev/null 2>&1; then
  not_ok "no_jq_no_eval: jq or eval found in sage-tsc-ratchet.sh (AC-08)"
else
  ok "no_jq_no_eval: neither jq nor eval used (AC-08)"
fi

# =============================================================================
# ケース9: installer_untouched — AC-09 (CHECK-009)
# SPEC-0030 コミット群 (closed SPEC-0030 range) の diff に install.sh / SHA256SUMS /
# scripts/generator/ が含まれない (INV-05, SEC-04)。
# =============================================================================
if git -C "$REPO_ROOT" diff --name-only "${BASE_COMMIT}..${END_COMMIT}" 2>/dev/null \
    | grep -qE '^(install\.sh|SHA256SUMS|scripts/generator/)'; then
  not_ok "installer_untouched: installer files changed in ${BASE_COMMIT}..${END_COMMIT} (AC-09)"
else
  ok "installer_untouched: no installer/generator diff in SPEC-0030 commits (AC-09)"
fi

# =============================================================================
# ケース10: runner_untouched — AC-10 (CHECK-010)
# run-tests.sh は自動 discovery のため SPEC-0030 で変更されない (非破壊)。
# 全テスト PASS 自体は run-tests.sh 実行 (Done Definition 自動検証) で確認。
# =============================================================================
if git -C "$REPO_ROOT" diff --name-only "${BASE_COMMIT}..${END_COMMIT}" 2>/dev/null \
    | grep -qF 'templates/hooks/tests/run-tests.sh'; then
  not_ok "runner_untouched: run-tests.sh modified — auto-discovery should suffice (AC-10)"
else
  ok "runner_untouched: run-tests.sh unchanged in SPEC-0030 commits (AC-10)"
fi

# =============================================================================
# ケース11: docs_reference — AC-11 (CHECK-011)
# docs/ts-enforcement.md / docs/stack-presets.md / README.md の相互参照 +
# tsconfig 規約 + graduation (昇格) 節 (FR-07/08, OPS-01)。
# =============================================================================
if grep -qF 'sage-tsc-ratchet' "${REPO_ROOT}/docs/ts-enforcement.md" 2>/dev/null \
   && grep -qF 'ts-enforcement' "${REPO_ROOT}/docs/stack-presets.md" 2>/dev/null \
   && grep -qF 'ts-enforcement' "${REPO_ROOT}/README.md" 2>/dev/null; then
  ok "docs_reference: cross-references present in docs + README (AC-11)"
else
  not_ok "docs_reference: missing cross-reference(s) (AC-11)"
fi
if grep -qF 'tsconfig' "${REPO_ROOT}/docs/ts-enforcement.md" 2>/dev/null; then
  ok "docs_reference: tsconfig convention documented (AC-11)"
else
  not_ok "docs_reference: tsconfig not mentioned in docs/ts-enforcement.md (AC-11)"
fi
if grep -qE '昇格|graduation' "${REPO_ROOT}/docs/ts-enforcement.md" 2>/dev/null; then
  ok "docs_reference: graduation section documented (AC-11)"
else
  not_ok "docs_reference: graduation/昇格 absent from docs/ts-enforcement.md (AC-11)"
fi

# =============================================================================
# ケース12: preset_values_unchanged — AC-12 (CHECK-012)
# templates/project-checks/ts-pnpm.yaml が SPEC-0030 コミット群で不変
# (INV-06, リスク5 判断済み)。
# =============================================================================
if [ -z "$(git -C "$REPO_ROOT" diff "${BASE_COMMIT}..${END_COMMIT}" -- templates/project-checks/ts-pnpm.yaml 2>/dev/null)" ]; then
  ok "preset_values_unchanged: ts-pnpm.yaml has no diff in SPEC-0030 commits (AC-12)"
else
  not_ok "preset_values_unchanged: ts-pnpm.yaml modified (AC-12)"
fi

# =============================================================================
# ケース13: zero_baseline — 境界ケース1
# エラー 0 件で --init → "errors": 0、検査モード exit 0、
# 0 件からの増加 (1 エラー) も exit 1 で検出される。
# =============================================================================
SB="$(new_sandbox)"
run_ratchet "$SB" "$MOCK0" --init
if [ "$RUN_RC" = "0" ] && grep -qF '"errors": 0' "$SB/.tsc-baseline.json" 2>/dev/null; then
  ok "zero_baseline: --init on clean project writes \"errors\": 0 (boundary 1)"
else
  not_ok "zero_baseline: rc=${RUN_RC} or baseline not 0 (boundary 1)"
fi
run_ratchet "$SB" "$MOCK0"
if [ "$RUN_RC" = "0" ]; then
  ok "zero_baseline: check mode at 0 vs 0 exits 0 (boundary 1)"
else
  not_ok "zero_baseline: rc=${RUN_RC}, expected 0 (boundary 1)"
fi
run_ratchet "$SB" "$MOCK1"
if [ "$RUN_RC" = "1" ]; then
  ok "zero_baseline: increase from 0 to 1 detected as exit 1 (boundary 1)"
else
  not_ok "zero_baseline: increase from 0 not detected rc=${RUN_RC} (boundary 1)"
fi

# =============================================================================
# ケース14: init_existing_rejected — 想定エラー3 (FR-02)
# 既存 baseline がある状態で --init → exit 1 + --update 案内、baseline 非変更。
# =============================================================================
before="$(mktemp -t sage-ts-before-XXXXXX)"
cp "$SB/.tsc-baseline.json" "$before"
run_ratchet "$SB" "$MOCK3" --init
if [ "$RUN_RC" = "1" ] && echo "$RUN_ALL" | grep -qF -- '--update'; then
  ok "init_existing_rejected: --init on existing baseline exits 1 with --update guidance (FR-02)"
else
  not_ok "init_existing_rejected: rc=${RUN_RC} or no --update guidance (FR-02)"
fi
if cmp -s "$before" "$SB/.tsc-baseline.json"; then
  ok "init_existing_rejected: baseline unchanged by rejected --init (FR-02, INV-01)"
else
  not_ok "init_existing_rejected: baseline modified by rejected --init (FR-02, INV-01)"
fi
rm -f "$before"

# =============================================================================
# ケース15: tsc_failure_distinguished — 境界ケース2 (INV-02 fail-closed)
# tsc 実行失敗 (error TS パターン 0 件 + 非0 exit) → exit 1 + 出力を stderr へ
# 透過。エラー 0 件 (exit 0) と誤認しない。baseline も非変更。
# =============================================================================
before="$(mktemp -t sage-ts-before-XXXXXX)"
cp "$SB/.tsc-baseline.json" "$before"
run_ratchet "$SB" "$MOCKFAIL"
if [ "$RUN_RC" = "1" ]; then
  ok "tsc_failure_distinguished: tsc execution failure exits 1, not 0 (boundary 2)"
else
  not_ok "tsc_failure_distinguished: rc=${RUN_RC}, expected 1 (boundary 2)"
fi
if echo "$RUN_ERR" | grep -qF 'command not found'; then
  ok "tsc_failure_distinguished: failing tsc output passed through to stderr (boundary 2)"
else
  not_ok "tsc_failure_distinguished: tsc output not surfaced on stderr (boundary 2)"
fi
if cmp -s "$before" "$SB/.tsc-baseline.json"; then
  ok "tsc_failure_distinguished: baseline unchanged on tsc failure (INV-01)"
else
  not_ok "tsc_failure_distinguished: baseline modified on tsc failure (INV-01)"
fi
rm -f "$before"
rm -r "$SB" 2>/dev/null || true

echo ""
echo "SUMMARY pass=${PASS} fail=${FAIL}"
[ "$FAIL" -eq 0 ] || exit 1
exit 0
