# TASK-0101: Hook test harness + smoke tests for existing 5 hooks

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0101 |
| SPEC-ID   | SPEC-0011 |
| PLAN-ID   | PLAN-0011 |
| ステータス | Pending |
| 担当Agent | Implementation/Test |
| 並列可否  | Yes |
| 依存TASK  | none |
| 見積     | 90m |

## 責務

`templates/hooks/tests/` 以下に pure-bash test harness を構築し、既存 5 hooks (block-dangerous-commands / protect-sage-files / check-file-scope / session-start / session-stop) それぞれに smoke test (正常系 1 + block 期待ケース 1) を追加する。

## 入力

- SPEC-0011 FR-01, FR-02, NFR-02, OPS-01
- Codex review R8 (新規 hook には test 必須)
- 既存 hook 5 ファイル (各 76-164 行)

## 出力

1. `templates/hooks/tests/run-tests.sh` (test runner — glob で `test-*.sh` を実行、PASS/FAIL 集計、exit 0/1)
2. `templates/hooks/tests/test-helpers.sh` (共通: setup/teardown/assert_exit_code/assert_stderr_contains)
3. `templates/hooks/tests/test-block-dangerous-commands.sh` (allow case + block case 最低 1 件ずつ)
4. `templates/hooks/tests/test-protect-sage-files.sh` (同上)
5. `templates/hooks/tests/test-check-file-scope.sh` (同上)
6. `templates/hooks/tests/test-session-start.sh` (smoke: stderr 出力が含まれること)
7. `templates/hooks/tests/test-session-stop.sh` (smoke: 副作用が `.sage/metrics/` に記録されること)
8. `templates/hooks/tests/README.md` (書き方ガイド: setup → run → assert)

## File Scope（変更許可範囲）

- 作成: `templates/hooks/tests/run-tests.sh`, `templates/hooks/tests/test-helpers.sh`, `templates/hooks/tests/test-*.sh` (5 件), `templates/hooks/tests/README.md`
- 変更: なし
- 削除: なし

## 禁止事項

- 既存 hook 5 ファイル本体への変更禁止 (TASK-0103/0104 で扱う)
- BATS や bash-tap 等の external dependency 導入禁止 (pure bash + diff)
- test 内で実 `.sage/` 状態を破壊しない (`mktemp -d` で sandbox 化、trap で cleanup)
- install.sh / scripts/generate-installer.sh への変更禁止 (TASK-0103/0104 で hook 変更時にまとめて再生成)

## 完了条件

- [ ] `bash templates/hooks/tests/run-tests.sh` exit 0
- [ ] PASS/FAIL count が stdout に表示される (例: `PASS: 8 / FAIL: 0 / TOTAL: 8`)
- [ ] 5 hooks 全てに最低 1 test ファイルが存在 (`ls templates/hooks/tests/test-*.sh | wc -l` >= 5)
- [ ] `time bash templates/hooks/tests/run-tests.sh` < 5 秒 (NFR-02)
- [ ] test ファイル全てが `set -euo pipefail` で開始 + `trap` cleanup を持つ
- [ ] `templates/hooks/tests/README.md` が存在し書き方の最小例を含む
- [ ] commit message に `TASK-0101:` を含む
