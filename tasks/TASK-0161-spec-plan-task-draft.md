# TASK-0161: SPEC-0024 + PLAN-0024 + 10 TASK draft + sage-evaluate 100/100 PASS

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0161 |
| SPEC-ID   | SPEC-0024 |
| PLAN-ID   | PLAN-0024 |
| ステータス | Done |
| 担当Agent | Spec Agent |
| 並列可否  | No (foundation) |
| 依存TASK  | none |
| 見積     | 75m |

## 責務

SPEC-0024 / PLAN-0024 / 10 TASK file を draft + Codex review feedback (6 点) 全反映 + sage-evaluate 100/100 PASS させる。

## 入力

- Notion ソース: SPECA フレームワーク要点 ([https://www.notion.so/cce3f82cbe07449ebb355f4f531bf89e](https://www.notion.so/cce3f82cbe07449ebb355f4f531bf89e))
- GitHub ソース: [NyxFoundation/speca](https://github.com/NyxFoundation/speca/) (CLAUDE.md / scripts/orchestrator/ / prompts/)
- Paper: [arXiv:2604.26495](https://arxiv.org/abs/2604.26495) Beyond Code Reasoning
- Codex review feedback (本 SPEC outline review、6 点修正要求済)
- 既存 SPEC-0007 / SPEC-0011 / SPEC-0014 / SPEC-0015 / SPEC-0023 (依存・参照)
- 既存 templates/skills/sage-review/SKILL.md (拡張対象)
- 既存 sage/failures.md (cause field 追加対象)
- 既存 sage/governance.md (§11 新節)

## 出力

- `specs/SPEC-0024-property-based-verify-review-gate.md` (Draft、20 AC、10 リスク、Codex 6 点反映済)
- `plans/PLAN-0024-property-based-verify-review-gate.md` (Draft、10 TASK、依存グラフ、4 stream 並列計画)
- `tasks/TASK-0161-*.md` 〜 `tasks/TASK-0170-*.md` (10 file)
- sage-evaluate 100/100 (`bash scripts/sage-evaluate.sh specs/SPEC-0024-*.md plans/PLAN-0024-*.md`)

## File Scope（変更許可範囲）

- 作成: `specs/SPEC-0024-property-based-verify-review-gate.md`
- 作成: `plans/PLAN-0024-property-based-verify-review-gate.md`
- 作成: `tasks/TASK-0161-spec-plan-task-draft.md` (本ファイル)
- 作成: `tasks/TASK-0162-template-and-governance.md`
- 作成: `tasks/TASK-0163-claude-md-and-snippet.md`
- 作成: `tasks/TASK-0164-agents-md-and-snippet.md`
- 作成: `tasks/TASK-0165-review-skill-fp-filter.md`
- 作成: `tasks/TASK-0166-failures-cause-additive.md`
- 作成: `tasks/TASK-0167-pilot-retrofit.md`
- 作成: `tasks/TASK-0168-test-property-section-hook.md`
- 作成: `tasks/TASK-0169-installer-and-version-bump.md`
- 作成: `tasks/TASK-0170-paired-verification-and-final.md`

## 禁止事項

- 既存 SPEC-0001..0023 の本文を本 TASK で変更しない (Foundation phase は draft のみ)
- 既存 sage/failures.md の FAIL-0001 を変更しない (Codex review 反映済)
- AGENTS.md / CLAUDE.md / 既存 hook test を本 TASK で変更しない (TASK-0163/0164/0168 で実施)
- pilot retrofit (SPEC-0011/0014/0015) を本 TASK で実施しない (TASK-0167)
- install.sh を本 TASK で再生成しない (TASK-0169)
- 推測で TASK-ID を増減しない (10 TASK 固定、scope 変更時は SPEC 改訂)

## 完了条件

- [x] `specs/SPEC-0024-property-based-verify-review-gate.md` に SPEC-ID / 依存 SPEC / 全 20 AC / 10 リスク / Codex 6 点修正反映
- [x] `plans/PLAN-0024-property-based-verify-review-gate.md` に 10 TASK 表 + 依存グラフ + 並列実行計画
- [ ] `tasks/TASK-0161..0170-*.md` 10 file 作成、各々 File Scope 明示
- [ ] `/sage-evaluate specs/SPEC-0024-*.md plans/PLAN-0024-*.md` skill で 100/100 PASS (採点 + 構造化フィードバック、`templates/skills/sage-evaluate` ワークフロー経由)
- [ ] commit message に `TASK-0161:` 含む
- [ ] feature branch 上で実施 (`feature/spec-0024-property-based-verify-review-gate`)
