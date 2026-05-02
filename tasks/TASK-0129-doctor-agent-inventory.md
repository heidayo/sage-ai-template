# TASK-0129: sage-doctor.sh 拡張 — agent inventory drift check

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0129 |
| SPEC-ID   | SPEC-0017 |
| PLAN-ID   | PLAN-0017 |
| ステータス | Pending |
| 並列可否  | No |
| 依存TASK  | TASK-0128 |
| 見積     | 45m |

## 責務

`scripts/sage-doctor.sh` に「[4/5] agent inventory drift check」step 追加 + Python audit script (sage-mcp-allowlist-audit.sh と同パターン)。

## 出力

1. `scripts/sage-doctor.sh` 拡張:
   - 新 step `[4/5] Agent inventory check`
   - inventory 存在チェック (WARN if missing)
   - 最近 10 RUN log を Python で集計、declared vs observed mismatch 件数 → WARN
   - missing runtime field 件数 → INFO

2. `scripts/sage-agent-inventory-audit.sh` (CLI wrapper、TSV 出力)

## File Scope

- 変更: `scripts/sage-doctor.sh`
- 作成: `scripts/sage-agent-inventory-audit.sh`

## 禁止事項

- 既存 doctor step ([1/4]..[3/4]) を削除 / 順序変更しない (既存 OK / WARN / FAIL 集計に影響しない)
- inventory drift を doctor で FAIL にしない (warn-only 厳守、SPEC-0017 doctrine)
- agent inventory 関連で MCP server を kill / signal しない (governance §9.2)
- audit script を `.sage/audit/` 以外のディレクトリに書かせない (NFR-04 と同方針)
- TASK-0124 の MCP allowlist check step を変更しない (本 TASK は新 step 追加のみ)

## 完了条件

- [ ] doctor step 数 4 → 5
- [ ] inventory 不在で WARN
- [ ] inventory 存在 + 既存 RUN log (runtime 不在) で INFO 集計
- [ ] doctor 全体 0 FAIL
- [ ] commit message に `TASK-0129:` 含む
