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

（ここに実際の失敗を追記する）
