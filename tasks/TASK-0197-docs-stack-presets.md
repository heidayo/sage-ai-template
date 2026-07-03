# TASK-0197: docs/stack-presets.md 新規 + README 参照追記

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0197 |
| SPEC-ID   | SPEC-0028 |
| PLAN-ID   | PLAN-0028 |
| ステータス | Pending |
| 担当Agent | Implementation |
| 並列可否  | Yes（TASK-0192 完了後、TASK-0193〜0195 と並列可 — File Scope は互いに素） |
| 依存TASK  | TASK-0192 |
| 見積     | 1h |

## 責務

`docs/stack-presets.md`（日本語）を新規作成し、README に参照を追記する（SPEC-0028 Slice ヒント T6）。

## 入力

- TASK-0192 の成果物: `templates/project-checks/*.yaml`（プリセット内容の転記元）
- OPS-01: プリセット一覧・各プリセットのコマンド内容・`--stack` / 自動検出の選択手順・優先順位（go > ts-pnpm > node-npm > python とマーカー対応）・適用後のカスタマイズ方法（config.yaml 直接編集）
- リスク1/3 対策: 誤検出時の `--stack` 上書き手順、各プリセットの前提ツール（pnpm 等）を記載

## 出力

- `docs/stack-presets.md`（新規、日本語 — Language Rules 準拠）
- `README.md` への docs/stack-presets.md 参照追記（参照追記のみ）

## File Scope（変更許可範囲）

- 作成: `docs/stack-presets.md`
- 変更: `README.md`（参照追記のみ）
- 削除: なし

## 禁止事項

- 本リポジトリの `.sage/config.yaml` の変更（AC-11、全 TASK 横断制約）
- `CLAUDE.md` §9.1 への追記（Human-only — 追記案は PR 本文に記載する）
- `AGENTS.md` / `docs/codex-*.md` の編集（Codex-specific boundary）
- README の参照追記以外の変更

## 完了条件

- [ ] AC-12: `grep -rqF 'templates/project-checks' docs/stack-presets.md README.md` が exit 0
- [ ] AC-12: `grep -qF -- '--stack' docs/stack-presets.md` が exit 0
- [ ] docs に優先順位（go > ts-pnpm > node-npm > python）とカスタマイズ手順の記載がある
- [ ] `git diff --name-only main | grep -qxF '.sage/config.yaml'` が exit 非0（AC-11）
- [ ] コミットメッセージに TASK-0197 を含む

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
