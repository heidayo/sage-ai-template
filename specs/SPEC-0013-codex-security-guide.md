# SPEC-0013: Codex Security Guide (Phase 3)

## メタデータ

| フィールド | 内容 |
|-----------|------|
| SPEC-ID   | SPEC-0013 |
| ステータス | Approved |
| 作成日    | 2026-05-02 |
| 更新日    | 2026-05-02 |
| 担当Agent | Spec Agent |
| 依存SPEC  | SPEC-0010 (Phase 1), SPEC-0011 (Phase 2A), SPEC-0012 (Phase 2B) |
| 権限レベル | system |

## 背景・目的

SAGE v2 改修ロードマップ Phase 3。Phase 1-2B で Claude Code 向け hooks / sandbox template / governance を整備したが、**Codex 利用者向けの security guidance は AGENTS.md §2.1 (12 行) と SECURITY.md §4 (簡潔表) のみ**。Codex 利用者にとって以下が散在しており参照しづらい:

- Codex CLI の `~/.codex/config.toml` 推奨設定 (sandbox_mode / approval_policy / [sandbox_workspace_write] network_access)
- Codex Cloud / web の agent internet access 制御
- CODEX_HOME redirect 攻撃 (CVE-2025-61260) 対策
- branch name / PR title / issue body を untrusted input として扱うルール (BeyondTrust 報告)
- codex-action を GitHub Actions で動かす際の hardening (`allow-users` / `OPENAI_API_KEY` scope / drop-sudo / job 順序)
- SAGE が Codex runtime enforcement を提供しないことの再確認

本 SPEC は `docs/codex-security.md` を新規作成し、上記を一元化する。AGENTS.md / SECURITY.md / governance §9 はリンクするだけで膨らませない (Codex review R7 doctrine 厳守)。

## 対象ユーザー

- SAGE 採用組織で Codex を **メインまたはサブとして** 利用する開発者
- AGENTS.md §2.1 を読んで詳細を求める読者
- Codex を GitHub Actions (codex-action) で動かす CI 担当者
- security 監査担当 (Codex 関連 CVE への SAGE の対応状況確認)

## スコープ（含む）

- `docs/codex-security.md` 新規作成 (一次ソース引用付き)。セクション:
  1. **概要** — SAGE は Codex runtime enforcement を提供しない doctrine 再確認 + 補完関係
  2. **Codex CLI 推奨設定** — `~/.codex/config.toml` の sandbox_mode / approval_policy / [sandbox_workspace_write] network_access。実 TOML 例
  3. **Codex Cloud / web** — agent internet access の環境単位管理、setup phase と agent phase の分離
  4. **CODEX_HOME redirect 攻撃 (CVE-2025-61260) 対策** — Codex CLI 0.23.0+ への更新、`.env` 経由の redirect を疑う、Phase 2B `protect-sage-files.sh` の content check が `.env` 書き込みで CODEX_HOME を block する旨
  5. **Untrusted input as code** — branch name / PR title / issue body / [AGENTS.md](http://AGENTS.md) を untrusted として扱う。BeyondTrust 報告と整合
  6. **codex-action GitHub Actions hardening** — `allow-users` 制限 / `OPENAI_API_KEY` 専用化 / drop-sudo / Codex job を最後に置く / branch name shell injection 対策。実 YAML サンプル
  7. **incident response** — Codex 関連 incident の triage 手順 (`gh api` で audit log 確認、token rotate)
  8. **References** — Codex 公式 config-reference / cloud internet-access / codex-action security / 主要 CVE NVD link
- `AGENTS.md` §2.1: 末尾に `docs/codex-security.md` への 1 行リンク追加 (callout 全体の長さは Codex review R7 上限内に維持)
- `SECURITY.md` §4 (Out of Scope) と §3 (Threat Model) の Codex 関連行に `docs/codex-security.md` への参照追加
- `sage/governance.md` §9.2 の Codex sandbox 行 / §9.6 関連ドキュメント節に `docs/codex-security.md` 追加
- `README.md` の関連リンク section (もしくは目次相当箇所) に Codex 利用者向けエントリ追加 — 1 行のみ

## スコープ外（明示的に除外）

- **Codex sandbox / approval / network の自動セットアップ script**: SAGE は doctrine + 雛形のみ提供 (Codex review R2 厳守)。`scripts/sage-codex-setup.sh` のような自動化は別 SPEC で扱う
- **`templates/settings/codex/config.toml.example` 雛形**: 採用するか否かは Phase 5 (SPEC-0015) で判断 — 本 SPEC は doc only
- **新規 hook 追加**: Phase 2B で Codex specificity は doctrine 化済、本 Phase で hook は追加しない
- **install.sh 分割**: SPEC-0014 (別 SPEC) で扱う
- **MCP allowlist runtime / agent identity inventory**: Phase 5 (SPEC-0015) で扱う

## 要件

### 機能要件

- [FR-01] `docs/codex-security.md` が新規作成され、上記 8 セクションすべてを含む
- [FR-02] FR-01 の各 CVE 引用 (CVE-2025-61260 / CVE-2025-59536 / CVE-2026-33068) が NVD または Check Point Research の一次ソース URL を持つ
- [FR-03] FR-01 の Codex CLI 設定例が公式 reference ([developers.openai.com/codex/config-reference](https://developers.openai.com/codex/config-reference)) と整合
- [FR-04] FR-01 の Codex Cloud 内 internet access 説明が公式 docs ([developers.openai.com/codex/cloud/internet-access](https://developers.openai.com/codex/cloud/internet-access)) と整合
- [FR-05] FR-01 の codex-action サンプルが公式 [openai/codex-action security](https://github.com/openai/codex-action/security) と整合 (`allow-users` 制限 / shell injection 対策)
- [FR-06] AGENTS.md §2.1 末尾に `docs/codex-security.md` への 1 行リンク追加 (callout 全体長さ ≤ 18 行)
- [FR-07] SECURITY.md §3 / §4 の Codex 関連行に `docs/codex-security.md` 参照追加
- [FR-08] sage/governance.md §9.2 / §9.6 に `docs/codex-security.md` への参照追加
- [FR-09] README.md の関連リンク節に 1 行追加

### 非機能要件

- [NFR-01] 互換性: 既存 hook / install.sh / Phase 1-2B 機能は完全保持
- [NFR-02] doc サイズ: `docs/codex-security.md` は 600 行以内 (読みやすさ優先)
- [NFR-03] CLAUDE.md 不変 (Codex 専用 doc なので Claude Code 向け最上位ファイルは触らない)
- [NFR-04] AGENTS.md 増分 ≤ 3 行 (Codex review R7 厳守)

### セキュリティ要件

- [SEC-01] `docs/codex-security.md` 内の TOML / YAML サンプルに本物の secret を含めない
- [SEC-02] サンプル `OPENAI_API_KEY` 値は `${{ secrets.OPENAI_API_KEY }}` 形式で reference のみ
- [SEC-03] CVE 引用が事実と整合 (fix version、影響範囲、引用 URL のすべてが公式情報と一致)

### 運用要件

- [OPS-01] `docs/codex-security.md` の最終更新日と "確認した Codex CLI version" を doc 末尾に明記
- [OPS-02] 将来 Codex CLI / Codex Cloud の仕様が変わった場合、CHANGELOG または release note で本 doc 更新を案内する手順を含める

## 受け入れ条件（Acceptance Criteria）

- [ ] AC-01: `test -f docs/codex-security.md` exit 0
- [ ] AC-02: `grep -c "## " docs/codex-security.md` >= 8 (8 セクション以上)
- [ ] AC-03: `grep -E "CVE-2025-61260|CVE-2025-59536|CVE-2026-33068" docs/codex-security.md | wc -l` >= 3
- [ ] AC-04: `grep -F "[sandbox_workspace_write]" docs/codex-security.md` 含む (Codex CLI 公式 schema)
- [ ] AC-05: `grep -F "developers.openai.com/codex/config-reference" docs/codex-security.md` 含む
- [ ] AC-06: `grep -F "developers.openai.com/codex/cloud/internet-access" docs/codex-security.md` 含む
- [ ] AC-07: `grep -F "github.com/openai/codex-action/security" docs/codex-security.md` 含む
- [ ] AC-08: `grep -F "docs/codex-security.md" AGENTS.md SECURITY.md sage/governance.md README.md | wc -l` >= 4 (各 file から 1 件以上参照)
- [ ] AC-09: `wc -l docs/codex-security.md` ≤ 600
- [ ] AC-10: `wc -l AGENTS.md` ≤ (現状 + 3) (NFR-04)
- [ ] AC-11: `bash scripts/sage-validate.sh` PASS
- [ ] AC-12: `bash scripts/sage-doctor.sh` 0 FAIL
- [ ] AC-13: `bash scripts/sage-doc-drift.sh` PASS

## 異常系

- 想定エラー1: Codex CLI 設定例が将来の version で deprecated → CHANGELOG / OPS-02 で更新責任を明示
- 想定エラー2: `docs/codex-security.md` の URL がリンク切れ → 一次ソース URL 全件 (NVD / OpenAI公式 / Check Point / BeyondTrust) を doc 内 References セクションに集約、変更時は 1 箇所修正で済む
- 境界ケース1: Codex を使わない user に doc の存在が context bloat になるか → CLAUDE.md は touch しない (NFR-03)、AGENTS.md は 1 行リンクのみ (NFR-04)

## 契約

- API: なし
- DB: なし
- イベント: なし
- File contract: `docs/codex-security.md` 新規 (約 600 行以内)、AGENTS.md / SECURITY.md / sage/governance.md / README.md は 1-3 行追記のみ

## リスク

- リスク1: doc 600 行は SAGE doctrine "簡潔さ" と矛盾する印象 → 各セクションを「TL;DR + 詳細 + 一次ソース link」3 段構成にし、TL;DR だけ読めば実用可能にする
- リスク2: Codex CLI 公式 docs が更新されて本 doc が陳腐化 → OPS-02 で更新手順、doc 末尾に "Last reviewed: YYYY-MM-DD with Codex CLI vX.Y.Z" を明記
- リスク3: codex-action sample yaml が本物の `OPENAI_API_KEY` を leak する → SEC-02 で `${{ secrets.OPENAI_API_KEY }}` 形式のみ使用、test fixture でも実値禁止
- リスク4: AGENTS.md §2.1 が膨らむ誘惑 → リンク追加だけ、説明は doc 側に書く

## 実装メモ（Implementation Agent向け）

- `docs/codex-security.md` は Phase 1 SECURITY.md / Phase 2A AGENTS.md §2.1 / Phase 2B governance §9 の延長として書く (重複説明は避け、リンクで参照)
- TOML / YAML サンプルは syntax-highlighted markdown code block (` ```toml ` / ` ```yaml `)
- 一次ソース引用は References セクションに集約、本文中はラベル参照 ([Codex CLI config][1] のような形式は不要、直接 URL link で OK)
- AGENTS.md §2.1 末尾追加は `> 詳細: [docs/codex-security.md](docs/codex-security.md)` 1 行のみ

## 関連ID

- PLAN-ID: PLAN-0013 (本 SPEC と同時作成)
- TASK-ID: TASK-0114 (`docs/codex-security.md` 本体作成), TASK-0115 (cross-references update + verify)
