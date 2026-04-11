# TASK-0062: SPEC-0006 の文言整合

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0062 |
| SPEC-ID   | SPEC-0006 |
| PLAN-ID   | PLAN-0006 |
| ステータス | Done |
| 担当Agent | Planning |
| 並列可否  | No |
| 依存TASK  | TASK-0061 |
| 見積     | 20m |

## 責務

SPEC-0006 / PLAN-0006 の受け入れ条件と統合テスト期待値を、実装済み挙動および手動E2E結果に合わせて整合させる。

## 入力

- `specs/SPEC-0006-vibe-coding-lanes-and-promotion.md`
- `plans/PLAN-0006-vibe-coding-lanes-and-promotion.md`
- `scripts/sage-promote.sh`
- `scripts/sage-retro-spec.sh`
- `scripts/sage-validate.sh`
- 手動 E2E 結果（`vibe/* → promote/*`）

## 出力

- `SPEC-0006` の AC-07 更新
- `PLAN-0006` の promotion シナリオ更新
- 本 TASK ファイル

## File Scope（変更許可範囲）

- 作成: `tasks/TASK-0062-spec0006-wording-alignment.md`
- 変更: `specs/SPEC-0006-vibe-coding-lanes-and-promotion.md`
- 変更: `plans/PLAN-0006-vibe-coding-lanes-and-promotion.md`
- 変更: `.sage/runs/RUN-0002.yaml`

## 禁止事項

- `src/`, `tests/`, `scripts/` の実装ロジックを変更しない
- SPEC-0006 のスコープを拡張しない
- 新しい検証基盤の設計を追加しない

## 完了条件

- [x] `SPEC-0006` の AC-07 が Retro-SPEC ドラフトの実装実態と一致している
- [x] `PLAN-0006` の E2E シナリオが実際の promotion 挙動と一致している
- [x] 本 TASK の実行内容が `.sage/runs/` に記録されている

## Done Definition（ラウンド単位）

参照: `tasks/done-def-SPEC-0006-round-1.md`（未作成のため本タスクでは参照のみ）

## 実行ログ

| フィールド | 内容 |
|-----------|------|
| RUN-ID    | RUN-0002 |
| 開始     | 2026-04-11 13:29 |
| 完了     | 2026-04-11 13:29 |
| 結果     | Pass |
| Gate結果  | structural: skipped / functional: skipped / security: skipped |
