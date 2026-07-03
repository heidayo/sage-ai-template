# TASK-0176: README「カスタマイズと更新の共存」ガイドの新設

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0176 |
| SPEC-ID   | SPEC-0025 |
| PLAN-ID   | PLAN-0025 |
| ステータス | Pending |
| 担当Agent | Implementation |
| 並列可否  | Yes（TASK-0174 / TASK-0175 と並列可） |
| 依存TASK  | TASK-0171, TASK-0172 |
| 見積     | 1h |

## 責務

README / docs に「カスタマイズと更新の共存」ガイド（日本語）を新設または更新し、local overlay の使い方・対比表・レビュー責任を文書化する。

## 入力

- SPEC-0025（SEC-01, OPS-02, リスク2, スコープ「README / docs ガイド」）
- 既存 `README.md` の構成・トーン
- PLAN-0025 リスク2（注記追加による checksum 変化は install-state 再生成で解消される旨の明記）

## 出力

- 更新済み `README.md`（または `docs/` 配下の新規ガイド + README からのリンク）に以下を含む:
  - 「managed ファイル直接編集 → 更新で消える / `local/` 配置 → 保持される」の対比表（OPS-02）
  - overlay は checksum 検証対象外であり、`local/` 配下は導入プロジェクト自身のレビュー責任である旨（SEC-01）
  - テンプレート更新で managed rules の checksum が変わった場合は install-state 再生成で解消される旨（リスク2 軽減策）

## File Scope（変更許可範囲）

- 作成: `docs/local-overlay-guide.md`（docs 分離する場合のみ）
- 変更: `README.md`
- 削除: なし

## 禁止事項

- コード（`scripts/`, `install.sh`, `templates/hooks/`）の変更（AP-03 — 本 TASK は docs のみ）
- `AGENTS.md` / `docs/codex-*.md` / `sage/` / `CLAUDE.md` の編集
- 他 TASK 責務（rules 注記 = TASK-0174、CLAUDE.md 規約 = TASK-0175）の取り込み（AP-02 Big Bang）
- ユーザー向け文書の英語化（Language Rules: user-facing documentation は日本語）
- TASK-ID なしコミット（AP-05）

## 完了条件

- [ ] `grep -q 'local/' README.md` が成功する（SPEC T6 完了条件）
- [ ] `bash templates/hooks/tests/run-tests.sh` が全件 PASS（AC-07 非破壊）
- [ ] README ガイドに対比表（OPS-02）とレビュー責任の記載（SEC-01）が含まれる: `grep -q 'レビュー責任' README.md`（docs 分離時は当該ファイルで確認しREADMEにリンクがあること）

## Done Definition（ラウンド単位）

参照: `tasks/done-def-SPEC-0025-round-1.md`

## 実行ログ

| フィールド | 内容 |
|-----------|------|
| RUN-ID    | （実行時に自動採番） |
| 開始     | - |
| 完了     | - |
| 結果     | - |
| Gate結果  | - |
