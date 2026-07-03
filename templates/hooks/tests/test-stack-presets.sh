#!/usr/bin/env bash
# =============================================================================
# TASK-0196: test-stack-presets.sh (SPEC-0028)
# Purpose:  Integration test for project_checks stack presets: explicit
#           --stack apply, marker autodetect + priority, no-marker fallback,
#           preserve-if-exists, unknown-stack rejection, dry-run non-write.
# Style:    Follows test-installer-preservation.sh (tmpdir + install.sh run).
# Note:     Expected values are derived from SPEC-0028 AC-01..AC-12 and the
#           documented boundary cases only, never from installer internals
#           (AP-07 prevention). The AC-05 baseline fixture
#           fixtures/project-checks-default.golden was frozen from the
#           pre-change (main) install.sh output, not from this branch's
#           artifact (PLAN-0028 risk 5: no self-referential golden).
# =============================================================================
set -uo pipefail

PASS=0
FAIL=0

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${TEST_DIR}/../../.." && pwd)"
INSTALL_SH="${REPO_ROOT}/install.sh"
GOLDEN="${TEST_DIR}/fixtures/project-checks-default.golden"

ok() { PASS=$((PASS + 1)); echo "  ok   $1"; }
not_ok() { FAIL=$((FAIL + 1)); echo "  not ok $1" >&2; }

# run_install <sandbox-dir> [args...] — run install.sh from a sandbox cwd,
# capturing rc / stdout / stderr into RUN_RC / RUN_OUT / RUN_ERR.
run_install() {
  local dir="$1"; shift
  local out_file err_file
  out_file="$(mktemp -t sage-stack-out-XXXXXX)"
  err_file="$(mktemp -t sage-stack-err-XXXXXX)"
  ( cd "$dir" && bash "$INSTALL_SH" "$@" </dev/null >"$out_file" 2>"$err_file" )
  RUN_RC=$?
  RUN_OUT="$(cat "$out_file")"
  RUN_ERR="$(cat "$err_file")"
  rm -f "$out_file" "$err_file"
}

# project_checks_section <config.yaml> — extract the project_checks section
# (from the `project_checks:` line up to the first blank line). Same rule was
# used to freeze the golden fixture from the pre-change install.sh output.
project_checks_section() {
  awk '/^project_checks:/{f=1} f && /^$/{exit} f{print}' "$1"
}

echo "# project_checks stack presets (SPEC-0028)"

if [ ! -f "$INSTALL_SH" ]; then
  not_ok "install.sh not found at ${INSTALL_SH} — cannot run stack preset tests"
  echo ""
  echo "SUMMARY pass=${PASS} fail=${FAIL}"
  exit 1
fi
if [ ! -f "$GOLDEN" ]; then
  not_ok "golden fixture not found at ${GOLDEN} (AC-05 baseline)"
  echo ""
  echo "SUMMARY pass=${PASS} fail=${FAIL}"
  exit 1
fi

# =============================================================================
# ケース1: presets_exist_and_complete — AC-01 (CHECK-001)
# 4 プリセット x 5 キーが templates/project-checks/ に存在・形式充足
# =============================================================================
preset_missing=""
for f in go ts-pnpm node-npm python; do
  for k in lint format type_check test_command coverage_command; do
    grep -qE "^ *${k}:" "${REPO_ROOT}/templates/project-checks/${f}.yaml" 2>/dev/null \
      || preset_missing="${preset_missing} ${f}.yaml:${k}"
  done
done
if [ -z "$preset_missing" ]; then
  ok "presets_exist_and_complete: all 4 presets have the 5 required keys (AC-01)"
else
  not_ok "presets_exist_and_complete: missing keys —${preset_missing} (AC-01)"
fi

# =============================================================================
# ケース2: explicit_stack_applied — AC-02 (CHECK-002)
# 空の一時ディレクトリで --stack <name> 適用後、config.yaml がそのスタックの
# コマンドを含み、他スタック固有コマンドを含まない (4 プリセット同型検証)。
# 期待マーカーは AC-02 例示 (pnpm 含む / go vet 非含む) を各スタックの標準
# ツールチェーンへ一般化したもの。
# =============================================================================
# stack:expected_present:expected_absent
for spec in \
  "go:go vet:pnpm" \
  "ts-pnpm:pnpm:go vet" \
  "node-npm:npm:go vet" \
  "python:pytest:go vet"; do
  stack="${spec%%:*}"; rest="${spec#*:}"
  want="${rest%%:*}"; absent="${rest#*:}"
  SB="$(mktemp -d -t sage-stack-ex-XXXXXX)"
  run_install "$SB" --stack "$stack"
  if [ "$RUN_RC" = "0" ] && [ -f "$SB/.sage/config.yaml" ]; then
    ok "explicit_stack_applied[${stack}]: install --stack ${stack} exits 0 and writes config.yaml (AC-02)"
  else
    not_ok "explicit_stack_applied[${stack}]: rc=${RUN_RC} or config.yaml missing (AC-02)"
  fi
  section="$(project_checks_section "$SB/.sage/config.yaml" 2>/dev/null)"
  if echo "$section" | grep -vE '^\s*#' | grep -qF -- "$want"; then
    ok "explicit_stack_applied[${stack}]: project_checks contains '${want}' (AC-02)"
  else
    not_ok "explicit_stack_applied[${stack}]: project_checks lacks '${want}' (AC-02)"
  fi
  if echo "$section" | grep -vE '^\s*#' | grep -qF -- "$absent"; then
    not_ok "explicit_stack_applied[${stack}]: foreign command '${absent}' present in active keys (AC-02)"
  else
    ok "explicit_stack_applied[${stack}]: no foreign command '${absent}' in active keys (AC-02)"
  fi
  rm -r "$SB" 2>/dev/null || true
done

# =============================================================================
# ケース3: autodetect_single — AC-03 (CHECK-003)
# go.mod のみの一時ディレクトリで --stack なし install → go プリセット適用
# + stdout に検出 INFO (go.mod 言及)
# =============================================================================
SB="$(mktemp -d -t sage-stack-ad1-XXXXXX)"
printf 'module example.com/m\n' > "$SB/go.mod"
run_install "$SB"
if [ "$RUN_RC" = "0" ] \
   && project_checks_section "$SB/.sage/config.yaml" 2>/dev/null | grep -vE '^\s*#' | grep -qF 'go vet ./...'; then
  ok "autodetect_single: go.mod-only dir gets go preset (go vet ./...) (AC-03)"
else
  not_ok "autodetect_single: go preset not applied, rc=${RUN_RC} (AC-03)"
fi
if echo "$RUN_OUT" | grep -qF 'go.mod'; then
  ok "autodetect_single: stdout INFO mentions detected marker go.mod (AC-03 / POST-02)"
else
  not_ok "autodetect_single: no go.mod detection INFO on stdout (AC-03 / POST-02)"
fi
rm -r "$SB" 2>/dev/null || true

# =============================================================================
# ケース4: autodetect_priority — AC-04 (CHECK-004)
# go.mod + package.json 併存 → 優先順位 go > ts-pnpm > node-npm > python で
# go を適用、INFO に両マーカーの検出 (複数検出 + 採用理由の可視化)
# =============================================================================
SB="$(mktemp -d -t sage-stack-ad2-XXXXXX)"
printf 'module example.com/m\n' > "$SB/go.mod"
printf '{"name":"m"}\n' > "$SB/package.json"
run_install "$SB"
if [ "$RUN_RC" = "0" ] \
   && project_checks_section "$SB/.sage/config.yaml" 2>/dev/null | grep -vE '^\s*#' | grep -qF 'go vet'; then
  ok "autodetect_priority: go.mod+package.json applies go preset (AC-04)"
else
  not_ok "autodetect_priority: go preset not applied on multi-marker, rc=${RUN_RC} (AC-04)"
fi
if echo "$RUN_OUT" | grep -qF 'go.mod' && echo "$RUN_OUT" | grep -qF 'package.json'; then
  ok "autodetect_priority: INFO reports both detected markers (AC-04 / FR-04)"
else
  not_ok "autodetect_priority: INFO does not report all detected markers (AC-04 / FR-04)"
fi
rm -r "$SB" 2>/dev/null || true

# 境界ケース1: pnpm-lock.yaml + package.json 併存 → ts-pnpm 採用
# (pnpm マーカーは package.json より特異的、FR-04)
SB="$(mktemp -d -t sage-stack-ad3-XXXXXX)"
printf '{"name":"m"}\n' > "$SB/package.json"
printf 'lockfileVersion: 9\n' > "$SB/pnpm-lock.yaml"
run_install "$SB"
if [ "$RUN_RC" = "0" ] \
   && project_checks_section "$SB/.sage/config.yaml" 2>/dev/null | grep -vE '^\s*#' | grep -qF 'pnpm'; then
  ok "autodetect_priority: pnpm-lock.yaml+package.json applies ts-pnpm preset (AC-04 / 境界ケース1)"
else
  not_ok "autodetect_priority: ts-pnpm not chosen over node-npm, rc=${RUN_RC} (AC-04 / 境界ケース1)"
fi
rm -r "$SB" 2>/dev/null || true

# =============================================================================
# ケース5: autodetect_none_fallback — AC-05 (CHECK-005) / NFR-01 / 境界ケース2
# マーカーなし → project_checks セクションが変更前 (main) install.sh 生成物
# から固定した golden fixture と diff 一致 (後方互換)
# =============================================================================
SB="$(mktemp -d -t sage-stack-ad0-XXXXXX)"
run_install "$SB"
if [ "$RUN_RC" = "0" ]; then
  ok "autodetect_none_fallback: marker-less install exits 0 (AC-05)"
else
  not_ok "autodetect_none_fallback: marker-less install rc=${RUN_RC} (AC-05)"
fi
actual_section="$(mktemp -t sage-stack-sec-XXXXXX)"
project_checks_section "$SB/.sage/config.yaml" 2>/dev/null > "$actual_section"
if diff -u "$GOLDEN" "$actual_section" >/dev/null 2>&1; then
  ok "autodetect_none_fallback: project_checks section matches pre-change golden (AC-05 / NFR-01 / INV-02)"
else
  not_ok "autodetect_none_fallback: project_checks section differs from pre-change golden (AC-05 / NFR-01 / INV-02)"
  diff -u "$GOLDEN" "$actual_section" | head -10 >&2
fi
rm -f "$actual_section"
rm -r "$SB" 2>/dev/null || true

# =============================================================================
# ケース6: existing_config_preserved — AC-06 (CHECK-006) / INV-01 / 想定エラー2
# カスタム project_checks 入り config.yaml 配置済み環境で --stack python →
# config.yaml バイト不変 + スキップ INFO + install 自体は正常続行 (exit 0)
# =============================================================================
SB="$(mktemp -d -t sage-stack-keep-XXXXXX)"
mkdir -p "$SB/.sage"
cat > "$SB/.sage/config.yaml" <<'EOF'
project_checks:
  lint: "my-custom-lint --strict"
  format: "my-custom-fmt --check"
  type_check: "my-custom-typecheck"
  test_command: "my-custom-test"
  coverage_command: "my-custom-cov"
EOF
cp "$SB/.sage/config.yaml" "$SB/config.yaml.before"
run_install "$SB" --stack python
if [ "$RUN_RC" = "0" ]; then
  ok "existing_config_preserved: install continues normally (exit 0) despite skip (AC-06 / 想定エラー2)"
else
  not_ok "existing_config_preserved: install rc=${RUN_RC}, expected 0 (AC-06 / 想定エラー2)"
fi
if cmp -s "$SB/.sage/config.yaml" "$SB/config.yaml.before"; then
  ok "existing_config_preserved: existing config.yaml is byte-identical after --stack python (AC-06 / INV-01)"
else
  not_ok "existing_config_preserved: existing config.yaml was modified (AC-06 / INV-01)"
fi
if echo "$RUN_OUT" | grep -qF 'config.yaml'; then
  ok "existing_config_preserved: stdout INFO explains the skip (existing config.yaml) (AC-06 / FR-06)"
else
  not_ok "existing_config_preserved: no skip INFO on stdout (AC-06 / FR-06)"
fi
rm -r "$SB" 2>/dev/null || true

# =============================================================================
# ケース7: unknown_stack_rejected — AC-07 (CHECK-007) / SEC-01 / 想定エラー1
# 未知の --stack 値 → exit 非0 + stderr に usage + 書き込みゼロ
# =============================================================================
SB="$(mktemp -d -t sage-stack-bad-XXXXXX)"
run_install "$SB" --stack rust
if [ "$RUN_RC" != "0" ]; then
  ok "unknown_stack_rejected: --stack rust exits non-zero (AC-07)"
else
  not_ok "unknown_stack_rejected: --stack rust exited 0 (AC-07)"
fi
if echo "$RUN_ERR" | grep -qiF 'usage'; then
  ok "unknown_stack_rejected: stderr contains usage (AC-07 / FR-03)"
else
  not_ok "unknown_stack_rejected: no usage on stderr (AC-07 / FR-03)"
fi
file_count="$(find "$SB" -type f | wc -l | tr -d ' ')"
if [ "$file_count" = "0" ]; then
  ok "unknown_stack_rejected: no files written to sandbox (AC-07 / FR-03)"
else
  not_ok "unknown_stack_rejected: ${file_count} file(s) written despite rejection (AC-07 / FR-03)"
fi
rm -r "$SB" 2>/dev/null || true

# SEC-01: パストラバーサル形の値も許可リスト不一致として同型拒否・書き込みゼロ
SB="$(mktemp -d -t sage-stack-sec-XXXXXX)"
run_install "$SB" --stack ../evil
sec_files="$(find "$SB" -type f | wc -l | tr -d ' ')"
if [ "$RUN_RC" != "0" ] && [ "$sec_files" = "0" ]; then
  ok "unknown_stack_rejected: --stack ../evil rejected with zero writes (SEC-01 / INV-03)"
else
  not_ok "unknown_stack_rejected: --stack ../evil rc=${RUN_RC} files=${sec_files} (SEC-01 / INV-03)"
fi
rm -r "$SB" 2>/dev/null || true

# =============================================================================
# ケース8: dry_run_no_write — AC-08 (CHECK-008) / PRE-03 / 境界ケース3
# --dry-run --stack go → 書き込みゼロ + stdout に適用予定プリセット表示
# =============================================================================
SB="$(mktemp -d -t sage-stack-dry-XXXXXX)"
run_install "$SB" --dry-run --stack go
if [ "$RUN_RC" = "0" ]; then
  ok "dry_run_no_write: --dry-run --stack go exits 0 (AC-08)"
else
  not_ok "dry_run_no_write: --dry-run --stack go rc=${RUN_RC} (AC-08)"
fi
dry_files="$(find "$SB" -type f | wc -l | tr -d ' ')"
if [ "$dry_files" = "0" ]; then
  ok "dry_run_no_write: no files created or modified (AC-08 / FR-07 / PRE-03)"
else
  not_ok "dry_run_no_write: ${dry_files} file(s) created during dry-run (AC-08 / FR-07 / PRE-03)"
fi
if echo "$RUN_OUT" | grep -qF 'go'; then
  ok "dry_run_no_write: stdout shows the preset that would be applied (AC-08 / FR-07)"
else
  not_ok "dry_run_no_write: no planned-preset display on stdout (AC-08 / FR-07)"
fi
rm -r "$SB" 2>/dev/null || true

# =============================================================================
# ケース9: SHA256SUMS 再現性 — AC-09 (CHECK-009) install.sh エントリ検証
# =============================================================================
if ( cd "$REPO_ROOT" && grep ' install\.sh$' SHA256SUMS | shasum -a 256 -c - >/dev/null 2>&1 ); then
  ok "SHA256SUMS install.sh entry verifies (AC-09 / NFR-02 / INV-05)"
else
  not_ok "SHA256SUMS install.sh entry verification failed (AC-09 / NFR-02 / INV-05)"
fi

# =============================================================================
# ケース10: run-tests.sh 登録 — AC-10 (CHECK-010)
# run-tests.sh は test-*.sh を自動 discovery するため、本ファイルが discovery
# glob に含まれることを検証する (全件 PASS 自体は run-tests.sh 実行で確認)。
# =============================================================================
if grep -qF 'test-*.sh' "${TEST_DIR}/run-tests.sh" 2>/dev/null \
   && [ -f "${TEST_DIR}/test-stack-presets.sh" ]; then
  ok "run_tests_discovery: run-tests.sh glob test-*.sh discovers this test (AC-10)"
else
  not_ok "run_tests_discovery: run-tests.sh does not discover test-stack-presets.sh (AC-10)"
fi

# =============================================================================
# ケース11: repo_config_untouched — AC-11 (CHECK-011) / ASM-03
# SPEC-0028 のコミット群 (cb62786..HEAD) に本リポジトリの .sage/config.yaml
# の変更が含まれない。base が無い環境 (shallow clone 等) では skip 扱い。
# =============================================================================
if ( cd "$REPO_ROOT" && git cat-file -t cb62786 >/dev/null 2>&1 ); then
  if ( cd "$REPO_ROOT" && git diff --name-only cb62786..HEAD | grep -qxF '.sage/config.yaml' ); then
    not_ok "repo_config_untouched: .sage/config.yaml changed in SPEC-0028 commits cb62786..HEAD (AC-11 / ASM-03)"
  else
    ok "repo_config_untouched: .sage/config.yaml unchanged in SPEC-0028 commits cb62786..HEAD (AC-11 / ASM-03)"
  fi
else
  ok "repo_config_untouched: base commit cb62786 unavailable — skipped (AC-11)"
fi

# =============================================================================
# ケース12: docs_reference — AC-12 (CHECK-012)
# =============================================================================
if grep -rqF 'templates/project-checks' "$REPO_ROOT/docs/stack-presets.md" "$REPO_ROOT/README.md" 2>/dev/null \
   && grep -qF -- '--stack' "$REPO_ROOT/docs/stack-presets.md" 2>/dev/null; then
  ok "docs_reference: docs/stack-presets.md + README reference presets and --stack (AC-12)"
else
  not_ok "docs_reference: docs/stack-presets.md or README missing required references (AC-12)"
fi

echo ""
echo "SUMMARY pass=${PASS} fail=${FAIL}"
[ "$FAIL" -eq 0 ]
