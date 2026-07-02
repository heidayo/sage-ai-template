#!/usr/bin/env bash
# =============================================================================
# TASK-0173: test-local-overlay.sh (SPEC-0025)
# Purpose:  Integration test for the local overlay invariance (INV-01):
#           install / re-install / --dry-run / --verify-checksum must never
#           create, modify, or delete .claude/rules/local/ or .codex/rules/local/.
# Style:    Follows test-installer-modularize.sh (tmpdir + generated install.sh).
# Note:     Expected values are derived from SPEC-0025 AC-01..AC-10 only,
#           never from installer internals (AP-07 prevention).
# =============================================================================
set -uo pipefail

PASS=0
FAIL=0

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
INSTALL_SH="${REPO_ROOT}/install.sh"

ok() { PASS=$((PASS + 1)); echo "  ok   $1"; }
not_ok() { FAIL=$((FAIL + 1)); echo "  not ok $1" >&2; }

# run_install <sandbox-dir> [args...] — run the generated installer from a
# sandbox cwd, capturing rc/stdout+stderr into RUN_RC / RUN_OUT.
run_install() {
  local dir="$1"; shift
  local out_file
  out_file="$(mktemp -t sage-overlay-out-XXXXXX)"
  ( cd "$dir" && bash "$INSTALL_SH" "$@" </dev/null >"$out_file" 2>&1 )
  RUN_RC=$?
  RUN_OUT="$(cat "$out_file")"
  rm -f "$out_file"
}

echo "# local overlay invariance (SPEC-0025)"

if [ ! -f "$INSTALL_SH" ]; then
  not_ok "install.sh not found at ${INSTALL_SH} — cannot run overlay tests"
  echo ""
  echo "SUMMARY pass=${PASS} fail=${FAIL}"
  exit 1
fi

# =============================================================================
# ケース1: 非作成 — clean install は overlay を作成しない (AC-02, NFR-01)
# =============================================================================
SB1="$(mktemp -d -t sage-overlay-1-XXXXXX)"
run_install "$SB1"
# NFR-01: local/ 不在でも install がエラーにならない
if [ "$RUN_RC" = "0" ]; then
  ok "clean install exits 0 without local/ (NFR-01)"
else
  not_ok "clean install failed rc=${RUN_RC} (NFR-01)"
fi
# AC-02: installer は .claude/rules/local も .codex/rules/local も作成しない
if [ ! -e "$SB1/.claude/rules/local" ] && [ ! -e "$SB1/.codex/rules/local" ]; then
  ok "installer does not create overlay dirs (AC-02)"
else
  not_ok "overlay dir was created by installer (AC-02)"
fi

# =============================================================================
# ケース2: install-state 宣言 — unmanaged_paths に overlay が列挙される (AC-03)
# =============================================================================
# AC-03: grep -A3 'unmanaged_paths' .sage/install-state.yaml | grep '.claude/rules/local/'
if grep -A3 'unmanaged_paths' "$SB1/.sage/install-state.yaml" 2>/dev/null | grep -q '.claude/rules/local/'; then
  ok "install-state declares .claude/rules/local/ in unmanaged_paths (AC-03)"
else
  not_ok "unmanaged_paths declaration missing for .claude/rules/local/ (AC-03)"
fi
if grep -A3 'unmanaged_paths' "$SB1/.sage/install-state.yaml" 2>/dev/null | grep -q '.codex/rules/local/'; then
  ok "install-state declares .codex/rules/local/ in unmanaged_paths (AC-03)"
else
  not_ok "unmanaged_paths declaration missing for .codex/rules/local/ (AC-03)"
fi

# =============================================================================
# ケース3: CLAUDE.md 規約記載 — 生成 CLAUDE.md に overlay 読み込み規約 (AC-10)
# test case: claude_md_convention
# =============================================================================
if grep -q 'rules/local/' "$SB1/CLAUDE.md" 2>/dev/null; then
  ok "claude_md_convention: generated CLAUDE.md references rules/local/ (AC-10)"
else
  not_ok "claude_md_convention: rules/local/ convention missing in CLAUDE.md (AC-10)"
fi

# =============================================================================
# ケース4: managed rules 注記 — 全 managed rules 末尾に local/ 参照注記 (AC-05)
# =============================================================================
managed_total=$(ls "$SB1"/.claude/rules/*.md 2>/dev/null | wc -l | tr -d ' ')
noted_total=$(grep -l 'rules/local/' "$SB1"/.claude/rules/*.md 2>/dev/null | wc -l | tr -d ' ')
if [ "$managed_total" -gt 0 ] && [ "$managed_total" = "$noted_total" ]; then
  ok "all ${managed_total} managed rules reference rules/local/ (AC-05)"
else
  not_ok "managed rules notice mismatch: ${noted_total}/${managed_total} (AC-05)"
fi

# =============================================================================
# ケース5: overlay 保持 — 再 install で overlay 内容・mtime・存在が不変 (AC-01, INV-01)
# =============================================================================
mkdir -p "$SB1/.claude/rules/local" "$SB1/.codex/rules/local"
printf '# my project rule\ndo not touch\n' > "$SB1/.claude/rules/local/my-rule.md"
printf '# codex local rule\n' > "$SB1/.codex/rules/local/codex-rule.md"
before_claude="$(cat "$SB1/.claude/rules/local/my-rule.md")"
before_codex="$(cat "$SB1/.codex/rules/local/codex-rule.md")"
# mtime を過去に固定し、installer が touch したら検出できるようにする (INV-01)
touch -t 202001010000 "$SB1/.claude/rules/local/my-rule.md"
before_mtime="$(ls -l "$SB1/.claude/rules/local/my-rule.md")"

run_install "$SB1"
if [ "$RUN_RC" = "0" ]; then
  ok "re-install exits 0 with overlay present (AC-01)"
else
  not_ok "re-install failed rc=${RUN_RC} (AC-01)"
fi
if [ "$(cat "$SB1/.claude/rules/local/my-rule.md" 2>/dev/null)" = "$before_claude" ]; then
  ok "overlay .claude/rules/local/my-rule.md content unchanged after re-install (AC-01)"
else
  not_ok "overlay .claude/rules/local/my-rule.md content changed (AC-01)"
fi
if [ "$(cat "$SB1/.codex/rules/local/codex-rule.md" 2>/dev/null)" = "$before_codex" ]; then
  ok "overlay .codex/rules/local/codex-rule.md content unchanged after re-install (AC-01)"
else
  not_ok "overlay .codex/rules/local/codex-rule.md content changed (AC-01)"
fi
after_mtime="$(ls -l "$SB1/.claude/rules/local/my-rule.md")"
if [ "$before_mtime" = "$after_mtime" ]; then
  ok "overlay file mtime unchanged after re-install (INV-01)"
else
  not_ok "overlay file mtime changed after re-install (INV-01)"
fi

# =============================================================================
# ケース6: verify-checksum 非干渉 — overlay 追加・変更状態で PASS (AC-04)
# =============================================================================
# ケース5 の再 install で install-state は再生成済み。overlay 追加状態で PASS:
echo "extra local content" >> "$SB1/.claude/rules/local/my-rule.md"
run_install "$SB1" --verify-checksum
if [ "$RUN_RC" = "0" ]; then
  ok "verify-checksum passes with overlay files added/modified (AC-04)"
else
  not_ok "verify-checksum failed rc=${RUN_RC} with overlay present (AC-04)"
fi
# overlay の有無で PASS/FAIL が変わらないこと: overlay を退避しても PASS (AC-04)
mv "$SB1/.claude/rules/local/my-rule.md" "$SB1/.claude/rules/local/my-rule.md.bak"
run_install "$SB1" --verify-checksum
if [ "$RUN_RC" = "0" ]; then
  ok "verify-checksum passes regardless of overlay file presence (AC-04)"
else
  not_ok "verify-checksum failed rc=${RUN_RC} after overlay file removal (AC-04)"
fi
mv "$SB1/.claude/rules/local/my-rule.md.bak" "$SB1/.claude/rules/local/my-rule.md"

# =============================================================================
# ケース7: dry-run 不介入 — --dry-run は overlay を変更しない (INV-01, NFR-03)
# =============================================================================
before_dry="$(cat "$SB1/.claude/rules/local/my-rule.md")"
run_install "$SB1" --dry-run
if [ "$RUN_RC" = "0" ]; then
  ok "dry-run exits 0 with overlay present (NFR-03)"
else
  not_ok "dry-run failed rc=${RUN_RC} (NFR-03)"
fi
if [ "$(cat "$SB1/.claude/rules/local/my-rule.md" 2>/dev/null)" = "$before_dry" ]; then
  ok "dry-run leaves overlay content untouched (INV-01)"
else
  not_ok "dry-run modified overlay content (INV-01)"
fi

# =============================================================================
# ケース8: 境界ケース1 — 空の local/ ディレクトリは削除されない (INV-01)
# =============================================================================
SB2="$(mktemp -d -t sage-overlay-2-XXXXXX)"
run_install "$SB2"
mkdir -p "$SB2/.claude/rules/local"
run_install "$SB2"
if [ -d "$SB2/.claude/rules/local" ]; then
  ok "empty local/ directory survives re-install (境界ケース1 / INV-01)"
else
  not_ok "empty local/ directory was removed by re-install (境界ケース1 / INV-01)"
fi

# =============================================================================
# ケース9: 異常系1 local_is_file — local が通常ファイルでも exit 0 + WARN + 不変 (AC-08)
# =============================================================================
SB3="$(mktemp -d -t sage-overlay-3-XXXXXX)"
run_install "$SB3"
printf 'i am a plain file, not a directory\n' > "$SB3/.claude/rules/local"
before_file="$(cat "$SB3/.claude/rules/local")"
run_install "$SB3"
if [ "$RUN_RC" = "0" ]; then
  ok "local_is_file: installer exits 0 when local is a regular file (AC-08)"
else
  not_ok "local_is_file: installer exited rc=${RUN_RC}, expected 0 (AC-08)"
fi
if echo "$RUN_OUT" | grep -qi 'warn'; then
  ok "local_is_file: installer emits WARN (AC-08)"
else
  not_ok "local_is_file: no WARN output when local is a regular file (AC-08)"
fi
if [ -f "$SB3/.claude/rules/local" ] && [ "$(cat "$SB3/.claude/rules/local")" = "$before_file" ]; then
  ok "local_is_file: regular file content unchanged (AC-08)"
else
  not_ok "local_is_file: regular file was modified or removed (AC-08)"
fi

# =============================================================================
# ケース10: 異常系2 legacy_state — unmanaged_paths なし旧フォーマットで verify PASS (AC-09)
# =============================================================================
SB4="$(mktemp -d -t sage-overlay-4-XXXXXX)"
run_install "$SB4"
# 旧フォーマットを再現: unmanaged_paths セクション (キー行 + list 行) を除去
legacy_tmp="$(mktemp -t sage-overlay-legacy-XXXXXX)"
grep -v -e 'unmanaged_paths' -e 'rules/local/' "$SB4/.sage/install-state.yaml" > "$legacy_tmp"
cat "$legacy_tmp" > "$SB4/.sage/install-state.yaml"
rm -f "$legacy_tmp"
mkdir -p "$SB4/.claude/rules/local"
printf '# overlay under legacy state\n' > "$SB4/.claude/rules/local/legacy-rule.md"
run_install "$SB4" --verify-checksum
if [ "$RUN_RC" = "0" ]; then
  ok "legacy_state: verify-checksum passes on old-format install-state (AC-09)"
else
  not_ok "legacy_state: verify-checksum failed rc=${RUN_RC} on old format (AC-09)"
fi

# =============================================================================
# ケース11: 異常系3 symlink 非追従 — local/ 内の外向き symlink を辿らない (INV-01)
# =============================================================================
SB5="$(mktemp -d -t sage-overlay-5-XXXXXX)"
run_install "$SB5"
outside_target="$(mktemp -d -t sage-overlay-target-XXXXXX)"
printf 'outside content must stay\n' > "$outside_target/outside.md"
mkdir -p "$SB5/.claude/rules/local"
ln -s "$outside_target/outside.md" "$SB5/.claude/rules/local/escape.md"
run_install "$SB5"
if [ "$RUN_RC" = "0" ]; then
  ok "symlink in local/ does not break install (異常系3)"
else
  not_ok "install failed rc=${RUN_RC} with symlink in local/ (異常系3)"
fi
if [ "$(cat "$outside_target/outside.md" 2>/dev/null)" = "outside content must stay" ]; then
  ok "installer does not follow symlink out of overlay (異常系3 / SEC-02)"
else
  not_ok "symlink target outside overlay was modified (異常系3 / SEC-02)"
fi
if [ -L "$SB5/.claude/rules/local/escape.md" ]; then
  ok "symlink itself is preserved in local/ (異常系3 / INV-01)"
else
  not_ok "symlink in local/ was removed or replaced (異常系3 / INV-01)"
fi

# Cleanup: only mktemp-created sandboxes. If removal is blocked by hooks,
# unique tmpdirs are simply left behind (allowed by TASK-0173 rules).
for d in "$SB1" "$SB2" "$SB3" "$SB4" "$SB5" "$outside_target"; do
  case "$d" in
    */sage-overlay-*) rm -r "$d" 2>/dev/null || true ;;
  esac
done

echo ""
echo "SUMMARY pass=${PASS} fail=${FAIL}"
[ "$FAIL" -eq 0 ]
