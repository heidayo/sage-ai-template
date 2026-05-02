# TASK-0124: sage-doctor.sh に MCP allowlist check 追加

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0124 |
| SPEC-ID   | SPEC-0015 |
| PLAN-ID   | PLAN-0015 |
| ステータス | Pending |
| 担当Agent | Implementation |
| 並列可否  | No |
| 依存TASK  | TASK-0123 (audit logic re-use) |
| 見積     | 45m |

## 責務

`scripts/sage-doctor.sh` に MCP allowlist の health check ステップを新規追加する。TASK-0123 の audit hook と同 logic (drift 検出) を CLI から呼べる形に factor out し、doctor からも reuse できる構造にする。doctor の既存 step は不変。

## 入力

- SPEC-0015 FR-03 (doctor 拡張仕様)
- SPEC-0015 AC-04 (新ステップが OK/WARN/FAIL を返す)
- TASK-0123 で実装した audit hook の drift 検出ロジック
- 既存 `scripts/sage-doctor.sh` の structure (各 step の出力 format / FAIL 集計)

## 出力

1. `scripts/sage-doctor.sh` 拡張:
   - 新 step「MCP allowlist check」を既存 step 群の後に追加 (出力 format は既存と統一)
   - 3 観点の check:
     - **(a) registry 存在**: `.sage/mcp-allowlist.yaml` 存在しなければ WARN (initial setup 案内)
     - **(b) registry validity**: YAML parse 不能 → FAIL
     - **(c) drift count**: TASK-0123 hook の drift 検出を reuse して件数報告。drift1 件数 > 0 → WARN
   - **(d) expired approvals 集計**: `expires_at` < 今日の server 数を WARN (件数のみ表示)
   - 出力 format: `[N/M] MCP allowlist check...` + 各 sub-check で `OK: ...` / `WARN: ...` / `FAIL: ...`
   - 既存 summary line (`OK: X  WARN: Y  FAIL: Z`) に集計が反映される

2. (optional) `scripts/sage-mcp-allowlist-audit.sh` 新規 — TASK-0123 の audit logic を CLI から呼べる shell script として共通化:
   - hook と doctor の両方が source または call で reuse
   - もし hook 側 logic が十分 modular なら本 script は不要、TASK-0123 内の関数を doctor から source するだけで済む

## File Scope（変更許可範囲）

- 変更: `scripts/sage-doctor.sh`
- 作成: (optional) `scripts/sage-mcp-allowlist-audit.sh`
- 削除: なし

## 禁止事項

- 既存 doctor step を削除 / 順序変更しない
- doctor から MCP server を kill / restart しない (audit-only)
- `.sage/audit/*.log` の内容を改変 / rotate しない (本 TASK は read-only)
- Phase 1-3 の test 109/109 を破壊しない (regression)

## 完了条件

- [ ] `scripts/sage-doctor.sh` に「MCP allowlist check」step が追加され、既存 step 数 + 1 に
- [ ] registry 不在で WARN 出る (実機テスト: registry を一時削除して doctor 実行)
- [ ] registry valid + drift なし で OK 出る
- [ ] drift1 inject で WARN 出る (実機テスト: `.mcp.json` に registry にない server 追加)
- [ ] expired approval inject で WARN 出る
- [ ] `bash scripts/sage-doctor.sh` 全体で 0 FAIL 維持 (本 TASK 完了直後の repo state で)
- [ ] commit message に `TASK-0124:` を含む
