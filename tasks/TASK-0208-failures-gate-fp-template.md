# TASK-0208: sage/failures.md への GATE-FP テンプレート・記録ルール追記

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0208 |
| SPEC-ID   | SPEC-0031 |
| PLAN-ID   | PLAN-0031 |
| ステータス | Pending |
| 担当Agent | Implementation |
| 並列可否  | Yes（TASK-0209 と並列可） |
| 依存TASK  | none |
| 見積     | 45m |

## 責務

`sage/failures.md` に GATE-FP-XXXX エントリテンプレート（必須 7 フィールド）と記録ルール（FAIL との使い分け + 3 回エスカレーション）を追加のみで追記する。

## human 承認要件（必読）

`sage/failures.md` は File Scope Rules 上 **human-only 領域**である。本 TASK の変更は **PR レビューとマージをもって human 承認とする**（SPEC-0031「human 承認要件」節）:

- PR 本文に「**sage/failures.md (human-only 領域) の変更を含むため、human によるレビュー承認とマージが本変更の承認行為である**」旨を必ず記載する（AC-08）
- protect-sage-files hook がブロックする場合、SPEC-0031 承認済みを根拠として human がブロック解除を判断する。無断バイパスは禁止

## 入力

- SPEC-0031 スコープ節（必須 7 フィールド定義: 発生日 / 誤検知した Gate + チェック名 / TASK-ID / 誤検知の根拠 / 一時対応 / 恒久対応 / 再発回数）
- 使い分けルール: FAIL-XXXX = 実装・プロセス側の失敗、GATE-FP-XXXX = gate 側の誤検知。迷う場合は FAIL 優先 + GATE-FP から相互参照
- エスカレーションルール: 同一チェックの誤検知が累計 3 回で「gate 設定の見直し」必須化。見直し結果は該当 GATE-FP エントリの恒久対応欄に追記
- 既存 `sage/failures.md` の「エントリフォーマット」節・「記録ルール」節の構成

## 出力

- `sage/failures.md`: 「エントリフォーマット」節の直後に新節「Gate False Positive エントリフォーマット (GATE-FP-XXXX)」、「記録ルール」節に使い分け + エスカレーションの 2 項目追記。日本語で記述

## File Scope（変更許可範囲）

- 作成: なし
- 変更: `sage/failures.md`（節追加・ルール追記のみ）
- 削除: なし

## 禁止事項

- 既存エントリ（FAIL-0001 / FAIL-0002）・既存節の変更（バイト単位で不変, AC-11 / INV-05。追加以外の diff `-` 行を出さない）
- FAIL-XXXX エントリフォーマット自体の変更
- `sage/anti-patterns.md` / `CLAUDE.md` / `AGENTS.md` / その他ファイルへの変更
- 恒久対応欄に「TBD」を許容する記述（「未対応」と明記する書式にする）
- install.sh / SHA256SUMS の再生成（TASK-0211 の責務 — 本 TASK のコミットに混入させない）

## 完了条件

- [ ] AC-01: `grep -qF 'GATE-FP-XXXX' sage/failures.md` が exit 0、かつ `for kw in '発生日' '誤検知した Gate' 'TASK-ID' '誤検知の根拠' '一時対応' '恒久対応' '再発回数'; do grep -qF "$kw" sage/failures.md || exit 1; done` が exit 0 (case: `template_fields_present`)
- [ ] AC-02: `grep -qF 'GATE-FP' sage/failures.md && grep -qE '3\s*回' sage/failures.md && grep -qF 'gate 設定の見直し' sage/failures.md` が exit 0 (case: `escalation_rule_present`)
- [ ] AC-11: `git diff main -- sage/failures.md` に追加以外の `-` 行（FAIL-0001 / FAIL-0002 エントリ行の変更）が含まれない (case: `existing_entries_unchanged`)
- [ ] コミットメッセージに TASK-0208 を含む

## Done Definition（ラウンド単位）

参照: `tasks/done-def-SPEC-0031-round-1.md`

## 実行ログ

| フィールド | 内容 |
|-----------|------|
| RUN-ID    | （実行時に採番） |
| 開始     | |
| 完了     | |
| 結果     | |
| Gate結果  | |
