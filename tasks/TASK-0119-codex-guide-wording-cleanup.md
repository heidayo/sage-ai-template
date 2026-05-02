# TASK-0119: Codex Guide Wording Cleanup — last-step-in-a-job + isolation 主張の精緻化 (PR #17 followup)

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0119 |
| SPEC-ID   | (lite lane — fix/*、SPEC 不要) |
| PLAN-ID   | (lite lane — PLAN 不要) |
| ステータス | In Progress |
| 担当Agent | Implementation |
| 並列可否  | No |
| 依存TASK  | TASK-0118 (PR #17 で merged 済) |
| 見積     | 25m |

## 責務

PR #17 (merged 済) の Codex 3rd-round adversarial review で指摘された **P2×1 / P3×1 = 2 件** を解消する。両件、openai/codex-action [security docs](https://github.com/openai/codex-action/blob/main/docs/security.md) を WebFetch で一次ソース確認済。本 fix は wording の精緻化であり factual error の訂正というより「公式推奨より広く言い切っている」を狭める方向。

## 入力 (Codex 3rd-round 指摘 2 件)

1. **[P2]** `docs/codex-security.md` 2 箇所が PR #17 の post_feedback job 追加と矛盾:
   - L183 (TL;DR): 「Codex job は workflow の **最後** に配置」← post_feedback が後ろに来た以上不正確
   - L269 (禁止事項): 「Codex job を deploy job より **前** に配置 → 禁止」← 同上、job レベルで言うのは誤り
   公式 security docs の表現は「**run openai/codex-action as the last step in a job**」(step レベル) + 「pass the output along to a new job within the workflow」(別 job への output 受け渡しは推奨)。step / job の粒度を区別する必要がある。

2. **[P3]** `docs/codex-security.md:240-241` インラインコメント「Codex 自身は触らないので write 権限を持たせても prompt injection から isolate されている」が広すぎる。post_feedback は Codex の `final_message` を **そのまま PR comment body** として投稿するため、comment 内容自体は untrusted model output で prompt injection の影響を受け得る (phishing link / 偽情報 / 人間 reader への偽指示など)。狭く書くと:
   - write token を持つ runner で Codex は実行しない (token exfil の compute 経路なし)
   - 固定 script で comment 投稿のみ → shell/code execution 経路はない
   - **ただし** comment body は untrusted model output として扱う (HTML/script は GitHub 側で sanitize されるが意味内容は信用しない)

## 出力

- `docs/codex-security.md` の 3 箇所修正:
  - L183 (TL;DR §6): 「Codex action **step** は Codex **job** の最後の step に配置 (副作用拡大を防ぐ)」+ 1 行追加「PR comment 投稿のような固定処理は別 job への output 受け渡し可」
  - L269 (禁止事項 §6): 「Codex action step を **同一 job 内** で deploy/build/privileged step より前に配置 → 禁止 (Codex が後続 step の host state を汚染し得る)」に書き換え。「別 job」への配置誘導は禁止しないことを明記
  - L240-241 (sample inline コメント): 「Codex 自身は触らないので write 権限を持たせても prompt injection から isolate されている」→ 3 段階に分解 (token exfil 経路なし / shell 実行経路なし / **ただし comment body は untrusted model output**)

- `tasks/TASK-0119-codex-guide-wording-cleanup.md` 新規 (本ファイル)

## File Scope（変更許可範囲）

- 変更: `docs/codex-security.md`
- 作成: `tasks/TASK-0119-codex-guide-wording-cleanup.md`
- 削除: なし

## 禁止事項

- TASK-0114/0115/0117/0118 で確定した他セクションを触らない (本 TASK は §6 の 3 箇所のピンポイント wording fix のみ)
- AGENTS.md / CLAUDE.md / SECURITY.md / sage/governance.md / README.md の cross-reference 行は不変 (R7 doctrine 維持)
- post_feedback job の構造 (`needs:` / `outputs:` / `actions/github-script@v7`) は変えない (TASK-0118 で公式 example 準拠を確定済)

## 完了条件

- [ ] L183 (TL;DR) に「last step in a job」相当の表現あり、「workflow の最後」表現なし
- [ ] L269 (禁止事項) が step / job の粒度を区別、「別 job」分離が許容されている記述
- [ ] L240-241 (sample) の isolation 主張が 3 段階に分解され「comment body は untrusted model output」明記
- [ ] `bash templates/hooks/tests/run-tests.sh` 全 PASS (109/109、regression)
- [ ] `bash scripts/sage-validate.sh` PASS
- [ ] `bash scripts/sage-doctor.sh` 0 FAIL
- [ ] `bash scripts/sage-doc-drift.sh` PASS
- [ ] commit message に `TASK-0119:` を含む
- [ ] branch `fix/codex-guide-wording-cleanup` (lite lane、Gate 1+3 のみ)
