# TASK-0150: Codex review follow-up fixes

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0150 |
| SPEC-ID   | SPEC-0022 |
| PLAN-ID   | PLAN-0022 |
| ステータス | Done |
| 担当Agent | Implementation |
| 並列可否  | No |
| 依存TASK  | TASK-0148 |
| 見積     | 45m |

## 責務

Claude review で指摘された SPEC-0022 の Major / Minor / Nit を、Codex 側の範囲に限って反映する。

## 入力

- Claude Review findings for SPEC-0022
- TASK-0145..0149 の成果物

## 出力

- RUN log runtime 注記の明確化
- Claude 側 follow-up artifact の追加
- Codex Delegation Packet の example / future extension 追記
- Claude-specific diff test の false positive 低減
- installer 再生成と checksum 更新

## File Scope（変更許可範囲）

- 変更: `specs/SPEC-0022-codex-delegation-packet.md`
- 変更: `plans/PLAN-0022-codex-delegation-packet.md`
- 変更: `tasks/TASK-0148-codex-delegation-tests.md`
- 作成: `tasks/TASK-0149-claude-delegation-followup.md`
- 作成: `tasks/TASK-0150-codex-review-followup.md`
- 変更: `docs/codex-delegation-packet.md`
- 変更: `AGENTS.md`
- 変更: `templates/agents-md-snippet.md`
- 変更: `scripts/generator/07-installer-main.sh`
- 変更: `templates/hooks/tests/test-codex-delegation-packet.sh`
- 変更: `install.sh`
- 変更: `SHA256SUMS`
- 作成: `.sage/runs/RUN-0007.yaml`

## 禁止事項

- `CLAUDE.md` / `templates/claude-md-snippet.md` / `.claude/` を編集しない
- RUN log の observed runtime 値を推奨値に偽装しない
- review finding を無根拠に dismiss しない

## 完了条件

- [x] Major findings の対応が file artifact として残る
- [x] `bash templates/hooks/tests/test-codex-delegation-packet.sh` が PASS
- [x] `bash templates/hooks/tests/run-tests.sh` が PASS
- [x] `bash scripts/sage-validate.sh` が PASS
- [x] `bash scripts/sage-doc-drift.sh` が PASS
- [x] `shasum -a 256 -c SHA256SUMS` が PASS
