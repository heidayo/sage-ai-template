# PLAN-0011: Hook Hardening & Test Infrastructure (Phase 2A)

## メタデータ

| フィールド | 内容 |
|-----------|------|
| PLAN-ID   | PLAN-0011 |
| SPEC-ID   | SPEC-0011 |
| ステータス | Active |
| 作成日    | 2026-05-01 |
| 担当Agent | Planning Agent |

## 変更レイヤ

- [x] infra (hooks, scripts/generate-installer.sh, install.sh)
- [x] test (templates/hooks/tests/)
- [x] CI (.github/workflows/sage-structural-gate.yml)
- [x] doc (AGENTS.md, sage/governance.md)
- [ ] controller / usecase / domain / frontend (該当なし)

## 影響範囲

- **AI agent runtime**: hook の追加 pattern により block されるケースが増える (positive case の test で regression 確認)
- **CI**: shellcheck job 追加で structural gate の所要時間が +30 秒 程度
- **install workflow**: install.sh 内の embedded hook content が更新されるため install.sh size が +1-2 KB 程度
- **影響を受けない**: src/, tests/, .sage/config.yaml の hooks profile 値 (既定 standard のまま)

## 実装方針

### 全体方針
1. **既存挙動の完全保持** + **新規 pattern 追加**: 既存 test (なければ smoke test を追加してから) で regression 0 確認
2. **shellcheck baseline**: 既存 .sh の WARN は scope 外、新規/変更行のみ enforce (CI で `--severity=error` → 段階的に warning 化)
3. **Codex の hook 非対応** を明示するが、Phase 1 §9.4 の補完関係図と整合させる (SAGE = rules/templates/governance、Claude Code = hooks runtime、Codex = 別 sandbox config)

### TASK 順序と依存
1. TASK-0101 (test harness) → 他全 TASK の前提
2. TASK-0102 (shellcheck CI) → TASK-0101 と並列可、CI workflow のみ変更
3. TASK-0103 (block-dangerous 拡張) → TASK-0101 完了後 (test で regression 検出)
4. TASK-0104 (protect-sage 拡張) → TASK-0101 完了後
5. TASK-0105 (doctrine clarify) → 並列可、doc のみ

## タスク分解

| TASK-ID | 責務 | 担当Agent | 見積 | 依存TASK | 並列可否 |
|---------|------|----------|------|---------|---------|
| TASK-0101 | hook test harness + 既存 5 hooks に smoke test 各 1-3 ケース | Implementation/Test | 90m | none | Yes (start first) |
| TASK-0102 | sage-structural-gate.yml に shellcheck step 追加 | Implementation | 30m | none | Yes |
| TASK-0103 | block-dangerous-commands.sh 拡張 (chain長/redirection/interpreter -c file write/Unicode) + test 追加 | Implementation | 75m | TASK-0101 | No |
| TASK-0104 | protect-sage-files.sh 拡張 (content 検査: bypassPermissions / CODEX_HOME / ANTHROPIC_BASE_URL / mcp_servers) + test 追加 | Implementation | 75m | TASK-0101 | No |
| TASK-0105 | AGENTS.md + sage/governance.md §9.2 に Codex specificity 明記 | Implementation | 30m | none | Yes |

## リスク

- リスク1: install.sh embedded hook の test も含めるかで size 肥大化 → 含めない (test は repo にのみ存在、install.sh には実 hook のみ embed)
- リスク2: macOS / Linux で shellcheck version 差異 → CI は GitHub-hosted ubuntu-latest (deterministic), local は best-effort
- リスク3: protect-sage-files の content 検査で base64 / chunked write を完全には防げない → SECURITY.md / governance §9.2 に「pattern matching の限界」として記載 (Codex R3 と同根)
- リスク4: AGENTS.md 修正が Phase 1 で human-approved meta change として実施したのと同様、protect-sage-files hook 自体に block されないこと確認

## 必要な検証

- [x] structural: shellcheck templates/hooks/*.sh
- [x] structural: bash scripts/sage-validate.sh
- [x] structural: bash scripts/sage-doctor.sh
- [x] functional: bash templates/hooks/tests/run-tests.sh (PASS)
- [x] functional: 各新規 pattern の positive (block) + negative (allow) ケース確認
- [x] functional: bash install.sh --dry-run (Phase 1 regression 確認)
- [x] doc consistency: AGENTS.md / governance §9 / SECURITY.md の Codex 言及が矛盾しない
- [x] AC-01〜AC-15 全件 (SPEC-0011 受け入れ条件)
