# TASK-0070: Gate 2 カバレッジ閾値の数値抽出 + 比較

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0070 |
| SPEC-ID   | SPEC-0008 |
| PLAN-ID   | PLAN-0008-A |
| ステータス | In Progress |
| 担当Agent | Implementation |
| 並列可否  | Yes |
| 依存TASK  | none |
| 見積     | 2h |
| sage-managed | true |

## 責務

`.sage/config.yaml` の `functional.unit_test_coverage: 0.80` が宣言されているだけで実 workflow では閾値判定されていなかった問題を解消する。`sage-functional-gate.yml` に coverage 抽出と threshold 比較を実装し、閾値未達で workflow を fail させる。言語非依存性を保つため coverage 出力の parser は薄く自前実装 (`scripts/sage-coverage-parse.sh`)、実際の coverage 計測コマンドは `project_checks.coverage_command` で各プロジェクトが定義する。

## 入力

- `.sage/config.yaml` の `functional.unit_test_coverage` (default 0.80) と新規 `project_checks.coverage_command`
- `.github/workflows/sage-functional-gate.yml` (既存ロジックは temper しない)
- 既存 project_checks.test_command (別変数、別実行)

## 出力

- 新規 `scripts/sage-coverage-parse.sh`: 標準入力から coverage 値 (例 `80.5%` や `0.805` や `80.5`) を抽出し 0.0〜1.0 正規化 float で stdout に出力、閾値と比較した結果を exit code で返す
- `project_checks.coverage_command` が設定されていれば workflow で実行し、出力を parser に渡して閾値比較
- coverage_command 未設定: SKIPPED (既存挙動踏襲)
- coverage_command 設定済 + 閾値未達: FAIL (exit 1)、PR コメントに実測値を表示
- coverage_command 設定済 + 閾値達成: PASS

## File Scope（変更許可範囲）

- 作成:
  - `scripts/sage-coverage-parse.sh`
  - `tasks/TASK-0070-coverage-threshold.md` (本ファイル)
- 変更:
  - `.github/workflows/sage-functional-gate.yml` (coverage ブロック追加 + PR コメント整形追加)
  - `.sage/config.yaml` (`project_checks.coverage_command` のコメント例を追加)
- 削除: なし

## 禁止事項

- 既存 test_command ロジックの変更禁止 (回帰リスク)
- `.sage/config.yaml` の `functional.unit_test_coverage` のデフォルト値変更禁止 (0.80 維持)
- 言語別 parser のハードコード禁止 (coverage_command で吸収)
- 外部 action (codecov 等) の追加禁止

## 完了条件

- [ ] `scripts/sage-coverage-parse.sh` が `<input>` と `<threshold>` を引数または stdin で受けて exit 0/1 を返す
- [ ] `echo 80.5 | bash scripts/sage-coverage-parse.sh 0.80` が exit 0
- [ ] `echo 65 | bash scripts/sage-coverage-parse.sh 0.80` が exit 1
- [ ] `echo 0.92 | bash scripts/sage-coverage-parse.sh 0.80` が exit 0 (0-1 スケール入力も受理)
- [ ] workflow で `coverage_command` 未設定時 SKIPPED と表示される
- [ ] coverage_command が float を出力するモック設定で workflow が局所的に動作確認可能 (workflow YAML の構文確認)
- [ ] コミットメッセージに `TASK-0070` を含む

## Done Definition（ラウンド単位）

参照: (PLAN-0008-A 統合時に作成)

## 実行ログ

| フィールド | 内容 |
|-----------|------|
| RUN-ID    | (実行時に自動採番) |
| 開始     | 2026-04-17 |
| 完了     | (実行完了時に記入) |
| Gate結果  | structural: - / functional: - / security: - |
