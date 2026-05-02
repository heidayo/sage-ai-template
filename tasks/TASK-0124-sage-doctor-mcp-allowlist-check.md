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
   - 4 観点の check:
     - **(a) registry 存在**: `.sage/mcp-allowlist.json` 存在しなければ WARN (initial setup 案内)
     - **(b) registry validity**: JSON parse 不能 → FAIL (Python stdlib `json.loads()`)
     - **(c) drift count**: TASK-0123 hook の drift 検出 logic を reuse して件数報告。drift1 / drift5 件数 > 0 → WARN
     - **(d) expired approvals 集計**: `expires_at` < 今日の server 数を WARN
   - 出力 format: `[N/M] MCP allowlist check...` + 各 sub-check で `OK: ...` / `WARN: ...` / `FAIL: ...`
   - 既存 summary line (`OK: X  WARN: Y  FAIL: Z`) に集計反映

2. `scripts/sage-mcp-allowlist-audit.sh` 新規 (TASK-0123 の audit logic を CLI から呼べる shell script として共通化):
   - hook (`templates/hooks/mcp-allowlist-audit.sh`) と doctor 両方が source または call で reuse
   - hook 側 logic が十分 modular なら本 script は wrapper のみ

3. `templates/hooks/tests/test-detection-only-behavior.sh` 新規 (Codex review P2-5 反映):
   - `templates/hooks/mcp-allowlist-audit.sh` を **subprocess として実行**
   - 実行中に `ps aux | grep -E "kill|pkill|killall"` で kill 系プロセスが新規起動していないことを確認
   - hook 終了後 PID 一覧の差分で 「new kill 系 child process 0 件」を assertion
   - grep ベース検査 (`! grep -E "kill|pkill|killall" hook.sh`) はコメント / 文字列にも反応するため不採用、**挙動 test** で実際の process spawn を監視
   - もし behavior test の OS 依存が高い場合 fallback として AST-level check (`bash -n` + token scan) も併用

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
- behavior test を grep のみで代替しない (Codex review P2-5 反映、コメント/文字列 false positive 回避)

## 完了条件

- [ ] `scripts/sage-doctor.sh` に「MCP allowlist check」step が追加され、既存 step 数 + 1 に
- [ ] registry 不在で WARN 出る (実機テスト: registry を一時削除して doctor 実行)
- [ ] registry valid + drift なし で OK 出る
- [ ] drift1 inject で WARN 出る (実機テスト: `.mcp.json` に registry にない server 追加)
- [ ] drift5 inject で WARN 出る (実機テスト: sha256 mismatch 状況を simulate)
- [ ] expired approval inject で WARN 出る
- [ ] `bash scripts/sage-doctor.sh` 全体で 0 FAIL 維持 (本 TASK 完了直後の repo state で)
- [ ] `templates/hooks/tests/test-detection-only-behavior.sh` PASS (kill 系 process 起動 0 件を behavior 検証)
- [ ] commit message に `TASK-0124:` を含む
