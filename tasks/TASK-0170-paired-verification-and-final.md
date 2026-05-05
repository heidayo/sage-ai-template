# TASK-0170: paired-verification + RUN-0009 + final verification

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0170 |
| SPEC-ID   | SPEC-0024 |
| PLAN-ID   | PLAN-0024 |
| ステータス | Pending |
| 担当Agent | Test Agent (paired-verification) + Implementation (final regen) |
| 並列可否  | No (最終検証) |
| 依存TASK  | TASK-0169 |
| 見積     | 45m |

## 責務

最終検証 + RUN-0009 採番 + paired-update doctrine 検証 (SPEC-0023 §10 doctrine の 2 例目として記録)。

## 入力

- SPEC-0024 全 AC (AC-01..AC-20)
- TASK-0162..0169 の完了状態
- 既存 templates/hooks/tests/test-claude-collaboration-pairing.sh (paired-update doctrine 検証、流用)
- 既存 scripts/sage-doctor.sh / sage-validate.sh / sage-doc-drift.sh

## 出力

### .sage/runs/RUN-0009.yaml (新規)

```yaml
run_id: RUN-0009
spec_id: SPEC-0024
plan_id: PLAN-0024
task_ids: [TASK-0161, TASK-0162, TASK-0163, TASK-0164, TASK-0165, TASK-0166, TASK-0167, TASK-0168, TASK-0169, TASK-0170]
runtime: claude-code
agent_id: spec-implementation-test-paired
status: pass
gate_results:
  structural: pass
  functional: pass
  security: pass
  architecture: pass
  release: skipped  # main/production PR で発火、本 PR は feature branch
verdict: PASS
ac_results:
  ac_01_through_ac_20: pass  # 全 20 AC PASS
properties_applied:
  count: (pilot 3 SPEC × 5+ Property = 15+)
paired_update_doctrine_evidence: SPEC-0023 §10 の 2 例目 (本 SPEC が SPEC-0023 doctrine を踏襲)
codex_review_feedback_iteration: round 1 (本 outline で 6 点既反映、実装後追加 round 想定)
notes:
  - SPEC-0024 が SPECA framework (https://github.com/NyxFoundation/speca/) を一次採用
  - 既存 SPEC retrofit は pilot 3 件 (SPEC-0011/0014/0015) のみ、incremental migration
  - 既存 FAIL-0001 cause field は未追加 (Codex review feedback 5 準拠、推定 retrofit 禁止)
```

### paired-update doctrine 検証

既存 `bash templates/hooks/tests/test-claude-collaboration-pairing.sh` を流用し、CLAUDE.md / AGENTS.md / claude-md-snippet.md / agents-md-snippet.md の SPEC-0024 reference 同期を検証 (新 hook 不要、既存 hook の grep 範囲拡張のみ)。

具体的には以下を検証:
- `grep -F "Property-based Verify" CLAUDE.md && grep -F "Property-based Verify" AGENTS.md` (両者に存在)
- `diff <(grep -A3 "Property-based Verify" CLAUDE.md) <(grep -A3 "Property-based Verify" AGENTS.md)` で 0 行 (semantic 完全一致)
- `grep -F "Properties section" templates/claude-md-snippet.md && grep -F "Properties section" templates/agents-md-snippet.md`

### final verification

```bash
bash templates/hooks/tests/run-tests.sh           # 195+ PASS
bash templates/hooks/tests/test-property-section.sh  # 8+ PASS
bash templates/hooks/tests/test-claude-collaboration-pairing.sh  # paired test PASS
bash scripts/sage-validate.sh                     # PASS
bash scripts/sage-doctor.sh                       # 0 FAIL
bash scripts/sage-doc-drift.sh                    # PASS
bash scripts/generate-installer.sh > /tmp/new.sh && diff install.sh /tmp/new.sh  # 0 行
shellcheck templates/hooks/tests/test-property-section.sh scripts/generator/03-rules.sh scripts/generator/07-installer-main.sh  # error 0 件
gitleaks detect --source .                        # PASS (secret なし)
```

### SPEC-0024 / PLAN-0024 / TASK-0161..0170 status update

| File | Before | After |
|---|---|---|
| specs/SPEC-0024 | Draft | Review |
| plans/PLAN-0024 | Draft | Review |
| tasks/TASK-0161..0170 | Pending / In Progress | Done |

## File Scope（変更許可範囲）

- 作成: `.sage/runs/RUN-0009.yaml`
- 変更: `specs/SPEC-0024-property-based-verify-review-gate.md` (status field のみ)
- 変更: `plans/PLAN-0024-property-based-verify-review-gate.md` (status field のみ)
- 変更: `tasks/TASK-0161-*.md` 〜 `tasks/TASK-0170-*.md` (status field のみ)

## 禁止事項

- TASK-0162..0169 の他 field (File Scope / 完了条件 / 禁止事項) を変更しない (status のみ)
- install.sh を本 TASK で再生成しない (TASK-0169 で完了済)
- SHA256SUMS を本 TASK で書き換えない (release tag push 時、本 PR は feature branch)
- AC-01..AC-20 のいずれか fail の状態で status: Review に変更しない (回帰防止)
- RUN-0009.yaml に secret / token / API key を含めない (R5)
- 新 hook を作成しない (既存 test-claude-collaboration-pairing.sh 流用、SPEC-0024 scope 維持)
- pilot 3 件以外の SPEC を本 TASK で変更しない (TASK-0167 で完了、本 TASK は status のみ)

## 完了条件

- [ ] `.sage/runs/RUN-0009.yaml` 存在 + RUN-0009 / SPEC-0024 / 10 TASK-ID 含む
- [ ] SPEC-0024 / PLAN-0024 status = Review
- [ ] TASK-0161..0170 status = Done
- [ ] `bash templates/hooks/tests/run-tests.sh` 195+ PASS
- [ ] `bash templates/hooks/tests/test-property-section.sh` 8+ PASS
- [ ] `bash templates/hooks/tests/test-claude-collaboration-pairing.sh` PASS (paired-update doctrine 検証)
- [ ] `bash scripts/sage-doctor.sh` 0 FAIL
- [ ] `bash scripts/sage-doc-drift.sh` PASS
- [ ] `bash scripts/sage-validate.sh` PASS
- [ ] `gitleaks detect --source .` で 0 secret
- [ ] `bash scripts/generate-installer.sh > /tmp/new.sh && diff install.sh /tmp/new.sh` 0 行
- [ ] AC-01..AC-20 全件 PASS (各 AC 検証コマンドを RUN-0009.yaml に記録)
- [ ] commit message に `TASK-0170:` 含む
