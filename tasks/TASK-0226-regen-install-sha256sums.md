# TASK-0226: install.sh 再生成 + SHA256SUMS 更新（TASK-0225）

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0226 |
| SPEC-ID   | N/A（lite lane `fix/*`。TASK-0225 の変更を再生成物に反映するのみ） |
| PLAN-ID   | N/A（同上） |
| ステータス | Review |
| 担当Agent | Implementation |
| 並列可否  | No |
| 依存TASK  | TASK-0225 |
| 見積     | 10m |

## 責務

TASK-0225 の変更（`TMPL_COMMIT_HOOK` / `TMPL_VALIDATE` / `TMPL_RETRO_SPEC` / `TMPL_HOOK_SESSION_STOP` の埋め込み対象）を install.sh に再生成反映し、SHA256SUMS を更新する。**再生成のみの単独コミット**（FAIL-0002）。

## 入力

- TASK-0225 のコミット済み変更
- 既存の再生成手順: `bash scripts/generate-installer.sh > install.sh`（generator ソースの変更は不要）
- SHA256SUMS の形式: `<sha256>  install.sh`（`.github/workflows/release.yml` と同じ）

## 出力

- 再生成済み `install.sh`（差分は TASK-0225 で直した 5 行のみ。`scripts/sage-report.sh` は install.sh に埋め込まれていない）
- 更新済み `SHA256SUMS`

## File Scope（変更許可範囲）

- 作成: `tasks/TASK-0226-regen-install-sha256sums.md`
- 変更: `install.sh`、`SHA256SUMS`（再生成による更新のみ）
- 削除: なし

## 禁止事項

- 再生成以外の変更（install.sh の手動編集は Forbidden Shortcuts「Manually edit generated code」違反）
- `scripts/generator/` の変更
- TASK-0225 の変更と同一コミットへの混入（FAIL-0002）

## 完了条件

- [x] `bash scripts/sage-installer-reproduce.sh` が exit 0
- [x] `bash scripts/generate-installer.sh | diff install.sh -` の差分なし（`test-installer-modularize` の byte-identical がパス）
- [x] `shasum -a 256 -c SHA256SUMS` が `install.sh: OK`
- [x] `shellcheck -S error install.sh` が exit 0
- [x] コミットが install.sh / SHA256SUMS のみを含む単独コミットであり、メッセージに TASK-0226 を含む

## 実行ログ

| フィールド | 内容 |
|-----------|------|
| RUN-ID    | RUN-0028（TASK-0225 と同じ実行） |
| 開始     | 2026-09-15 18:58 |
| 完了     | 2026-09-15 19:05 |
| 結果     | Pass |
| Gate結果  | structural: ○ / functional: ○ / security: ○ |
