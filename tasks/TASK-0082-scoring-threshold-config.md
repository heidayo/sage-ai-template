# TASK-0082: 採点閾値緩和と ブレ対策パラメータ追加 (config のみ)

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0082 |
| SPEC-ID   | SPEC-0008 |
| PLAN-ID   | PLAN-0008-D |
| ステータス | In Progress |
| 担当Agent | Implementation |
| 並列可否  | Yes (他 TASK と並列可) |
| 依存TASK  | none |
| 見積     | 0.5h |

## 責務

`.sage/config.yaml` の `harness:` セクションに対して、採点閾値を 100→95 に緩和し、採点ブレ対策用の 3 パラメータ (window_size / best_of_n / variance_abort) を追加する。ロジック実装は TASK-0083/0084 の範囲、本 TASK は **設定値の導入のみ**。

## 入力

- 現状 ([.sage/config.yaml:92-94](.sage/config.yaml:92)):
  - `spec_score_threshold: 100`
  - `plan_score_threshold: 100`
  - `review_score_threshold: 100`
- SPEC-0008 の FR-11/FR-12 で挙動が規定されている

## 出力

- 変更後の値:
  - `spec_score_threshold: 95`
  - `plan_score_threshold: 95`
  - `review_score_threshold: 95`
  - 新規 `scoring_window_size: 3`
  - 新規 `scoring_best_of_n: 3`
  - 新規 `scoring_variance_abort: 15`
- 既存コメントは保持、意図を説明する新コメント追加

## File Scope（変更許可範囲）

- 作成: なし
- 変更:
  - `.sage/config.yaml` (`harness:` セクションのみ)
- 削除: なし

## 禁止事項

- `.claude/skills/sage-harness/SKILL.md` の編集禁止 (これは TASK-0083/0084 の範囲、本 TASK で触ると silent scope expansion)
- `templates/skills/sage-harness/SKILL.md` の編集禁止 (同上)
- `spec_eval_max_iterations` / `plan_eval_max_iterations` / `same_fail_abort_threshold` の変更禁止 (本 TASK は新規閾値導入のみ)
- `auto_approve` の変更禁止

## 完了条件

- [ ] `.sage/config.yaml` の 3 つの threshold 値が `95` に変更されている
- [ ] 新規 3 キー (`scoring_window_size`, `scoring_best_of_n`, `scoring_variance_abort`) が `harness:` セクションに追加されている
- [ ] `bash -c 'command -v yq && yq eval .harness .sage/config.yaml'` で YAML パースエラーが出ない
- [ ] コミットメッセージに `TASK-0082` を含む

## Done Definition（ラウンド単位）

参照: (PLAN-0008-D 統合時に作成)

## 実行ログ

| フィールド | 内容 |
|-----------|------|
| RUN-ID    | (実行時に自動採番) |
| 開始     | 2026-04-17 |
| 完了     | (実行完了時に記入) |
| 結果     | (実行完了時に記入) |
| Gate結果  | structural: - / functional: - / security: - |
