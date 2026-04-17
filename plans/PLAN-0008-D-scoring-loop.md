# PLAN-0008-D: 採点ループ改善 (閾値緩和 + ブレ対策)

## メタデータ

| フィールド | 内容 |
|-----------|------|
| PLAN-ID   | PLAN-0008-D |
| SPEC-ID   | SPEC-0008 |
| ステータス | Active |
| 作成日    | 2026-04-17 |
| 担当Agent | Planning Agent |

## 変更レイヤ

- [ ] controller
- [ ] usecase
- [ ] domain
- [x] infra (config + harness skill)
- [ ] frontend
- [ ] test

## 影響範囲

`.sage/config.yaml` の harness セクション、`.claude/skills/sage-harness/SKILL.md`、`.claude/skills/sage-evaluate/SKILL.md`、および同名の templates/ 側ファイル (install.sh drift 防止)。

## 実装方針

- **閾値変更 + 新パラメータ (TASK-0082)**: threshold 100→95、scoring_window_size=3、scoring_best_of_n=3、scoring_variance_abort=15 を config.yaml に導入。
- **moving window + best-of-N (TASK-0083)**: evaluator は 1 ラウンドで N 回採点し最高値を返す。harness は直近 window_size ラウンドの最小値が threshold 以上で PASS。`scoring_best_of_n: 1` で旧挙動フォールバック。
- **oscillation 検知 (TASK-0084)**: best-of-N の max - min が scoring_variance_abort 超で `abort_reason: scoring_oscillation` → human escalation。

API コスト 3 倍化のトレードオフは config で吸収できる設計。

## タスク分解

| TASK-ID | 責務 | 担当Agent | 見積 | 依存TASK | 並列可否 |
|---------|------|----------|------|---------|---------|
| TASK-0082 | 閾値緩和 + scoring パラメータ config 導入 | Implementation | 0.5h | - | Yes |
| TASK-0083 | moving window + best-of-N のロジック記述 | Implementation | 2h | TASK-0082 | No |
| TASK-0084 | oscillation 検知 + abort_reason 追加 | Implementation | 1h | TASK-0083 | No |

## リスク

- リスク 1: best-of-N=3 デフォルトで採点 API コスト 3 倍 → 軽減策: config で N=1 に落とせるフォールバック、デフォルトは 3
- リスク 2: SKILL.md の記述だけで強制されるため、プロンプト遵守性に依存 → 軽減策: abort 条件を明示的に列挙、フォーマット違反時に失敗を返す擬似コード併記

## 必要な検証

- [x] unit test (擬似採点 [95,95,95]→PASS, [94,95,96]→FAIL, [100,80,90]→oscillation abort)
- [ ] integration test (実 harness 走行での回帰)
- [ ] security scan
- [ ] e2e test
- [ ] architecture boundary check
