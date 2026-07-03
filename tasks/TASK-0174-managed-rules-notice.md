# TASK-0174: managed rules 末尾への local overlay 参照規約注記

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0174 |
| SPEC-ID   | SPEC-0025 |
| PLAN-ID   | PLAN-0025 |
| ステータス | Pending |
| 担当Agent | Implementation |
| 並列可否  | Yes（TASK-0175 / TASK-0176 と並列可） |
| 依存TASK  | TASK-0171, TASK-0172 |
| 見積     | 1h |

## 責務

managed ルールファイル（`templates/rules/` 由来の `.claude/rules/*.md`）の末尾に「プロジェクト固有ルールは `local/` に置く。このファイルは install.sh 更新で全置換される」旨の参照規約注記（英語コメント + 日本語1行）を generator 経由で追加する。

## 入力

- SPEC-0025（FR-04, AC-05, リスク2）
- `scripts/generator/03-rules.sh`（rules ファイル生成部）
- `templates/rules/` 配下の managed ルールファイル一覧

## 出力

- 変更済み `scripts/generator/03-rules.sh`（全 managed rules 末尾に注記を出力）
- 注記が反映された `templates/rules/*.md`（generator がテンプレートを直接持つ場合は generator のみ）

※ `install.sh` 再生成 + `SHA256SUMS` 更新は TASK-0177 に直列化（本 TASK では行わない）

## File Scope（変更許可範囲）

- 作成: なし
- 変更: `scripts/generator/03-rules.sh`, `templates/rules/*.md`
- 削除: なし

## 禁止事項

- 注記以外のルール本文の変更（AP-03 Silent Scope Expansion）
- `install.sh` / `SHA256SUMS` の編集（再生成は TASK-0177 の責務）
- `.claude/rules/local/` 自体の作成（installer は overlay を作成しない — AC-02）
- `AGENTS.md` / `docs/codex-*.md` / `sage/` / `CLAUDE.md` の編集
- 他 TASK 責務（CLAUDE.md 規約 = TASK-0175、README = TASK-0176）の取り込み（AP-02 Big Bang）
- TASK-ID なしコミット（AP-05）

## 完了条件

- [ ] `grep -q 'rules/local/' scripts/generator/03-rules.sh` が成功し、かつ `git diff --name-only | grep -v -E '^(scripts/generator/03-rules.sh|templates/rules/)' | wc -l` が 0（変更が注記出力のみであることのコマンド検証。AC-05 の実装側。clean install での grep 検証は TASK-0177 再生成後に実施）
- [ ] `bash templates/hooks/tests/run-tests.sh` が全件 PASS（非破壊）

※ `shasum -a 256 -c SHA256SUMS`（AC-06）の PASS は TASK-0177 の完了条件

## Done Definition（ラウンド単位）

参照: `tasks/done-def-SPEC-0025-round-1.md`

## 実行ログ

| フィールド | 内容 |
|-----------|------|
| RUN-ID    | （実行時に自動採番） |
| 開始     | - |
| 完了     | - |
| 結果     | - |
| Gate結果  | - |
