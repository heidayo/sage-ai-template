# TASK-0144: Codex Review Follow-up — installer sync checksum regression fix

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0144 |
| SPEC-ID   | SPEC-0018 |
| PLAN-ID   | PLAN-0018 |
| ステータス | Done |
| 担当Agent | Implementation |
| 並列可否  | No |
| 依存TASK  | TASK-0139, TASK-0140, TASK-0141, TASK-0142, TASK-0143 |
| 見積     | 30m |

## 責務

Claude 実装後の Codex 確認で見つかった installer sync 検証の byte checksum regression と release checksum artifact 漏れを修正する。

## 入力

- SPEC-0018 AC-03 / AC-04 / AC-07 / AC-13 / AC-14
- PLAN-0018 検証方法
- Claude 実装コミット `TASK-0139`..`TASK-0143`

## 出力

- `scripts/sage-validate.sh` Check 9 が remote installer bytes を一時ファイルで検証し、末尾改行を落とさない
- `templates/hooks/tests/test-release-workflow.sh` に同一 remote content の回帰テストを追加
- `install.sh` を再生成
- `SHA256SUMS` を現在の `install.sh` に対して生成
- `.sage/install-state.yaml` と `.sage/runs/RUN-0005.yaml` を更新

## File Scope（変更許可範囲）

- 作成: `tasks/TASK-0144-codex-review-followup.md`
- 作成: `SHA256SUMS`
- 作成: `.sage/runs/RUN-0005.yaml`
- 変更: `scripts/sage-validate.sh`
- 変更: `templates/hooks/tests/test-release-workflow.sh`
- 変更: `install.sh`
- 変更: `.sage/install-state.yaml`

## 禁止事項

- AGENTS.md / CLAUDE.md / sage/governance.md など protected documentation を追加編集しない
- SPEC-0018 の scope を拡張しない
- remote content を shell 変数に丸ごと格納して checksum しない
- `curl | bash` 推奨文言の追加を行わない

## 完了条件

- [x] `bash templates/hooks/tests/test-release-workflow.sh` が PASS
- [x] `bash templates/hooks/tests/run-tests.sh` が PASS
- [x] `bash scripts/generate-installer.sh > /tmp/new.sh && diff install.sh /tmp/new.sh` が PASS
- [x] `shasum -a 256 -c SHA256SUMS` が PASS
- [x] `bash scripts/sage-validate.sh` が PASS
- [x] `bash scripts/sage-doctor.sh` が 0 FAIL
- [x] `bash scripts/sage-doc-drift.sh` が PASS

## 実行ログ

| フィールド | 内容 |
|-----------|------|
| RUN-ID    | RUN-0005 |
| 開始     | 2026-05-02 15:20 UTC |
| 完了     | 2026-05-02 15:27 UTC |
| 結果     | Pass |
| Gate結果  | structural: pass / functional: pass / security: pass / architecture: pass |
