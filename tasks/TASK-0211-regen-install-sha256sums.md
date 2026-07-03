# TASK-0211: install.sh 再生成 + SHA256SUMS 更新（SPEC-0031）

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0211 |
| SPEC-ID   | SPEC-0031 |
| PLAN-ID   | PLAN-0031 |
| ステータス | Pending |
| 担当Agent | Implementation |
| 並列可否  | No |
| 依存TASK  | TASK-0208, TASK-0209 |
| 見積     | 20m |

## 責務

TASK-0208 / TASK-0209 の変更（TMPL_FAILURES / TMPL_ID_GEN 埋め込み対象）を install.sh に再生成反映し、SHA256SUMS を更新する。**再生成のみの単独コミット**（FAIL-0002 教訓 — 再生成物は再生成専用 TASK の別コミット）。

## 入力

- SPEC-0031 FR-06 / SEC-02 / INV-06 / POST-02、設計判断1
- TASK-0208 / TASK-0209 のコミット済み変更
- 既存の再生成手順（scripts/generator/ 経由。generator ソース自体は変更不要 — embed_file が sage/failures.md / scripts/sage-id-gen.sh を実行時読み込みする）

## 出力

- 再生成済み `install.sh`
- 更新済み `SHA256SUMS`

## File Scope（変更許可範囲）

- 作成: なし
- 変更: `install.sh`、`SHA256SUMS`（再生成による更新のみ）
- 削除: なし

## 禁止事項

- 再生成以外の変更（install.sh の手動編集は Forbidden Shortcuts「Manually edit generated code」違反）
- `scripts/generator/` の変更（必要と判明した場合は Spec Agent へ差し戻し — silent scope expansion 禁止）
- 他 TASK の変更と同一コミットへの混入（リスク3 / FAIL-0002）

## 完了条件

- [ ] AC-09: 再生成後 `git diff --exit-code install.sh SHA256SUMS` が exit 0（drift なし）、かつ `grep -qF 'GATE-FP-XXXX' install.sh && grep -qF 'gate-fp' install.sh` が exit 0 (case: `installer_regenerated`)
- [ ] SEC-02: `bash install.sh --verify-checksum` が PASS
- [ ] コミットが install.sh / SHA256SUMS のみを含む単独コミットであり、メッセージに TASK-0211 を含む

## Done Definition（ラウンド単位）

参照: `tasks/done-def-SPEC-0031-round-1.md`

## 実行ログ

| フィールド | 内容 |
|-----------|------|
| RUN-ID    | （実行時に採番） |
| 開始     | |
| 完了     | |
| 結果     | |
| Gate結果  | |
