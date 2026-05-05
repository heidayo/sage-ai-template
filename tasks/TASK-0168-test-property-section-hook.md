# TASK-0168: test-property-section.sh + run-tests.sh integration

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0168 |
| SPEC-ID   | SPEC-0024 |
| PLAN-ID   | PLAN-0024 |
| ステータス | Done |
| 担当Agent | Test Agent |
| 並列可否  | No (pilot 3 件 retrofit が test fixture の前提) |
| 依存TASK  | TASK-0162, TASK-0167 |
| 見積     | 60m |

## 責務

新規 hook test `templates/hooks/tests/test-property-section.sh` を作成 (8+ scenarios)、`templates/hooks/tests/run-tests.sh` に統合。SPEC-0015 (NFR-01) と同じく 5 回測定中央値 < 200ms を満たす。

## 入力

- SPEC-0024 FR-07 (8+ scenarios の test schema)
- SPEC-0024 NFR-01 / NFR-04 (backward compat / performance)
- TASK-0162 確定の specs/_template.md Properties schema
- TASK-0167 完了の pilot 3 SPEC (test fixture の reference)
- 既存 templates/hooks/tests/run-tests.sh
- 既存 templates/hooks/tests/measure-hook-time.py (SPEC-0015 NFR-08)

## 出力

### templates/hooks/tests/test-property-section.sh (新規、8+ scenarios)

```bash
#!/usr/bin/env bash
# Test for SPEC-0024 Property-based Verify hook
set -euo pipefail

# Scenarios:
# 1. specs/_template.md has "## Properties" section
# 2. specs/_template.md has 4 sub-headers (Invariants/Pre-conditions/Post-conditions/Assumptions)
# 3. New SPEC has Properties with Gate mapping `(Gate N)` on each item
# 4. system/platform + Security 要件あり SPEC has >= 5 Properties (test pilot 3 件)
# 5. feature SPEC may have "Properties: not applicable + 理由" (PASS)
# 6. (異常系) Property セクション削除 fixture で FAIL
# 7. (異常系) Gate mapping 欠落 fixture で FAIL
# 8. (backward compat) 既存 SPEC (SPEC-0001..0010) に Property 不在 → WARN-only

# (full implementation in actual file)
```

### templates/hooks/tests/run-tests.sh (変更なし)

現行 `run-tests.sh` は `test-*.sh` を glob で自動発見する設計。`templates/hooks/tests/test-property-section.sh` を配置するだけで自動的に統合される。本 TASK で `run-tests.sh` 自体は変更しない。

## File Scope（変更許可範囲）

- 作成: `templates/hooks/tests/test-property-section.sh`

## 禁止事項

- 既存 hook test を変更しない (additive、SPEC-0023 同 pattern)
- pilot 3 件以外の SPEC を test fixture に hardcode しない (将来の retrofit に備える)
- shellcheck error を残さない (R9)
- profile gating (none/minimal/standard/strict) の挙動を `.sage/config.yaml` に依存させて壊さない
- 既存 SPEC で WARN を FAIL に格上げしない (incremental migration、NFR-06)
- test 中で git working tree を mutate しない (heredoc + grep simulate のみ、SPEC-0023 TASK-0155 教訓)

## 完了条件

- [ ] `bash templates/hooks/tests/test-property-section.sh` で 8/8+ PASS
- [ ] `bash templates/hooks/tests/run-tests.sh` で全 PASS (既存 187 + 新規 8 = 195+)
- [ ] `python3 templates/hooks/tests/measure-hook-time.py templates/hooks/tests/test-property-section.sh` で 5 回測定中央値 < 200ms
- [ ] `shellcheck templates/hooks/tests/test-property-section.sh` で error 0 件
- [ ] 異常系 fixture (Property 削除 / Gate mapping 欠落) で test が FAIL を返すこと (内部 mutation simulate)
- [ ] backward compat: 既存 SPEC (SPEC-0001 fixture) で WARN-only、FAIL にしない
- [ ] commit message に `TASK-0168:` 含む
