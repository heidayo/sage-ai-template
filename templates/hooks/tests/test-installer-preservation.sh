#!/usr/bin/env bash
# =============================================================================
# TASK-0182: test-installer-preservation.sh (SPEC-0026)
# Purpose:  Integration regression test for installer customization
#           preservation: pre-update backup (3 generations), --diff preview,
#           marker edge-case safe fallback, idempotent re-install.
# Style:    Follows test-local-overlay.sh (tmpdir + generated install.sh).
# Note:     Expected values are derived from SPEC-0026 AC-01..AC-13 and the
#           documented boundary cases only, never from installer internals
#           (AP-07 prevention). Update pressure is simulated by lowering
#           .sage/version (an installed-state file, part of the observable
#           file contract) so the installer sees a template difference.
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
  out_file="$(mktemp -t sage-pres-out-XXXXXX)"
  ( cd "$dir" && bash "$INSTALL_SH" "$@" </dev/null >"$out_file" 2>&1 )
  RUN_RC=$?
  RUN_OUT="$(cat "$out_file")"
  rm -f "$out_file"
}

# force_update <sandbox-dir> — make the installer see a pending template
# update on the next run (simulates an older installed version).
force_update() {
  printf '0.0.1\n' > "$1/.sage/version"
}

# mutate_managed_section <file> — change a line inside the SAGE managed
# section so the file itself becomes an UPDATE target (content differs from
# the template-rendered result). Uses awk (portable, no sed -i).
mutate_managed_section() {
  local f="$1" tmp
  tmp="$(mktemp -t sage-pres-mut-XXXXXX)"
  awk '/^## SAGE Development System$/ { print $0 " (locally mutated)"; next } { print }' "$f" > "$tmp"
  cat "$tmp" > "$f"
  rm -f "$tmp"
}

# checksum_tree <dir> — stable checksum listing of every file in the sandbox.
checksum_tree() {
  ( cd "$1" && find . -type f -print0 | sort -z | xargs -0 shasum -a 256 )
}

# managed_checksums <dir> — checksums of the managed file group (AC-05).
managed_checksums() {
  ( cd "$1" && shasum -a 256 CLAUDE.md AGENTS.md .claude/rules/*.md .sage/install-state.yaml 2>/dev/null )
}

backup_gen_count() {
  ls -d "$1"/.sage/backup/*/ 2>/dev/null | wc -l | tr -d ' '
}

echo "# installer customization preservation (SPEC-0026)"

if [ ! -f "$INSTALL_SH" ]; then
  not_ok "install.sh not found at ${INSTALL_SH} — cannot run preservation tests"
  echo ""
  echo "SUMMARY pass=${PASS} fail=${FAIL}"
  exit 1
fi

# =============================================================================
# ケース1: marker_outside_preserved + backup_created — AC-01 / AC-02
# =============================================================================
SB1="$(mktemp -d -t sage-pres-1-XXXXXX)"
run_install "$SB1"
if [ "$RUN_RC" = "0" ]; then
  ok "clean install exits 0 (setup for AC-01)"
else
  not_ok "clean install failed rc=${RUN_RC} (setup for AC-01)"
fi

# AC-01: マーカー外にユーザー文言を追記して再 install → 保持される
printf '\nUSER_NOTE_CLAUDE keep me around\n' >> "$SB1/CLAUDE.md"
printf '\nUSER_NOTE_AGENTS keep me around\n' >> "$SB1/AGENTS.md"
# AC-02: マーカー内も変えて CLAUDE.md 自体を UPDATE 対象にする
mutate_managed_section "$SB1/CLAUDE.md"
cp "$SB1/CLAUDE.md" "$SB1/CLAUDE.md.pre-update"
force_update "$SB1"
run_install "$SB1"
if [ "$RUN_RC" = "0" ]; then
  ok "marker_outside_preserved: re-install exits 0 (AC-01)"
else
  not_ok "marker_outside_preserved: re-install failed rc=${RUN_RC} (AC-01)"
fi
if grep -qF 'USER_NOTE_CLAUDE keep me around' "$SB1/CLAUDE.md"; then
  ok "marker_outside_preserved: CLAUDE.md user text outside markers survives update (AC-01)"
else
  not_ok "marker_outside_preserved: CLAUDE.md user text outside markers lost (AC-01)"
fi
if grep -qF 'USER_NOTE_AGENTS keep me around' "$SB1/AGENTS.md"; then
  ok "marker_outside_preserved: AGENTS.md user text outside markers survives update (AC-01)"
else
  not_ok "marker_outside_preserved: AGENTS.md user text outside markers lost (AC-01)"
fi

# AC-02: ls .sage/backup/*/CLAUDE.md が成功し、内容が更新前ファイルと一致
if ls "$SB1"/.sage/backup/*/CLAUDE.md >/dev/null 2>&1; then
  ok "backup_created: .sage/backup/<ts>/CLAUDE.md exists after update (AC-02)"
else
  not_ok "backup_created: no CLAUDE.md backup found under .sage/backup/ (AC-02)"
fi
backup_matches=0
for f in "$SB1"/.sage/backup/*/CLAUDE.md; do
  [ -f "$f" ] && cmp -s "$f" "$SB1/CLAUDE.md.pre-update" && backup_matches=1
done
if [ "$backup_matches" = "1" ]; then
  ok "backup_created: backup content matches pre-update CLAUDE.md (AC-02)"
else
  not_ok "backup_created: backup content differs from pre-update CLAUDE.md (AC-02)"
fi
# SEC-03: stdout はパスのみでバックアップ内容をダンプしない
if echo "$RUN_OUT" | grep -qF 'USER_NOTE_CLAUDE keep me around'; then
  not_ok "backup_created: stdout dumps backed-up file content (SEC-03)"
else
  ok "backup_created: stdout does not dump backup content, paths only (SEC-03)"
fi

# =============================================================================
# ケース2: backup_rotation — AC-03 (世代上限3) + FR-02 stdout 出力
# =============================================================================
for i in 1 2 3 4; do
  mutate_managed_section "$SB1/CLAUDE.md"
  force_update "$SB1"
  run_install "$SB1"
done
gens="$(backup_gen_count "$SB1")"
if [ "$gens" = "3" ]; then
  ok "backup_rotation: generation count is 3 after 4+ updates (AC-03)"
else
  not_ok "backup_rotation: expected 3 generations, got ${gens} (AC-03)"
fi
if echo "$RUN_OUT" | grep -qi 'remov'; then
  ok "backup_rotation: oldest-generation removal is reported on stdout (FR-02)"
else
  not_ok "backup_rotation: no removal message on stdout during rotation (FR-02)"
fi

# =============================================================================
# ケース3: rotation_skips_foreign_entries — AC-11 (非タイムスタンプエントリ保持)
# =============================================================================
mkdir -p "$SB1/.sage/backup/keep-me-user-notes"
printf 'user data must survive rotation\n' > "$SB1/.sage/backup/keep-me-user-notes/note.txt"
mutate_managed_section "$SB1/CLAUDE.md"
force_update "$SB1"
run_install "$SB1"
if [ -d "$SB1/.sage/backup/keep-me-user-notes" ] \
   && [ "$(cat "$SB1/.sage/backup/keep-me-user-notes/note.txt" 2>/dev/null)" = "user data must survive rotation" ]; then
  ok "rotation_skips_foreign_entries: non-timestamp entry survives rotation (AC-11)"
else
  not_ok "rotation_skips_foreign_entries: non-timestamp entry was deleted or modified (AC-11)"
fi

# =============================================================================
# ケース4: timestamp_collision_no_overwrite — AC-12 (-N suffix、上書きなし)
# =============================================================================
# 直近数秒分のタイムスタンプ世代ディレクトリを sentinel 付きで先置きし、
# 次の install のバックアップが必ず衝突するようにする (同一秒連続実行の模擬)。
now_epoch="$(date -u +%s)"
precreated=""
for off in 0 1 2 3; do
  if date -u -r 1 +%Y%m%d-%H%M%S >/dev/null 2>&1; then
    ts="$(date -u -r $((now_epoch + off)) +%Y%m%d-%H%M%S)"   # BSD date
  else
    ts="$(date -u -d "@$((now_epoch + off))" +%Y%m%d-%H%M%S)" # GNU date
  fi
  mkdir -p "$SB1/.sage/backup/$ts"
  printf 'collision sentinel\n' > "$SB1/.sage/backup/$ts/sentinel.txt"
  precreated="$precreated $ts"
done
mutate_managed_section "$SB1/CLAUDE.md"
force_update "$SB1"
run_install "$SB1"
if ls -d "$SB1"/.sage/backup/*/ 2>/dev/null | grep -qE '/[0-9]{8}-[0-9]{6}-[0-9]+/$'; then
  ok "timestamp_collision_no_overwrite: backup saved to -N suffixed directory (AC-12)"
else
  not_ok "timestamp_collision_no_overwrite: no -N suffixed generation found (AC-12)"
fi
collision_overwrite=0
for ts in $precreated; do
  if [ -d "$SB1/.sage/backup/$ts" ]; then
    [ "$(cat "$SB1/.sage/backup/$ts/sentinel.txt" 2>/dev/null)" = "collision sentinel" ] || collision_overwrite=1
  fi
done
if [ "$collision_overwrite" = "0" ]; then
  ok "timestamp_collision_no_overwrite: pre-existing generation dirs not overwritten (AC-12)"
else
  not_ok "timestamp_collision_no_overwrite: an existing generation dir was overwritten (AC-12)"
fi

# =============================================================================
# ケース5: idempotent_reinstall — AC-05 + 境界ケース1 (UPDATE 0件で世代非増加)
# =============================================================================
SB2="$(mktemp -d -t sage-pres-2-XXXXXX)"
run_install "$SB2"
force_update "$SB2"
run_install "$SB2"                       # 1回目 (実更新あり)
first_sums="$(managed_checksums "$SB2")"
first_gens="$(backup_gen_count "$SB2")"
run_install "$SB2"                       # 2回目 (完全冪等な再実行)
second_sums="$(managed_checksums "$SB2")"
second_gens="$(backup_gen_count "$SB2")"
if [ "$RUN_RC" = "0" ]; then
  ok "idempotent_reinstall: second consecutive install exits 0 (AC-05)"
else
  not_ok "idempotent_reinstall: second install failed rc=${RUN_RC} (AC-05)"
fi
if [ -n "$first_sums" ] && [ "$first_sums" = "$second_sums" ]; then
  ok "idempotent_reinstall: managed file checksums identical after 2nd run (AC-05)"
else
  not_ok "idempotent_reinstall: managed file checksums changed on 2nd run (AC-05)"
fi
# 境界ケース1: UPDATE 0件ではバックアップ世代を作成しない (空世代でローテーション非消費)
if [ "$first_gens" = "$second_gens" ]; then
  ok "idempotent_reinstall: backup generation count unchanged on no-op re-run (AC-05 / 境界ケース1)"
else
  not_ok "idempotent_reinstall: backup generations grew ${first_gens} -> ${second_gens} on no-op re-run (AC-05 / 境界ケース1)"
fi

# =============================================================================
# ケース6: diff_no_write — AC-04 (unified diff 表示 + 全ファイル checksum 不変)
# =============================================================================
SB3="$(mktemp -d -t sage-pres-3-XXXXXX)"
run_install "$SB3"
mutate_managed_section "$SB3/CLAUDE.md"
force_update "$SB3"
before_tree="$(checksum_tree "$SB3")"
run_install "$SB3" --diff
if [ "$RUN_RC" = "0" ]; then
  ok "diff_no_write: install.sh --diff exits 0 (AC-04)"
else
  not_ok "diff_no_write: --diff exited rc=${RUN_RC} (AC-04)"
fi
if echo "$RUN_OUT" | grep -q '^---' && echo "$RUN_OUT" | grep -q '^+++'; then
  ok "diff_no_write: output contains unified diff ---/+++ headers (AC-04)"
else
  not_ok "diff_no_write: no unified diff headers in --diff output (AC-04)"
fi
after_tree="$(checksum_tree "$SB3")"
if [ "$before_tree" = "$after_tree" ]; then
  ok "diff_no_write: all file checksums unchanged by --diff (AC-04 / POST-02)"
else
  not_ok "diff_no_write: --diff modified files in the sandbox (AC-04 / POST-02)"
fi
if [ ! -e "$SB3/.sage/backup" ]; then
  ok "diff_no_write: --diff does not create .sage/backup/ (AC-04 / FR-03)"
else
  not_ok "diff_no_write: --diff created .sage/backup/ (AC-04 / FR-03)"
fi

# =============================================================================
# ケース7: diff_shows_outside_marker — AC-04b (マーカー外変更の可視化, FR-04)
# =============================================================================
# マーカー外 (開始マーカー直前) に sentinel 行を挿入 — diff 表示範囲に隠されず現れること
sent_tmp="$(mktemp -t sage-pres-sent-XXXXXX)"
{ printf 'SENTINEL_OUTSIDE_MARKER_LINE do not hide me\n'; cat "$SB3/CLAUDE.md"; } > "$sent_tmp"
cat "$sent_tmp" > "$SB3/CLAUDE.md"
rm -f "$sent_tmp"
run_install "$SB3" --diff
if echo "$RUN_OUT" | grep -qF 'SENTINEL_OUTSIDE_MARKER_LINE'; then
  ok "diff_shows_outside_marker: sentinel outside markers appears in --diff output (AC-04b)"
else
  not_ok "diff_shows_outside_marker: sentinel outside markers hidden from --diff output (AC-04b)"
fi

# =============================================================================
# ケース8: --dry-run はバックアップを作成しない (SPEC スコープ「含む」)
# =============================================================================
run_install "$SB3" --dry-run
if [ "$RUN_RC" = "0" ] && [ ! -e "$SB3/.sage/backup" ]; then
  ok "dry-run with pending update creates no backup (SPEC scope: --dry-run 時はバックアップ非作成)"
else
  not_ok "dry-run created backup or failed rc=${RUN_RC} (SPEC scope violation)"
fi

# =============================================================================
# ケース9: marker_half_broken_safe — AC-08 (片方欠損 = WARN + スキップ + exit 0)
# =============================================================================
SB4="$(mktemp -d -t sage-pres-4-XXXXXX)"
run_install "$SB4"
# 終了マーカーのみ削除 (開始マーカーは残す)
half_tmp="$(mktemp -t sage-pres-half-XXXXXX)"
grep -v 'End SAGE' "$SB4/CLAUDE.md" > "$half_tmp"
cat "$half_tmp" > "$SB4/CLAUDE.md"
rm -f "$half_tmp"
cp "$SB4/CLAUDE.md" "$SB4/CLAUDE.md.broken"
force_update "$SB4"
run_install "$SB4"
if [ "$RUN_RC" = "0" ]; then
  ok "marker_half_broken_safe: installer exits 0 with half-broken markers (AC-08)"
else
  not_ok "marker_half_broken_safe: installer exited rc=${RUN_RC}, expected 0 (AC-08)"
fi
if echo "$RUN_OUT" | grep -qi 'warn'; then
  ok "marker_half_broken_safe: WARN is emitted (AC-08)"
else
  not_ok "marker_half_broken_safe: no WARN output (AC-08)"
fi
if cmp -s "$SB4/CLAUDE.md" "$SB4/CLAUDE.md.broken"; then
  ok "marker_half_broken_safe: file content unchanged, no append (AC-08)"
else
  not_ok "marker_half_broken_safe: file was modified or appended (AC-08)"
fi

# =============================================================================
# ケース10: marker_both_missing_append — 境界ケース2 (末尾 append、既存行不変)
# =============================================================================
SB5="$(mktemp -d -t sage-pres-5-XXXXXX)"
run_install "$SB5"
printf 'my fully manual claude file\nsecond user line\n' > "$SB5/CLAUDE.md"
force_update "$SB5"
run_install "$SB5"
if [ "$RUN_RC" = "0" ]; then
  ok "marker_both_missing_append: installer exits 0 on marker-less file (境界ケース2)"
else
  not_ok "marker_both_missing_append: installer failed rc=${RUN_RC} (境界ケース2)"
fi
if head -2 "$SB5/CLAUDE.md" | grep -qF 'my fully manual claude file' \
   && grep -qF 'second user line' "$SB5/CLAUDE.md"; then
  ok "marker_both_missing_append: existing user lines are unchanged (境界ケース2)"
else
  not_ok "marker_both_missing_append: existing user lines were lost (境界ケース2)"
fi
if grep -q 'End SAGE' "$SB5/CLAUDE.md"; then
  ok "marker_both_missing_append: SAGE section appended to marker-less file (境界ケース2)"
else
  not_ok "marker_both_missing_append: SAGE section was not appended (境界ケース2)"
fi

# =============================================================================
# ケース11: backup_unwritable_aborts — AC-09 (fail-safe: バックアップ不能なら更新しない)
# =============================================================================
SB6="$(mktemp -d -t sage-pres-6-XXXXXX)"
run_install "$SB6"
mutate_managed_section "$SB6/CLAUDE.md"
cp "$SB6/CLAUDE.md" "$SB6/CLAUDE.md.before"
force_update "$SB6"
mkdir -p "$SB6/.sage/backup"
chmod 555 "$SB6/.sage/backup"
run_install "$SB6"
if [ "$RUN_RC" != "0" ]; then
  ok "backup_unwritable_aborts: installer exits non-zero when backup dir is unwritable (AC-09)"
else
  not_ok "backup_unwritable_aborts: installer exited 0 despite unwritable backup dir (AC-09)"
fi
if echo "$RUN_OUT" | grep -qiE 'error|cannot'; then
  ok "backup_unwritable_aborts: error message is emitted (AC-09)"
else
  not_ok "backup_unwritable_aborts: no error message emitted (AC-09)"
fi
if cmp -s "$SB6/CLAUDE.md" "$SB6/CLAUDE.md.before"; then
  ok "backup_unwritable_aborts: CLAUDE.md not overwritten without backup (AC-09 / INV-02)"
else
  not_ok "backup_unwritable_aborts: CLAUDE.md was overwritten without backup (AC-09 / INV-02)"
fi
chmod 755 "$SB6/.sage/backup"

# =============================================================================
# ケース12: claude_md_backup_convention — AC-13 (clean install に規約記載)
# =============================================================================
SB7="$(mktemp -d -t sage-pres-7-XXXXXX)"
run_install "$SB7"
if grep -qF '.sage/backup/' "$SB7/CLAUDE.md"; then
  ok "claude_md_backup_convention: clean-install CLAUDE.md documents .sage/backup/ (AC-13)"
else
  not_ok "claude_md_backup_convention: .sage/backup/ convention missing in CLAUDE.md (AC-13)"
fi

# =============================================================================
# ケース13: docs_restore_and_matrix — AC-10 (復元手順 + 対比表)
# =============================================================================
if grep -rq '\.sage/backup/' "$REPO_ROOT/README.md" "$REPO_ROOT/docs/"; then
  ok "docs_restore_and_matrix: restore steps reference .sage/backup/ in README/docs (AC-10)"
else
  not_ok "docs_restore_and_matrix: no .sage/backup/ restore reference in README/docs (AC-10)"
fi
if grep -rq '防御されないケース' "$REPO_ROOT/docs/"; then
  ok "docs_restore_and_matrix: marker protection matrix (防御されないケース) exists in docs (AC-10)"
else
  not_ok "docs_restore_and_matrix: marker protection matrix missing in docs (AC-10)"
fi

# =============================================================================
# ケース14: SHA256SUMS 再現性 — AC-06 (install.sh エントリの検証)
# =============================================================================
if ( cd "$REPO_ROOT" && grep ' install\.sh$' SHA256SUMS | shasum -a 256 -c - >/dev/null 2>&1 ); then
  ok "SHA256SUMS install.sh entry verifies (AC-06 / POST-03)"
else
  not_ok "SHA256SUMS install.sh entry verification failed (AC-06 / POST-03)"
fi

# =============================================================================
# ケース15: .sage/backup/ の gitignore 対象確認 (SPEC スコープ「含む」/ ASM-02)
# =============================================================================
if grep -q '^\.sage/backup/$' "$REPO_ROOT/.gitignore"; then
  ok ".sage/backup/ is gitignored in repo .gitignore (SPEC scope / ASM-02)"
else
  not_ok ".sage/backup/ missing from repo .gitignore (SPEC scope / ASM-02)"
fi

# Cleanup: only mktemp-created sandboxes (rm -r without -f on unique tmpdirs).
for d in "$SB1" "$SB2" "$SB3" "$SB4" "$SB5" "$SB6" "$SB7"; do
  case "$d" in
    */sage-pres-*) rm -r "$d" 2>/dev/null || true ;;
  esac
done

echo ""
echo "SUMMARY pass=${PASS} fail=${FAIL}"
[ "$FAIL" -eq 0 ]
