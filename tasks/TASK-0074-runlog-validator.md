# TASK-0074: RUN ログ YAML バリデーター

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0074 |
| SPEC-ID   | SPEC-0008 |
| PLAN-ID   | PLAN-0008-B |
| ステータス | In Progress |
| 担当Agent | Implementation |
| 並列可否  | Yes |
| 依存TASK  | none |
| 見積     | 1h |

## 責務

`.sage/runs/*.yaml` の schema 準拠を機械検証する script を作成する。`.sage/config.yaml` の `run_log_schema` セクションが宣言だけで validator 不在だった問題を解消する。既存 3 件の RUN ログ (RUN-0001〜0003) はすべて pass することが受け入れ条件。

## 入力

- `.sage/config.yaml` の `run_log_schema` (L49-66): 必須フィールド定義
  - run_id (format: `RUN-\d{4}`)
  - task_id (format: `TASK-\d{4}`)
  - agent_id (enum: spec/planning/implementation/review/test/security/operations)
  - started_at, completed_at (ISO 8601 文字列)
  - status (enum: pass/fail/skipped)
  - files_changed (array of strings)
  - gate_results (object with 5 keys: structural, functional, security, architecture, release)
- 既存ファイル: `.sage/runs/RUN-0001.yaml`, `RUN-0002.yaml`, `RUN-0003.yaml`

## 出力

- `scripts/sage-runlog-validate.sh` 新規作成
- 引数なし → `.sage/runs/*.yaml` を全件検証
- 引数あり → 指定ファイルのみ検証
- 不正な YAML / 必須フィールド欠落 / enum 違反 / 型不一致で exit 1
- 全件 pass で exit 0 、1 行ずつ結果を stdout に出す

## File Scope（変更許可範囲）

- 作成:
  - `scripts/sage-runlog-validate.sh`
  - `tasks/TASK-0074-runlog-validator.md` (本ファイル)
- 変更: なし
- 削除: なし

## 禁止事項

- 既存 RUN ログの内容変更禁止 (validator 側を既存データに合わせる、逆はしない)
- `.github/workflows/` の変更禁止 (workflow 呼び出しは別 TASK または後続作業で)
- `.sage/config.yaml` の `run_log_schema` セクション変更禁止
- yq などの新規外部依存の追加禁止 (python3 + yaml モジュールは使用可、既にプロジェクトで利用)

## 完了条件

- [ ] `bash scripts/sage-runlog-validate.sh` が既存 3 ファイルを全て PASS で完走 (exit 0)
- [ ] 意図的に task_id を欠落させたファイルを投入すると exit 1
- [ ] 意図的に status を不正値 (例 `winning`) にしたファイルを投入すると exit 1
- [ ] 意図的に不正 YAML (例: 末尾の `:` のみ) を投入すると exit 1
- [ ] 既存の正常ファイル検証時、画面出力は 1 行/file でファイル名 + OK が出る
- [ ] コミットメッセージに `TASK-0074` を含む

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
