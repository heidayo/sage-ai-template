# TASK-0083: 採点ループの moving window + best-of-N 導入

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0083 |
| SPEC-ID   | SPEC-0008 |
| PLAN-ID   | PLAN-0008-D |
| ステータス | In Progress |
| 担当Agent | Implementation |
| 並列可否  | No (TASK-0082 の config パラメータが前提) |
| 依存TASK  | TASK-0082 |
| 見積     | 2h |

## 責務

`templates/skills/sage-harness/SKILL.md` の Phase 1 (SPEC 採点) および Phase 2 (PLAN 採点) のループ制御ロジックを以下のとおり改修する:

1. **best-of-N**: 各 iteration で Evaluator を `scoring_best_of_n` 回呼び出し、最高スコアを iteration_score として採用。対応する eval_feedback (findings/fix_instructions) も最高スコアのものを採用。
2. **moving window**: 直近 `scoring_window_size` iteration の iteration_score すべてが threshold 以上で PASS と判定。window 未充足時は継続 iteration。
3. 旧挙動 (single-sample) は `scoring_best_of_n: 1` + `scoring_window_size: 1` に config を倒せば復元可能。

oscillation 検知 (variance > threshold での abort) は TASK-0084 の範囲。本 TASK では最高スコア採用のみ実装。

## 入力

- `.sage/config.yaml` の `harness.scoring_window_size`, `scoring_best_of_n`, `*_score_threshold` (TASK-0082)
- `templates/skills/sage-harness/SKILL.md` L276-292 (Phase 1 ループ制御)、L361-366 (Phase 2 ループ制御)
- `templates/skills/sage-evaluate/SKILL.md` (Read-Only 採点のフロー — 変更なし)

## 出力

- Phase 1 と Phase 2 それぞれのループ制御擬似コードが best-of-N + moving window 方式に書き換えられる
- Evaluator 呼び出しセクションに「1 iteration で N 回呼び出す」旨を追加
- 旧挙動との互換を config パラメータで保てることを明記

## File Scope（変更許可範囲）

- 作成:
  - `tasks/TASK-0083-moving-window-best-of-n.md` (本ファイル)
- 変更:
  - `templates/skills/sage-harness/SKILL.md` (Phase 1 / Phase 2 のループ制御セクションと Evaluator 呼び出しセクションのみ)
- 削除: なし

## 禁止事項

- `.claude/skills/` の直接編集禁止 (install.sh 再生成で同期)
- TASK-0084 の範囲 (oscillation 検知、variance abort) の実装禁止
- `scripts/sage-id-gen.sh` / validator スクリプトの変更禁止
- config.yaml の変更禁止 (TASK-0082 成果物)

## 完了条件

- [ ] Phase 1 ループ制御擬似コードに「best-of-N 採点」と「moving window 判定」が明記されている
- [ ] Phase 2 ループ制御擬似コードに同じ 2 要素が明記されている
- [ ] Evaluator 呼び出しセクションに「1 iteration で N 回呼び出す」旨が記載されている
- [ ] `scoring_best_of_n: 1` + `scoring_window_size: 1` で旧挙動と等価になることが文中で明記されている
- [ ] 擬似コード上で、スコア例 `[95,95,95]` が PASS、`[94,95,96]` が FAIL、`[96,95,97]` が PASS になるロジックであることが読み取れる
- [ ] コミットメッセージに `TASK-0083` を含む

## Done Definition（ラウンド単位）

参照: (PLAN-0008-D 統合時に作成)

## 実行ログ

| フィールド | 内容 |
|-----------|------|
| RUN-ID    | (実行時に自動採番) |
| 開始     | 2026-04-17 |
| 完了     | (実行完了時に記入) |
| Gate結果  | structural: - / functional: - / security: - |
