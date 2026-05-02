# TASK-0151: SPEC-0023 + PLAN-0023 + 5 TASK draft + sage-evaluate 100/100 PASS

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0151 |
| SPEC-ID   | SPEC-0023 |
| PLAN-ID   | PLAN-0023 |
| ステータス | Pending |
| 担当Agent | Spec / Planning |
| 並列可否  | No (foundation) |
| 依存TASK  | none |
| 見積     | 60m |

## 責務

SPEC-0022 が意図的に未対応で残した Claude side の paired update を SPEC-0023 として起票し、PLAN + 5 TASK draft を sage-evaluate で 100/100 まで仕上げて Specify phase commit する。

## 入力

- SPEC-0022 (Codex Delegation Packet、本 SPEC の paired counterpart)
- 8 件 Notion 教材 (Codex / Claude Code 役割分担、collaboration vs delegation)
- Claude SPEC-0022 review report (Major #2 「AGENTS.md / CLAUDE.md semantic alignment intentional break, no follow-up TASK」が本 SPEC の起票根拠)

## 出力

1. `specs/SPEC-0023-claude-collaboration-pairing.md`
2. `plans/PLAN-0023-claude-collaboration-pairing.md`
3. `tasks/TASK-0151..0155-*.md` (5 file)

## File Scope（変更許可範囲）

- 作成: `specs/SPEC-0023-claude-collaboration-pairing.md`
- 作成: `plans/PLAN-0023-claude-collaboration-pairing.md`
- 作成: `tasks/TASK-0151-spec-plan-task-draft.md`
- 作成: `tasks/TASK-0152-claude-collaboration-brief-doc.md`
- 作成: `tasks/TASK-0153-claude-md-snippet-doctrine-update.md`
- 作成: `tasks/TASK-0154-governance-installer-version.md`
- 作成: `tasks/TASK-0155-paired-test-and-verification.md`

## 禁止事項

- SPEC-0022 が確定済の AGENTS.md / docs/codex-delegation-packet.md / agents-md-snippet.md を本 TASK で修正しない
- sage-evaluate スコアが 100 未満で commit しない
- TASK 番号を重複させない (TASK-0149/0150 は SPEC-0022 PR #28 で利用済の可能性、TASK-0151 から開始)

## 完了条件

- [ ] SPEC-0023 / PLAN-0023 / TASK-0151..0155 全 7 file 作成
- [ ] sage-evaluate skill で SPEC-0023 + PLAN-0023 採点 → 100/100 (S++) PASS
- [ ] Specify phase commit message に `TASK-0151: SPEC-0023 + PLAN-0023 + 5 TASK draft (sage-evaluate 100/100 PASS, paired with SPEC-0022)` 含む
- [ ] commit に SPEC/PLAN/5 TASK ファイル全てが staged
