# TASK-0157: fix RUN-ID collision (RUN-0007 restore + RUN-0008 NEW)

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0157 |
| SPEC-ID   | SPEC-0023 |
| PLAN-ID   | PLAN-0023 |
| ステータス | Done |
| 担当Agent | Implementation |
| 並列可否  | No (Codex review Blocker B1 即時対応) |
| 依存TASK  | TASK-0155 (RUN log の対象) |
| 見積     | 15m |

## 責務

Codex SPEC-0023 review Blocker B1 「RUN-0007 traceability 衝突」を解消する。私 (Claude) が `Write` で `.sage/runs/RUN-0007.yaml` を上書きしたが、main 側の RUN-0007 は Codex SPEC-0022 follow-up (task_id: TASK-0150、runtime: codex-cli) であり、上書きは traceability 違反だった。RUN-0007 を main 状態に restore し、Claude 側 RUN は RUN-0008 で新規作成する。

## 入力

- Codex review Blocker B1
- main の `.sage/runs/RUN-0007.yaml` (Codex 由来、`git show main:.sage/runs/RUN-0007.yaml` で取得可)
- 既存 `.sage/runs/RUN-0007.yaml` (Claude が上書きした内容、TASK-0155 用)

## 出力

1. `.sage/runs/RUN-0007.yaml` を `git show main:` 内容で restore (Codex TASK-0150 復元)
2. `.sage/runs/RUN-0008.yaml` 新規作成 (Claude TASK-0155 + 0156 内容、runtime: claude-code)
3. `tasks/TASK-0155-paired-test-and-verification.md` の RUN-0007 → RUN-0008 全置換

## File Scope（変更許可範囲）

- 変更: `.sage/runs/RUN-0007.yaml` (restore to main)
- 作成: `.sage/runs/RUN-0008.yaml`
- 変更: `tasks/TASK-0155-paired-test-and-verification.md` (RUN-ID 参照のみ)
- 作成: `tasks/TASK-0157-fix-runid-collision.md` (本ファイル)

## 禁止事項

- main の RUN-0007.yaml 内容を改変しない (Codex traceability 保護)
- 既存 RUN-0001..0006 を触らない
- TASK-0155 の File Scope / 完了条件以外を本 TASK で修正しない (TASK-0159 で行う)
- RUN-0008 の `runtime` field を偽装しない (実態は claude-code、SPEC-0017 準拠)

## 完了条件

- [x] `.sage/runs/RUN-0007.yaml` の `task_id` が `TASK-0150` (main 元値)、`runtime` が `codex-cli`
- [x] `.sage/runs/RUN-0008.yaml` が存在し `bash scripts/sage-runlog-validate.sh .sage/runs/RUN-0008.yaml` PASS
- [x] `tasks/TASK-0155-paired-test-and-verification.md` 内に `RUN-0007` への参照が 0 件 (`! grep -F "RUN-0007" tasks/TASK-0155-*.md`)
- [x] commit message に `TASK-0157:` 含む
