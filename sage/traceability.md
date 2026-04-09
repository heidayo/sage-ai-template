# SAGE トレーサビリティ

## ID体系

| ID種別 | フォーマット | 例 | 生成方法 |
|--------|-----------|-----|---------|
| SPEC-ID | SPEC-XXXX | SPEC-0001 | `make id-gen TYPE=spec` |
| PLAN-ID | PLAN-XXXX | PLAN-0001 | `make id-gen TYPE=plan` |
| TASK-ID | TASK-XXXX | TASK-0001 | `make id-gen TYPE=task` |
| RUN-ID | RUN-XXXX | RUN-0001 | `make id-gen TYPE=run` |
| FAIL-ID | FAIL-XXXX | FAIL-0001 | `make id-gen TYPE=fail` |
| MERGE-ID | PR番号 | #42 | GitHub自動 |

## 追跡チェーン

```
SPEC-ID → PLAN-ID → TASK-ID → AGENT-ID → RUN-ID → MERGE-ID
```

すべての変更はこのチェーンで追跡可能でなければならない。

## 記録場所

| ID | 記録場所 |
|----|---------|
| SPEC-ID | `specs/SPEC-XXXX-*.md` + PR本文 |
| PLAN-ID | `plans/PLAN-XXXX-*.md` + PR本文 |
| TASK-ID | `tasks/TASK-XXXX-*.md` + コミットメッセージ + PR本文 |
| RUN-ID | `.sage/runs/RUN-XXXX.yaml` |
| FAIL-ID | `sage/failures.md` |
| MERGE-ID | GitHub PR |

## 必須ルール

1. **すべてのPR** に SPEC-ID, PLAN-ID, TASK-ID を含む
2. **すべてのコミット** に TASK-ID を含む（形式: `feat: description [TASK-0001]`）
3. **すべてのエージェント実行** に RUN-ID を記録
4. **すべての失敗** に FAIL-ID を記録

## コミットメッセージ形式

```
<type>: <description> [TASK-XXXX]

Types: feat, fix, refactor, test, docs, chore, ci
```

例:
```
feat: add user authentication endpoint [TASK-0003]
fix: resolve null pointer in payment flow [TASK-0015]
test: add boundary tests for date validation [TASK-0016]
```

## 検証方法

```bash
# 直近コミットのTASK-ID存在チェック
make trace-check

# 自動検証（CI: sage-architecture-gate.yml）
# - PR本文のSPEC-ID存在チェック
# - コミットのTASK-ID存在チェック
# - Big Bang Prompt検出（20ファイル超の単一コミット）
```
