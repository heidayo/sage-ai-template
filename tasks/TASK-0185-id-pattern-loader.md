# TASK-0185: 共有ローダー sage-id-pattern.sh + .sage/id-patterns.json テンプレート新設

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0185 |
| SPEC-ID   | SPEC-0027 |
| PLAN-ID   | PLAN-0027 |
| ステータス | Pending |
| 担当Agent | Implementation |
| 並列可否  | Yes（起点タスク。完了後に TASK-0186/0187/0188/0191 が並列可能） |
| 依存TASK  | none |
| 見積     | 2h |

## 責務

ID 受理パターンの共有ローダー `scripts/sage-id-pattern.sh` と設定テンプレート `.sage/id-patterns.json` を新設する（SPEC-0027 Slice ヒント T1）。

## 入力

- SPEC-0027 スコープ「共有ローダー」節、FR-01〜04、SEC-01/03、INV-02/04、PRE-01、POST-01
- 現行ハードコード regex: `TASK-[0-9]{4}` 等（fallback 値の正）

## 出力

- `scripts/sage-id-pattern.sh`（source 用）:
  - `sage_id_accept_regex <type>`: 種別 → 受理用 ERE（複数 accept は `(p1|p2)` に合成）
  - `sage_id_default_regex <type>`: 生成（連番スキャン）用デフォルト形式 ERE
  - 欠損・パース不能・種別未定義・空 accept 時は fallback + WARN（stderr、exit 0）
  - パースは POSIX ツール（grep/sed/awk）のみ。jq 依存禁止。`eval` 禁止
- `.sage/id-patterns.json`（テンプレート、デフォルト内容は現行ハードコードと完全同一。`.sage/` 保護対象のため PR で人間承認を明示）

## File Scope（変更許可範囲）

- 作成: `scripts/sage-id-pattern.sh`, `.sage/id-patterns.json`
- 変更: なし
- 削除: なし

## 禁止事項

- 5 スクリプト側の変更（TASK-0186/0187/0188 の責務）
- `eval` の使用（SEC-01）、jq 依存の追加（スコープ外）
- `sage/` / `AGENTS.md` / `docs/codex-*.md` への変更

## 完了条件

- [ ] `rm -f .sage/id-patterns.json` 相当の一時環境で `source scripts/sage-id-pattern.sh; sage_id_accept_regex task` が `TASK-[0-9]{4}` を出力する（AC-01）
- [ ] デフォルト設定ありで `echo 'TASK-0001: msg' | grep -qE "$(sage_id_accept_regex task)"` が exit 0（AC-02）
- [ ] 不正 JSON 配置時に fallback 値を返し stderr に WARN、exit 0（AC-04）
- [ ] 空 accept 配列で fallback 使用、`NOTASK` が拒否される（AC-05）
- [ ] `grep -nE '(^|[^a-zA-Z_])eval([^a-zA-Z_]|$)' scripts/sage-id-pattern.sh` のヒット 0 件（AC-11）

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
