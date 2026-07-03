# TASK-0192: スタックプリセット 4 ファイルの新設

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0192 |
| SPEC-ID   | SPEC-0028 |
| PLAN-ID   | PLAN-0028 |
| ステータス | Pending |
| 担当Agent | Implementation |
| 並列可否  | Yes（起点、依存なし） |
| 依存TASK  | none |
| 見積     | 1h |

## 責務

`templates/project-checks/` を新設し、go / ts-pnpm / node-npm / python の 4 プリセット YAML 断片を作成する（SPEC-0028 Slice ヒント T1）。

## 入力

- SPEC-0028 FR-01: 各ファイルは `lint` / `format` / `type_check` / `test_command` / `coverage_command` の 5 キーを持つ `.sage/config.yaml` の `project_checks:` セクション用 YAML 断片
- コマンド内容は config.yaml の既存 commented examples（Node/Go/Python）+ SPEC-0008 の Go 実績値ベース。標準ツールチェーンのみ（golangci-lint 等の追加ツール前提を置かない）
- 全プリセットは同一キーセット・同一インデント規約（機械検証可能、AC-01）

## 出力

- `templates/project-checks/go.yaml`
- `templates/project-checks/ts-pnpm.yaml`
- `templates/project-checks/node-npm.yaml`
- `templates/project-checks/python.yaml`

## File Scope（変更許可範囲）

- 作成: `templates/project-checks/go.yaml`, `templates/project-checks/ts-pnpm.yaml`, `templates/project-checks/node-npm.yaml`, `templates/project-checks/python.yaml`
- 変更: なし
- 削除: なし

## 禁止事項

- 本リポジトリの `.sage/config.yaml` の変更（AC-11、全 TASK 横断制約）
- generator / install.sh / SHA256SUMS への変更（TASK-0193/0195 の責務）
- `AGENTS.md` / `docs/codex-*.md` / `sage/` / `CLAUDE.md` の変更
- 標準ツールチェーン外のツール前提コマンドの記載

## 完了条件

- [ ] AC-01: `for f in go ts-pnpm node-npm python; do for k in lint format type_check test_command coverage_command; do grep -qE "^ *${k}:" "templates/project-checks/${f}.yaml" || exit 1; done; done` が exit 0
- [ ] `git diff --name-only main | grep -qxF '.sage/config.yaml'` が exit 非0（AC-11）
- [ ] コミットメッセージに TASK-0192 を含む

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
