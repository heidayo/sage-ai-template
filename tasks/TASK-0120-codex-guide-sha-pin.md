# TASK-0120: Codex Guide SHA Pin — actions/github-script を SAGE pin convention に揃える (PR #18 followup)

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0120 |
| SPEC-ID   | (lite lane — fix/*、SPEC 不要) |
| PLAN-ID   | (lite lane — PLAN 不要) |
| ステータス | In Progress |
| 担当Agent | Implementation |
| 並列可否  | No |
| 依存TASK  | TASK-0118 (PR #17 で merged 済) / TASK-0119 (PR #18 で in review) |
| 見積     | 15m |

## 責務

PR #18 (in review) の Codex 4th-round adversarial review で指摘された **P3×1 = 1 件** を解消する。Codex 自身も「Findings remain — 1 more micro-round expected」と収束直前を宣言。本 fix は SAGE 既存 workflow と Phase 3 doc sample の SHA pin 一貫性確保のみ (factual error なし)。

## 入力 (Codex 4th-round 指摘 1 件)

1. **[P3]** `docs/codex-security.md:251` (現 main 上の行番号) の `actions/github-script@v7` だけ tag 参照 (sample 内の `actions/checkout@11bd71...` / `openai/codex-action@<PIN_TO_SHA>` は SHA pin 済)。SAGE は自身の `.github/workflows/*.yml` 全 8 箇所で `actions/github-script@60a0d83039c74a4aee543508d2ffcb1c3799cdea # v7.0.1` の形で SHA pin を徹底している (`grep -rn "actions/github-script" .github/workflows/` で確認済)。Phase 3 sample でも write 権限を持つ post_feedback job 内の action こそ SHA pin が望ましい (GitHub Actions secure use reference 推奨)。

## 出力

- `docs/codex-security.md` の 1 箇所修正:
  - L251 (post_feedback job 内): `uses: actions/github-script@v7` → `uses: actions/github-script@<PIN_TO_SHA>  # v7.0.1` に変更 (placeholder 形式は同 sample の `openai/codex-action@<PIN_TO_SHA>` と一致)

- `tasks/TASK-0120-codex-guide-sha-pin.md` 新規 (本ファイル)

## File Scope（変更許可範囲）

- 変更: `docs/codex-security.md`
- 作成: `tasks/TASK-0120-codex-guide-sha-pin.md`
- 削除: なし

## 禁止事項

- TASK-0114/0115/0117/0118/0119 で確定した他箇所を触らない (本 TASK は 1 行のみ)
- AGENTS.md / CLAUDE.md / SECURITY.md / sage/governance.md / README.md は不変
- `actions/checkout@11bd71...` と `openai/codex-action@<PIN_TO_SHA>` の既存表記は変えない
- 具体 SHA を baking しない (placeholder で読者の責任を明示、SAGE 既存 workflow は内部で具体 SHA を pin、利用者が設定する Phase 3 sample は placeholder + コメントで version 推奨を示す方針)

## 完了条件

- [ ] `docs/codex-security.md` から `actions/github-script@v7` tag 参照消滅
- [ ] `actions/github-script@<PIN_TO_SHA>  # v7.0.1` の形に変更
- [ ] sample 内の他 action 参照 (`actions/checkout`, `openai/codex-action`) と SHA pin の方針が一致
- [ ] `bash templates/hooks/tests/run-tests.sh` 全 PASS (109/109、regression)
- [ ] `bash scripts/sage-validate.sh` PASS
- [ ] `bash scripts/sage-doctor.sh` 0 FAIL
- [ ] `bash scripts/sage-doc-drift.sh` PASS
- [ ] commit message に `TASK-0120:` を含む
- [ ] branch `fix/codex-guide-sha-pin` (lite lane、Gate 1+3 のみ)
