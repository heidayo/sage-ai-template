# TASK-0075: sage-report.sh に cycle_time / gate_pass_rate / rework_rate 追加

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0075 |
| SPEC-ID   | SPEC-0008 |
| PLAN-ID   | PLAN-0008-B |
| ステータス | In Progress |
| 担当Agent | Implementation |
| 並列可否  | Yes |
| 依存TASK  | none |
| 見積     | 2h |

## 責務

`.sage/config.yaml` の `metrics:` セクションで宣言されていた cycle_time / gate_pass_rate / rework_rate の計算を `scripts/sage-report.sh` に実装し、`make report` 実行時に既存メトリクス (Sessions / FAIL) と合わせて 5 系統を出力する。データソースが利用不可の場合は当該メトリクスのみ SKIPPED と表示 (全体 fail させない fail-soft)。

## 入力

- `.sage/config.yaml` L25-46 の metrics 宣言
- 現状 [scripts/sage-report.sh](scripts/sage-report.sh): Sessions count + FAIL count + STATUS のみ
- 利用可能ツール: `git log`, `gh` (optional), `python3`, `date`

## 出力

各メトリクスをセクション別に出力:

- **cycle_time**: SPEC 作成 (git log で `specs/SPEC-XXXX*.md` の最初のコミット時刻) → PR マージ時刻 (merge commit の committer date) の差分 p50 を時間単位で表示。データ無し → SKIPPED
- **gate_pass_rate**: `gh run list --workflow=sage-*-gate.yml --limit=N --json=conclusion` で最新 N 件の conclusion 集計。`gh` 不在 → SKIPPED
- **rework_rate**: `git log --grep=TASK-` を叩いて、各 TASK-ID がコミットメッセージに現れた回数を集計。再コミット率 = (total_commits - unique_task_ids) / total_commits。git 履歴無し → SKIPPED

全メトリクスが揃わなくても既存出力 (Sessions / FAIL / Status) は継続する。

## File Scope（変更許可範囲）

- 作成:
  - `tasks/TASK-0075-sage-report-metrics-expansion.md` (本ファイル)
- 変更:
  - `scripts/sage-report.sh` (既存ロジックを保持したまま末尾に 3 メトリクス計算を追加)
- 削除: なし

## 禁止事項

- 既存 Sessions / FAIL / Status 計算ロジックの変更禁止 (回帰リスク)
- 新規 shell 依存の追加禁止 (jq は optional、なければ sed/python3 fallback)
- `.sage/config.yaml` の metrics セクション変更禁止 (schema は既存のまま活用)
- GitHub API レート制限を考慮し、`gh run list --limit` を 30 以下で抑える

## 完了条件

- [ ] `bash scripts/sage-report.sh` 実行時、出力に cycle_time / gate_pass_rate / rework_rate の 3 セクションが追加されている
- [ ] `gh` 未インストールでも cycle_time と rework_rate は算出され、gate_pass_rate は SKIPPED 表示
- [ ] git 履歴なし状態でも exit 0 (SKIPPED 扱い)
- [ ] 既存 Sessions / FAIL / Status 計算の出力形式が変わらない
- [ ] コミットメッセージに `TASK-0075` を含む

## Done Definition（ラウンド単位）

参照: (PLAN-0008-B 統合時に作成)

## 実行ログ

| フィールド | 内容 |
|-----------|------|
| RUN-ID    | (実行時に自動採番) |
| 開始     | 2026-04-17 |
| 完了     | (実行完了時に記入) |
| Gate結果  | structural: - / functional: - / security: - |
