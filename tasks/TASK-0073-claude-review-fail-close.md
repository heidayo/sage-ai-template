# TASK-0073: Claude review workflow の fail-open を fail-close 化

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0073 |
| SPEC-ID   | SPEC-0008 |
| PLAN-ID   | PLAN-0008-A |
| ステータス | In Progress |
| 担当Agent | Implementation |
| 並列可否  | Yes |
| 依存TASK  | none |
| 見積     | 0.5h |

## 責務

`sage-claude-review.yml` の verdict 判定ロジックにおいて、review bot の応答欠落 / フォーマット不正 / verdict 解釈不能のケースで `core.warning` で通過していた挙動を `core.setFailed` に変更し、Gate として fail-close 化する。

## 入力

- 現状 ([.github/workflows/sage-claude-review.yml:108-121](.github/workflows/sage-claude-review.yml:108)):
  - L108-111: `reviewComment` 未発見 → `core.warning(...)` + `return` (fail-open)
  - L120-121: verdict 解釈不能 → `core.warning(...)` (fail-open)
- timeout は前段の `claude-code-action` の `timeout_minutes: 10` で action 自体が失敗する動作なので、本 TASK は本ステップの fail-close 化に専念

## 出力

- `reviewComment` 未取得 → `core.setFailed` で明示的 FAIL
- verdict 文字列が `総合判定` を含まない / `✅`/`❌` いずれもマッチしない → `core.setFailed` で明示的 FAIL

## File Scope（変更許可範囲）

- 作成: なし
- 変更:
  - `.github/workflows/sage-claude-review.yml` (L85-122 の Check review verdict step のみ)
- 削除: なし

## 禁止事項

- 前段の claude-code-action ステップ (L30-83) の変更禁止 (プロンプト・timeout・モデル等は本 TASK の範囲外)
- 他の workflow ファイルの変更禁止

## 完了条件

- [ ] `reviewComment` 未検出時に `core.setFailed` が呼ばれる
- [ ] verdict 解釈不能時に `core.setFailed` が呼ばれる
- [ ] FAIL verdict (`❌`) と PASS verdict (`✅`) の既存の判定挙動は保持される (回帰なし)
- [ ] `actionlint` などの yaml syntax チェックが存在すれば通過 (本リポジトリでは未導入のため目視確認)
- [ ] コミットメッセージに `TASK-0073` を含む

## Done Definition（ラウンド単位）

参照: (PLAN-0008-A 統合時に作成)

## 実行ログ

| フィールド | 内容 |
|-----------|------|
| RUN-ID    | (実行時に自動採番) |
| 開始     | 2026-04-17 |
| 完了     | (実行完了時に記入) |
| 結果     | (実行完了時に記入) |
| Gate結果  | structural: - / functional: - / security: - |
