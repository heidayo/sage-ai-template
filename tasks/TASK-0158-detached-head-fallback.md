# TASK-0158: detached HEAD fallback for test-codex-delegation-packet.sh branch detection

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0158 |
| SPEC-ID   | SPEC-0023 |
| PLAN-ID   | PLAN-0023 |
| ステータス | Done |
| 担当Agent | Implementation |
| 並列可否  | No (Codex review M1 即時対応) |
| 依存TASK  | TASK-0156 (元 branch-aware 化を強化) |
| 見積     | 20m |

## 責務

Codex SPEC-0023 review Major M1 「test-codex-delegation-packet.sh の `git rev-parse --abbrev-ref HEAD` が detached HEAD context (CI / 多くの worktree) で `HEAD` を返し strict mode が skip される」を解消する。`GITHUB_HEAD_REF` / `GITHUB_REF_NAME` の fallback chain を追加し、detached / unknown branch では strict mode (fail-safe) を default にする。

## 入力

- Codex review Major M1
- 既存 `templates/hooks/tests/test-codex-delegation-packet.sh` Scenario 6 (TASK-0156 で branch-aware 化済)
- GitHub Actions docs: `GITHUB_HEAD_REF` (PR context) / `GITHUB_REF_NAME` (push context)

## 出力

`templates/hooks/tests/test-codex-delegation-packet.sh` Scenario 6 の branch detection を改善:

1. **branch resolution priority**: `GITHUB_HEAD_REF` > `GITHUB_REF_NAME` > `git rev-parse --abbrev-ref HEAD`
2. **detached / unknown fallback**: branch が `HEAD` (detached) または空 / `unknown` の場合は strict mode を default 適用 (Codex PR が CI 上の detached checkout 経由で boundary check を silent bypass するのを防止)
3. **SKIP message** で実際の branch 名を表示 (debug 性向上)

## File Scope（変更許可範囲）

- 変更: `templates/hooks/tests/test-codex-delegation-packet.sh` (Scenario 6 の branch detection ロジックのみ)
- 作成: `tasks/TASK-0158-detached-head-fallback.md` (本ファイル)

## 禁止事項

- Scenario 1-5 を変更しない (Codex packet structural check は branch 非依存)
- branch resolution の env var を `GITHUB_*` 以外 (e.g. `BUILDKITE_*`, `JENKINS_*`) に hardcode しない (本 SPEC は GitHub Actions 前提)
- shellcheck error を残さない (R9)
- 既存 codex/* branch での挙動を変えない (backward compat)
- detached HEAD で SKIP に倒さない (fail-safe 必須)

## 完了条件

- [x] `templates/hooks/tests/test-codex-delegation-packet.sh` で `GITHUB_HEAD_REF` / `GITHUB_REF_NAME` fallback chain 実装
- [x] detached HEAD (`HEAD` / `unknown` / 空) では `APPLY_STRICT=true` に倒れる
- [x] codex/* branch では従来通り strict
- [x] 他 branch では従来通り SKIP (PASS としてカウント)
- [x] 現 branch (`feature/spec-0023-*`) で `bash templates/hooks/tests/test-codex-delegation-packet.sh` 6/6 PASS (Scenario 6 SKIP)
- [x] detached simulation: `BR="HEAD"` で strict mode に分岐することを bash logic で確認
- [x] shellcheck error 0 件
- [x] commit message に `TASK-0158:` 含む
