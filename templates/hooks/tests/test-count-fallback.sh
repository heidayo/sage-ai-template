#!/usr/bin/env bash
# =============================================================================
# TASK-0225: test-count-fallback.sh
# Purpose:  Regression test for `grep -c ... || echo "0"` count captures.
#           grep -c prints 0 and exits 1 when nothing matches, so the
#           `|| echo "0"` fallback appended a second 0 ("0\n0"). The following
#           `[ "$N" -gt 0 ]` then failed with "integer expression expected"
#           and only passed because `[` returned 2. These cases exercise the
#           no-match path (must be silent) and the match path (must still
#           reject) of every reachable count check.
# Style:    Follows test-id-patterns.sh (tmpdir git sandboxes + ok/not_ok).
# =============================================================================
set -uo pipefail

PASS=0
FAIL=0

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
HOOK="${REPO_ROOT}/templates/pre-commit-task-id.sh"
INT_ERR='integer expression expected'

ok() { PASS=$((PASS + 1)); echo "  ok   $1"; }
not_ok() { FAIL=$((FAIL + 1)); echo "  not ok $1" >&2; }

# git_sandbox <branch> — git repo with one commit on main, then <branch>
# checked out. Echos the sandbox path.
git_sandbox() {
  local branch="$1" dir
  dir="$(mktemp -d -t sage-count-XXXXXX)"
  (
    cd "$dir" || exit 1
    git init -q
    git checkout -q -b main
    git -c user.email=t@t -c user.name=t commit -q --allow-empty -m "TASK-0000: init fixture"
    git checkout -q -b "$branch"
  ) >/dev/null 2>&1
  echo "$dir"
}

# commit_in <sandbox> <message> — empty commit with a fixed identity.
commit_in() {
  ( cd "$1" && git -c user.email=t@t -c user.name=t commit -q --allow-empty -m "$2" ) >/dev/null 2>&1
}

# run_captured <sandbox> <cmd...> — run a command from the sandbox cwd.
# Sets RUN_RC / RUN_OUT / RUN_ERR.
run_captured() {
  local dir="$1" out_file err_file
  shift
  out_file="$(mktemp -t sage-count-out-XXXXXX)"
  err_file="$(mktemp -t sage-count-err-XXXXXX)"
  ( cd "$dir" && "$@" >"$out_file" 2>"$err_file" )
  RUN_RC=$?
  RUN_OUT="$(cat "$out_file")"
  RUN_ERR="$(cat "$err_file")"
  rm -f "$out_file" "$err_file"
}

# run_hook_staged <sandbox> <message> — run the commit-msg hook against the
# sandbox's staged files.
run_hook_staged() {
  local dir="$1" msg_file
  msg_file="$(mktemp -t sage-count-msg-XXXXXX)"
  printf '%s\n' "$2" > "$msg_file"
  run_captured "$dir" bash "$HOOK" "$msg_file"
  rm -f "$msg_file"
}

# validate_sandbox <branch> — git sandbox carrying sage-validate.sh and its
# ID pattern loader, so the promote/* checks can run against fixtures.
validate_sandbox() {
  local dir
  dir="$(git_sandbox "$1")"
  mkdir -p "${dir}/scripts" "${dir}/specs"
  cp "${REPO_ROOT}/scripts/sage-validate.sh" "${REPO_ROOT}/scripts/sage-id-pattern.sh" "${dir}/scripts/"
  echo "$dir"
}

# write_retro_spec <sandbox> <name> <source-sha> <extra-line> — minimal
# Retro-SPEC with the 昇格元SHA row read by sage-validate.sh.
write_retro_spec() {
  cat > "$1/specs/RETRO-SPEC-$2.md" <<EOF
# Retro-SPEC: $2

| フィールド | 内容 |
|-----------|------|
| 昇格元SHA | $3 |

$4
EOF
}

echo "# grep -c count fallback (TASK-0225)"

# =============================================================================
# ケース1: commit_msg_lite_no_contract
# fix/* で契約ファイルなしのコミットは exit 0 で、stderr にエラーが出ない
# =============================================================================
SB1="$(git_sandbox fix/count-fixture)"
echo "content" > "$SB1/app.txt"
( cd "$SB1" && git add app.txt )
run_hook_staged "$SB1" 'TASK-0001: fix typo'
if [ "$RUN_RC" = "0" ]; then
  ok "commit_msg_lite_no_contract: exit 0 without contract files"
else
  not_ok "commit_msg_lite_no_contract: rc=${RUN_RC}, expected 0 (out='${RUN_OUT}' err='${RUN_ERR}')"
fi
if [ -z "$RUN_ERR" ]; then
  ok "commit_msg_lite_no_contract: stderr is empty"
else
  not_ok "commit_msg_lite_no_contract: unexpected stderr '${RUN_ERR}'"
fi

# =============================================================================
# ケース2: commit_msg_lite_schema_rejected
# fix/* で schema ファイルをステージしたコミットは拒否され、件数が 1 と表示される
# =============================================================================
mkdir -p "$SB1/db"
echo "create table t (id int);" > "$SB1/db/schema.sql"
( cd "$SB1" && git add db/schema.sql )
run_hook_staged "$SB1" 'TASK-0001: fix typo'
if [ "$RUN_RC" != "0" ]; then
  ok "commit_msg_lite_schema_rejected: staged schema file is rejected"
else
  not_ok "commit_msg_lite_schema_rejected: rc=0, expected rejection"
fi
case "$RUN_OUT" in
  *"lite lane prohibits contract changes"*"Detected 1 contract file(s) in staging."*)
    ok "commit_msg_lite_schema_rejected: reports 1 contract file" ;;
  *)
    not_ok "commit_msg_lite_schema_rejected: missing contract message (out='${RUN_OUT}')" ;;
esac

# =============================================================================
# ケース3: validate_promote_clean
# TBD なし・昇格後コミットが全て TASK-ID ありの promote/* で、2 つの件数
# チェックが OK を出し、integer エラーが出ない
# =============================================================================
SB3="$(validate_sandbox promote/count-clean)"
SOURCE_SHA3="$(cd "$SB3" && git rev-parse HEAD)"
write_retro_spec "$SB3" count-clean "$SOURCE_SHA3" "すべて記入済み"
commit_in "$SB3" "TASK-0002: promote fixture"
run_captured "$SB3" bash scripts/sage-validate.sh
case "$RUN_OUT" in
  *"OK: Retro-SPEC に未記入項目なし"*) ok "validate_promote_clean: TBD check reports OK" ;;
  *) not_ok "validate_promote_clean: TBD OK line missing (out='${RUN_OUT}')" ;;
esac
case "$RUN_OUT" in
  *"OK: 昇格後コミットは全て TASK-ID あり"*) ok "validate_promote_clean: TASK-ID check reports OK" ;;
  *) not_ok "validate_promote_clean: TASK-ID OK line missing (out='${RUN_OUT}')" ;;
esac
case "$RUN_ERR" in
  *"$INT_ERR"*) not_ok "validate_promote_clean: stderr has '${INT_ERR}' (err='${RUN_ERR}')" ;;
  *) ok "validate_promote_clean: no '${INT_ERR}' on stderr" ;;
esac

# =============================================================================
# ケース4: validate_promote_dirty
# TBD 1 件・TASK-ID なしコミット 1 件の promote/* で、両チェックが件数 1 の
# ERROR を出す
# =============================================================================
SB4="$(validate_sandbox promote/count-dirty)"
SOURCE_SHA4="$(cd "$SB4" && git rev-parse HEAD)"
write_retro_spec "$SB4" count-dirty "$SOURCE_SHA4" "受け入れ基準: TBD"
commit_in "$SB4" "promote fixture without id"
run_captured "$SB4" bash scripts/sage-validate.sh
case "$RUN_OUT" in
  *"ERROR: Retro-SPEC に TBD が 1 件残っています"*) ok "validate_promote_dirty: TBD check reports 1" ;;
  *) not_ok "validate_promote_dirty: TBD error line missing (out='${RUN_OUT}')" ;;
esac
case "$RUN_OUT" in
  *"TASK-ID なしが 1 件あります"*) ok "validate_promote_dirty: TASK-ID check reports 1" ;;
  *) not_ok "validate_promote_dirty: TASK-ID error line missing (out='${RUN_OUT}')" ;;
esac

# =============================================================================
# ケース5: retro_spec_no_changes
# main と差分のない vibe/* で、変更ファイル数が 1 行の "Found 0 changed files"
# と表示される
# =============================================================================
SB5="$(git_sandbox vibe/count-empty)"
mkdir -p "$SB5/scripts" "$SB5/specs"
cp "${REPO_ROOT}/scripts/sage-retro-spec.sh" "$SB5/scripts/"
run_captured "$SB5" bash scripts/sage-retro-spec.sh vibe/count-empty
case "$RUN_OUT" in
  *"Found 0 changed files"*) ok "retro_spec_no_changes: reports 'Found 0 changed files'" ;;
  *) not_ok "retro_spec_no_changes: expected 'Found 0 changed files' (rc=${RUN_RC} out='${RUN_OUT}' err='${RUN_ERR}')" ;;
esac

rm -rf "$SB1" "$SB3" "$SB4" "$SB5"

echo ""
echo "SUMMARY pass=${PASS} fail=${FAIL}"
[ "$FAIL" -eq 0 ]
