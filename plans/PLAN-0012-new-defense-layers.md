# PLAN-0012: New Defense Layers (Phase 2B)

## メタデータ

| フィールド | 内容 |
|-----------|------|
| PLAN-ID   | PLAN-0012 |
| SPEC-ID   | SPEC-0012 |
| ステータス | Active |
| 作成日    | 2026-05-01 |
| 担当Agent | Planning Agent |

## 変更レイヤ

- [x] infra (templates/hooks/, templates/settings/, install.sh, generate-installer.sh)
- [x] CI (test harness 拡張、新 test files)
- [x] doc (sage/governance.md, SECURITY.md, templates/settings/README.md, .claude/settings.json)
- [ ] controller / usecase / domain / frontend / src (該当なし)

## 影響範囲

- **AI agent runtime**: 新 3 hooks が PreToolUse + Stop で動作。secret-read-multi-layer は Bash 拡張で false positive 0 確認必須 (Stop event 名は Claude Code 公式準拠、TASK-0112 で確定)
- **install workflow**: 新 hook 3 件 + sandbox.json + README が install.sh に embed されサイズ +5-8 KB 程度想定
- **Claude Code settings**: `.claude/settings.json` の `hooks` 配列が拡張 (既存 hooks 全保持)
- **影響を受けない**: 既存 hook 5 件本体 (Phase 2A で完了)、Phase 1 install.sh 機能、CLAUDE.md/AGENTS.md (新 §2.1 のみ既存)

## 実装方針

### 全体方針
1. **Codex review R3 厳守**: lethal-trifecta は warn-only (block 禁止)
2. **Codex review R2 整合**: sandbox.json は **template** であり SAGE 自身は適用しない (`templates/settings/README.md` で明記)
3. **Phase 2A test harness 全面活用**: 新 3 hooks すべてに test ファイル + smoke level

### TASK 順序と依存
1. TASK-0107 (lethal-trifecta) → 並列可、状態管理が独立
2. TASK-0108 (secret-read) → 並列可、独立 hook
3. TASK-0109 (security-filter) → 並列可、Stop hook で全 RUN log scan
4. TASK-0110 (sandbox.json + README) → 並列可、純 doc/JSON
5. TASK-0111 (.claude/settings.json + governance + SECURITY.md + install.sh 再生成) → 全 TASK 後

## タスク分解

| TASK-ID | 責務 | 担当Agent | 見積 | 依存TASK | 並列可否 |
|---------|------|----------|------|---------|---------|
| TASK-0107 | lethal-trifecta-detect.sh (warn-only) + test + 状態管理 .sage/runtime/ | Implementation/Test | 90m | none | Yes |
| TASK-0108 | secret-read-multi-layer.sh + test (cat .env / printenv | grep / SSH key 直接 read) | Implementation/Test | 60m | none | Yes |
| TASK-0109 | security-filter.sh (Stop hook、全 RUN log を per-file atomic redact) + test (sk-/ghp_/xox/AKIA + idempotent + multi-file) | Implementation/Test | 75m | none | Yes |
| TASK-0110 | templates/settings/sandbox.json + README.md | Implementation | 45m | none | Yes |
| TASK-0111 | .claude/settings.json + governance §9.1 + SECURITY.md §3 + install.sh 再生成 + .gitignore (.sage/runtime/) | Implementation | 60m | TASK-0107..0110 | No |

## リスク

- リスク1: lethal-trifecta が session 跨ぎ状態管理で `.sage/runtime/` 新規 dir を作る → `.gitignore` に entry 追加 (Phase 2A の `.sage/runs/` 教訓: installer に embed しない、手動明示のみ)
- リスク2: security-filter.sh の atomic write が partial failure で RUN log 破損 → trap + 失敗時 rollback、test で induced failure 検証
- リスク3: sandbox.json の denyRead が現実の dev workflow を壊す可能性 → README で「最小推奨、user 環境で削るべき」明記
- リスク4: hook が増えて Claude Code session start が遅延 → 各 hook に early exit (profile=minimal/none で skip)、合計実行時間を test で計測

## 必要な検証

- [x] structural: shellcheck templates/hooks/*.sh
- [x] structural: bash scripts/sage-validate.sh
- [x] structural: bash scripts/sage-doc-drift.sh
- [x] structural: bash scripts/sage-doctor.sh
- [x] structural: jq . templates/settings/sandbox.json (valid JSON)
- [x] functional: bash templates/hooks/tests/run-tests.sh (PASS, +6-9 new cases)
- [x] functional: bash install.sh --dry-run (regression)
- [x] functional: security-filter idempotent (run twice, same output)
- [x] doc consistency: governance §9.1 / SECURITY.md / templates/settings/README.md
- [x] AC-01〜AC-15 全件 (SPEC-0012 受け入れ条件)
