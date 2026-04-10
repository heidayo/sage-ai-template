# PLAN-0003: Hooks実用化

## メタデータ

| フィールド | 内容 |
|-----------|------|
| PLAN-ID   | PLAN-0003 |
| SPEC-ID   | SPEC-0003 |
| ステータス | Draft |
| 作成日    | 2026-04-10 |
| 担当Agent | Planning Agent |

## 変更レイヤ

- [ ] controller
- [ ] usecase
- [ ] domain
- [x] infrastructure（.claude/settings.json, hooks スクリプト）
- [ ] frontend
- [x] infra（.sage/config.yaml, install.sh, generate-installer.sh）
- [ ] test

## 影響範囲

- `.claude/settings.json` — hook 定義の大幅拡張
- `templates/hooks/` — 新規ディレクトリ（5スクリプト）
- `scripts/generate-installer.sh` — hook テンプレート埋め込み追加
- `install.sh`（再生成対象）— hook 展開ロジック追加
- `.sage/config.yaml` — hooks.profile セクション追加
- `.sage/metrics/` — sessions.jsonl 出力先

## 実装方針

### bash ベースの軽量 hook

全 hook を bash で実装する。Node.js 依存を避け、SAGE の既存スクリプト群と統一する。

JSON stdin のパースは `jq` を使用し、`jq` 不在時は `grep` ベースのフォールバックを提供する:

```bash
# jq available
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""' 2>/dev/null)
# fallback
if [ -z "$COMMAND" ]; then
  COMMAND=$(echo "$INPUT" | grep -oP '"command"\s*:\s*"[^"]*"' | head -1 | sed 's/.*: *"//;s/".*//')
fi
```

### プロファイル制御

各 hook スクリプトの先頭でプロファイルチェックを行う:

```bash
# Profile gating
PROFILE=$(grep 'hooks:' .sage/config.yaml 2>/dev/null | grep 'profile:' | awk '{print $2}' || echo "standard")
case "$REQUIRED_PROFILE" in
  standard) [[ "$PROFILE" == "minimal" || "$PROFILE" == "none" ]] && exit 0 ;;
  strict)   [[ "$PROFILE" != "strict" ]] && exit 0 ;;
esac
```

### hook 配置構造

```
templates/hooks/
├── block-dangerous-commands.sh   # PreToolUse (Bash) — standard+
├── protect-sage-files.sh         # PreToolUse (Edit|Write) — standard+
├── check-file-scope.sh           # PreToolUse (Edit|Write) — standard(warn) / strict(block)
├── session-start.sh              # SessionStart — minimal+
└── session-stop.sh               # Stop — minimal+
```

### install.sh への統合

`generate-installer.sh` の `embed_file` 関数（行18-33）で各 hook を heredoc として埋め込む。install.sh 実行時に `templates/hooks/` に展開し、`.claude/settings.json` に hook 定義を追加する。

## タスク分解

| TASK-ID | 責務 | 担当Agent | 見積 | 依存TASK | 並列可否 |
|---------|------|----------|------|---------|---------|
| TASK-0035 | `.sage/config.yaml` に `hooks.profile` セクション追加 | Implementation | 10m | - | Yes |
| TASK-0036 | `templates/hooks/block-dangerous-commands.sh` 実装 | Implementation | 30m | TASK-0035 | No |
| TASK-0037 | `templates/hooks/protect-sage-files.sh` 実装 | Implementation | 30m | TASK-0035 | No |
| TASK-0038 | `templates/hooks/check-file-scope.sh` 実装 | Implementation | 30m | TASK-0035 | No |
| TASK-0039 | `templates/hooks/session-start.sh` 実装 | Implementation | 30m | TASK-0035 | No |
| TASK-0040 | `templates/hooks/session-stop.sh` 実装 | Implementation | 20m | TASK-0035 | No |
| TASK-0041 | `.claude/settings.json` に5つの hook 定義を追加 | Implementation | 15m | TASK-0036〜TASK-0040 | No |
| TASK-0042 | `scripts/generate-installer.sh` に hook テンプレート埋め込み追加 | Implementation | 20m | TASK-0036〜TASK-0040 | No |
| TASK-0043 | `install.sh` に hook 展開 + settings.json 登録ロジック追加 | Implementation | 30m | TASK-0042 | No |
| TASK-0044 | SPEC-0003 の全 AC 検証 | Test | 30m | TASK-0043 | No |

**並列実行可能グループ**:
- グループA（並列）: TASK-0035
- グループB（TASK-0035完了後、互いに並列）: TASK-0036, TASK-0037, TASK-0038, TASK-0039, TASK-0040
- グループC（グループB完了後、互いに並列）: TASK-0041, TASK-0042
- グループD（直列）: TASK-0043 → TASK-0044

## リスク

- リスク1: Claude Code の hook stdin 形式が将来変更される可能性 -> 軽減策: JSON パース部分を共通関数化し、1箇所の修正で対応可能にする
- リスク2: `jq` 不在環境での grep フォールバックが不完全 -> 軽減策: フォールバック時は安全側（exit 0）に倒す。正確なパースは jq 依存を明示
- リスク3: protect-sage-files.sh が SAGE テンプレート自身の開発を妨げる -> 軽減策: `hooks.profile: minimal` でバイパス可能

## 必要な検証

- [x] unit test（各 hook スクリプトの入出力テスト — echo + exit code 確認）
- [ ] integration test（Claude Code セッションでの実動作確認）
- [x] security scan（hook スクリプト自体のセキュリティ — SPEC-0004 で対応）
- [ ] e2e test（該当なし）
- [x] architecture boundary check（hook が SAGE のファイルスコープルールと整合するか）
