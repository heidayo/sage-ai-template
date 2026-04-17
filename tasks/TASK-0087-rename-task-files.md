# TASK-0087: TASK-0064〜0069 のファイル名を H1 準拠に改名

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0087 |
| SPEC-ID   | SPEC-0008 |
| PLAN-ID   | PLAN-0008-E |
| ステータス | In Progress |
| 担当Agent | Implementation |
| 並列可否  | Yes |
| 依存TASK  | none |
| 見積     | 0.3h |

## 責務

6 ファイルが `TASK-006X-spec0007.md` という情報量ゼロの命名になっている問題を解消し、各ファイルの H1 タイトルから意味的サフィックスを付ける。ファイル内容は変更しない (rename only)。

## 入力

現在のファイル名 → H1:

- `TASK-0064-spec0007.md` → `ガバナンス文書更新（anti-patterns AP-07〜09 + governance原則7）`
- `TASK-0065-spec0007.md` → `src-rules同期（テンプレート＋ランタイム）`
- `TASK-0066-spec0007.md` → `レビュースキル・採点基準同期（テンプレート＋ランタイム）`
- `TASK-0067-spec0007.md` → `ハーネスTest Agent独立性強化（テンプレート＋ランタイム）`
- `TASK-0068-spec0007.md` → `config.yamlオプション検査項目追加`
- `TASK-0069-spec0007.md` → `installer再生成`

## 出力

- `TASK-0064-governance-docs-update.md`
- `TASK-0065-src-rules-sync.md`
- `TASK-0066-review-skill-sync.md`
- `TASK-0067-harness-test-agent-independence.md`
- `TASK-0068-config-optional-checks.md`
- `TASK-0069-installer-regen.md`

## File Scope（変更許可範囲）

- 作成: なし
- 変更 (rename): 上記 6 ファイル
- 削除: なし

## 禁止事項

- ファイル内容の編集禁止 (本 TASK は rename のみ)
- 他 TASK ファイルの rename 禁止 (TASK-0064〜0069 のみが対象、既存 TASK-0001〜0063 の "historical" サフィックスには触らない)
- commit 履歴の改変禁止 (`git filter-branch` 等は使わない)

## 完了条件

- [ ] 6 ファイルが新しい命名で存在する
- [ ] 旧ファイル名が存在しない (`ls tasks/TASK-006[4-9]-spec0007.md` が空)
- [ ] 各ファイルの H1 は変更なし (サニティとして`head -1 tasks/TASK-0064-governance-docs-update.md` が元の H1 を返す)
- [ ] `git mv` を使いコミット履歴が追跡可能であること
- [ ] コミットメッセージに `TASK-0087` を含む

## Done Definition（ラウンド単位）

参照: (PLAN-0008-E 統合時に作成)

## 実行ログ

| フィールド | 内容 |
|-----------|------|
| RUN-ID    | (実行時に自動採番) |
| 開始     | 2026-04-17 |
| 完了     | (実行完了時に記入) |
| 結果     | (実行完了時に記入) |
| Gate結果  | structural: - / functional: - / security: - |
