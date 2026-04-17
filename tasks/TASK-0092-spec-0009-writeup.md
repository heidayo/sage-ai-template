# TASK-0092: SPEC-0009 (Calculator HTTP API) 仕様書の切り出し

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0092 |
| SPEC-ID   | SPEC-0009 |
| PLAN-ID   | PLAN-0008-F |
| ステータス | In Progress |
| 担当Agent | Spec |
| 並列可否  | No (TASK-0090 実装 + TASK-0091 config 済が前提) |
| 依存TASK  | TASK-0091 |
| 見積     | 1h |

## 責務

SPEC-0008 (enforcement gap closure) の dogfooding 成果物としての Go 電卓 API を、独立した SPEC-0009 として切り出す。SAGE フロー上 "SAGE のメタ SPEC" と "それを使って作ったサンプルアプリの SPEC" が明確に分離されることを示す。

## 入力

- TASK-0090 で実装済の `src/calculator/` と `tests/calculator/`
- TASK-0091 で設定済の `.sage/config.yaml project_checks`
- SPEC-0008 (本 TASK の親ではないが、機能的前提)

## 出力

- `specs/SPEC-0009-calculator-api.md` 新規 (Implemented ステータスで記載、実装はすでに存在)

## File Scope（変更許可範囲）

- 作成:
  - `specs/SPEC-0009-calculator-api.md`
  - `tasks/TASK-0092-spec-0009-writeup.md` (本ファイル)
- 変更: なし
- 削除: なし

## 禁止事項

- `src/` `tests/` の変更禁止 (本 TASK は文書化のみ)
- 他 SPEC (特に SPEC-0008) の変更禁止
- PLAN-0009 / TASK-01XX の新設禁止 (本 TASK の範囲外、必要なら別途)

## 完了条件

- [ ] SPEC-0009 が specs/_template.md の全セクション (メタデータ / 背景 / スコープ / 要件 / AC / 異常系 / 契約 / リスク / 実装メモ / 関連ID) を持つ
- [ ] スコープ外 が "none" ではなく明示的に記述されている
- [ ] AC が 3 件以上、すべてコマンドまたはテストで検証可能
- [ ] 異常系が 1 件以上定義されている
- [ ] コミットメッセージに `TASK-0092` を含む

## Done Definition（ラウンド単位）

参照: (PLAN-0008-F 統合時に作成)

## 実行ログ

| フィールド | 内容 |
|-----------|------|
| RUN-ID    | (実行時に自動採番) |
| 開始     | 2026-04-17 |
| 完了     | (実行完了時に記入) |
| Gate結果  | structural: - / functional: - / security: - |
