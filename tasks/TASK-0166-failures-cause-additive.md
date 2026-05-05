# TASK-0166: sage/failures.md cause field additive (template only, no retrofit)

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0166 |
| SPEC-ID   | SPEC-0024 |
| PLAN-ID   | PLAN-0024 |
| ステータス | Pending |
| 担当Agent | Implementation (shared-core) |
| 並列可否  | Yes (TASK-0165 / TASK-0167 と並列、別 File Scope) |
| 依存TASK  | TASK-0162 |
| 見積     | 20m |

## 責務

`sage/failures.md` の **エントリフォーマット節のみ** に `cause` field (additive) を追加。既存 `FAIL-0001` entry の本文は **変更しない** (Codex review feedback 5: 推定 retrofit 禁止)。

## 入力

- SPEC-0024 FR-05 (cause field schema、additive 方針)
- SPEC-0024 OPS-05 (cause 推定 retrofit 禁止 doctrine)
- 既存 sage/failures.md (FAIL-0001 entry 含む)
- Codex review feedback 5: 「既存 entry の cause を後付け推定する PR は禁止」

## 出力

### sage/failures.md エントリフォーマット節更新

`### FAIL-XXXX` の field 列 (発生日 / TASK-ID / 該当アンチパターン / ...) に `cause` field を追加 (additive、新規 entry 起票時のみ任意記入推奨):

```markdown
### FAIL-XXXX
- **発生日**: YYYY-MM-DD
- **TASK-ID**: TASK-XXXX
- **該当アンチパターン**: (あれば) Vibe Merge / Big Bang Prompt / Silent Scope Expansion / AI Monolith / Invisible Development / Human-Only Guard
- **cause** (任意、SPEC-0024 OPS-05 — 新規 entry のみ): trust-boundary / code-reading / spec-misinterpretation / not-applicable / other
- **症状**: 何が起きたか
- **根本原因**: なぜ起きたか
- **修正**: どう直したか
- **防止策**: 今後どう防ぐか
- **昇格済み**: Yes / No
```

cause enum の意味 (SPECA paper §4.2 由来、適用例):
- `trust-boundary`: untrusted/attacker-controlled input の信頼境界誤解 (例: SQL injection、CSRF token 不足)
- `code-reading`: 実装読解のミス (例: dead code branch の見落とし、複雑な制御フロー誤読)
- `spec-misinterpretation`: SPEC 文言の誤解 (例: MUST と SHOULD の混同、scope 不明確な記述)
- `not-applicable`: 上記分類が当てはまらない構造的問題 (例: infrastructure 障害)
- `other`: 上記いずれにも分類できない (詳細は症状欄に記述)

### 既存 FAIL-0001 entry

**変更しない** (Codex review feedback 5)。本 TASK は template only。

## File Scope（変更許可範囲）

- 変更: `sage/failures.md` (エントリフォーマット節のみ、`cause` field 追加 + enum 説明 ≤+10 行)

## 禁止事項

- **既存 FAIL-0001 entry の本文を一切変更しない** (Codex review feedback 5、推定 retrofit 禁止)
- 既存 FAIL-0001 に cause field を後付け追加しない
- enum 値を本 TASK で 5 値以外に拡張しない (拡張は別 SPEC)
- 「## 記録ルール」「## 記録」セクションの構造を変更しない
- `sage/anti-patterns.md` を本 TASK で変更しない (FAIL → anti-pattern 昇格は別 process)

## 完了条件

- [ ] `grep -F '**cause**' sage/failures.md` で 1 件以上 hit (markdown bold field marker、既存 `**発生日**` `**TASK-ID**` 等と整合)
- [ ] `for c in trust-boundary code-reading spec-misinterpretation not-applicable other; do grep -qF "$c" sage/failures.md || exit 1; done`
- [ ] FAIL-0001 entry 本文未変更: `git diff main HEAD -- sage/failures.md | awk '/^### FAIL-0001/,/^### FAIL-/{print}' | grep -E "^[-+]" | grep -v "^[-+][-+][-+]"` で 0 行 (本文 diff なし)
- [ ] template 節の `cause` 追加分のみ diff: `git diff main HEAD -- sage/failures.md | grep -c "^+" ` で ≤+15 行
- [ ] commit message に `TASK-0166:` 含む
