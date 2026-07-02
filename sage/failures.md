# SAGE Failures Log

アンチパターンの実例記録。繰り返し発生するパターンは `anti-patterns.md` に昇格する。

## 記録ルール

- 失敗が発生したら即座に記録する
- 同じ失敗が3回発生したら `anti-patterns.md` に昇格する
- 昇格後もこのログは削除しない（履歴として残す）

---

## エントリフォーマット

### FAIL-XXXX
- **発生日**: YYYY-MM-DD
- **TASK-ID**: TASK-XXXX
- **該当アンチパターン**: (あれば) Vibe Merge / Big Bang Prompt / Silent Scope Expansion / AI Monolith / Invisible Development / Human-Only Guard
- **cause** (任意、SPEC-0024 OPS-05 — **新規 entry のみ**、既存 entry の後付け推定は禁止): trust-boundary / code-reading / spec-misinterpretation / not-applicable / other
- **症状**: 何が起きたか
- **根本原因**: なぜ起きたか
- **修正**: どう直したか
- **防止策**: 今後どう防ぐか（CI追加 / ルール追加 / テンプレ修正等）
- **昇格済み**: Yes / No（anti-patterns.mdに追加済みか）

cause enum の意味 (SPECA paper §4.2 由来、SPEC-0024 で SAGE に採用):
- `trust-boundary`: untrusted/attacker-controlled input の信頼境界誤解 (例: SQL injection、CSRF token 不足、auth バイパス)
- `code-reading`: 実装読解のミス (例: dead code branch の見落とし、複雑な制御フロー誤読)
- `spec-misinterpretation`: SPEC 文言の誤解 (例: MUST と SHOULD の混同、scope 不明確な記述)
- `not-applicable`: 上記分類が当てはまらない構造的問題 (例: infrastructure 障害、CI 環境固有の flaky)
- `other`: 上記いずれにも分類できない (詳細は症状欄に記述)

---

## 記録

### FAIL-0001
- **発生日**: 2026-04
- **TASK-ID**: SAGE-QUALITY-001
- **該当アンチパターン**: なし（新規パターン）
- **症状**: PRレビューでtrailing whitespace / 既存パターンと異なる記法 / 目的不明なコードが繰り返し指摘される
- **根本原因**: AIが「動くコード」優先で既存ファイルの書式・パターンを確認せず、可読性・保守性の観点が欠落していた
- **修正**: src-rules に Code readability セクション追加、sage-review に Code Quality 観点追加、sage-validate.sh にノイズ差分検出追加
- **防止策**: セルフレビュー（src-rules）+ レビュー（sage-review）+ CI（sage-validate.sh Check 6）の3層で担保
- **昇格済み**: No

### FAIL-0002
- **発生日**: 2026-07-02
- **TASK-ID**: TASK-0171, TASK-0175
- **該当アンチパターン**: AP-03 (Silent Scope Expansion)
- **cause**: trust-boundary
- **症状**: SPEC-0025 実装中、(1) TASK-0171 の bugfix コミットが File Scope 外の install.sh/SHA256SUMS 再生成を同梱、(2) spec drift 訂正コミット (specs/plans/tasks) が Implementation 系列の TASK-0175 ラベルでコミットされた (Review Agent REV-001/REV-002 で検出、Gate 4 FAIL)
- **根本原因**: オーケストレーターが「修正→再生成→コミット」を単一エージェント実行に束ねた際、コミット分割の File Scope 境界指示が欠けていた
- **修正**: コミット履歴を再構成 — 再生成を TASK-0177 の別コミットに分割、spec 訂正コミットを Spec Agent 帰属に relabel。テスト 22/22 + checksum PASS を再確認
- **防止策**: 複数 TASK を1エージェントに委任する際、プロンプトに「再生成物は再生成 TASK の TASK-ID で別コミット」「specs/plans/tasks の修正は Spec/Planning Agent コミットに分離」を明記する
- **昇格済み**: No
