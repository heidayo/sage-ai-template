# TASK-0072: Gate 4 禁止依存 (forbidden_deps) チェック

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0072 |
| SPEC-ID   | SPEC-0008 |
| PLAN-ID   | PLAN-0008-A |
| ステータス | In Progress |
| 担当Agent | Implementation |
| 並列可否  | No (TASK-0071 と同一ファイルを編集) |
| 依存TASK  | TASK-0071 |
| 見積     | 1h |

## 責務

`.sage/architecture.yaml` の `forbidden_deps:` ルールを scripts/sage-architecture-check.sh に実装し、PR diff に登録済の禁止パッケージ名が出現したら violation として報告する。TASK-0071 と同一スクリプト内の別セクションとして実装する。

## 入力

- `.sage/architecture.yaml` の `forbidden_deps:` リスト (name + reason)
- PR diff (git diff --unified=0 の added lines) または fallback としての src/* grep

## 出力

- スクリプト内 `# --- forbidden_deps (banned package names) ---` セクションに組み込む
- violation 発見で VIOLATIONS カウント増加、exit 1
- 未登録時 SKIPPED 表示

## File Scope（変更許可範囲）

- 作成:
  - `tasks/TASK-0072-forbidden-deps-check.md` (本ファイル)
- 変更:
  - `scripts/sage-architecture-check.sh` (TASK-0071 と同一ファイル)
  - `.sage/architecture.yaml` (TASK-0071 で既に schema 定義済、forbidden_deps サンプルコメント追加のみ)
- 削除: なし

## 禁止事項

- TASK-0071 の forbidden (layer boundary) 実装の変更禁止
- 外部依存追加禁止

## 完了条件

- [ ] `.sage/architecture.yaml` の forbidden_deps コメント例に lodash/moment 等が含まれる
- [ ] 空の forbidden_deps で SKIPPED 表示
- [ ] lodash を含む mock ファイルを検出 (TASK-0071 との統合テストで確認済み)
- [ ] コミットメッセージに `TASK-0072` を含む

## Done Definition（ラウンド単位）

参照: (PLAN-0008-A 統合時に作成)

## 実行ログ

| フィールド | 内容 |
|-----------|------|
| RUN-ID    | (実行時に自動採番) |
| 開始     | 2026-04-17 |
| 完了     | (実行完了時に記入) |
| Gate結果  | structural: - / functional: - / security: - |
