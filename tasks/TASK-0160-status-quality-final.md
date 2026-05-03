# TASK-0160: status update + qualifications + final regen (Codex review m1/m2/m3/n1)

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0160 |
| SPEC-ID   | SPEC-0023 |
| PLAN-ID   | PLAN-0023 |
| ステータス | Done |
| 担当Agent | Implementation |
| 並列可否  | No (Codex review m/n 一括対応 + 最終 regen) |
| 依存TASK  | TASK-0159 |
| 見積     | 45m |

## 責務

Codex SPEC-0023 review の Minor + Nit を一括対応 + 最終 install.sh 再生成 + version bump する:

- **m1 (status update)**: SPEC-0023 / PLAN-0023 status: Draft → Review、TASK-0151..0156 status: Pending → Done (commit 済 TASK)
- **m2 (72% claim qualify)**: docs/claude-collaboration-brief.md L132 の「約 72% 少ない」を Composio 2026-05 ベンチマーク source URL 付き引用 + 「絶対値ではなく傾向」と qualify
- **m3 (count drift)**: tasks/TASK-0155 L86 「190+ scenarios」→ 「189 scenarios (180 既存 + 9 新規)」に修正
- **n1 (CLAUDE/AGENTS doctrine 文言整合)**: AGENTS.md §2 doctrine に「(Codex Delegation Packet, Claude Collaboration Brief)」examples を追加し CLAUDE.md と完全一致
- **最終 regen**: install.sh 再生成 (TASK-0159 で governance §10.7 等が更新されたため)、`.sage-version` 1.7.0 → 1.7.1 patch bump、SHA256SUMS sync

## 入力

- Codex review Minor m1/m2/m3 + Nit n1
- 既存 specs/SPEC-0023 / plans/PLAN-0023 / tasks/TASK-0151..0156 の status field
- 既存 docs/claude-collaboration-brief.md L132
- 既存 tasks/TASK-0155 L86 完了条件
- 既存 AGENTS.md §2 doctrine

## 出力

### m1: status updates

| File | Before | After |
|---|---|---|
| specs/SPEC-0023 | Draft | Review |
| plans/PLAN-0023 | Draft | Review |
| tasks/TASK-0151 | Pending | Done |
| tasks/TASK-0152 | Pending | Done |
| tasks/TASK-0153 | Pending | Done |
| tasks/TASK-0154 | Pending | Done |
| tasks/TASK-0155 | Pending | Done |
| tasks/TASK-0156 | Pending | Done |

(TASK-0157..0160 は本 TASK 内で Done として作成、別途 status update 不要)

### m2: docs/claude-collaboration-brief.md L132

旧: `(Codex は Claude より約 72% 少ない output token)`
新: `(Composio 2026-05 ベンチマーク <https://composio.dev/content/claude-code-vs-openai-codex> では Codex のほうが output token が約 72% 少ない事例があったが、モデル世代・タスク・プロンプトで変動するため絶対値ではなく傾向として参照)`

### m3: tasks/TASK-0155 L86

旧: `bash templates/hooks/tests/run-tests.sh 全 PASS (190+ scenarios)`
新: `bash templates/hooks/tests/run-tests.sh 全 PASS (180 既存 + 9 新規 = 189 scenarios)`

### n1: AGENTS.md §2 doctrine 文言整合

旧: `CLI-specific guidance may diverge but requires...`
新: `CLI-specific guidance (Codex Delegation Packet, Claude Collaboration Brief) may diverge but requires...`

CLAUDE.md と完全一致。

### 最終 regen + version bump

- `.sage-version`: 1.7.0 → 1.7.1 (patch bump、Codex review fix を含む内容更新の通知)
- `bash scripts/generate-installer.sh > install.sh` で再生成 (TASK-0159 governance §10.7 等を embed に反映)
- `shasum -a 256 install.sh > SHA256SUMS` で SHA 同期

## File Scope（変更許可範囲）

- 変更: `specs/SPEC-0023-claude-collaboration-pairing.md` (status field のみ)
- 変更: `plans/PLAN-0023-claude-collaboration-pairing.md` (status field のみ)
- 変更: `tasks/TASK-0151..0156-*.md` (status field のみ)
- 変更: `docs/claude-collaboration-brief.md` (L132 qualify のみ)
- 変更: `tasks/TASK-0155-paired-test-and-verification.md` (L86 count fix のみ)
- 変更: `AGENTS.md` (§2 doctrine 1 行のみ、CLAUDE.md と完全一致化)
- 変更: `.sage-version` (1.7.0 → 1.7.1)
- 変更: `install.sh` (regen)
- 変更: `SHA256SUMS` (新 SHA)
- 作成: `tasks/TASK-0160-status-quality-final.md` (本ファイル)

## 禁止事項

- TASK-0151..0156 の他 field (File Scope / 完了条件 / 禁止事項) を本 TASK で変更しない
- docs/claude-collaboration-brief.md L132 以外を本 TASK で編集しない
- AGENTS.md §2 doctrine 以外を本 TASK で編集しない
- install.sh を手編集しない (generator 経由再生成のみ)
- SHA256SUMS を手書きしない (sha256sum / shasum -a 256 で算出)
- shellcheck error を残さない (R9)
- byte-identical 検証 skip しない

## 完了条件

- [x] specs/SPEC-0023 / plans/PLAN-0023 status = Review
- [x] tasks/TASK-0151..0156 status = Done (6 file)
- [x] docs/claude-collaboration-brief.md L132 に Composio source URL + 「傾向」qualify
- [x] tasks/TASK-0155 L86 に「189 scenarios」記載
- [x] AGENTS.md §2 doctrine に「(Codex Delegation Packet, Claude Collaboration Brief)」examples
- [x] AGENTS.md §2 doctrine が CLAUDE.md §2 doctrine と完全一致 (`diff <(grep "may diverge" AGENTS.md) <(grep "may diverge" CLAUDE.md)` で 0 行)
- [x] `.sage-version` = 1.7.1
- [x] `bash scripts/generate-installer.sh > /tmp/new.sh && diff install.sh /tmp/new.sh` 0 行 (byte-identical)
- [x] `shasum -a 256 -c SHA256SUMS` PASS
- [x] `bash templates/hooks/tests/run-tests.sh` 全 PASS (189/189)
- [x] `bash scripts/sage-doctor.sh` 0 FAIL
- [x] `bash scripts/sage-doc-drift.sh` PASS
- [x] commit message に `TASK-0160:` 含む
