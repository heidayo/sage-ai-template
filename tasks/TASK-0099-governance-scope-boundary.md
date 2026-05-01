# TASK-0099: sage/governance.md に「SAGE Scope Boundary」章追加

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0099 |
| SPEC-ID   | SPEC-0010 |
| PLAN-ID   | PLAN-0010 |
| ステータス | Pending |
| 担当Agent | Implementation |
| 並列可否  | No (TASK-0095 SECURITY.md が先) |
| 依存TASK  | TASK-0095 |
| 見積     | 30m |

## 責務

SAGE が「提供するもの」と「提供しないもの」を明示的に章立て、Codex/Claude 本体の runtime sandbox を SAGE が置き換えるかのような過大表示を構造的に防ぐ。

## 入力

- SPEC-0010 FR-10, リスク4
- Codex review R2 (Sandbox は SAGE が "提供" するものと見せるな、Claude/Codex 本体機能であり SAGE はテンプレ提供のみ)
- 既存 `sage/governance.md` (12 章構成、原則 1-10 + 7 ライフサイクル)

## 出力

`sage/governance.md` の末尾に「13. SAGE Scope Boundary」章を追加。以下 3 リストを含む:

### 13.1 SAGE が提供するもの (What SAGE provides)
- ライフサイクルテンプレート (SPEC / PLAN / TASK)
- Quality Gate の構造 (Gate 1-5 の定義と CI workflow テンプレ)
- Lane 設計 (vibe / lite / standard / promotion)
- File Scope ルール
- Anti-pattern / Failure 蓄積の枠組み
- Hook テンプレート (`templates/hooks/`) — pattern matching 補助
- AI agent 向けルールファイル (CLAUDE.md / AGENTS.md / .claude/rules/)
- Skill / governance / traceability のドキュメント

### 13.2 SAGE が提供しないもの (What SAGE does NOT provide)
- **Claude Code / Codex 本体の runtime sandbox 強制**: filesystem isolation / network allowlist は Claude/Codex 側設定で実現する。SAGE は `templates/settings/` で雛形を示すのみ
- **MCP server の許可制御**: MCP runtime は Claude Code / Codex 本体の機能
- **GitHub branch protection の自動セットアップ**: opt-in script として別途提供 (SPEC-0012 予定)
- **Production credential / secret の保管**: vault / proxy / CI secrets で別途構築
- **AI モデル自体の脆弱性検出**: deterministic security scanner (gitleaks / trivy / semgrep 等) と組み合わせる前提
- **CVE 検出を block で強制する hook**: pattern matching 限界のため warn-only (Codex R3)

### 13.3 ユーザーが別途用意すべきもの (What you must bring)
- Claude Code / Codex 本体および最新 version (CVE-2026-25723 / CVE-2026-33068 / CVE-2025-61260 fix 適用済)
- リポジトリの GitHub branch protection 設定 (人間が GitHub UI または管理 script で実行)
- secret 管理基盤 (Vault / 1Password / GitHub Encrypted Secrets 等)
- deterministic security scanner (gitleaks, trivy, semgrep 等)
- incident response 担当者と連絡網

### 13.4 章の冒頭で示す姿勢 (リスク4 への対応)
- 「SAGE は強い」と見せるよりも、「何が SAGE の責務外か」を正直に開示することが、長期的な信頼と correct adoption を生む (= Codex review との合意点)
- runtime tool (Claude/Codex) との **補完関係** を強調 (置き換えではない)

## File Scope（変更許可範囲）

- 変更: `sage/governance.md` (末尾追記のみ、既存 1-12 章は変更禁止)
- 削除: なし

## 禁止事項

- 既存 1-12 章の修正禁止
- SECURITY.md と内容が矛盾しないこと (TASK-0095 と整合)
- runtime sandbox を SAGE が提供するかのような表現禁止
- protect-sage-files hook が sage/ 編集を block する場合: commit message に `TASK-0099: SPEC-0010 human-approved meta change` を明記

## 完了条件

- [ ] `grep -q "Scope Boundary\|スコープ境界" sage/governance.md`
- [ ] `grep -q "does NOT provide\|提供しない" sage/governance.md`
- [ ] `grep -q "runtime sandbox" sage/governance.md`
- [ ] sage/governance.md の章番号が 13 まで連続している (1-12 既存 + 13 新規)
- [ ] commit message に `TASK-0099:` を含む
