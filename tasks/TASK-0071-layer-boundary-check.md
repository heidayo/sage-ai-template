# TASK-0071: Gate 4 レイヤ境界チェック (言語中立 grep ベース)

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0071 |
| SPEC-ID   | SPEC-0008 |
| PLAN-ID   | PLAN-0008-A |
| ステータス | In Progress |
| 担当Agent | Implementation |
| 並列可否  | Yes |
| 依存TASK  | none |
| 見積     | 2h |

## 責務

SAGE が宣言していた `.sage/config.yaml` の `architecture.layer_boundary: required` を実行可能なチェックとして実装する。`.sage/architecture.yaml` (新規) に禁止 import 対を宣言し、Gate 4 workflow がそれを読んで PR diff に違反がないかを grep ベースで検査する。

## 入力

- 現状 [`.github/workflows/sage-architecture-gate.yml`](.github/workflows/sage-architecture-gate.yml): traceability と Big Bang 検出のみ
- `.sage/config.yaml` L18: `layer_boundary: required`

## 出力

- `.sage/architecture.yaml` 新規: サンプル最小限の禁止対を宣言 (layer_boundary + forbidden_deps 両対応のスキーマ)
- `scripts/sage-architecture-check.sh` 新規: architecture.yaml を読み、PR diff (もしくは全 src) から違反を検出。違反あり → stdout に列挙 + exit 1
- `.github/workflows/sage-architecture-gate.yml` に新 step を追加: architecture.yaml が存在する場合のみスクリプトを呼ぶ (SKIPPED fallback)

## File Scope（変更許可範囲）

- 作成:
  - `.sage/architecture.yaml`
  - `scripts/sage-architecture-check.sh`
  - `tasks/TASK-0071-layer-boundary-check.md` (本ファイル)
- 変更:
  - `.github/workflows/sage-architecture-gate.yml` (新 step 追加のみ)
- 削除: なし

## 禁止事項

- 既存 traceability / Big Bang 検査ロジックの変更禁止
- `.sage/config.yaml` の layer_boundary キー変更禁止
- 言語別 linter (go-arch-lint, depcruise 等) の導入禁止 (本 TASK は grep ベースの Phase A)
- PR diff 解析に外部 action の導入禁止 (git diff + grep のみ)

## 完了条件

- [ ] `.sage/architecture.yaml` が `layers:` と `forbidden:` の最小例を持つ
- [ ] `bash scripts/sage-architecture-check.sh` がルート直実行可能
- [ ] 違反なし (現在の src/ は空) で exit 0
- [ ] 意図的に `src/domain/foo.go` から `src/infra/bar.go` を import する mock ファイルを tmp 作成 + architecture.yaml に相当ルールを置くと exit 1
- [ ] workflow で architecture.yaml 未設定時 SKIPPED 扱い
- [ ] コミットメッセージに `TASK-0071` を含む

## Done Definition（ラウンド単位）

参照: (PLAN-0008-A 統合時に作成)

## 実行ログ

| フィールド | 内容 |
|-----------|------|
| RUN-ID    | (実行時に自動採番) |
| 開始     | 2026-04-17 |
| 完了     | (実行完了時に記入) |
| Gate結果  | structural: - / functional: - / security: - |
