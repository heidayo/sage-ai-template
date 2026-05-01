# TASK-0107: lethal-trifecta-detect.sh (warn-only) + state mgmt + tests

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0107 |
| SPEC-ID   | SPEC-0012 |
| PLAN-ID   | PLAN-0012 |
| ステータス | Pending |
| 担当Agent | Implementation/Test |
| 並列可否  | Yes |
| 依存TASK  | none |
| 見積     | 90m |

## 責務

Simon Willison の Lethal Trifecta (private data + untrusted input + exfiltration vector) を検出する **warn-only** PreToolUse hook を新規作成。3 条件のうち 2 条件以上同時成立時に stderr に WARN を出すが、exit 0 を維持して block しない (Codex review R3 厳守)。

## 入力

- SPEC-0012 FR-01, SEC-03, リスク1
- Codex review R3 (lethal-trifecta は warn-only)
- 参考: [Lethal Trifecta — Airia](https://airia.com/ai-security-in-2026-prompt-injection-the-lethal-trifecta-and-how-to-defend/)
- Phase 2A test harness (`_helpers.sh`)

## 出力

1. `templates/hooks/lethal-trifecta-detect.sh` 新規:
   - `set -euo pipefail` + profile gating (minimal/none で skip)
   - jq + grep fallback で `tool_input` parse
   - **Trifecta condition tracking**: 3 boolean を判定:
     - `T_PRIVATE`: 直前/同 session で private data path read 痕跡 (`.sage/runtime/lethal-trifecta-state.json` を読み、TTL 5 分以内のエントリ参照)
     - `T_UNTRUSTED`: 現コマンド/Read target に external content 由来 marker (`https://`, `gh issue view`, `gh pr view`, `cat README.md`, `WebFetch`)
     - `T_EXFIL`: 現コマンドに exfiltration vector (`curl -X POST`, `webhook.site`, `nc <host>`, `mail`, `mailx`, `sendmail`, `slack-send`)
   - 2 条件以上 true で stderr に WARN (各成立条件の種別のみ、secret value は含めない)
   - exit 0 を必ず返す (block しない、Codex R3)
   - state file 書き込み: 現操作で private data を読んだら `.sage/runtime/lethal-trifecta-state.json` に append (TTL 5 分)
2. `.sage/runtime/.gitkeep` 不要 (gitignored)
3. `.gitignore` に `.sage/runtime/` 追加 (手動: setup_gitignore は Phase 2A 教訓で installer に追加しない)
4. `templates/hooks/tests/test-lethal-trifecta-detect.sh`:
   - 3 条件すべて false → no WARN, exit 0
   - 1 条件のみ true → no WARN, exit 0 (lone-condition allowed)
   - 2 条件 true → WARN 出力, exit 0 (block しない確認)
   - 3 条件 true → WARN 出力, exit 0
   - profile=minimal で skip 確認

## File Scope（変更許可範囲）

- 作成: `templates/hooks/lethal-trifecta-detect.sh`
- 作成: `templates/hooks/tests/test-lethal-trifecta-detect.sh`
- 変更: `.gitignore` (`.sage/runtime/` 追記、手動)
- 削除: なし

## 禁止事項

- **block (exit 2) 禁止** — Codex R3 厳守、warn-only でなければ false positive で実害
- WARN message に secret value を含めない (SEC-03)
- state file 書き込み失敗で hook 自体が落ちない (常に exit 0)
- session 跨ぎ複雑な状態管理は避ける (TTL 5 分で自然減衰)
- TASK-0108/0109 の hook ファイルへの変更禁止

## 完了条件

- [ ] `bash templates/hooks/tests/run-tests.sh` 全 PASS (新 test 含む)
- [ ] 2 条件成立で stderr に "WARN" + "lethal trifecta" 出力 + exit 0
- [ ] 3 条件成立で同上
- [ ] 1 条件以下で stderr 静寂 + exit 0
- [ ] profile=minimal で完全 skip (state file 書き込みもしない)
- [ ] state file 不在/parse 失敗で hook 自体が exit 0 を維持
- [ ] commit message に `TASK-0107:` を含む
