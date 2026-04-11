# TASK-0063: README / governance の 4レーン表記整合

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0063 |
| SPEC-ID   | SPEC-0006 |
| PLAN-ID   | PLAN-0006 |
| ステータス | Done |
| 担当Agent | Planning |
| 並列可否  | No |
| 依存TASK  | TASK-0062 |
| 見積     | 20m |

## 責務

README / governance のレーン説明を、実装済みの `promotion` レーンを含む 4レーン表記へ整合させる。

## 入力

- `README.md`
- `sage/governance.md`
- `AGENTS.md`
- `CLAUDE.md`
- `templates/claude-md-snippet.md`
- `templates/agents-md-snippet.md`

## 出力

- `README.md` のレーン説明更新
- `sage/governance.md` のレーン説明更新
- `PLAN-0006` / `SPEC-0006` の関連ID更新
- 本 TASK ファイル

## File Scope（変更許可範囲）

- 作成: `tasks/TASK-0063-spec0006-readme-governance-alignment.md`
- 変更: `README.md`
- 変更: `sage/governance.md`
- 変更: `specs/SPEC-0006-vibe-coding-lanes-and-promotion.md`
- 変更: `plans/PLAN-0006-vibe-coding-lanes-and-promotion.md`
- 変更: `.sage/runs/RUN-0003.yaml`
- 変更: `install.sh`

## 禁止事項

- `scripts/` の実装ロジックを変更しない
- レーンの挙動を変更しない
- 新しい Gate や workflow を追加しない

## 完了条件

- [x] `README.md` が `promotion` を含む 4レーン表記になっている
- [x] `sage/governance.md` が `promotion` を含む 4レーン表記になっている
- [x] `install.sh` が再生成され、配布物にも同じ説明が入る

## Done Definition（ラウンド単位）

参照: `tasks/done-def-SPEC-0006-round-1.md`（未作成のため本タスクでは参照のみ）

## 実行ログ

| フィールド | 内容 |
|-----------|------|
| RUN-ID    | RUN-0003 |
| 開始     | 2026-04-11 13:33 |
| 完了     | 2026-04-11 13:33 |
| 結果     | Pass |
| Gate結果  | structural: skipped / functional: skipped / security: skipped |
