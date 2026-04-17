# TASK-0084: 採点 oscillation 検知 + 新 abort_reason

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0084 |
| SPEC-ID   | SPEC-0008 |
| PLAN-ID   | PLAN-0008-D |
| ステータス | In Progress |
| 担当Agent | Implementation |
| 並列可否  | No (TASK-0083 の best-of-N が先行必須) |
| 依存TASK  | TASK-0083 |
| 見積     | 1h |

## 責務

best-of-N 採点において、1 iteration 内の N サンプルの max - min が `scoring_variance_abort` (デフォルト 15) を超えた場合、oscillation とみなして `abort_reason: scoring_oscillation` で human escalation に移行する。合わせて、有効な採点サンプルが 0 件のケースを `abort_reason: evaluator_unavailable` として明文化する。

## 入力

- `.sage/config.yaml` の `harness.scoring_variance_abort` (TASK-0082 で追加済)
- `templates/skills/sage-harness/SKILL.md` の Phase 1 ループ制御擬似コード (TASK-0083 で best-of-N 導入済)
- `abort_reason` enum (既に TASK-0076 で 2 値追加済だが、発火ロジックは未記述)

## 出力

- Phase 1 ループ制御擬似コードに oscillation 検知分岐を挿入
- Phase 2 は「Phase 1 と同一パターン」記述でカバー
- SKILL.md の abort_reason 一覧セクションに oscillation / evaluator_unavailable の発火条件を記載

## File Scope（変更許可範囲）

- 作成:
  - `tasks/TASK-0084-oscillation-detection.md` (本ファイル)
- 変更:
  - `templates/skills/sage-harness/SKILL.md` (Phase 1 ループ擬似コードと abort_reason 説明のみ)
- 削除: なし

## 禁止事項

- `.claude/skills/` の直接編集禁止
- config.yaml の変更禁止 (TASK-0082 成果物)
- TASK-0083 で導入した best-of-N / moving window ロジックの変更禁止 (差分最小化)
- 新規 abort_reason の追加禁止 (TASK-0076 で既に enum に 2 値追加済、本 TASK は発火条件の記述のみ)

## 完了条件

- [ ] Phase 1 ループ制御擬似コードで「N サンプル採点後 → variance 判定 → 超過なら abort_reason: scoring_oscillation」の流れが読み取れる
- [ ] 有効採点サンプル 0 件 (全呼び出しが YAML 不正など) で `abort_reason: evaluator_unavailable` に遷移する記述がある
- [ ] 例として `[100, 80, 90]` (variance=20) → abort、`[96, 95, 97]` (variance=2) → 継続 が書かれている
- [ ] コミットメッセージに `TASK-0084` を含む

## Done Definition（ラウンド単位）

参照: (PLAN-0008-D 統合時に作成)

## 実行ログ

| フィールド | 内容 |
|-----------|------|
| RUN-ID    | (実行時に自動採番) |
| 開始     | 2026-04-17 |
| 完了     | (実行完了時に記入) |
| Gate結果  | structural: - / functional: - / security: - |
