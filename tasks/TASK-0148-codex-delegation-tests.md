# TASK-0148: Codex delegation tests and run log

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0148 |
| SPEC-ID   | SPEC-0022 |
| PLAN-ID   | PLAN-0022 |
| ステータス | Done |
| 担当Agent | Test |
| 並列可否  | No |
| 依存TASK  | TASK-0146, TASK-0147 |
| 見積     | 45m |

## 責務

Codex Delegation Packet の文書・AGENTS・installer 伝播を検証し、RUN log を記録する。

## 入力

- TASK-0145..0147 の成果物

## 出力

- `templates/hooks/tests/test-codex-delegation-packet.sh`
- `.sage/runs/RUN-0006.yaml`

## File Scope（変更許可範囲）

- 作成: `templates/hooks/tests/test-codex-delegation-packet.sh`
- 作成: `.sage/runs/RUN-0006.yaml`
- post-execution metadata update: `tasks/TASK-0145-codex-delegation-doc.md`, `tasks/TASK-0146-agents-codex-guidance.md`, `tasks/TASK-0147-installer-codex-doc-propagation.md`, `tasks/TASK-0148-codex-delegation-tests.md`

## 禁止事項

- テストを skip 前提にしない
- `.claude/` 配下を変更しない
- 失敗した検証を RUN log で pass と記録しない

## 完了条件

- [x] `bash templates/hooks/tests/test-codex-delegation-packet.sh` が PASS
- [x] `bash templates/hooks/tests/run-tests.sh` が PASS
- [x] `bash scripts/sage-validate.sh` が PASS
- [x] `bash scripts/sage-doc-drift.sh` が PASS
- [x] RUN-0006 が `bash scripts/sage-runlog-validate.sh` を PASS
