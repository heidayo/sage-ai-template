# TASK-0076: harness RUN ログ生成手順の標準化 + canonical template

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0076 |
| SPEC-ID   | SPEC-0008 |
| PLAN-ID   | PLAN-0008-B |
| ステータス | In Progress |
| 担当Agent | Implementation |
| 並列可否  | No (TASK-0074 validator の存在を前提とする) |
| 依存TASK  | TASK-0074 |
| 見積     | 1h |

## 責務

harness が Verify フェーズ完了時に書き出す RUN ログのフォーマットを、TASK-0074 validator が通る canonical form に揃える。具体的には:

1. `task_ids: [list]` → `task_id: TASK-XXXX` (validator は singular を要求)
2. `abort_reason` の enum に `scoring_oscillation` / `evaluator_unavailable` を追加 (TASK-0082/0084 対応)
3. `templates/run-log-template.yaml` を新規作成し、SKILL.md がそれを参照する形に変更

`sage/governance.md` への記載更新は protect-sage-files hook との兼ね合い上、別 TASK で扱う (scope 縮小)。

## 入力

- `templates/skills/sage-harness/SKILL.md` L622-682 の現 RUN ログ YAML 例
- `.sage/config.yaml` の `run_log_schema` セクション
- `scripts/sage-runlog-validate.sh` の検証仕様 (TASK-0074)
- 既存 `.sage/runs/RUN-0001〜0003.yaml` のフォーマット

## 出力

- `templates/run-log-template.yaml` 新規 (validator-compatible な canonical form + 補足 optional フィールド)
- `templates/skills/sage-harness/SKILL.md` の Phase 5 セクションを更新:
  - `task_ids: [...]` → `task_id: TASK-XXXX` + optional `related_tasks: []`
  - abort_reason enum に 2 値追加
  - template 参照に変更

## File Scope（変更許可範囲）

- 作成:
  - `templates/run-log-template.yaml`
  - `tasks/TASK-0076-runlog-harness-standardization.md` (本ファイル)
- 変更:
  - `templates/skills/sage-harness/SKILL.md` (Phase 5 セクション + abort_reason 記述のみ)
- 削除: なし

## 禁止事項

- `sage/governance.md` の編集禁止 (protect-sage-files hook との兼ね合い上、別 TASK)
- `.claude/skills/` 配下の直接編集禁止 (install.sh 再生成で同期)
- validator script (`scripts/sage-runlog-validate.sh`) の変更禁止 (TASK-0074 成果物)
- run_log_schema (`.sage/config.yaml`) の変更禁止 (別 task_ids 議論を作らない)

## 完了条件

- [ ] `templates/run-log-template.yaml` が存在し、validator を通る必須フィールドを全て持つ
- [ ] SKILL.md の Phase 5 セクションが canonical form を反映している
- [ ] SKILL.md の abort_reason 記述に `scoring_oscillation` と `evaluator_unavailable` が含まれる
- [ ] テンプレートから生成した仮想 RUN ログ (必須フィールドを埋めたもの) が `bash scripts/sage-runlog-validate.sh <tmpfile>` で PASS する
- [ ] コミットメッセージに `TASK-0076` を含む

## Done Definition（ラウンド単位）

参照: (PLAN-0008-B 統合時に作成)

## 実行ログ

| フィールド | 内容 |
|-----------|------|
| RUN-ID    | (実行時に自動採番) |
| 開始     | 2026-04-17 |
| 完了     | (実行完了時に記入) |
| 結果     | (実行完了時に記入) |
| Gate結果  | structural: - / functional: - / security: - |
