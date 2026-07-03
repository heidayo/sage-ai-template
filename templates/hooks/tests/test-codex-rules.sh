#!/usr/bin/env bash
# =============================================================================
# TASK-0202: test-codex-rules.sh (SPEC-0029)
# Purpose:  Integration test for the Codex rules layer distribution:
#           installer must distribute 5 managed rules to .codex/rules/,
#           keep .codex/rules/local/ untouched, and document precedence.
# Style:    Follows test-local-overlay.sh (tmpdir + generated install.sh).
# Note:     Expected values are derived from SPEC-0029 AC-01..AC-12 only,
#           never from generator internals (AP-07 prevention).
# =============================================================================
set -uo pipefail

PASS=0
FAIL=0

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
INSTALL_SH="${REPO_ROOT}/install.sh"

# The 5 managed rules names fixed by SPEC-0029 AC-02 (file contract).
RULE_NAMES="specs plans tasks src sage-governance"

ok() { PASS=$((PASS + 1)); echo "  ok   $1"; }
not_ok() { FAIL=$((FAIL + 1)); echo "  not ok $1" >&2; }

# run_install <sandbox-dir> [args...] — run the generated installer from a
# sandbox cwd, capturing rc/stdout+stderr into RUN_RC / RUN_OUT.
run_install() {
  local dir="$1"; shift
  local out_file
  out_file="$(mktemp -t sage-codexrules-out-XXXXXX)"
  ( cd "$dir" && bash "$INSTALL_SH" "$@" </dev/null >"$out_file" 2>&1 )
  RUN_RC=$?
  RUN_OUT="$(cat "$out_file")"
  rm -f "$out_file"
}

echo "# codex rules layer distribution (SPEC-0029)"

if [ ! -f "$INSTALL_SH" ]; then
  not_ok "install.sh not found at ${INSTALL_SH} — cannot run codex rules tests"
  echo ""
  echo "SUMMARY pass=${PASS} fail=${FAIL}"
  exit 1
fi

# =============================================================================
# ケース1: templates_paired — 配布対象 5 rules の 1:1 対応 (AC-01 / CHECK-001)
# harness-rules.md は Claude 専用のため除外 (SPEC-0029 スコープ外)
# =============================================================================
if diff <(ls "$REPO_ROOT/templates/rules/" | grep -v '^harness-rules.md$') \
        <(ls "$REPO_ROOT/templates/codex-rules/") >/dev/null 2>&1; then
  ok "templates_paired: templates/codex-rules/ mirrors distributable rules 1:1 (AC-01)"
else
  not_ok "templates_paired: templates/rules/ vs templates/codex-rules/ set mismatch (AC-01)"
fi

# =============================================================================
# ケース2: codex_rules_installed — clean install で 5 ファイル + marker + overlay 案内 (AC-02 / CHECK-002)
# =============================================================================
SB1="$(mktemp -d -t sage-codexrules-1-XXXXXX)"
run_install "$SB1"
if [ "$RUN_RC" = "0" ]; then
  ok "codex_rules_installed: clean install exits 0 (AC-02)"
else
  not_ok "codex_rules_installed: clean install failed rc=${RUN_RC} (AC-02)"
fi
missing=""
for f in $RULE_NAMES; do
  rule="$SB1/.codex/rules/${f}-rules.md"
  # AC-02: file exists, contains the SAGE managed marker, and points the
  # reader at the .codex/rules/local/ overlay for project-specific rules.
  if [ ! -f "$rule" ] || ! grep -qF 'SAGE managed' "$rule" || ! grep -qF '.codex/rules/local' "$rule"; then
    missing="${missing} ${f}"
  fi
done
if [ -z "$missing" ]; then
  ok "codex_rules_installed: all 5 rules exist with marker + local overlay notice (AC-02)"
else
  not_ok "codex_rules_installed: bad/missing rules:${missing} (AC-02)"
fi

# =============================================================================
# ケース3: overlay_untouched — .codex/rules/local/ は install/再installで不可侵 (AC-03 / CHECK-003)
# =============================================================================
SB2="$(mktemp -d -t sage-codexrules-2-XXXXXX)"
mkdir -p "$SB2/.codex/rules/local"
printf '# my project codex rule\ndo not touch\n' > "$SB2/.codex/rules/local/my-rules.md"
before_overlay="$(cat "$SB2/.codex/rules/local/my-rules.md")"
run_install "$SB2"
run_install "$SB2"
if [ -f "$SB2/.codex/rules/local/my-rules.md" ] && \
   [ "$(cat "$SB2/.codex/rules/local/my-rules.md")" = "$before_overlay" ]; then
  ok "overlay_untouched: .codex/rules/local/my-rules.md byte-identical after install + re-install (AC-03)"
else
  not_ok "overlay_untouched: overlay file modified or deleted (AC-03)"
fi

# =============================================================================
# ケース4: reinstall_idempotent — install 2 回で .codex/rules/ がバイト同一 (AC-04 / CHECK-004)
# =============================================================================
SB3="$(mktemp -d -t sage-codexrules-3-XXXXXX)"
run_install "$SB3"
snap1="$(mktemp -d -t sage-codexrules-snap-XXXXXX)"
cp -R "$SB3/.codex/rules/." "$snap1/"
run_install "$SB3"
if diff -r "$snap1" "$SB3/.codex/rules" >/dev/null 2>&1; then
  ok "reinstall_idempotent: .codex/rules/ byte-identical across two installs (AC-04)"
else
  not_ok "reinstall_idempotent: .codex/rules/ differs between installs (AC-04)"
fi

# =============================================================================
# ケース5: managed_replace — バージョン差分前提の --update 復元 (AC-05 / CHECK-005)
# 段階1: 同一バージョンでの --update は no-op (既存のバージョンゲート仕様確認)
# 段階2: .sage/version を旧値に下げた --update でテンプレート内容へ全置換
# =============================================================================
echo "LOCAL EDIT MUST BE REPLACED" >> "$SB3/.codex/rules/specs-rules.md"
run_install "$SB3" --update
if [ "$RUN_RC" = "0" ]; then
  ok "managed_replace: same-version --update exits 0 (AC-05)"
else
  not_ok "managed_replace: same-version --update failed rc=${RUN_RC} (AC-05)"
fi
if grep -qF 'LOCAL EDIT MUST BE REPLACED' "$SB3/.codex/rules/specs-rules.md"; then
  ok "managed_replace: same-version --update is no-op, appended line survives (AC-05)"
else
  not_ok "managed_replace: same-version --update replaced managed rule unexpectedly (AC-05)"
fi
# Downgrade installed version so --update sees a version diff and redistributes.
echo "0.0.0" > "$SB3/.sage/version"
run_install "$SB3" --update
if [ "$RUN_RC" = "0" ]; then
  ok "managed_replace: version-diff --update exits 0 (AC-05)"
else
  not_ok "managed_replace: version-diff --update failed rc=${RUN_RC} (AC-05)"
fi
if ! grep -qF 'LOCAL EDIT MUST BE REPLACED' "$SB3/.codex/rules/specs-rules.md"; then
  ok "managed_replace: appended line removed, template content restored (AC-05)"
else
  not_ok "managed_replace: appended line survived version-diff --update (AC-05)"
fi

# =============================================================================
# ケース6: verify_checksum_covers — install-state managed 登録 + verify PASS (AC-06 / CHECK-006)
# =============================================================================
state_count="$(grep -c '.codex/rules/' "$SB1/.sage/install-state.yaml" 2>/dev/null || echo 0)"
if [ "$state_count" -ge 5 ]; then
  ok "verify_checksum_covers: install-state lists .codex/rules/ entries >= 5 (AC-06, got ${state_count})"
else
  not_ok "verify_checksum_covers: install-state .codex/rules/ entries = ${state_count}, expected >= 5 (AC-06)"
fi
run_install "$SB1" --verify-checksum
if [ "$RUN_RC" = "0" ]; then
  ok "verify_checksum_covers: --verify-checksum passes after clean install (AC-06)"
else
  not_ok "verify_checksum_covers: --verify-checksum failed rc=${RUN_RC} (AC-06)"
fi

# =============================================================================
# ケース7: dry_run_no_write — 異常系: dry-run は .codex を作らず WOULD-* 表示 (AC-07 / CHECK-007)
# =============================================================================
SB4="$(mktemp -d -t sage-codexrules-4-XXXXXX)"
run_install "$SB4" --dry-run
if [ ! -e "$SB4/.codex" ]; then
  ok "dry_run_no_write: --dry-run creates nothing under .codex (AC-07)"
else
  not_ok "dry_run_no_write: --dry-run created .codex (AC-07)"
fi
if echo "$RUN_OUT" | grep -F '.codex/rules' | grep -q 'WOULD-'; then
  ok "dry_run_no_write: stdout shows WOULD-* line for .codex/rules (AC-07)"
else
  not_ok "dry_run_no_write: no WOULD-* output for .codex/rules (AC-07)"
fi

# =============================================================================
# ケース8: local_as_file — 異常系: .codex/rules/local が通常ファイル (AC-08 / CHECK-008)
# installer は当該ファイルに書き込まず (WARN + 不介入)、managed 5 件は配布継続
# =============================================================================
SB5="$(mktemp -d -t sage-codexrules-5-XXXXXX)"
mkdir -p "$SB5/.codex/rules"
printf 'i am a plain file, not a directory\n' > "$SB5/.codex/rules/local"
before_file="$(cat "$SB5/.codex/rules/local")"
run_install "$SB5"
if [ "$RUN_RC" = "0" ]; then
  ok "local_as_file: installer exits 0 when local is a regular file (AC-08)"
else
  not_ok "local_as_file: installer exited rc=${RUN_RC}, expected 0 (AC-08)"
fi
if [ -f "$SB5/.codex/rules/local" ] && [ "$(cat "$SB5/.codex/rules/local")" = "$before_file" ]; then
  ok "local_as_file: regular file byte-identical after install (AC-08)"
else
  not_ok "local_as_file: regular file modified or removed (AC-08)"
fi
missing=""
for f in $RULE_NAMES; do
  [ -f "$SB5/.codex/rules/${f}-rules.md" ] || missing="${missing} ${f}"
done
if [ -z "$missing" ]; then
  ok "local_as_file: managed 5 rules still distributed (AC-08)"
else
  not_ok "local_as_file: managed rules missing:${missing} (AC-08)"
fi

# =============================================================================
# ケース9: docs_reference — docs/codex-rules.md 配布 + 優先順位・対応表記載 (AC-09 / CHECK-009)
# =============================================================================
DOC="$REPO_ROOT/docs/codex-rules.md"
if [ -f "$DOC" ] && \
   grep -qF '.codex/rules/' "$DOC" && \
   grep -qF 'AGENTS.md' "$DOC" && \
   grep -qF '.claude/rules/' "$DOC" && \
   grep -qF '.codex/rules/local/' "$DOC"; then
  ok "docs_reference: docs/codex-rules.md covers precedence / mapping / overlay (AC-09)"
else
  not_ok "docs_reference: docs/codex-rules.md missing or lacks required sections (AC-09)"
fi
if grep -qF 'docs/codex-rules.md' "$REPO_ROOT/README.md"; then
  ok "docs_reference: README.md references docs/codex-rules.md (AC-09)"
else
  not_ok "docs_reference: README.md does not reference docs/codex-rules.md (AC-09)"
fi
# AC-09/FR-07: docs is also distributed by the installer
if [ -f "$SB1/docs/codex-rules.md" ]; then
  ok "docs_reference: installer distributes docs/codex-rules.md (FR-07)"
else
  not_ok "docs_reference: docs/codex-rules.md not distributed by installer (FR-07)"
fi

# =============================================================================
# ケース10: SHA256SUMS — install.sh エントリの checksum 一致 (AC-10 / CHECK-010)
# =============================================================================
if ( cd "$REPO_ROOT" && grep ' install.sh$' SHA256SUMS | shasum -a 256 -c - >/dev/null 2>&1 ); then
  ok "sha256sums: install.sh entry in SHA256SUMS verifies (AC-10)"
else
  not_ok "sha256sums: install.sh does not match SHA256SUMS (AC-10)"
fi

# =============================================================================
# ケース11: boundary — PR diff に boundary ファイルが含まれない (AC-12 前半 / CHECK-012)
# (git 履歴が浅い CI 等で main が参照できない場合は判定不能として skip)
# =============================================================================
if git -C "$REPO_ROOT" rev-parse --verify main >/dev/null 2>&1; then
  if git -C "$REPO_ROOT" diff --name-only main 2>/dev/null | \
     grep -E '^(AGENTS\.md|docs/codex-delegation-packet\.md|docs/codex-security\.md|templates/rules/|\.claude/rules/)' >/dev/null; then
    not_ok "boundary: diff vs main touches Codex/Claude boundary files (AC-12)"
  else
    ok "boundary: no boundary files (AGENTS.md / codex docs / templates/rules/ / .claude/rules/) in diff vs main (AC-12)"
  fi
else
  ok "boundary: main ref unavailable, boundary check skipped (AC-12)"
fi

# Cleanup: only mktemp-created sandboxes. If removal is blocked by hooks,
# unique tmpdirs are simply left behind (allowed by TASK-0202 rules).
for d in "$SB1" "$SB2" "$SB3" "$SB4" "$SB5" "$snap1"; do
  case "$d" in
    */sage-codexrules-*) rm -r "$d" 2>/dev/null || true ;;
  esac
done

echo ""
echo "SUMMARY pass=${PASS} fail=${FAIL}"
[ "$FAIL" -eq 0 ]
