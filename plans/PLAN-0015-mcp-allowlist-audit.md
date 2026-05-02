# PLAN-0015: MCP allowlist audit (supply-chain pinned) — implementation plan

## メタデータ

| フィールド | 内容 |
|-----------|------|
| PLAN-ID   | PLAN-0015 |
| SPEC-ID   | SPEC-0015 |
| ステータス | Draft (Codex Specify-phase review 反映済) |
| 作成日    | 2026-05-02 |
| 担当Agent | Planning Agent |

## SPEC からの落とし込み方針

SPEC-0015 (Codex review 後 scope 縮小、agent identity は SPEC-0017 に分離) の 6 機能要件 (FR-01..FR-06) を独立性が高い 4 TASK に分割する。

**設計上の判断 (Codex review 1st + 2nd 反映)**:
- registry schema は **JSON 形式** (Python stdlib `json` で安定 parse、awk-based shape comparison 不採用)
- **transport-aware** (Codex review 2nd P1 反映): `transport: "stdio" | "http"` を必須化、HTTP MCP は `url` / `url_origin_pin` / `bearer_token_env_var` 等の独立 field
- **artifact_type 区別** (Codex review 2nd P2-1 反映): `npm_package` (npm_integrity 第一級) / `local_binary` (command_path_sha256) / `remote_http` (tls_pin_sha256 optional)
- supply-chain pin field 必須化 (version_pin / publisher / source_registry / npm_integrity)
- audit hook の default 比較対象は **repo-local config** のみ、user-global `~/.codex/config.toml` は opt-in
- audit log で **args / bearer_token_env_var の値を redact** (env name のみ記録)
- Performance test helper は **Python ベース** (Codex review 2nd P2-3 反映、`/usr/bin/time -f` macOS 不対応問題回避)
- Detection-only behavior test は **fake wrapper 方式** (Codex review 2nd P2-2 反映、grep / `ps aux` 方式の false positive/negative 回避)

## 影響レイヤー

| レイヤー | 影響 |
|---|---|
| `templates/sage/` (新規) | registry の JSON template |
| `templates/hooks/` | 新 hook 1 つ追加 (`mcp-allowlist-audit.sh`) |
| `templates/hooks/tests/` | 新 test 1 つ追加 + performance test helper 1 つ追加 |
| `scripts/` | `sage-doctor.sh` 拡張 (`sage-validate.sh` の RUN log validator 拡張は SPEC-0017 へ移動) |
| `.claude/settings.json` template | SessionStart hook に `mcp-allowlist-audit.sh` 追加 (standard profile) |
| `install.sh` | 上記 templates の embed |
| 5 文書ファイル | doc cross-reference 追加 (各最大 +3 行) |

## 影響スコープ

- **MCP runtime side**: なし (SAGE doctrine §9.2 維持、本 SPEC は audit-only / runtime-process-safe)
- **Hook side**: SessionStart hook に 1 つ追加。既存 7 hook と共存
- **Doctor side**: 新 step 追加、既存 step に影響なし
- **RUN log side**: 影響なし (SPEC-0017 で別途、本 SPEC スコープ外)

## TASK 分割 (4 TASK、SPEC-0017 分離後)

| TASK | 責務 | FR/AC mapping | 依存 | 並列可 | 見積 |
|---|---|---|---|---|---|
| TASK-0122 | MCP allowlist registry schema + JSON template (`templates/sage/mcp-allowlist-template.json`) | FR-01, FR-02 / AC-01 | - | No (foundation) | 30m |
| TASK-0123 | MCP allowlist audit hook (transport-aware) + tests (17 シナリオ) + Python performance test helper | FR-03, FR-05 / AC-02, AC-03, AC-05, AC-07, AC-11, AC-12, AC-13, NFR-01..NFR-09 | TASK-0122 | No | 150m (Codex 2nd review P1 transport-aware + P2 Python helper / fake wrapper で +30m) |
| TASK-0124 | sage-doctor.sh に MCP allowlist check 追加 + detection-only behavior test | FR-04 / AC-04, AC-09 | TASK-0123 (logic re-use) | No | 60m (旧 45m + behavior test で +15m) |
| TASK-0126 | Documentation 更新 (5 ファイル) + installer regeneration | FR-06 / AC-06, AC-08, AC-10 | TASK-0122..0124 | No (最後) | 45m |

合計見積: 285 min (4.75 h、Codex 2nd review 反映で TASK-0123 が +30m)
**TASK-0125 (agent identity) は本 PLAN から削除済 → SPEC-0017 へ移動**

## 依存グラフ

```
TASK-0122 (foundation, 30m)
    │
    ▼
TASK-0123 (audit hook + perf helper, 120m)
    │
    ▼
TASK-0124 (doctor + behavior test, 60m)
    │
    ▼
TASK-0126 (doc + installer regen, 45m)
```

シリアル実行 (旧 PLAN の TASK-0123 || TASK-0125 並列は SPEC-0017 分離で消滅)。総 wall-clock 時間は短縮 (270m → 255m + 並列消滅で実質変化なし)。

## 検証方法

| 検証 | 方法 |
|---|---|
| Unit test | `bash templates/hooks/tests/run-tests.sh` で 109 + 17 シナリオ = 126+ 全 PASS (transport-aware に拡張) |
| Integration test | `bash scripts/sage-doctor.sh` で MCP allowlist check が新ステップとして OK 返す |
| Performance | `python3 templates/hooks/tests/measure-hook-time.py templates/hooks/mcp-allowlist-audit.sh` で 5 回中央値 < 200ms (Python `time.perf_counter()` で macOS / Linux 互換、Codex review 2nd P2-3 反映) |
| Detection-only behavior | `bash templates/hooks/tests/test-detection-only-behavior.sh` で fake wrapper 方式 PASS (kill 系 wrapper 呼び出し 0 件、Codex review 2nd P2-2 反映で grep / `ps aux` 方式 完全廃止) |
| Doctrine alignment | `bash scripts/sage-doc-drift.sh` PASS |
| Doc cross-ref | `grep -rn "SPEC-0015\|mcp-allowlist-audit" SECURITY.md sage/governance.md AGENTS.md CLAUDE.md docs/codex-security.md` で各 1+ 件 |
| R7 increment check | `wc -l` で 5 文書ファイル各 +3 行以内 |
| Regression | Phase 1-3 hook tests 109/109 不変 (新 hook は独立ファイル) |
| JSON schema validity | `python3 -c "import json; json.load(open('templates/sage/mcp-allowlist-template.json'))"` |

## リスク

1. **registry schema field 過不足** — supply-chain pin field を多数追加したため registry 記入負荷が上がる。Mitigation: `policy.require_sha256: false` default で sha256 は推奨止まり、必須化は org 判断
2. **audit hook の SessionStart 遅延** — 200ms threshold (NFR-01) を満たさないと UX 劣化。Mitigation: Python parsing は `json.loads()` のみ (sha256 verification は optional + cache)
3. **既存 protect-sage-files との二重 warn** — 同じ mcp_servers 追加で両 hook が warn 出すと noise。Mitigation: protect-sage-files は **書き込み block**、本 hook は **session-start audit + supply-chain pin check** で発火 trigger 異なる、warn 文言を区別
4. **install.sh 再生成のタイミング** — 各 TASK で再生成するか TASK-0126 で一括か。Mitigation: TASK-0126 で一括 (Phase 3 の TASK-0117/0119 で経験した「install.sh 巻き戻し問題」回避)
5. **Python 依存の追加** — Phase 1-3 では shell only だったが、本 SPEC で Python stdlib 依存追加。Mitigation: `command -v python3` 失敗時 graceful skip (NFR-03)、既に CI/macOS/Linux で標準環境

## Cross-model adversarial review 計画

Phase 1-3 で確立した cross-model adversarial review pattern を本 SPEC でも厳密適用。

### Phase 1-3 確立 doctrine の本 SPEC への適用

| Doctrine | 本 SPEC での適用 |
|---|---|
| **R1** (no branch protection auto-config) | 本 SPEC で branch protection / Ruleset を触らない |
| **R2** (sandbox_mode template only, runtime change なし) | 本 SPEC は audit-only、MCP runtime / process 起動は SAGE 範囲外 (governance §9.2 維持)。`audit-first` / `runtime-process-safe` 用語で精緻化 (Codex review continued doctrine 反映) |
| **R3** (Lethal Trifecta warn-only) | 本 SPEC の drift detection も warn-only ベース、strict profile のみ block (drift1 / drift5)。R3 と同方向 |
| **R4** (no SecPass thresholds) | 本 SPEC で「100% drift 0 必須」のような硬い閾値を設定しない。OPS-05 の昇格条件は運用 doctrine、強制ではない |
| **R5** (RUN log redaction first) | 本 SPEC の audit log は drift event 集計用、args は **redact** (Codex review P2 反映)、secret 漏洩防止 |
| **R6** (license vs security 分離) | 本 SPEC は security 専念 |
| **R7** (CLAUDE/AGENTS 肥大化禁止) | TASK-0126 で AGENTS / CLAUDE 各 +1 行のみ、長文は SPEC + docs/codex-security.md (§2 末尾 1 行) に集約 |
| **R8** (hook tests required) | TASK-0123 で 13 シナリオ test 必須、test 抜きの hook 追加禁止 |
| **R9** (shellcheck required) | TASK-0123 で `mcp-allowlist-audit.sh` に shellcheck error 0 件必須 |
| **R10** (一次ソース引用) | OWASP Agentic Skills Top 10 / OpenAI Codex config reference / SAGE governance §9.2 を一次ソースとして引用 |

### Review プロセス

1. **Specify phase** (本 PR #21): SPEC + PLAN + 4 TASK draft → sage-evaluate 100 点 → **Codex Specify-phase review** (本回で実施済、6 finding 全反映) → user 承認
2. **Implementation phase** (PR #22+ 想定): TASK-0122 → 0123 → 0124 → 0126 の順で実装
3. **Codex implementation review**: 実装 PR 完了後、Phase 3 と同 format で Codex に依頼
4. **Multi-round 収束**: 必要に応じて micro-round を繰り返す
5. **CONVERGED 判定**: 下記 exit criteria 達成 → main merge

### Exit criteria (収束件数予測ではなく明示判定基準、Codex review P3 反映)

実装 PR の Codex review が収束したと判定する基準:

- [ ] **P1 (critical) 0 件**
- [ ] **P2 (should fix) 0 件**
- [ ] **P3 (nit) は明示 accept** — 各 P3 finding に対し「accept (理由)」または「fix」の判断を PR コメントで明記
- [ ] **R7 regression なし** — `wc -l SECURITY.md sage/governance.md AGENTS.md CLAUDE.md docs/codex-security.md` で 5 文書の合計増分 ≤ +15 行
- [ ] **R10 regression なし** — 全 claim に primary source URL 紐付き、二次ソース推測なし

### 失敗時のエスカレーション

5 round 経過しても新 P2 以上の finding が出続ける場合:
1. SPEC を draft に戻し、Spec Agent で再設計
2. `sage/failures.md` に「FAIL-SPEC-0015-DESIGN-ITERATION」として記録
3. user に方針相談 (本 SPEC の scope 更なる縮小 / 別 SPEC への分割等)

## 完了条件 (Plan レベル)

- [ ] SPEC-0015 の AC-01..AC-13 全件達成
- [ ] 4 TASK 全 commit に TASK-ID 含有、Phase 1-3 と同 pattern
- [ ] PR description に SPEC-0015 / PLAN-0015 / TASK-0122/0123/0124/0126 全 link
- [ ] Codex implementation review が exit criteria 全 ✅ で収束
