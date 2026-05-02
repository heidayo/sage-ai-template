# TASK-0124: sage-doctor.sh に MCP allowlist check 追加 + detection-only behavior test

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0124 |
| SPEC-ID   | SPEC-0015 |
| PLAN-ID   | PLAN-0015 |
| ステータス | Pending |
| 担当Agent | Implementation |
| 並列可否  | No |
| 依存TASK  | TASK-0123 (audit logic re-use + behavior test 対象) |
| 見積     | 60m (Codex review P2 反映で behavior test 追加 +15m) |

## 責務

`scripts/sage-doctor.sh` に MCP allowlist の health check ステップを新規追加。TASK-0123 の audit hook と同 logic を CLI から呼べる形に factor out し、doctor から reuse。**Detection-only behavior test** を追加し、`kill / pkill / killall` 等の実コマンドが hook script に含まれていないことを grep ベースではなく **挙動 test** で検証 (Codex review P2-5 反映)。

## 入力

- SPEC-0015 FR-04 (doctor 拡張仕様)
- SPEC-0015 SEC-01 (detection-only / runtime-process-safe behavior test)
- SPEC-0015 AC-04, AC-09 (doctor が OK/WARN/FAIL 返す + 0 FAIL)
- TASK-0123 で実装した audit hook の drift 検出ロジック
- 既存 `scripts/sage-doctor.sh` の structure (各 step の出力 format / FAIL 集計)
- Codex review P2-5 (verification command flakiness)

## 出力

1. `scripts/sage-doctor.sh` 拡張:
   - 新 step「MCP allowlist check」を既存 step 群の後に追加 (出力 format 統一)
   - 5 観点の check (Codex 5th review P2 #3 反映で strict-block drift type を全部 doctor にも反映):
     - **(a) registry 存在**: `.sage/mcp-allowlist.json` 存在しなければ WARN (initial setup 案内)
     - **(b) registry validity**: JSON parse 不能 → FAIL (Python stdlib `json.loads()`)
     - **(c) strict-block drift count**: TASK-0123 hook の drift 検出 logic を reuse して件数報告。**strict 時 block 対象 4 cases (drift1 / drift5 / drift6 anonymous / drift8 OAuth callback mismatch) のいずれか 1 件 > 0 で WARN** (Codex 5th review P2 #3 反映: doctor が事前に検出することで strict 昇格時の予期せぬ block を防ぐ)
     - **(d) other drift count** (warn-only category): drift2 / drift3 / drift4 / drift6 OAuth approve / drift6 Bearer approve / drift7 sensitive header / transport mismatch の合計件数を INFO レベルで報告
     - **(e) expired approvals 集計**: `expires_at` < 今日の server 数を WARN
   - 出力 format: `[N/M] MCP allowlist check...` + 各 sub-check で `OK: ...` / `WARN: ...` / `FAIL: ...`
   - 既存 summary line (`OK: X  WARN: Y  FAIL: Z`) に集計反映

2. `scripts/sage-mcp-allowlist-audit.sh` 新規 (TASK-0123 の audit logic を CLI から呼べる shell script として共通化):
   - hook (`templates/hooks/mcp-allowlist-audit.sh`) と doctor 両方が source または call で reuse
   - hook 側 logic が十分 modular なら本 script は wrapper のみ

3. `templates/hooks/tests/test-detection-only-behavior.sh` 新規 (**fake wrapper 方式**、Codex review P2-2 反映):
   - **setup**: tempdir に fake `kill` / `pkill` / `killall` 実行可能 wrapper を作成、各 wrapper は呼び出し時に `$INVOCATION_LOG` に追記
   - **PATH manipulation**: `PATH="$tempdir:$PATH"` で fake wrapper を先頭に置く
   - **execute**: `templates/hooks/mcp-allowlist-audit.sh` を subprocess として実行 (sample stdin 付き)
   - **assertion**: `[ ! -s "$INVOCATION_LOG" ]` (= log file が空) を確認、非空なら FAIL
   - **cleanup**: tempdir 削除
   - `ps aux | grep` 方式は採用しない (test 自身の grep プロセス / SPEC コメント記述が false fail を起こすため、Codex review P2-2 で却下)
   - 副次効果: hook 内で `kill` を文字列として `echo` する場合は wrapper が呼ばれないので false fail にならない (= 真の behavior 検証)

   ```bash
   # 概念実装イメージ:
   tempdir=$(mktemp -d)
   trap "rm -rf $tempdir" EXIT
   INVOCATION_LOG="$tempdir/invocations.log"
   for cmd in kill pkill killall; do
     cat > "$tempdir/$cmd" <<'WRAPPER'
   #!/bin/sh
   echo "$0 called with: $*" >> "$INVOCATION_LOG"
   WRAPPER
     chmod +x "$tempdir/$cmd"
   done
   PATH="$tempdir:$PATH" bash templates/hooks/mcp-allowlist-audit.sh < /dev/null
   if [ -s "$INVOCATION_LOG" ]; then
     echo "FAIL: detection-only violation, kill family invoked:"
     cat "$INVOCATION_LOG"
     exit 1
   fi
   echo "PASS: no kill family invocation"
   ```

## File Scope（変更許可範囲）

- 変更: `scripts/sage-doctor.sh`
- 作成: `scripts/sage-mcp-allowlist-audit.sh`
- 作成: `templates/hooks/tests/test-detection-only-behavior.sh`
- 削除: なし

## 禁止事項

- 既存 doctor step を削除 / 順序変更しない
- doctor から MCP server を kill / restart しない (audit-only)
- `.sage/audit/*.log` の内容を改変 / rotate しない (本 TASK は read-only)
- Phase 1-3 の test 109/109 を破壊しない (regression)
- behavior test を grep / `ps aux` ベースで実装しない (Codex review P2-2 反映、test 自身の grep プロセス混入で false fail、または SPEC/PLAN コメント記述で false positive、**fake wrapper 方式必須**)

## 完了条件

- [ ] `scripts/sage-doctor.sh` に「MCP allowlist check」step が追加され、既存 step 数 + 1 に
- [ ] registry 不在で WARN 出る (実機テスト: registry を一時削除して doctor 実行)
- [ ] registry valid + drift なし で OK 出る
- [ ] drift1 inject で WARN 出る (実機テスト: `.mcp.json` に registry にない server 追加)
- [ ] drift5 inject で WARN 出る (実機テスト: artifact_type ごとに simulate — npm_package: npm_integrity mismatch / local_binary: command_path_sha256 mismatch / remote_http: tls_pin_sha256 mismatch)
- [ ] expired approval inject で WARN 出る
- [ ] `bash scripts/sage-doctor.sh` 全体で 0 FAIL 維持 (本 TASK 完了直後の repo state で)
- [ ] `templates/hooks/tests/test-detection-only-behavior.sh` PASS (kill 系 process 起動 0 件を behavior 検証)
- [ ] commit message に `TASK-0124:` を含む
