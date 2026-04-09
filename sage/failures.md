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
- **症状**: 何が起きたか
- **根本原因**: なぜ起きたか
- **修正**: どう直したか
- **防止策**: 今後どう防ぐか（CI追加 / ルール追加 / テンプレ修正等）
- **昇格済み**: Yes / No（anti-patterns.mdに追加済みか）

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
