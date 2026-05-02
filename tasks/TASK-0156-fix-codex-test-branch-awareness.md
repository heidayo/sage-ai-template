# TASK-0156: fix test-codex-delegation-packet.sh branch awareness for paired-SPEC coexistence

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0156 |
| SPEC-ID   | SPEC-0023 |
| PLAN-ID   | PLAN-0023 |
| ステータス | Pending |
| 担当Agent | Implementation |
| 並列可否  | No (TASK-0155 完了後の判明事項) |
| 依存TASK  | TASK-0155 |
| 見積     | 20m |

## 責務

SPEC-0022 で導入された `templates/hooks/tests/test-codex-delegation-packet.sh` の Scenario 6「Claude-specific files untouched」が、SPEC-0023 paired branch (Claude side intentional touches) で誤検出する問題を修正する。branch context を判定し、Codex side branch (`codex/*`) でのみ厳格 check、それ以外では SKIP に倒す。

## 入力

- 既存 `templates/hooks/tests/test-codex-delegation-packet.sh` Scenario 6 (line 85-103)
- SPEC-0023 §「リスク」#2 (paired update brittleness)
- governance.md §10.5 「Drift 検知」doctrine

## 出力

`templates/hooks/tests/test-codex-delegation-packet.sh` Scenario 6 を branch-aware に変更:
- 現在の branch 名を `git rev-parse --abbrev-ref HEAD` で取得
- `codex/*` または `feature/spec-0022-*` で始まる branch では現行 check を実施 (Codex side intentional scope)
- それ以外 (`feature/spec-0023-*`, `claude/*`, `feature/*`, `main` 等) では SKIP し warning メッセージ表示

## File Scope (変更許可範囲)

- 変更: `templates/hooks/tests/test-codex-delegation-packet.sh` (Scenario 6 のみ)

## 禁止事項

- Scenario 1-5 の logic を変更しない (Codex packet structural check は branch 非依存)
- branch 名 patterns を installer に hardcode しない (script 内の正規表現マッチのみ)
- shellcheck error を残さない (R9)
- 既存の Codex side branch (codex/*) での挙動を変えない (backward compat)
- test の SUMMARY フォーマット (`SUMMARY pass=N fail=M`) を変更しない
- install.sh / generator を本 TASK で再生成しない (test のみ修正)

## 完了条件

- [ ] `templates/hooks/tests/test-codex-delegation-packet.sh` Scenario 6 が branch-aware
- [ ] 現 branch (`feature/spec-0023-*`) で test 実行: `bash templates/hooks/tests/test-codex-delegation-packet.sh` が PASS (Scenario 6 SKIP メッセージ含む)
- [ ] `bash templates/hooks/tests/run-tests.sh` で全 PASS (188 + 1 → 189 が SKIP 経由で全 PASS)
- [ ] shellcheck error 0 件
- [ ] commit message に `TASK-0156:` 含む
