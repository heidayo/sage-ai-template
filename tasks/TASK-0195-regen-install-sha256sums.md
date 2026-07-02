# TASK-0195: install.sh 再生成 + SHA256SUMS 更新（専用 TASK・単独コミット）

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0195 |
| SPEC-ID   | SPEC-0028 |
| PLAN-ID   | PLAN-0028 |
| ステータス | Pending |
| 担当Agent | Implementation |
| 並列可否  | No |
| 依存TASK  | TASK-0194 |
| 見積     | 0.5h |

## 責務

generator から `install.sh` を再生成し、`SHA256SUMS` を追随更新する（SPEC-0028 Slice ヒント T4。**FAIL-0002 教訓により専用 TASK・単独コミット**）。

## 入力

- TASK-0193/0194 完了後の `scripts/generator/` 一式
- NFR-02/INV-05/POST-03: 同一 generator 入力からの install.sh はバイト再現性を持ち、SHA256SUMS 検証（SPEC-0018 フロー）を壊さない

## 出力

- 再生成された `install.sh`（手動編集禁止）
- 更新された `SHA256SUMS`
- 上記 2 ファイルのみを含む単独コミット

## File Scope（変更許可範囲）

- 作成: なし
- 変更: `install.sh`（再生成のみ）, `SHA256SUMS`
- 削除: なし

## 禁止事項

- 本リポジトリの `.sage/config.yaml` の変更（AC-11、全 TASK 横断制約）
- `install.sh` の手動編集（generator 経由の再生成のみ許可）
- generator・テスト・docs 等、他ファイルの同コミットへの混入（単独コミット厳守 — FAIL-0002）
- `--verify-checksum` / provenance の検証対象・強度の縮小（SEC-03/INV-05）

## 完了条件

- [ ] AC-09: `shasum -a 256 -c SHA256SUMS`（install.sh エントリ）が成功する
- [ ] generator 再実行で install.sh がバイト一致する（NFR-02 再現性）
- [ ] コミットの変更ファイルが `install.sh` と `SHA256SUMS` の 2 件のみである（`git show --name-only` で確認）
- [ ] `git diff --name-only main | grep -qxF '.sage/config.yaml'` が exit 非0（AC-11）
- [ ] コミットメッセージに TASK-0195 を含む

## Done Definition（ラウンド単位）

参照: `tasks/done-def-SPEC-0028-round-1.md`

## 実行ログ

| フィールド | 内容 |
|-----------|------|
| RUN-ID    | （実行時に自動採番） |
| 開始     | |
| 完了     | |
| 結果     | |
| Gate結果  | |
