# TASK-0077: CLAUDE.md ↔ AGENTS.md drift 検知スクリプトと CI 呼び出し

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0077 |
| SPEC-ID   | SPEC-0008 |
| PLAN-ID   | PLAN-0008-C |
| ステータス | In Progress |
| 担当Agent | Implementation |
| 並列可否  | Yes |
| 依存TASK  | TASK-0085 (drift が埋まっていないと script が常時 FAIL するため、手元の状態を先に整えた方が運用しやすい) |
| 見積     | 1h |

## 責務

CLAUDE.md と AGENTS.md の「semantically aligned」宣言を機械検証する。節見出し (H2/H3) が両ファイルで対称でない場合に FAIL を返す script を作成し、構造ゲートから呼び出す。

本 TASK はまず script のみを成果物とする。CI workflow への組み込みは TASK-0078/0080 等と合わせて sage-structural-gate.yml を一度だけ変更する段取り (本 TASK 単独では workflow は触らない — File Scope 外)。

## 入力

- `CLAUDE.md` と `AGENTS.md` は `<!-- === SAGE Development System (auto-injected) === -->` マーカー以降を auto-injected 領域として持つ (installer が上書きする)
- 意図的差異:
  - `Claude Code` (CLAUDE.md) ↔ `Codex` (AGENTS.md) の名称ペア
  - Section 9.1: `## 9.1 Claude Code Hooks` (CLAUDE.md) ↔ `## 9.1 Hooks` (AGENTS.md)
  - auto-injected 領域 (マーカー以降) は構造的に異なる
- TASK-0085 完了時点の pre-marker 部分は対称化済み

## 出力

- `scripts/sage-doc-drift.sh` を新規作成
- 引数なしで CLAUDE.md と AGENTS.md を比較
- 節見出し集合が一致する (pre-marker 部分のみ、意図的差異を正規化後) → exit 0
- 一致しない場合 → exit 1、stdout に「CLAUDE.md only」「AGENTS.md only」の節を列挙

## File Scope（変更許可範囲）

- 作成:
  - `scripts/sage-doc-drift.sh`
  - `tasks/TASK-0077-doc-drift-check.md` (本ファイル)
- 変更: なし
- 削除: なし

## 禁止事項

- `CLAUDE.md` / `AGENTS.md` の編集禁止 (TASK-0085 で実施済、本 TASK は検証のみ)
- `.github/workflows/` の編集禁止 (TASK-0078 と統合 PR の範囲)
- auto-injected 領域 (マーカー以降) を検証対象に含めない (installer 責務)
- LLM 呼び出し禁止 (非決定的、CI 不適切)

## 完了条件

- [ ] 現在の CLAUDE.md / AGENTS.md で `bash scripts/sage-doc-drift.sh` が exit 0 を返す
- [ ] `AGENTS.md` から「### 4.1 Recommended Workflow: Harness」節を一時的に削除すると exit 1 を返し、diff 出力にその節名が表示される
- [ ] auto-injected マーカー以降 (SAGE Development System / SAGE Workflow の差異) が誤って FAIL 原因にならない
- [ ] `Claude Code` ↔ `Codex` の文字列差が FAIL 原因にならない
- [ ] コミットメッセージに `TASK-0077` を含む

## Done Definition（ラウンド単位）

参照: (PLAN-0008-C 統合時に作成)

## 実行ログ

| フィールド | 内容 |
|-----------|------|
| RUN-ID    | (実行時に自動採番) |
| 開始     | 2026-04-17 |
| 完了     | (実行完了時に記入) |
| 結果     | (実行完了時に記入) |
| Gate結果  | structural: - / functional: - / security: - |
