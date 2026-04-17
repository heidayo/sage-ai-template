# TASK-0079: templates/ → .claude/ コピー同期検証スクリプト

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0079 |
| SPEC-ID   | SPEC-0008 |
| PLAN-ID   | PLAN-0008-C |
| ステータス | In Progress |
| 担当Agent | Implementation |
| 並列可否  | Yes |
| 依存TASK  | none |
| 見積     | 1h |

## 責務

`templates/rules/` と `.claude/rules/`、`templates/skills/` と `.claude/skills/` が install.sh で意図される形で同期しているかを検証する script を作成する。`.claude/rules/` / `.claude/skills/` は gitignored なので CI では検出できない local drift を開発者が手動で確認するための手段。

## 入力

- `install.sh` の `write_file_if_new` / `update_file` ロジック: templates → .claude へのコピー単位
- 対応関係:
  - `templates/rules/*.md` → `.claude/rules/*.md`
  - `templates/skills/*/SKILL.md` と配下ファイル → `.claude/skills/*/*`

## 出力

- `scripts/sage-templates-sync-check.sh` 新規作成
- templates 側と .claude 側で対応するファイルを diff
- 差分ありで exit 1、なしで exit 0
- .claude/ 側にまだファイルがない (install.sh 未実行状態) はエラーではなく「not yet installed」として WARN 終了

## File Scope（変更許可範囲）

- 作成:
  - `scripts/sage-templates-sync-check.sh`
  - `tasks/TASK-0079-templates-claude-copy-verify.md` (本ファイル)
- 変更: なし
- 削除: なし

## 禁止事項

- `install.sh` / `scripts/generate-installer.sh` の変更禁止
- templates/ / .claude/ 側ファイルの変更禁止
- `.gitignore` の変更禁止 (.claude/* は gitignored のまま)

## 完了条件

- [ ] `bash scripts/sage-templates-sync-check.sh` 実行時、templates/rules の各ファイルが .claude/rules と一致している場合 OK
- [ ] templates/skills の各ファイルが .claude/skills と一致している場合 OK
- [ ] 1 件でも diff があれば FAIL (exit 1) で、どのファイルか列挙
- [ ] `.claude/rules/` が未生成 (install.sh 未実行) の場合、WARN 表示で exit 0 (fail にしない)
- [ ] コミットメッセージに `TASK-0079` を含む

## Done Definition（ラウンド単位）

参照: (PLAN-0008-C 統合時に作成)

## 実行ログ

| フィールド | 内容 |
|-----------|------|
| RUN-ID    | (実行時に自動採番) |
| 開始     | 2026-04-17 |
| 完了     | (実行完了時に記入) |
| Gate結果  | structural: - / functional: - / security: - |
