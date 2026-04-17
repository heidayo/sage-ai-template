# TASK-0081: installer_url 3 経路 sha256 同期検証 (sage-validate Check 9 + Makefile)

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0081 |
| SPEC-ID   | SPEC-0008 |
| PLAN-ID   | PLAN-0008-C |
| ステータス | In Progress |
| 担当Agent | Implementation |
| 並列可否  | Yes |
| 依存TASK  | none |
| 見積     | 1h |

## 責務

ローカル `install.sh` と `.sage/config.yaml` の `auto_update.installer_url` が指す Gist 公開版の sha256 を比較する Check を `sage-validate.sh` に追加し、Makefile にも単独実行用ターゲット `check-installer-sync` を追加する。

- オフライン CI や `curl` 失敗時は SKIPPED (fail-soft)
- main 直コミット時 (GITHUB_REF_NAME=main) のみ FAIL に昇格

## 入力

- `.sage/config.yaml` L197: `auto_update.installer_url`
- 現状 `.sage/gist-id`: `98c36fbaf41cc5170b071b21bde3bb51`
- ローカル `install.sh` のパス
- `scripts/sage-validate.sh` (現状 8 チェック)

## 出力

- `scripts/sage-validate.sh` に Check 9 を追加し全体を `[1/9]`〜`[9/9]` に更新
- `Makefile` に `check-installer-sync` ターゲット追加 (sage-validate 内 Check 9 相当のスタンドアロン実行)

## File Scope（変更許可範囲）

- 作成:
  - `tasks/TASK-0081-installer-url-sync.md` (本ファイル)
- 変更:
  - `scripts/sage-validate.sh` (Check 9 追加 + 全セクション `[X/8]` → `[X/9]` 更新)
  - `Makefile` (ターゲット追加 + `.PHONY` 更新)
- 削除: なし

## 禁止事項

- `.sage/config.yaml` の `installer_url` 変更禁止 (既定値を触らない)
- `.sage/gist-id` ファイル削除禁止
- CI で強制的に外部 URL アクセスする設計禁止 (オフラインでも通るよう fail-soft)

## 完了条件

- [ ] `bash scripts/sage-validate.sh` が 9 セクション全部走り、Check 9 の出力が含まれる
- [ ] オフライン環境で Check 9 が SKIPPED を返し、exit 0 になる
- [ ] 意図的に `install.sh` を 1 文字改変した状態で main 直シミュレーション (`GITHUB_REF_NAME=main bash scripts/sage-validate.sh`) すると Check 9 が FAIL
- [ ] `make check-installer-sync` が実行可能で、同 Check のみを単独実行できる
- [ ] コミットメッセージに `TASK-0081` を含む

## Done Definition（ラウンド単位）

参照: (PLAN-0008-C 統合時に作成)

## 実行ログ

| フィールド | 内容 |
|-----------|------|
| RUN-ID    | (実行時に自動採番) |
| 開始     | 2026-04-17 |
| 完了     | (実行完了時に記入) |
| Gate結果  | structural: - / functional: - / security: - |
