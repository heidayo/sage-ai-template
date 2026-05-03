# TASK-0155: test-claude-collaboration-pairing.sh + RUN log + final verification

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0155 |
| SPEC-ID   | SPEC-0023 |
| PLAN-ID   | PLAN-0023 |
| ステータス | Done |
| 担当Agent | Test |
| 並列可否  | No (TASK-0152, TASK-0153, TASK-0154 完了後) |
| 依存TASK  | TASK-0152, TASK-0153, TASK-0154 |
| 見積     | 60m |

## 責務

SPEC-0023 全成果物を検証する hook test を新規作成し、RUN log を記録、final verification を実施する。

## 入力

- SPEC-0023 §「機能要件」FR-07 (7 シナリオ)、§「受け入れ条件」AC-11/AC-16/AC-17
- TASK-0152 の `docs/claude-collaboration-brief.md`
- TASK-0153 の CLAUDE.md / AGENTS.md / claude-md-snippet.md 更新
- TASK-0154 の sage/governance.md §10 + installer + install.sh
- 既存 `templates/hooks/tests/run-tests.sh` (test runner)
- 既存 `templates/hooks/tests/test-codex-delegation-packet.sh` (パターン参照)

## 出力

### `templates/hooks/tests/test-claude-collaboration-pairing.sh` (新規、約 130-180 行)

7 scenarios + 2 異常系 fixture (合計 9 scenario):

1. **Scenario 1**: docs/claude-collaboration-brief.md 必須 7 セクション全存在 (FR-01)
2. **Scenario 2**: CLAUDE.md に collaboration brief reference (`docs/claude-collaboration-brief.md`) 存在
3. **Scenario 3**: CLAUDE.md に Codex-specific files boundary 文言存在
4. **Scenario 4**: claude-md-snippet.md に parallel 2 bullets 存在
5. **Scenario 5**: CLAUDE.md ↔ AGENTS.md doctrine semantic alignment (両者「may diverge」「SPEC-0023」を含む)
6. **Scenario 6**: governance.md §10「AI Agent Doc Pairing Doctrine」存在 + Shared/CLI-specific/Paired-update/Drift 4 bullet 含む
7. **Scenario 7**: install.sh に `TMPL_CLAUDE_COLLABORATION_BRIEF` 埋め込み + `docs/claude-collaboration-brief.md` write/update path 存在
8. **Scenario 8 (異常系 AC-16)**: CLAUDE.md doctrine 文言を mock で削除した state を simulate し、test scenario 5 が FAIL を返すことを確認 (in-memory mutation、git working tree 不変)
9. **Scenario 9 (異常系 AC-17)**: docs/claude-collaboration-brief.md の必須セクション「## Codex Handoff Triggers」を mock で rename した state を simulate し、test scenario 1 が FAIL を返すことを確認

### `.sage/runs/RUN-0008.yaml` (新規)

SPEC-0023 implementation の RUN log:
- run_id: RUN-0008
- task_id: TASK-0155
- agent_id: implementation
- runtime: claude-code
- tool_runtime: claude-code-2.x
- approval_policy: on-request (Claude Code 推奨)
- network_mode: off (Claude Code 推奨)
- gate_results: 全 PASS
- error_log: SPEC-0023 implementation summary

### Final verification

- [ ] `bash templates/hooks/tests/test-claude-collaboration-pairing.sh` 9/9 PASS
- [ ] `bash templates/hooks/tests/run-tests.sh` 全 PASS (180 既存 + 9 新規 = 189+)
- [ ] `bash scripts/sage-validate.sh` PASS (Check 9 MISMATCH WARN は許容、main 以外のため)
- [ ] `bash scripts/sage-doctor.sh` 0 FAIL (after `bash install.sh --update`)
- [ ] `bash scripts/sage-doc-drift.sh` PASS
- [ ] `bash scripts/sage-runlog-validate.sh .sage/runs/RUN-0008.yaml` PASS
- [ ] `shellcheck templates/hooks/tests/test-claude-collaboration-pairing.sh` PASS

## File Scope（変更許可範囲）

- 作成: `templates/hooks/tests/test-claude-collaboration-pairing.sh`
- 作成: `.sage/runs/RUN-0008.yaml`

## 禁止事項

- TASK-0152..0154 の成果物 (docs / CLAUDE.md / AGENTS.md / snippet / governance / generator / install.sh) を本 TASK で修正しない
- test を `set +e` で誤魔化さない (実際の exit code を確認)
- 異常系 fixture (Scenario 8/9) で git working tree を mutate しない (in-memory 文字列操作のみ)
- shellcheck error を残さない (R9)
- RUN-0008.yaml に secret / credential / `.env` 例値を含めない
- RUN-0008.yaml の `runtime` field を「unknown」「codex-cli」等に偽装しない (実態は claude-code、SPEC-0017 準拠)
- 失敗した検証を RUN log で `pass` と記録しない

## 完了条件

- [ ] `templates/hooks/tests/test-claude-collaboration-pairing.sh` 9/9 PASS (`bash templates/hooks/tests/test-claude-collaboration-pairing.sh; echo $?` で 0)
- [ ] `bash templates/hooks/tests/run-tests.sh` 全 PASS (180 既存 + 9 新規 = 189 scenarios)
- [ ] `.sage/runs/RUN-0008.yaml` 存在し `bash scripts/sage-runlog-validate.sh` PASS
- [ ] `bash scripts/sage-doctor.sh` 0 FAIL (after install.sh --update)
- [ ] `bash scripts/sage-doc-drift.sh` PASS
- [ ] `bash scripts/sage-validate.sh` PASS
- [ ] `shellcheck templates/hooks/tests/test-claude-collaboration-pairing.sh` 0 errors
- [ ] commit message に `TASK-0155:` 含む
