# TASK-0199: generator への Codex rules embed + write + managed_files + dry-run 表示追加

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0199 |
| SPEC-ID   | SPEC-0029 |
| PLAN-ID   | PLAN-0029 |
| ステータス | Pending |
| 担当Agent | Implementation |
| 並列可否  | Yes（TASK-0200 と並列可 — File Scope は互いに素） |
| 依存TASK  | TASK-0198 |
| 見積     | 2h |

## 責務

installer generator に `.codex/rules/` の配布ロジック（embed 5 件 + mkdir/write + managed_files 追加 + dry-run WOULD-* 表示 + `docs/codex-rules.md` 配布経路）を追加する（SPEC-0029 T2 / FR-02〜05, FR-07 / AC-02〜08 実装部）。

## 入力

- SPEC-0029（FR-02〜05, FR-07, SEC-01〜03, INV-01〜03, PRE-01/02, POST-01/02）
- TASK-0198 の成果物（`templates/codex-rules/` 5 ファイル）
- 既存機構: `scripts/generator/03-rules.sh`（embed + `RULES_LOCAL_NOTICE` + `write_rules_file`）、`07-installer-main.sh` L865-874（write 呼び出し）/ L1074-1079（managed_files）— 同構造をミラーし、overlay 案内先のみ `.codex/rules/local/` に差し替え
- `is_unmanaged_path` ガード（SPEC-0025）経由で書き込み（SEC-03）

## 出力

- `scripts/generator/03-rules.sh`: `TMPL_CODEX_RULES_*` embed 5 件 + Codex 向け overlay 注記（`.codex/rules/local/` 案内）+ `docs/codex-rules.md` embed 経路
- `scripts/generator/07-installer-main.sh`: `mkdir -p .codex/rules` / write 5 件 + docs write / managed_files に `.codex/rules/*.md` 5 件 + `docs/codex-rules.md` 追加 / dry-run WOULD-* 表示

## File Scope（変更許可範囲）

- 作成: なし
- 変更: `scripts/generator/03-rules.sh`, `scripts/generator/07-installer-main.sh`
- 削除: なし

## 禁止事項

- `AGENTS.md` / `docs/codex-delegation-packet.md` / `docs/codex-security.md` の編集（SPEC-0022/0023 boundary、AC-12）
- `templates/rules/` / `.claude/rules/` / `sage/` / `CLAUDE.md` / 本リポジトリの `.sage/config.yaml` の変更
- **`install.sh` の手動編集・再生成**（再生成は TASK-0201 専用、FAIL-0002）
- `.codex/rules/local/**` への書き込み経路の作成（INV-01 / SEC-03）
- 導入先ファイル内容を転記する経路の作成（SEC-01）、外部入力からのパス構成（SEC-02）
- File Scope 外の変更（AP-03）

## 完了条件

- [ ] `grep -c 'TMPL_CODEX_RULES_' scripts/generator/03-rules.sh` で embed 5 件が確認できる
- [ ] 一時ディレクトリで再生成した install.sh（`bash scripts/generate-installer.sh > /tmp/check.sh`、コミットはしない）を手動 install 検証し、`.codex/rules/` 5 ファイル + marker + `.codex/rules/local/` 案内注記を確認（AC-02 相当）
- [ ] 同検証で `--dry-run` 時に `.codex/` が作成されず WOULD-* 表示が出る（AC-07 相当）

## Done Definition（ラウンド単位）

参照: `tasks/done-def-SPEC-0029-round-1.md`

## 実行ログ

| フィールド | 内容 |
|-----------|------|
| RUN-ID    | （実行時に採番） |
| 開始     | - |
| 完了     | - |
| 結果     | - |
| Gate結果  | - |
