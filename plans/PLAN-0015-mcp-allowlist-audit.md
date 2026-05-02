# PLAN-0015: MCP allowlist audit + agent identity inventory — implementation plan

## メタデータ

| フィールド | 内容 |
|-----------|------|
| PLAN-ID   | PLAN-0015 |
| SPEC-ID   | SPEC-0015 |
| ステータス | Draft |
| 作成日    | 2026-05-02 |
| 担当Agent | Planning Agent |

## SPEC からの落とし込み方針

SPEC-0015 の 6 機能要件 (FR-01..FR-06) を独立性が高い 5 TASK に分割する。各 TASK は単一責務を持ち、並列実行可能なものは並列マークを付ける。

**設計上の判断**:
- registry schema (TASK-0122) を **最初に確定** させ、以後の TASK が schema を前提に書ける状態を作る (依存基盤)
- audit hook (TASK-0123) と inventory (TASK-0125) は schema 完成後 **並列開発可能**
- doctor 拡張 (TASK-0124) は audit hook の logic を re-use する形にする (DRY)
- documentation 更新 (TASK-0126) は **最後にまとめて** 行う (実装が確定してから書かないと drift する)

## 影響レイヤー

| レイヤー | 影響 |
|---|---|
| `templates/sage/` (新規) | registry / inventory の YAML template |
| `templates/hooks/` | 新 hook 1 つ追加 (`mcp-allowlist-audit.sh`) |
| `templates/hooks/tests/` | 新 test 1 つ追加 |
| `scripts/` | `sage-doctor.sh` 拡張、`sage-validate.sh` (RUN log validator) 拡張 |
| `.claude/settings.json` template | SessionStart hook に `mcp-allowlist-audit.sh` 追加 (standard profile) |
| `install.sh` | 上記 templates の embed (生成された `install.sh` で配布) |
| `SECURITY.md` / `sage/governance.md` / `AGENTS.md` / `CLAUDE.md` / `docs/codex-security.md` | 文書更新 (各最大 +3 行) |

## 影響スコープ (機能 / モジュール)

- **MCP runtime side**: なし (SAGE doctrine §9.2 維持、本 SPEC は audit-only)
- **Hook side**: SessionStart hook に 1 つ追加。既存 7 hook と共存
- **Doctor side**: 新 step 追加、既存 step に影響なし
- **RUN log side**: validator が「inventory に declared か」を warn する path 追加。既存 RUN log データ構造は不変

## TASK 分割

| TASK | 責務 | FR/AC mapping | 依存 | 並列可 | 見積 |
|---|---|---|---|---|---|
| TASK-0122 | MCP allowlist registry schema + template (`templates/sage/mcp-allowlist-template.yaml`) | FR-01 / AC-01 | - | No (最初) | 30m |
| TASK-0123 | MCP allowlist audit hook + tests (`templates/hooks/mcp-allowlist-audit.sh` + `tests/test-mcp-allowlist-audit.sh`) | FR-02 / AC-02, AC-03, NFR-01, NFR-02, NFR-03, NFR-05 | TASK-0122 | Yes (with TASK-0125) | 90m |
| TASK-0124 | sage-doctor.sh に MCP allowlist check 追加 | FR-03 / AC-04, AC-10 | TASK-0123 (logic re-use) | No | 45m |
| TASK-0125 | Agent identity inventory schema + template + RUN log validator 拡張 | FR-04, FR-05 / AC-05, AC-06 | TASK-0122 (schema 流儀) | Yes (with TASK-0123) | 60m |
| TASK-0126 | Documentation 更新 (5 ファイル) + installer regeneration | FR-06 / AC-07, AC-09, AC-11 | TASK-0122..0125 | No (最後) | 45m |

合計見積: 270 min (4.5 h)

## 検証方法

| 検証 | 方法 |
|---|---|
| Unit test | `bash templates/hooks/tests/run-tests.sh` で 109 + 新規 ≥ 7 = 116+ 全 PASS |
| Integration test | `bash scripts/sage-doctor.sh` で MCP allowlist check が新ステップとして OK 返す |
| Performance | `time bash templates/hooks/mcp-allowlist-audit.sh < /tmp/empty.json` < 200ms (AC-12) |
| Doctrine alignment | `bash scripts/sage-doc-drift.sh` PASS (CLAUDE/AGENTS 整合) |
| Doc cross-ref | `grep -rn "SPEC-0015\|mcp-allowlist-audit" SECURITY.md sage/governance.md AGENTS.md CLAUDE.md docs/codex-security.md` で各 1+ 件 |
| Regression | Phase 1-3 hook tests 109/109 不変 (新 hook は独立 ファイル) |

## リスク

1. **registry schema の field 過不足** — initial draft で多すぎる field を要求すると user 採用が遅れる。Mitigation: required field 6 個 + optional 3 個に抑える (SPEC FR-01)
2. **audit hook の SessionStart 遅延** — 200ms threshold (NFR-01) を満たさないと UX 劣化。Mitigation: registry parsing に awk 使用 (yq 依存しない)、Codex config check は `~/.codex/config.toml` 存在 conditional
3. **既存 protect-sage-files との二重 warn** — 同じ mcp_servers 追加で両 hook が warn 出すと noise。Mitigation: protect-sage-files は **書き込み block**、本 hook は **session-start audit** で発火 trigger が異なる、warn 文言を区別
4. **install.sh 再生成のタイミング** — 各 TASK で install.sh を再生成するか TASK-0126 で一括か。Mitigation: TASK-0126 で一括 (commit ノイズ削減、TASK-0117 / 0119 の install.sh 巻き戻し問題を回避)

## Cross-model adversarial review 計画

Phase 1-3 と同パターンで:
- 全 TASK 完了後 PR 作成 → Codex に review 依頼 (1st-round)
- 指摘が多 / 重要度高ければ Phase 2-3 と同じ multi-round 形式で収束
- Phase 3 の 6 round 収束パターンが先例として既にある

## 完了条件 (Plan レベル)

- [ ] SPEC-0015 の AC-01..AC-13 全件達成
- [ ] 5 TASK 全 commit に TASK-ID 含有、Phase 1-3 と同 pattern
- [ ] PR description に SPEC-0015 / PLAN-0015 / TASK-0122..0126 全 link
- [ ] Codex 1st-round review 完了 (収束は本 PLAN スコープ外、別ラウンド)
