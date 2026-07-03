# TASK-0204: scripts/sage-tsc-ratchet.sh 新設（tsc エラー数ラチェット）

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0204 |
| SPEC-ID   | SPEC-0030 |
| PLAN-ID   | PLAN-0030 |
| ステータス | Pending |
| 担当Agent | Implementation |
| 並列可否  | Yes（TASK-0205 と並列可 — File Scope 互いに素） |
| 依存TASK  | none |
| 見積     | 2h |

## 責務

汎用 tsc エラー数ラチェットスクリプト `scripts/sage-tsc-ratchet.sh` を新設する（検査モード / `--update` / `--init` / tsc コマンド注入 / baseline 整合検証）。

## 入力

- SPEC-0030 スコープ第 1 項・FR-01〜05・SEC-01〜03・異常系（想定エラー1〜3、境界ケース1〜3）・CLI 契約・ファイル契約・実装メモ
- 既存流儀参照: `scripts/sage-promote.sh`（usage / `set -euo pipefail` / INFO・ERROR プレフィックス）、SPEC-0027 実装の JSON 取り扱い

## 出力

- `scripts/sage-tsc-ratchet.sh`（新規、実行可能）
  - 検査モード: `error TS[0-9]+` 行数 vs `.tsc-baseline.json`。増加 → 現在数/baseline/増分を stderr + exit 1、同数 → exit 0、減少 → exit 0 + update 推奨 INFO
  - `--update`: baseline 上書き（唯一の正規更新経路）。`--init`: 不在時のみ作成、既存時 exit 1 + `--update` 案内
  - tsc 注入: `SAGE_TSC_COMMAND` > `--tsc-command` > `npx tsc --noEmit`。実行は `sh -c "$TSC_CMD"` の単一経路のみ
  - baseline 整合検証: 非負整数 `errors` 以外（負数/非数値/欠損/パース不能）→ 理由を stderr + exit 1、baseline 非変更
  - baseline 不在で検査モード → exit 1 + `--init` 案内
  - tsc 実行失敗（`error TS` パターン 0 件 + tsc 非0 exit）→ exit 1 + 出力全文を stderr へ透過（境界ケース2）
  - 書き込み JSON は固定スキーマ `{"errors": <N>, "updated_at": "<ISO8601>"}` の printf テンプレートのみ（SEC-02）

## File Scope（変更許可範囲）

- 作成: `scripts/sage-tsc-ratchet.sh`
- 変更: なし
- 削除: なし

## 禁止事項

- jq / eval の使用（AC-08 / INV-03）
- tsc 出力内容（パス・メッセージ）の baseline への転記（SEC-02 / INV-04）
- `install.sh` / `SHA256SUMS` / `scripts/generator/` / `templates/project-checks/ts-pnpm.yaml` / `sage/` / `AGENTS.md` / `docs/codex-*.md` / CLAUDE.md への変更（AC-09 / AC-12）
- テスト実装（TASK-0207 の Test Agent 責務 — AP-04 回避）
- 検査モード・異常終了経路での baseline 変更（INV-01）

## 完了条件

コマンドベース（一時ディレクトリに mock tsc スクリプトを手動配置して確認。正式テストは TASK-0207）:

- [ ] mock tsc（3 エラー出力）注入で `bash scripts/sage-tsc-ratchet.sh --init` → `.tsc-baseline.json` に `grep -F '"errors": 3'` が exit 0、続く検査モードが exit 0（AC-01 相当）
- [ ] baseline 3 + 5 エラー版 mock で検査モード → exit 1、出力に現在数 5 / baseline 3 / 増分 2（AC-02 相当）
- [ ] baseline 3 + 1 エラー版 mock で検査モード → exit 0 + update 推奨 INFO。`--update` 後 `grep -F '"errors": 1'` が exit 0（AC-03 相当）
- [ ] 不正 baseline（`{"errors": -1}` / `{"errors": "abc"}` / `not-json`）→ いずれも exit 1 + stderr 理由 + baseline バイト不変（AC-04 相当）
- [ ] baseline 不在で検査モード → exit 1 + stderr に `--init` 案内（AC-05 相当）
- [ ] `--tsc-command` 単独動作 + `SAGE_TSC_COMMAND` 併存時は環境変数優先（AC-06 相当）
- [ ] `grep -E '\bjq\b|\beval\b' scripts/sage-tsc-ratchet.sh` が exit 非0（AC-08）
- [ ] `bash templates/hooks/tests/run-tests.sh` が全件 PASS（既存テスト非破壊、AC-10）

## Done Definition（ラウンド単位）

参照: `tasks/done-def-SPEC-0030-round-1.md`

## 実行ログ

| フィールド | 内容 |
|-----------|------|
| RUN-ID    | （実行時に自動採番） |
| 開始     | |
| 完了     | |
| 結果     | |
| Gate結果  | |
