# TASK-0191: docs/id-patterns.md + README + config.yaml id_schema コメント整合

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0191 |
| SPEC-ID   | SPEC-0027 |
| PLAN-ID   | PLAN-0027 |
| ステータス | Pending |
| 担当Agent | Implementation |
| 並列可否  | Yes（TASK-0185 完了後、TASK-0186/0187/0188 と並列可。File Scope は互いに素） |
| 依存TASK  | TASK-0185 |
| 見積     | 1h |

## 責務

カスタム ID 形式の設定手順ドキュメントを新設し、README 参照と `.sage/config.yaml` の `id_schema` コメント整合を取る（SPEC-0027 Slice ヒント T7）。

## 入力

- SPEC-0027 OPS-01、AC-10、リスク2（書式サブセット規定）、リスク4（推奨パターン/アンチ例）、ASM-03
- 言語規則: ユーザー向けドキュメントは日本語

## 出力

- `docs/id-patterns.md`（新規、日本語）: `.sage/id-patterns.json` の書式（「1 パターン 1 行」制約付きサブセット）・設定例・「生成はデフォルト形式のみ（受理のみ拡張可）」の制約・推奨パターンとアンチ例（`TASK-.*` 等の緩すぎる regex）・preserve-if-exists の説明
- `README.md`: docs/id-patterns.md への参照追記
- `.sage/config.yaml`: `id_schema` コメントに `.sage/id-patterns.json` への参照を追記（protect-sage-files 対象のため人間承認必須、変更行を PR で明示）
- CLAUDE.md 追記案の PR 本文への記載（直接編集禁止 — human-only）: 「ID 受理パターンは .sage/id-patterns.json で拡張可能 (受理のみ。生成はデフォルト形式)。設定手順: docs/id-patterns.md」

## File Scope（変更許可範囲）

- 作成: `docs/id-patterns.md`
- 変更: `README.md`, `.sage/config.yaml`（id_schema コメント行のみ）
- 削除: なし

## 禁止事項

- `CLAUDE.md` の直接編集（追記案は PR 本文に記載し human が適用）
- `AGENTS.md` / `docs/codex-*.md` の編集（Codex boundary）
- `.sage/config.yaml` のコメント以外の変更

## 完了条件

- [ ] `grep -rqF '.sage/id-patterns.json' README.md docs/` が exit 0（AC-10）
- [ ] `grep -qF 'id-patterns' .sage/config.yaml` が exit 0（AC-10）
- [ ] docs に「生成はデフォルト形式のみ」の制約と推奨パターン/アンチ例が記載されている（OPS-01、目視 + `grep -qF '生成はデフォルト形式' docs/id-patterns.md`）

## Done Definition（ラウンド単位）

参照: `tasks/done-def-SPEC-0027-round-1.md`

## 実行ログ

| フィールド | 内容 |
|-----------|------|
| RUN-ID    | （実行時に自動採番） |
| 開始     | |
| 完了     | |
| 結果     | |
| Gate結果  | |
