# Harness Rules — ハーネス専用 Forbidden Shortcuts

> Applies to: `tasks/done-def-*`, `.sage/runs/*`, harness execution context

## ハーネス実行時の禁止事項

以下のルールはハーネスオーケストレーターが機械的に強制する。エージェントのプロンプト遵守に依存せず、条件分岐・事後検証で保証する。

### 禁止事項テーブル

| # | 禁止事項 | 検出方法 | 強制手段 |
|---|---------|---------|---------|
| H-01 | 同一 Verify Fail が3連続 → 即 abort | Run Log 内の `same_fail_count` フィールド比較 | オーケストレーターが `same_fail_count >= 3` で機械的にループ中断 |
| H-02 | Implementation Agent が File Scope 外に書き込み | Verify Agent の Gate 4（Architecture）で検出 | Gate 4 Fail でループ差し戻し |
| H-03 | Evaluator が S++ 未達のまま次フェーズへ進行 | オーケストレーターがスコア閾値を機械的にチェック | `if score < threshold: block`（条件分岐、スキップ不可） |
| H-04 | フィードバックなしで Execute を再実行 | オーケストレーターが前回の Verify 結果を必ずプロンプトに含める | フィードバック YAML が空なら Execute プロンプト生成を拒否 |
| H-05 | Verify Agent が Implementation のコードを修正 | Verify Agent 実行後の `git diff --name-only` で検出 | ファイル変更があれば `git checkout -- .` で revert |
| H-06 | 1ラウンドで複数 SPEC を同時進行 | ハーネス起動時に `.sage/runs/` 内の `status: running` をチェック | 既存の running がある場合は起動拒否 |
| H-07 | SPEC/PLAN を Implementation Agent が変更 | Implementation Agent の File Scope に specs/, plans/ が含まれないことを確認 | プロンプトで File Scope を明示 + Gate 4 で事後検証 |

### Verify Agent のツール制限

Verify Agent は以下のツールのみ使用可能:

| ツール | 使用可否 | 用途 |
|-------|---------|------|
| Read | 可 | 全ファイル読み取り |
| Bash | 可 | テスト実行・lint・カバレッジ計測・secret scan |
| Write | 禁止 | コード修正は Implementation Agent の責務 |
| Edit | 禁止 | 同上 |
| Agent | 禁止 | サブエージェント生成は不要 |

この制限はプロンプトベースで指示するが、以下の二重防御を行う:

1. **事前**: Verify Agent プロンプトに「Write/Edit 使用禁止」を明記
2. **事後**: オーケストレーターが `git diff --name-only` を実行し、ファイル変更があれば revert

### Abort 時の記録義務

abort 発生時、オーケストレーターは以下を必ず実行する:

1. `.sage/runs/RUN-XXXX.yaml` に `status: aborted` と `abort_reason` を記録
2. `auto_append_failures: true` の場合、`sage/failures.md` にパターンを追記
3. `failure_pattern_escalation` 閾値に達した場合、`sage/anti-patterns.md` に昇格
4. ユーザーに abort_reason・最終フィードバック・推奨アクションを報告
