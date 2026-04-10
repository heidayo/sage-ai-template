# TASK-0054: テンプレート安定化 + セキュリティ是正を一括実施

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0054 |
| SPEC-ID   | SPEC-0005 |
| PLAN-ID   | PLAN-0005 |
| ステータス | Done |
| 担当Agent | Implementation |
| 並列可否  | No |
| 依存TASK  | none |
| 見積     | 1 turn |

sage-managed: true

## 責務

公開テンプレートとして危険または破損している workflow / hook / packaging / documentation の整合を、互換優先でまとめて修正する。

## 入力

- SPEC-0005
- PLAN-0005
- 既存の security / hooks / install lifecycle / traceability 実装

## 出力

- 安全化された GitHub Actions
- `hooks.profile: none` と両言語ステータス対応済み hook 群
- review rubric を配布できる installer / adopt フロー
- 通知-only に変更された update-check
- 整合した README / CLAUDE.md / AGENTS.md / traceability 定義
- historical traceability を補完する `PLAN-0001`, `TASK-0001`〜`TASK-0026`, `done-def-*`

## File Scope（変更許可範囲）

- 変更: `.github/workflows/`
- 変更: `templates/hooks/`
- 変更: `scripts/`
- 変更: `templates/skills/sage-review/`
- 変更: `.sage/config.yaml`
- 変更: `.gitignore`
- 変更: `README.md`
- 変更: `CLAUDE.md`
- 変更: `AGENTS.md`
- 変更: `sage/traceability.md`
- 変更: `specs/SPEC-0001-sage-template-setup.md`
- 作成: `plans/PLAN-0001-sage-template-setup.md`
- 作成: `tasks/TASK-0001-*.md`
- 作成: `tasks/done-def-SPEC-0001-round-1.md`
- 作成: `tasks/done-def-SPEC-0002-round-1.md`
- 作成: `tasks/done-def-SPEC-0003-round-1.md`
- 作成: `tasks/done-def-SPEC-0004-round-1.md`
- 作成: `tasks/done-def-SPEC-0005-round-1.md`
- 変更: `.claude/settings.json`
- 作成: `specs/SPEC-0005-template-stabilization-remediation.md`
- 作成: `plans/PLAN-0005-template-stabilization-remediation.md`
- 作成: `tasks/TASK-0054-template-stabilization-remediation.md`

## 禁止事項

- `docs/setup.md` の既存差分を上書きしない
- `install.sh` を手編集しない（generator から再生成する）
- 新機能追加や言語固有ツール導入まで広げない
- retrospective placeholder を実装済み詳細記録のように偽装しない

## 完了条件

- [x] heredoc injection 経路が除去されている
- [x] hook 実行が `none` / `In Progress` / `実行中` を正しく扱う
- [x] `sage-review` の rubric 配布漏れが解消されている
- [x] `sage-update-check.sh` が remote installer を自動実行しない
- [x] `make report` / `CI=1 bash scripts/sage-validate.sh` / targeted hook checks が期待どおり通る
- [x] `SPEC-0001` の traceability 参照切れと AC ステータス矛盾が解消されている
- [x] `done-def-*` 参照切れが解消されている
- [x] Gate 1 / Gate 2 workflow に `eval "$CMD"` が残っていない

## Done Definition（ラウンド単位）

参照: `tasks/done-def-SPEC-0005-round-1.md`

## 残留制約

- `PLAN-0001` と `TASK-0001`〜`TASK-0026` は retrospective placeholder 補完であり、historical traceability の真正性そのものは遡及的に回復しない
- そのため C-4 は「参照切れ解消済み・historical limitation は受容」という扱いとする

## 実行ログ

| フィールド | 内容 |
|-----------|------|
| RUN-ID    | RUN-XXXX（未採番） |
| 開始     | 2026-04-10 |
| 完了     | |
| 結果     | |
| Gate結果  | structural / functional / security / architecture |
