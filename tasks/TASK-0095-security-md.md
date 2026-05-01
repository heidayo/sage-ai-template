# TASK-0095: SECURITY.md 新規作成

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0095 |
| SPEC-ID   | SPEC-0010 |
| PLAN-ID   | PLAN-0010 |
| ステータス | Pending |
| 担当Agent | Implementation |
| 並列可否  | Yes |
| 依存TASK  | none |
| 見積     | 45m |

## 責務

SAGE の脆弱性報告手順、サポート対象バージョン、threat model、非対応範囲を SECURITY.md として明文化する。GitHub の自動認識する標準パス (リポジトリ直下) に配置。

## 入力

- SPEC-0010 FR-04
- Codex review R6 (Apache-2.0 は法務判断と分離せよ)
- Codex review R10 (一次ソース引用)
- 一次ソース: NVD CVE-2026-25723, NVD CVE-2026-33068, OWASP AI Agent Cheat Sheet, OWASP Agentic Skills Top 10, Anthropic Claude Code Sandboxing 公式, OpenAI Codex Sandbox 公式, Check Point CVE-2025-59536, BeyondTrust Codex token compromise

## 出力

`SECURITY.md` (新規, GitHub 標準フォーマット準拠) に以下のセクション:
1. **Supported Versions** (table: SAGE_VERSION → security update status)
2. **Reporting a Vulnerability** (private channel, response SLA)
3. **Threat Model Summary** (SAGE が想定する脅威カテゴリ)
4. **Out of Scope (Non-Coverage)** ⭐ Codex review R2 必須項目: 「SAGE does NOT provide runtime sandbox enforcement」「Claude Code / Codex 本体機能の置き換えではない」
5. **Known Risks** (install.sh 大型化、テンプレ supply chain 等の正直な開示)
6. **References** (CVE / OWASP / Anthropic / OpenAI 一次ソース)

## File Scope（変更許可範囲）

- 作成: `SECURITY.md`
- 変更: なし
- 削除: なし

## 禁止事項

- 他のファイルへの変更禁止
- 一次ソース URL は実在する公式ページのみ (Notion 内部ページや非公開 URL は引用しない)
- threat model は誇大表示禁止 — SAGE が「できること」と「できないこと」を正直に記述

## 完了条件

- [ ] `test -f SECURITY.md`
- [ ] `grep -q "Reporting a Vulnerability\|Reporting Security" SECURITY.md`
- [ ] `grep -q "Supported Versions" SECURITY.md`
- [ ] `grep -q "does NOT provide\|Out of Scope\|Non-Coverage\|Scope Boundary" SECURITY.md` (Codex R2 対応の正直開示)
- [ ] `grep -E "CVE-202[5-6]" SECURITY.md` (一次ソース引用)
- [ ] commit message に `TASK-0095:` を含む
