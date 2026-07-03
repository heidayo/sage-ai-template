#!/usr/bin/env bash
# =============================================================================
# TASK-0190: test-id-patterns.sh (SPEC-0027)
# Purpose:  Integration test for ID acceptance pattern externalization:
#           shared loader fallback, custom pattern acceptance, malformed
#           config safety, hardcode-drift detection, id-gen non-interference,
#           installer preserve-if-exists, docs/config references.
# Style:    Follows test-local-overlay.sh / test-installer-preservation.sh
#           (tmpdir sandboxes + fixture execution).
# Note:     Expected values are derived from SPEC-0027 AC-01..AC-12 and the
#           done-def CHECK-001..016 only, never from loader/script internals
#           (AP-07 prevention). Behavior is observed by executing the public
#           contracts: `source scripts/sage-id-pattern.sh` + sage_id_accept_regex,
#           pre-commit-task-id.sh <msg-file>, sage-id-gen.sh <type>, install.sh.
# =============================================================================
set -uo pipefail

PASS=0
FAIL=0

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
LOADER="${REPO_ROOT}/scripts/sage-id-pattern.sh"
HOOK="${REPO_ROOT}/templates/pre-commit-task-id.sh"
INSTALL_SH="${REPO_ROOT}/install.sh"
DEFAULT_TASK_RE='TASK-[0-9]{4}'
CUSTOM_TASK_RE='TASK-[a-z]+-[0-9a-f]{4}'

ok() { PASS=$((PASS + 1)); echo "  ok   $1"; }
not_ok() { FAIL=$((FAIL + 1)); echo "  not ok $1" >&2; }

# loader_sandbox — sandbox with the shared loader only (no config by default).
loader_sandbox() {
  local dir
  dir="$(mktemp -d -t sage-idpat-XXXXXX)"
  mkdir -p "${dir}/scripts" "${dir}/.sage"
  cp "$LOADER" "${dir}/scripts/"
  echo "$dir"
}

# accept_regex <sandbox> <type> — run the loader's public contract from the
# sandbox cwd. Sets REGEX_OUT / REGEX_ERR / REGEX_RC.
accept_regex() {
  local dir="$1" type="$2" err_file
  err_file="$(mktemp -t sage-idpat-err-XXXXXX)"
  REGEX_OUT="$(cd "$dir" && bash -c "source scripts/sage-id-pattern.sh; sage_id_accept_regex $type" 2>"$err_file")"
  REGEX_RC=$?
  REGEX_ERR="$(cat "$err_file")"
  rm -f "$err_file"
}

# hook_sandbox — minimal git repo (non-vibe, non-lite branch) so the hook
# takes the TASK-ID-required lane. No scripts/ dir unless the case adds it.
hook_sandbox() {
  local dir
  dir="$(mktemp -d -t sage-idpat-hook-XXXXXX)"
  (
    cd "$dir"
    git init -q
    git checkout -q -b feature/id-patterns-fixture 2>/dev/null || true
    git -c user.email=t@t -c user.name=t commit -q --allow-empty -m "TASK-0000: init fixture"
  ) >/dev/null 2>&1
  mkdir -p "${dir}/.sage"
  echo "$dir"
}

# run_hook_msg <sandbox> <commit-message> — run the pre-commit hook against a
# commit message fixture file. Sets HOOK_RC / HOOK_OUT.
run_hook_msg() {
  local dir="$1" msg="$2" msg_file out_file
  msg_file="$(mktemp -t sage-idpat-msg-XXXXXX)"
  out_file="$(mktemp -t sage-idpat-out-XXXXXX)"
  printf '%s\n' "$msg" > "$msg_file"
  ( cd "$dir" && bash "$HOOK" "$msg_file" >"$out_file" 2>&1 )
  HOOK_RC=$?
  HOOK_OUT="$(cat "$out_file")"
  rm -f "$msg_file" "$out_file"
}

echo "# id patterns externalization (SPEC-0027)"

if [ ! -f "$LOADER" ]; then
  not_ok "loader not found at ${LOADER} — cannot run id-pattern tests"
  echo ""
  echo "SUMMARY pass=${PASS} fail=${FAIL}"
  exit 1
fi

# =============================================================================
# ケース1: fallback_no_config — AC-01 / CHECK-001
# 設定ファイルなしで sage_id_accept_regex task がデフォルト値を返す
# =============================================================================
SB1="$(loader_sandbox)"
rm -f "$SB1/.sage/id-patterns.json"
accept_regex "$SB1" task
if [ "$REGEX_OUT" = "$DEFAULT_TASK_RE" ]; then
  ok "fallback_no_config: no-config output is ${DEFAULT_TASK_RE} (AC-01)"
else
  not_ok "fallback_no_config: expected '${DEFAULT_TASK_RE}' got '${REGEX_OUT}' (AC-01)"
fi
if [ "$REGEX_RC" = "0" ]; then
  ok "fallback_no_config: exit 0 without config (AC-01 / POST-01)"
else
  not_ok "fallback_no_config: rc=${REGEX_RC}, expected 0 (AC-01 / POST-01)"
fi

# =============================================================================
# ケース2: default_accepted — AC-02 / CHECK-002
# デフォルト内容の設定ファイルありで TASK-0001 が受理される
# =============================================================================
cp "${REPO_ROOT}/.sage/id-patterns.json" "$SB1/.sage/id-patterns.json"
accept_regex "$SB1" task
if echo 'TASK-0001: msg' | grep -qE "$REGEX_OUT"; then
  ok "default_accepted: 'TASK-0001: msg' matches accept regex with default config (AC-02)"
else
  not_ok "default_accepted: 'TASK-0001: msg' rejected under default config, regex='${REGEX_OUT}' (AC-02)"
fi

# =============================================================================
# ケース3: custom_accepted — AC-03 / CHECK-003
# task.accept にカスタムパターンを追加した設定で TASK-hei-a7f3 が
# pre-commit-task-id.sh を通過する。設定なし時は拒否される
# =============================================================================
HSB1="$(hook_sandbox)"
# 設定なし: カスタム形式は拒否 (AC-03 設定なし時 / NFR-01 後方互換)
run_hook_msg "$HSB1" 'TASK-hei-a7f3: fix login'
if [ "$HOOK_RC" != "0" ]; then
  ok "custom_accepted: TASK-hei-a7f3 rejected without config (AC-03 / NFR-01)"
else
  not_ok "custom_accepted: TASK-hei-a7f3 accepted without config, expected rejection (AC-03 / NFR-01)"
fi
# カスタム設定を配置 (docs/id-patterns.md の設定例と同一書式)
cat > "$HSB1/.sage/id-patterns.json" <<EOF
{
  "task": {
    "accept": [
      "${DEFAULT_TASK_RE}",
      "${CUSTOM_TASK_RE}"
    ]
  }
}
EOF
run_hook_msg "$HSB1" 'TASK-hei-a7f3: fix login'
if [ "$HOOK_RC" = "0" ]; then
  ok "custom_accepted: TASK-hei-a7f3 passes pre-commit hook with custom accept (AC-03)"
else
  not_ok "custom_accepted: hook rejected TASK-hei-a7f3 rc=${HOOK_RC} out='${HOOK_OUT}' (AC-03)"
fi
# 併用: デフォルト形式も引き続き受理される (SPEC スコープ「併用サポート」)
run_hook_msg "$HSB1" 'TASK-0001: msg'
if [ "$HOOK_RC" = "0" ]; then
  ok "custom_accepted: default TASK-0001 still passes alongside custom pattern (AC-03 / POST-02)"
else
  not_ok "custom_accepted: default TASK-0001 rejected with custom config rc=${HOOK_RC} (AC-03 / POST-02)"
fi

# =============================================================================
# ケース4: invalid_json_fallback — AC-04 / CHECK-004
# 不正 JSON で fallback + WARN (stderr) + exit 0
# =============================================================================
printf '{ this is not json\n' > "$SB1/.sage/id-patterns.json"
accept_regex "$SB1" task
if [ "$REGEX_OUT" = "$DEFAULT_TASK_RE" ]; then
  ok "invalid_json_fallback: malformed JSON falls back to ${DEFAULT_TASK_RE} (AC-04)"
else
  not_ok "invalid_json_fallback: expected '${DEFAULT_TASK_RE}' got '${REGEX_OUT}' (AC-04)"
fi
if echo "$REGEX_ERR" | grep -qi 'WARN'; then
  ok "invalid_json_fallback: WARN emitted on stderr (AC-04)"
else
  not_ok "invalid_json_fallback: no WARN on stderr, got '${REGEX_ERR}' (AC-04)"
fi
if [ "$REGEX_RC" = "0" ]; then
  ok "invalid_json_fallback: exit 0 despite malformed config (AC-04 / POST-01)"
else
  not_ok "invalid_json_fallback: rc=${REGEX_RC}, expected 0 (AC-04 / POST-01)"
fi

# =============================================================================
# ケース5: empty_accept_fallback — AC-05 / CHECK-005 / SEC-03
# 空 accept 配列で fallback。空パターン全マッチ (NOTASK 受理) が起きない
# =============================================================================
printf '{ "task": { "accept": [] } }\n' > "$SB1/.sage/id-patterns.json"
accept_regex "$SB1" task
if [ -n "$REGEX_OUT" ]; then
  ok "empty_accept_fallback: regex is non-empty for empty accept array (AC-05 / INV-04)"
else
  not_ok "empty_accept_fallback: empty regex returned — grep -E '' would match all (AC-05 / SEC-03)"
fi
if printf 'NOTASK just text\n' | grep -qE "$REGEX_OUT"; then
  not_ok "empty_accept_fallback: NOTASK fixture matched — validation disabled (AC-05 / SEC-03)"
else
  ok "empty_accept_fallback: NOTASK fixture rejected (AC-05 / SEC-03)"
fi
if echo 'TASK-0001: msg' | grep -qE "$REGEX_OUT"; then
  ok "empty_accept_fallback: default TASK-0001 still accepted via fallback (AC-05)"
else
  not_ok "empty_accept_fallback: default TASK-0001 rejected under fallback (AC-05)"
fi

# =============================================================================
# ケース6: no_stray_hardcode — AC-06 / CHECK-006 / INV-03
# ERE/BRE 両表記のハードコードが hook 内包 fallback 定義行のみ (許容行数・位置の機械検証)
# =============================================================================
stray_hits="$(cd "$REPO_ROOT" && grep -rnE 'TASK-\[0-9\](\{4\}|\\\{4\\\})' \
  scripts/sage-id-gen.sh scripts/sage-trace-check.sh scripts/sage-report.sh \
  scripts/sage-validate.sh templates/pre-commit-task-id.sh 2>/dev/null || true)"
scripts_hits="$(echo "$stray_hits" | grep -c '^scripts/' || true)"
hook_hits="$(echo "$stray_hits" | grep '^templates/pre-commit-task-id.sh:' || true)"
hook_hit_count="$( [ -n "$hook_hits" ] && echo "$hook_hits" | wc -l | tr -d ' ' || echo 0 )"
if [ "$scripts_hits" = "0" ]; then
  ok "no_stray_hardcode: 0 hardcoded acceptance regex hits in scripts/ 4 files (AC-06 / INV-03)"
else
  not_ok "no_stray_hardcode: ${scripts_hits} stray hits in scripts/: $(echo "$stray_hits" | grep '^scripts/' | tr '\n' ' ') (AC-06)"
fi
# 位置検証: hook 側のヒットは内包 fallback 定義 (変数代入行) ちょうど 1 行のみ
if [ "$hook_hit_count" = "1" ]; then
  ok "no_stray_hardcode: exactly 1 hit in pre-commit hook (embedded fallback only) (AC-06)"
else
  not_ok "no_stray_hardcode: expected exactly 1 hook hit, got ${hook_hit_count}: '${hook_hits}' (AC-06)"
fi
if [ -n "$hook_hits" ] && echo "$hook_hits" | grep -qE '^templates/pre-commit-task-id\.sh:[0-9]+:[A-Za-z_]+="TASK-\[0-9\]\{4\}"$'; then
  ok "no_stray_hardcode: hook hit is a fallback variable definition line (AC-06 position check)"
else
  not_ok "no_stray_hardcode: hook hit is not a plain fallback definition: '${hook_hits}' (AC-06 position check)"
fi

# =============================================================================
# ケース7: idgen_ignores_custom — AC-07 / CHECK-007 / CHECK-014 (境界ケース1)
# カスタム形式 ID 混在環境で id-gen がデフォルト形式の次連番 (具体値) を返す
# =============================================================================
SB2="$(loader_sandbox)"
cp "${REPO_ROOT}/scripts/sage-id-gen.sh" "$SB2/scripts/"
mkdir -p "$SB2/tasks"
printf '# fixture\n' > "$SB2/tasks/TASK-0002-existing.md"
printf '# fixture\n' > "$SB2/tasks/TASK-hei-a7f3-x.md"
next_id="$(cd "$SB2" && bash scripts/sage-id-gen.sh task 2>/dev/null)"
idgen_rc=$?
if [ "$idgen_rc" = "0" ]; then
  ok "idgen_ignores_custom: sage-id-gen.sh task exits 0 with custom ID present (AC-07)"
else
  not_ok "idgen_ignores_custom: id-gen failed rc=${idgen_rc} (AC-07)"
fi
# CHECK-014: 採番結果の具体値 — デフォルト形式最大値 (0002) + 1 = TASK-0003
if [ "$next_id" = "TASK-0003" ]; then
  ok "idgen_ignores_custom: next ID is TASK-0003 (default max 0002 + 1, custom ignored) (AC-07 / CHECK-014)"
else
  not_ok "idgen_ignores_custom: expected 'TASK-0003' got '${next_id}' (AC-07 / CHECK-014)"
fi

# =============================================================================
# ケース8: SHA256SUMS 再現性 — AC-08 / CHECK-008 (install.sh エントリ)
# =============================================================================
if ( cd "$REPO_ROOT" && grep ' install\.sh$' SHA256SUMS | shasum -a 256 -c - >/dev/null 2>&1 ); then
  ok "SHA256SUMS install.sh entry verifies (AC-08 / POST-03)"
else
  not_ok "SHA256SUMS install.sh entry verification failed — regenerate install.sh (AC-08)"
fi

# =============================================================================
# ケース9: docs_and_config_reference — AC-10 / CHECK-010
# =============================================================================
if grep -rqF '.sage/id-patterns.json' "$REPO_ROOT/README.md" "$REPO_ROOT/docs/"; then
  ok "docs_and_config_reference: README/docs reference .sage/id-patterns.json (AC-10)"
else
  not_ok "docs_and_config_reference: no .sage/id-patterns.json reference in README/docs (AC-10)"
fi
if grep -qF 'id-patterns' "$REPO_ROOT/.sage/config.yaml"; then
  ok "docs_and_config_reference: .sage/config.yaml id_schema comment references id-patterns (AC-10)"
else
  not_ok "docs_and_config_reference: 'id-patterns' missing from .sage/config.yaml (AC-10)"
fi

# =============================================================================
# ケース10: eval 不使用 — AC-11 / CHECK-011 / SEC-01
# =============================================================================
eval_hits="$(grep -nE '(^|[^a-zA-Z_])eval([^a-zA-Z_]|$)' "$LOADER" || true)"
if [ -z "$eval_hits" ]; then
  ok "no eval usage in scripts/sage-id-pattern.sh (AC-11 / SEC-01)"
else
  not_ok "eval found in loader: '${eval_hits}' (AC-11 / SEC-01)"
fi

# =============================================================================
# ケース11: installer_preserves_config — AC-12 / CHECK-012 + CHECK-016 (境界ケース3)
# カスタム accept 配置済み環境で install.sh 実行・再実行後も設定が保持される
# =============================================================================
if [ -f "$INSTALL_SH" ]; then
  SB3="$(mktemp -d -t sage-idpat-inst-XXXXXX)"
  mkdir -p "$SB3/.sage"
  cat > "$SB3/.sage/id-patterns.json" <<EOF
{
  "task": {
    "accept": [
      "${DEFAULT_TASK_RE}",
      "${CUSTOM_TASK_RE}"
    ]
  }
}
EOF
  ( cd "$SB3" && bash "$INSTALL_SH" </dev/null >/dev/null 2>&1 )
  inst_rc=$?
  if [ "$inst_rc" = "0" ]; then
    ok "installer_preserves_config: install.sh exits 0 with pre-existing config (AC-12)"
  else
    not_ok "installer_preserves_config: install.sh failed rc=${inst_rc} (AC-12)"
  fi
  if grep -qF "$CUSTOM_TASK_RE" "$SB3/.sage/id-patterns.json"; then
    ok "installer_preserves_config: custom accept survives install (preserve-if-exists) (AC-12)"
  else
    not_ok "installer_preserves_config: custom accept lost after install (AC-12)"
  fi
  # CHECK-016: installer 再実行 (更新圧あり) でも上書きされない
  printf '0.0.1\n' > "$SB3/.sage/version"
  ( cd "$SB3" && bash "$INSTALL_SH" </dev/null >/dev/null 2>&1 )
  if grep -qF "$CUSTOM_TASK_RE" "$SB3/.sage/id-patterns.json"; then
    ok "installer_preserves_config: custom accept survives installer re-run (CHECK-016 / 境界ケース3)"
  else
    not_ok "installer_preserves_config: custom accept lost on installer re-run (CHECK-016)"
  fi
else
  not_ok "installer_preserves_config: install.sh not found at ${INSTALL_SH} (AC-12)"
fi

# =============================================================================
# ケース12: hook_standalone_fallback — CHECK-015 (境界ケース2 / FR-06)
# ローダーも設定もない fixture で hook が内包 fallback で単体動作する
# =============================================================================
HSB2="$(hook_sandbox)"
# scripts/sage-id-pattern.sh も .sage/id-patterns.json も存在しない
rm -f "$HSB2/.sage/id-patterns.json"
run_hook_msg "$HSB2" 'TASK-0001: msg'
if [ "$HOOK_RC" = "0" ]; then
  ok "hook_standalone_fallback: TASK-0001 accepted without loader/config (CHECK-015 / FR-06)"
else
  not_ok "hook_standalone_fallback: TASK-0001 rejected rc=${HOOK_RC} out='${HOOK_OUT}' (CHECK-015)"
fi
run_hook_msg "$HSB2" 'NOTASK: no id here'
if [ "$HOOK_RC" != "0" ]; then
  ok "hook_standalone_fallback: NOTASK rejected without loader/config (CHECK-015 / FR-06)"
else
  not_ok "hook_standalone_fallback: NOTASK accepted — fallback validation missing (CHECK-015)"
fi

# =============================================================================
# ケース13: missing_type_fallback — CHECK-013 (想定エラー3: 種別欠落)
# 設定に task のみ定義。欠落種別 (run) は no-config 時と同一の fallback を返す
# =============================================================================
SB4="$(loader_sandbox)"
rm -f "$SB4/.sage/id-patterns.json"
accept_regex "$SB4" run
run_fallback="$REGEX_OUT"
printf '{ "task": { "accept": ["%s"] } }\n' "$CUSTOM_TASK_RE" > "$SB4/.sage/id-patterns.json"
accept_regex "$SB4" run
if [ -n "$run_fallback" ] && [ "$REGEX_OUT" = "$run_fallback" ]; then
  ok "missing_type_fallback: missing 'run' type returns same regex as no-config fallback (CHECK-013)"
else
  not_ok "missing_type_fallback: expected '${run_fallback}' got '${REGEX_OUT}' (CHECK-013)"
fi
if [ "$REGEX_RC" = "0" ]; then
  ok "missing_type_fallback: exit 0 with partial config (CHECK-013 / POST-01)"
else
  not_ok "missing_type_fallback: rc=${REGEX_RC}, expected 0 (CHECK-013)"
fi
# 定義済み種別 (task) には設定が適用される
accept_regex "$SB4" task
if echo 'TASK-hei-a7f3: msg' | grep -qE "$REGEX_OUT"; then
  ok "missing_type_fallback: defined 'task' type applies custom config (CHECK-013)"
else
  not_ok "missing_type_fallback: custom task pattern not applied, regex='${REGEX_OUT}' (CHECK-013)"
fi

# =============================================================================
# ケース14: whitespace_variance — リスク2 (表記揺れ fixture)
# 1 パターン 1 行の制約内でインデント・空白が揺れても正しく読める。
# 逸脱しても安全側 (デフォルト受理 / NOTASK 拒否) が保たれる
# =============================================================================
SB5="$(loader_sandbox)"
cat > "$SB5/.sage/id-patterns.json" <<EOF
{
      "task"  :   {
          "accept" : [ "${DEFAULT_TASK_RE}" ,
              "${CUSTOM_TASK_RE}" ]
      }
}
EOF
accept_regex "$SB5" task
if echo 'TASK-hei-a7f3: msg' | grep -qE "$REGEX_OUT"; then
  ok "whitespace_variance: custom pattern parsed despite whitespace variance (リスク2)"
else
  not_ok "whitespace_variance: custom pattern lost under whitespace variance, regex='${REGEX_OUT}' (リスク2)"
fi
if echo 'TASK-0001: msg' | grep -qE "$REGEX_OUT"; then
  ok "whitespace_variance: default TASK-0001 still accepted (リスク2 safe side)"
else
  not_ok "whitespace_variance: default TASK-0001 rejected, regex='${REGEX_OUT}' (リスク2)"
fi
if printf 'NOTASK just text\n' | grep -qE "$REGEX_OUT"; then
  not_ok "whitespace_variance: NOTASK accepted — unsafe parse result (リスク2 / SEC-03)"
else
  ok "whitespace_variance: NOTASK rejected (リスク2 safe side)"
fi

# Cleanup: only mktemp-created sandboxes (rm -r without -f on unique tmpdirs).
for d in "${SB1:-}" "${SB2:-}" "${SB3:-}" "${SB4:-}" "${SB5:-}" "${HSB1:-}" "${HSB2:-}"; do
  case "$d" in
    */sage-idpat-*) rm -r "$d" 2>/dev/null || true ;;
  esac
done

echo ""
echo "SUMMARY pass=${PASS} fail=${FAIL}"
[ "$FAIL" -eq 0 ]
