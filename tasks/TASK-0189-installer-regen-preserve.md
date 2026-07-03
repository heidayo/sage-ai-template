# TASK-0189: install.sh 再生成 + SHA256SUMS 更新 + preserve-if-exists 対応（専用 TASK）

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0189 |
| SPEC-ID   | SPEC-0027 |
| PLAN-ID   | PLAN-0027 |
| ステータス | Pending |
| 担当Agent | Implementation |
| 並列可否  | No（TASK-0188 完了後に単独実行・単独コミット） |
| 依存TASK  | TASK-0188 |
| 見積     | 1h |

## 責務

generator 経由で `install.sh` を再生成して SHA256SUMS を更新し、installer に `.sage/id-patterns.json` の preserve-if-exists 対応を加える（SPEC-0027 Slice ヒント T5。FAIL-0002 教訓により専用 TASK・単独コミットとする）。

## 入力

- SPEC-0027 FR-08、NFR-02、INV-05、POST-03、境界ケース3、AC-08/12
- FAIL-0002 教訓（SPEC-0025 実装より）: `templates/pre-commit-task-id.sh` は `scripts/generator/02-config.sh` で `install.sh` に埋め込まれる。テンプレート変更後は必ず再生成 + SHA256SUMS 追随
- SPEC-0026 preservation 方針との整合（既存 `.sage/id-patterns.json` を上書きしない）

## 出力

- 再生成された `install.sh`（手動編集禁止）と一致する `SHA256SUMS`
- installer の `.sage/id-patterns.json` preserve-if-exists 対応（必要なら `scripts/generator/02-config.sh` 変更）

## File Scope（変更許可範囲）

- 作成: なし
- 変更: `scripts/generator/02-config.sh`（hook 埋め込み経路に変更が必要な場合のみ）, `scripts/generator/07-installer-main.sh`, `install.sh`（再生成のみ）, `SHA256SUMS`
  - 注記: `07-installer-main.sh` は実装フェーズで技術的必然により追加。配布済み validate/id-gen/trace-check が source するローダー `scripts/sage-id-pattern.sh` の配布（write + install-state manifest 登録）と、`.sage/id-patterns.json` の preserve-if-exists 書き込みは 07 側でのみ実装可能なため。
- 削除: なし

## 禁止事項

- `install.sh` の手動編集（generator 経由の再生成のみ）
- 本 TASK のコミットに他 TASK の変更を混在させること（単独コミット、FAIL-0002）
- SPEC-0018 検証フロー（--verify-checksum / provenance）の対象・強度の縮小（INV-05）

## 完了条件

- [ ] `shasum -a 256 -c SHA256SUMS`（install.sh エントリ）が成功する（AC-08）
- [ ] generator 再実行で `install.sh` がバイト一致する（NFR-02 再現性）
- [ ] カスタム accept を含む `.sage/id-patterns.json` 配置済み一時環境で `install.sh` 実行後、`grep -qF 'TASK-[a-z]+-[0-9a-f]{4}' .sage/id-patterns.json` が exit 0（AC-12）

## Done Definition（ラウンド単位）

参照: `tasks/done-def-SPEC-0027-round-1.md`

## 実行ログ

| フィールド | 内容 |
|-----------|------|
| RUN-ID    | （実行時に自動採番） |
| 開始     | |
| 完了     | |
| 結果     | |
| Gate結果  | |
