# TASK-0133: doctor [5/6] step + audit script + 2 シナリオ test

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0133 |
| SPEC-ID   | SPEC-0016 |
| PLAN-ID   | PLAN-0016 |
| ステータス | Pending |
| 並列可否  | No |
| 依存TASK  | TASK-0132 |
| 見積     | 45m |

## 責務

`scripts/sage-doctor.sh` に `[5/6]` step 追加 + `scripts/sage-runlog-db-audit.sh` audit CLI wrapper + 2 シナリオ test。

## 出力

1. `scripts/sage-doctor.sh` 拡張:
   - 全 [N/5] step を [N/6] に renumber
   - `[5/6] RUN log DB check` 新 step 追加 (4 sub-check):
     - DB 存在 (WARN if missing)
     - schema validity (FAIL if mismatch)
     - 最終 index 時刻 (WARN if > 7 日)
     - DB size (WARN if > 100 MB)

2. `scripts/sage-runlog-db-audit.sh` (TSV 出力 CLI wrapper)

3. `templates/hooks/tests/test-runlog-db-doctor.sh` (2 シナリオ):
   - DB 不在 → WARN
   - DB 存在 + 健全 → OK

## File Scope

- 変更: `scripts/sage-doctor.sh`
- 作成: `scripts/sage-runlog-db-audit.sh`
- 作成: `templates/hooks/tests/test-runlog-db-doctor.sh`

## 禁止事項

- 既存 doctor step ([1/5]..[4/5]) を **削除 / 順序変更しない** (既存集計に影響なし)
- DB 健全性 check を FAIL にしない (warn-only 厳守、`schema mismatch` のみ FAIL)
- audit script が `.sage/audit/` 以外に出力しない
- doctor から indexer を auto 起動しない (read-only)
- TASK-0124 (MCP) / TASK-0129 (inventory) step を変更しない (本 TASK は新 step 追加のみ)

## 完了条件

- [ ] doctor step 数 5 → 6
- [ ] DB 不在で WARN
- [ ] DB 健全で OK
- [ ] doctor 全体 0 FAIL
- [ ] commit message に `TASK-0133:` 含む
