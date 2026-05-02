# TASK-0128: sage-runlog-validate.sh 拡張 + 6 シナリオ test

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0128 |
| SPEC-ID   | SPEC-0017 |
| PLAN-ID   | PLAN-0017 |
| ステータス | Pending |
| 並列可否  | No |
| 依存TASK  | TASK-0127 |
| 見積     | 60m |

## 責務

`scripts/sage-runlog-validate.sh` に declared vs observed 差分検出を追加 (warn-only、backward compat)。test 6 シナリオ。

## 出力

1. `scripts/sage-runlog-validate.sh` 拡張:
   - inventory 不在: 既存 logic のみ (graceful)
   - RUN log の `runtime` field 不在: warn (新 field 推奨)
   - `runtime` ∉ `expected_runtime`: warn
   - `approval_policy` mismatch: warn
   - `network_mode` mismatch: warn
   - validator 全体は PASS (warn 止まり)

2. `templates/hooks/tests/test-agent-inventory-validator.sh` (6+ シナリオ):
   - inventory 不在 → existing logic only
   - RUN log runtime field 不在 → warn
   - runtime mismatch → warn
   - approval_policy mismatch → warn
   - network_mode mismatch → warn
   - 既存 RUN log (4 field なし) → PASS (backward compat)

## File Scope

- 変更: `scripts/sage-runlog-validate.sh`
- 作成: `templates/hooks/tests/test-agent-inventory-validator.sh`

## 完了条件

- [ ] 6+ scenarios PASS
- [ ] 既存 .sage/runs/RUN-000[1-4].yaml で validator PASS (regression)
- [ ] commit message に `TASK-0128:` 含む
