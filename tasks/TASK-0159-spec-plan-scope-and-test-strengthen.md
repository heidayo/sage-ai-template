# TASK-0159: SPEC/PLAN scope expansion + governance §10.5 wording + test scenario 5 強化 (Codex review M2/M3/M4)

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0159 |
| SPEC-ID   | SPEC-0023 |
| PLAN-ID   | PLAN-0023 |
| ステータス | Done |
| 担当Agent | Implementation |
| 並列可否  | No (Codex review M2/M3/M4 即時対応) |
| 依存TASK  | TASK-0158 |
| 見積     | 45m |

## 責務

Codex SPEC-0023 review の Major M2/M3/M4 を一括対応する:

- **M2 (TASK-0156 traceability)**: SPEC-0023 §関連ID と PLAN-0023 タスク表 / 依存グラフに TASK-0156..0160 を追加
- **M3 (AGENTS scope)**: SPEC-0023 §スコープ（含む）と sage/governance.md §10.7 に「`bash install.sh --update` 経由の AGENTS.md / CLAUDE.md SAGE-managed section propagation」を明示 (Q1=B 確定 — revert ではなく scope 内宣言)
- **M4 (Scenario 5 弱さ)**: Q2=B 確定 — `templates/hooks/tests/test-claude-collaboration-pairing.sh` Scenario 5 を強化、4 doc (CLAUDE/AGENTS/snippets) の paired CLI-specific markers を対称検証 (`Claude Code は協働型` ↔ `Codex は委任型` 等 4 pair)、合わせて governance §10.5 wording を「baseline coverage」に明示更新

## 入力

- Codex review Major M2 / M3 / M4
- 既存 `specs/SPEC-0023-claude-collaboration-pairing.md` §関連ID / §スコープ
- 既存 `plans/PLAN-0023-claude-collaboration-pairing.md` タスク表 / 依存グラフ
- 既存 `sage/governance.md` §10.5 / §10.6 / (新設 §10.7)
- 既存 `templates/hooks/tests/test-claude-collaboration-pairing.sh` Scenario 5

## 出力

### SPEC-0023 §「スコープ（含む）」

末尾に 2 bullet 追加:
- (Codex review M3 fix): install --update 経由の SAGE-managed section propagation を本 SPEC scope に明示
- (Codex review M1/M2/M4 paired-fix): test branch detection 強化 / Scenario 5 強化 / SPEC-0022 territory への paired-update を本 SPEC scope に明示

### SPEC-0023 §「関連ID」

TASK-0156..0160 と RUN-0008 を追加。

### PLAN-0023 タスク表

TASK-0156..0160 行を追加 (見積 + 依存 + 並列可否)、合計時間を更新。

### PLAN-0023 依存グラフ

TASK-0156..0160 を sequential fix chain として追加、Codex review feedback 受領 marker を中段に挿入。

### sage/governance.md

- **§10.5 Drift 検知** wording: 「baseline coverage」を明示、4 doc paired markers 対称検証を新項目として追加 (TASK-0159 強化 ref)、限界明記 (Phase 6.3+ で markers map 拡張余地)
- **§10.7 install --update propagation** 新設: snippet 編集が実体ファイルへ propagation する設計挙動を doctrine 化、SPEC scope 宣言で AGENTS.md / CLAUDE.md auto-injected section も含む扱いに

### test-claude-collaboration-pairing.sh Scenario 5 強化

- doctrine alignment check (既存) + paired CLI-specific markers 対称検証 (新規) を combined pass 判定
- 4 paired markers: `Claude Code は協働型` ↔ `Codex は委任型` / `docs/claude-collaboration-brief.md` ↔ `docs/codex-delegation-packet.md` / `Claude collaboration brief` ↔ `Codex delegation packet` (snippet) / `Claude-only boundary` ↔ `Codex-only boundary` (snippet)
- 不在 marker は具体名で stderr 出力 (debug 性向上)
- shellcheck pass (CODEX_DOC 未使用変数 cleanup 含む)

## File Scope（変更許可範囲）

- 変更: `specs/SPEC-0023-claude-collaboration-pairing.md` (§スコープ + §関連ID)
- 変更: `plans/PLAN-0023-claude-collaboration-pairing.md` (タスク表 + 依存グラフ)
- 変更: `sage/governance.md` (§10.5 wording + §10.7 新設)
- 変更: `templates/hooks/tests/test-claude-collaboration-pairing.sh` (Scenario 5 強化)
- 作成: `tasks/TASK-0159-spec-plan-scope-and-test-strengthen.md` (本ファイル)

## 禁止事項

- governance §10.1-10.4 / §10.6 既存内容を変更しない (本 TASK は §10.5 wording 更新 + §10.7 新設のみ)
- test の Scenario 1-4 / 6-9 を変更しない (Scenario 5 のみ強化)
- SPEC-0022 territory (docs/codex-delegation-packet.md / agents-md-snippet.md / AGENTS.md L41-43 の Codex bullets) を編集しない
- shellcheck error を残さない (R9)
- install.sh 再生成は本 TASK で行わない (TASK-0160 で実施)

## 完了条件

- [x] SPEC-0023 §「関連ID」に TASK-0156..0160 + RUN-0008 が記載
- [x] SPEC-0023 §「スコープ（含む）」に install --update propagation + paired-fix 2 bullets 追加
- [x] PLAN-0023 タスク表に TASK-0156..0160 行追加、合計時間更新
- [x] PLAN-0023 依存グラフに TASK-0156..0160 + Codex review marker 追加
- [x] sage/governance.md §10.5 wording に「baseline coverage」明示、TASK-0159 強化 ref
- [x] sage/governance.md §10.7 新設 (install --update propagation doctrine)
- [x] test-claude-collaboration-pairing.sh Scenario 5 強化 (4 paired markers 対称検証)
- [x] `bash templates/hooks/tests/test-claude-collaboration-pairing.sh` 9/9 PASS
- [x] shellcheck error 0 件
- [x] commit message に `TASK-0159:` 含む
