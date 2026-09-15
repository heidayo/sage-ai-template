# TASK-0225: `grep -c ... || echo "0"` の二重 0 を解消する

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0225 |
| SPEC-ID   | N/A（lite lane `fix/*`。件数取得の 1 行修正のみで、hook / script の入出力契約・設定スキーマの変更なし） |
| PLAN-ID   | N/A（同上） |
| ステータス | Review |
| 担当Agent | Implementation |
| 並列可否  | No |
| 依存TASK  | none |
| 見積     | 1h |

ID の採番: `origin/main` 上で `bash scripts/sage-id-gen.sh task` を実行すると TASK-0213 が返りますが、TASK-0213 は e94ec28 で使用済みです（タスクファイルなし）。また、ローカルで作業中の `codex/spec-0032-review-remediation` が未コミットのまま TASK-0224 / RUN-0027 まで使っているため、重複を避けて TASK-0225 / TASK-0226 / RUN-0028 を使いました。

## 責務

件数を `grep -c ... || echo "0"` で取得している箇所を、一致 0 件のときも単一の整数になるように直す。

## 入力

- 利用プロジェクト（makeculture-hp-v2）で、lite lane（`fix/*`）のコミットのたびに commit-msg フックが `line 42: [: 0\n0: integer expression expected` を出力する
- 原因: `grep -c` は一致 0 件のとき `0` を出力して exit 1 になるため、`|| echo "0"` がもう 1 つ `0` を追加し、値が `0\n0` になる。続く `[ "$N" -gt 0 ]` がエラー（戻り値 2）になり、if が偽になるので、結果的にチェックを通過しているだけ

## 出力

- 次の 5 か所で `|| echo "0"`（`|| echo 0`）を `|| true` に変更
  - `templates/pre-commit-task-id.sh`: lite lane の契約変更チェック（`CONTRACT_CHANGES`）
  - `scripts/sage-validate.sh`: promote/* の Retro-SPEC TBD 件数（`TBD_COUNT`）と TASK-ID なしコミット件数（`COMMITS_WITHOUT_TASKID`）
  - `scripts/sage-retro-spec.sh`: 変更ファイル数（`FILE_COUNT`）
  - `templates/hooks/session-stop.sh`: 変更ファイル数（`FILES_COUNT`）
  - `scripts/sage-report.sh`: サイクル計測サンプル数（`CYCLE_COUNT`）
- 回帰テスト `templates/hooks/tests/test-count-fallback.sh`（5 ケース / 10 アサーション）

`|| true` にした理由: `grep -c` は一致 0 件でも `0` を出力するので、終了コードだけを打ち消せば値は常に 1 つの整数になる。`sage-validate.sh` の `TBD_COUNT` は直前の `[ -f "$RETRO_SPEC_FILE" ]` でファイルの存在を確認済みで、他の 4 か所は標準入力を数えるため、`grep` が何も出力しないケースはない。

## File Scope（変更許可範囲）

- 作成: `templates/hooks/tests/test-count-fallback.sh`, `tasks/TASK-0225-grep-count-fallback.md`, `.sage/runs/RUN-0028.yaml`
- 変更: `templates/pre-commit-task-id.sh`, `scripts/sage-validate.sh`, `scripts/sage-retro-spec.sh`, `templates/hooks/session-stop.sh`, `scripts/sage-report.sh`（各ファイルの該当行のみ）
- 削除: なし

## 禁止事項

- `install.sh` / `SHA256SUMS` の変更（再生成は TASK-0226 の別コミット。FAIL-0002）
- 件数チェックの判定条件・メッセージの変更
- テストファイル内の同じパターン（`test-installer-preservation.sh:428`, `test-codex-rules.sh:146`）の変更。どちらも存在しない可能性のあるファイルを読むため `|| echo 0` が必要で、一致 0 件のときも文字列比較または else 側（テスト失敗）に進むので判定は正しい
- `scripts/sage-validate.sh` の [7/9] で macOS 標準の bash 3.2 だけに出る `SECURITY_SCAN_FILES[@]: unbound variable` の修正（今回のテストのサンドボックスで見つけた別の問題。CI の bash 5 では発生しない）

## 完了条件

- [x] `bash templates/hooks/tests/test-count-fallback.sh` が `SUMMARY pass=10 fail=0`（修正前は pass=7 fail=3 で、commit-msg 42 行目・sage-validate 177/202 行目・retro-spec の `Found 0\n0` を再現）
- [x] fix/* で契約ファイルなしのコミットは exit 0 で stderr が空、`db/schema.sql` をステージすると拒否され `Detected 1 contract file(s)` と表示される
- [x] `bash templates/hooks/tests/run-tests.sh` が全件パス（TASK-0226 の再生成後）
- [x] 変更した 5 ファイル + テストで `shellcheck -S warning` の指摘なし

## 実行ログ

| フィールド | 内容 |
|-----------|------|
| RUN-ID    | RUN-0028 |
| 開始     | 2026-09-15 18:45 |
| 完了     | 2026-09-15 19:05 |
| 結果     | Pass |
| Gate結果  | structural: ○ / functional: ○ / security: ○ |
