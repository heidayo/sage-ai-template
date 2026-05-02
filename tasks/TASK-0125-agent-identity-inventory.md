# TASK-0125: Agent identity inventory schema + RUN log validator 拡張

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0125 |
| SPEC-ID   | SPEC-0015 |
| PLAN-ID   | PLAN-0015 |
| ステータス | Pending |
| 担当Agent | Implementation |
| 並列可否  | Yes (with TASK-0123) |
| 依存TASK  | TASK-0122 (schema 流儀を踏襲) |
| 見積     | 60m |

## 責務

`.sage/agent-inventory.yaml` の YAML schema を確定し、`templates/sage/agent-inventory-template.yaml` として user 配布可能な雛形を作成する。既存 RUN log validator (TASK-0074 で導入) を拡張し、RUN log の `agent_id` が inventory に declared されているか warn レベルで検証する path を追加する。

## 入力

- SPEC-0015 FR-04 (inventory schema)
- SPEC-0015 FR-05 (validator 拡張)
- SPEC-0015 EC-05 (未 declared agent_id の warn)
- 既存 RUN log validator (`scripts/sage-validate.sh` 内、TASK-0074 由来)
- 既存 agent_id enum (spec/planning/implementation/review/test/security/operations、既存 7 値)

## 出力

1. `templates/sage/agent-inventory-template.yaml` 新規:
   - top-level: `version: "1.0"`
   - `agents`: list of objects、各 object に
     - `agent_id` (enum, 既存 7 値のいずれか)
     - `runtime` (list, claude-code / codex-cli / codex-cloud / cron / human の subset)
     - `expected_role` (string, 自由記述)
     - `restricted_to_branches` (list of glob, optional)
   - 例として全 7 agent_id を default 設定で declare (initial setup の手間削減)
   - inline コメントで「新 agent role 追加時は本 inventory も PR で更新」を案内

2. `scripts/sage-validate.sh` 内の RUN log validator 拡張:
   - 既存 logic: `agent_id` が enum (7 値) に含まれるか確認
   - 追加 logic:
     - `.sage/agent-inventory.yaml` 存在時のみ active (graceful degradation)
     - RUN log の `agent_id` が `inventory.agents[*].agent_id` に declared か確認
     - 未 declared の場合 warn (1 行 stderr、validate 全体は PASS のまま)
     - inventory 不在 → 既存 logic のみ実行 (新規 check skip)
   - run_log_schema.fields.agent_id 既存仕様は不変

3. (optional) `templates/hooks/tests/test-agent-inventory-validator.sh` 新規:
   - inventory に declared な agent_id を持つ RUN log → validator PASS
   - inventory に未 declared な agent_id を持つ RUN log → warn 出る、validator は PASS のまま (lite)
   - inventory 不在 → 既存 validator path のみ動作

## File Scope（変更許可範囲）

- 作成: `templates/sage/agent-inventory-template.yaml`
- 変更: `scripts/sage-validate.sh`
- 作成: (optional) `templates/hooks/tests/test-agent-inventory-validator.sh`
- 削除: なし

## 禁止事項

- 既存 agent_id enum の 7 値を変更しない (traceability 互換性破壊禁止)
- `.sage/agent-inventory.yaml` (実 user データ) を作成しない (本 TASK は template のみ)
- inventory に runtime enforcement (agent process の kill / SSO 認証) を含めない
- run_log_schema を破壊変更しない (新 field 追加のみ可、本 TASK は schema 不変、validator のみ拡張)
- inventory mismatch を FAIL レベルにしない (warn 止まり、運用 reminder)

## 完了条件

- [ ] `templates/sage/agent-inventory-template.yaml` 存在 + 7 agent_id default declare
- [ ] yaml lint で error 0 件
- [ ] `scripts/sage-validate.sh` に inventory check path 追加
- [ ] inventory 不在で既存 validator 通常動作 (regression なし)
- [ ] inventory 存在 + RUN log agent_id が未 declared → warn 出る (validate 全体は PASS)
- [ ] inventory 存在 + RUN log agent_id が declared → 沈黙 (extra warn なし)
- [ ] `bash scripts/sage-validate.sh` PASS (本 TASK 完了直後の repo state で)
- [ ] commit message に `TASK-0125:` を含む
