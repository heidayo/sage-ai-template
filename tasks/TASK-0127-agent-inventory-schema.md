# TASK-0127: agent inventory schema + template + RUN log + config.yaml

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0127 |
| SPEC-ID   | SPEC-0017 |
| PLAN-ID   | PLAN-0017 |
| ステータス | Pending |
| 並列可否  | No (foundation) |
| 依存TASK  | none |
| 見積     | 30m |

## 責務

`.sage/agent-inventory.yaml` schema を確定 + `templates/sage/agent-inventory-template.yaml` 配布雛形 + `templates/run-log-template.yaml` に 4 新 field (commented optional) 追加 + `.sage/config.yaml` の `run_log_schema.fields` 拡張。

## 出力

1. `templates/sage/agent-inventory-template.yaml` (7 agent_id 全 declare)
2. `templates/run-log-template.yaml` 更新 (4 新 field commented optional)
3. `.sage/config.yaml` `run_log_schema.fields` 拡張

## File Scope

- 作成: `templates/sage/agent-inventory-template.yaml`
- 変更: `templates/run-log-template.yaml`, `.sage/config.yaml`

## 完了条件

- [ ] template に 7 agent_id 全 declare、yaml lint pass
- [ ] run-log-template.yaml に 4 新 field commented optional
- [ ] config.yaml に 4 新 field 追加 (既存 schema 不破壊)
- [ ] commit message に `TASK-0127:` 含む
