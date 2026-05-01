# SPEC-0010: Distribution & Trust Foundation

## メタデータ

| フィールド | 内容 |
|-----------|------|
| SPEC-ID   | SPEC-0010 |
| ステータス | Approved |
| 作成日    | 2026-05-01 |
| 更新日    | 2026-05-01 |
| 担当Agent | Spec Agent |
| 依存SPEC  | SPEC-0004 (install lifecycle), SPEC-0007 (AI code risk) |
| 権限レベル | system |

## 背景・目的

外部評価 (2026-05) で SAGE は以下のブロッカーを指摘された:

1. **ライセンス未整備** — README.md 行531 が `All Rights Reserved. ライセンスは未定です。` と明記されており、業務利用・改変・再配布が法的に不可
2. **install.sh 5779行 / 213KB の自己完結スクリプト** — `.git/hooks` / `.github/workflows` / `.claude/settings.json` / `.sage/` を一括書き換える supply chain 攻撃面、未検証実行は危険
3. **`AGENTS.md` / `CLAUDE.md` テンプレ供給網リスク** — AI agent の行動規範を外部テンプレートに委ねる構造そのものが、Check Point CVE-2025-59536 / CVE-2026-33068 (Claude Code trust dialog bypass / 8.8 HIGH) と同質の攻撃面
4. **Codex runtime enforcement 過大表示** — `AGENTS.md` 自体に "Codex sessions are expected to honor the same rules via prompt-level guidance rather than runtime interception" と書かれており、SAGE が Codex の sandbox / approval / network を強制できない事実が doctrine 化されていない

Cross-model レビュー (Codex) でも上記評価は妥当と判定された。一次ソース (NVD CVE-2026-25723/33068, OWASP AI Agent Cheat Sheet, OWASP Agentic Skills Top 10, Anthropic Claude Code Sandboxing 公式, OpenAI Codex Sandbox 公式, Check Point Research, BeyondTrust, Trend Micro, Endor Labs Benchmark, BVP Identity Governance 等 65 資料) を統合した結果、Phase 1 として以下を最優先で解消する。

本 SPEC は SAGE v2 改修ロードマップ Phase 1 (Distribution / Legal / Trust) を実装する。

## 対象ユーザー

- SAGE テンプレートを業務利用検討中の組織 (法的にブロックされている)
- SAGE installer を実行する開発者 (現状は未検証実行を強いられる)
- AI coding agent (Claude Code / Codex) を SAGE 配下で動かす開発者 (テンプレ供給網警告がない)
- SAGE governance を読む開発者・監査担当 (Scope Boundary が不明)

## スコープ（含む）

- LICENSE ファイル新規作成 (Apache-2.0)
- README.md 「ライセンス」節の修正 (All Rights Reserved 削除、Apache-2.0 と ATTRIBUTION 参照を追加)
- ATTRIBUTION.md への外部知識統合源 (一次ソース 65資料の出典マップ) 追加
- SECURITY.md 新規作成 (vulnerability reporting / supported versions / threat model / non-coverage)
- CONTRIBUTING.md 新規作成 (PR process / hook tests / shellcheck / commit format / SAGE 自身への適用)
- install.sh の `--dry-run`, `--verify-checksum`, `--print-provenance` オプション追加 (分割は SPEC-0011 以降に分離)
- scripts/generate-installer.sh の対応修正 (install.sh は generated artifact のため)
- CLAUDE.md / AGENTS.md 冒頭に template-trust callout 追加 (cloned repo を未レビューで信頼してはいけない旨を最上位に明記)
- sage/governance.md に「SAGE Scope Boundary」章を追加 (SAGE が提供するもの / 提供しないもの = Codex/Claude runtime sandbox を置き換えるものではない、と明示)

## スコープ外（明示的に除外）

- **install.sh の分割**: 213KB → モジュール化は別 SPEC (SPEC-0011) で扱う。今回は dry-run / checksum 機能追加のみ。理由: 分割は generator 大改修となり、PR が肥大化して review 不能になる。
- **branch protection の自動セットアップ**: GitHub token 要求で installer 権限が肥大化するため、別 opt-in script (SPEC-0012) として分離。
- **runtime sandbox profile 提供**: Claude Code / Codex 本体機能であり SAGE は templates 提供しかできない。Phase 2 (SPEC-0013) で `templates/settings/` として扱う。
- **MCP allowlist / agent identity inventory**: Phase 5 (SPEC-0015) で扱う。
- **CVE 検証 hook / Lethal Trifecta 検出**: Phase 2 (SPEC-0013) で扱い、warn-only 起動とする。
- **Codex 専用 docs/codex-security.md**: Phase 3 (SPEC-0014) で扱う。
- **既存 SPEC-0001〜0009 の修正**: governance / anti-patterns / failures は既存定義を尊重し、本 SPEC では追記のみ。

## 要件

### 機能要件

- [FR-01] LICENSE ファイルが Apache-2.0 のフルテキストで存在し、Copyright holder が明記されていること
- [FR-02] README.md 行 531 の `All Rights Reserved. ライセンスは未定です。` が削除され、Apache-2.0 表記と ATTRIBUTION.md 参照に置き換わっていること
- [FR-03] ATTRIBUTION.md に「外部知識統合源」セクションが追加され、Phase 1 で参照した 65 資料の主要一次ソース URL が列挙されていること
- [FR-04] SECURITY.md が以下を含むこと: (a) vulnerability disclosure procedure, (b) supported versions table, (c) threat model summary, (d) explicit non-coverage section ("SAGE does NOT provide runtime sandbox enforcement")
- [FR-05] CONTRIBUTING.md が以下を含むこと: (a) SAGE-on-SAGE 開発フロー, (b) hook テスト要求, (c) shellcheck 必須, (d) commit message 規約, (e) PR テンプレート参照
- [FR-06] `bash install.sh --dry-run` が、ファイル書き込みを一切行わずに「作成予定ファイル一覧」「変更予定ファイル一覧」「実行予定 hook 一覧」を stdout に出力すること
- [FR-07] `bash install.sh --verify-checksum` が、`.sage/install-state.yaml` の SHA256 と現状ファイルの SHA256 を比較し、drift を検出して exit code 1 を返すこと
- [FR-08] `bash install.sh --print-provenance` が、SAGE_VERSION, installer SHA256, GitHub release URL, Apache-2.0 表記を出力すること
- [FR-09] CLAUDE.md / AGENTS.md の冒頭 (Section 0 として) に、cloned repository は未レビューで信頼してはいけない旨の callout が日英 (またはどちらか + リンク) で配置されていること
- [FR-10] sage/governance.md に「13. SAGE Scope Boundary」章が追加され、(a) SAGE が提供するもの, (b) SAGE が提供しないもの, (c) ユーザーが別途用意すべきもの の 3 リストが含まれること

### 非機能要件

- [NFR-01] 互換性: 既存の `bash install.sh` (フラグなし) は従来と完全に同じ挙動を保つ
- [NFR-02] サイズ: install.sh のサイズ増加は 5% 以内 (現 213KB → 224KB 以内)
- [NFR-03] レビュー容易性: 1 PR で全ファイル合計 1500 行以内 (新規ファイル + 既存ファイル diff)

### セキュリティ要件

- [SEC-01] LICENSE / SECURITY.md / CONTRIBUTING.md / 修正後 README はいずれも secret を含まないこと (gitleaks 通過必須)
- [SEC-02] install.sh の新規オプション (--dry-run / --verify-checksum / --print-provenance) は、いかなる場合も `.git/hooks/`, `.github/workflows/`, `~/.ssh`, `~/.aws`, `.env*` を読み書きしないこと
- [SEC-03] `--print-provenance` が出力する SHA256 は、installer 自身が ChainOfTrust 起点であることを明示するためのもので、外部 URL 取得を伴わないこと

### 運用要件

- [OPS-01] CHANGELOG entry または release note ドラフトを作成する (将来 release 時に使用)
- [OPS-02] PR description に「SAGE v2 Phase 1 (SPEC-0010)」を明記し、Codex review (cross-model adversarial review) のサマリーを引用する

## 受け入れ条件（Acceptance Criteria）

- [ ] AC-01: `test -f LICENSE && grep -q "Apache License" LICENSE` が成功する
- [ ] AC-02: `! grep -q "All Rights Reserved" README.md` が成功する (該当文字列が存在しない)
- [ ] AC-03: `test -f SECURITY.md && grep -q "Reporting" SECURITY.md && grep -q "non-coverage\|Scope Boundary\|does NOT provide" SECURITY.md` が成功する
- [ ] AC-04: `test -f CONTRIBUTING.md && grep -q "shellcheck" CONTRIBUTING.md` が成功する
- [ ] AC-05: `bash install.sh --dry-run` が exit 0 で終了し、`Would create:` または同等の出力を含み、対象ディレクトリのファイル数が変化しないこと
- [ ] AC-06: `bash install.sh --print-provenance` が `SAGE_VERSION` / `Apache-2.0` / `SHA256` を含む出力を返す
- [ ] AC-07: `head -50 CLAUDE.md | grep -i "template\|trust\|review before"` が match する (callout が冒頭 50 行内)
- [ ] AC-08: `head -50 AGENTS.md | grep -i "template\|trust\|review before"` が match する
- [ ] AC-09: `grep -q "Scope Boundary" sage/governance.md && grep -q "does NOT provide\|提供しない" sage/governance.md` が成功する
- [ ] AC-10: `bash scripts/sage-validate.sh` が pass する
- [ ] AC-11: `shellcheck install.sh scripts/*.sh` が pass する (既存 warning は許容、新規 warning なし)
- [ ] AC-12: `gitleaks detect --no-git --redact` が clean

## 異常系

- 想定エラー1: `--dry-run` 中に `mkdir -p` を誤って実行してしまう → mkdir/touch/cp/curl すべて DRY_RUN ガードでラップする
- 想定エラー2: `--verify-checksum` 実行時に `.sage/install-state.yaml` が存在しない (初回 install 前) → 「state not found, run install first」と warning して exit 0 (失敗扱いしない)
- 想定エラー3: ATTRIBUTION.md に既存セクションがある状態で追記する際の merge 衝突 → 末尾追記 (`---` separator + 新セクション) で対処
- 境界ケース1: CLAUDE.md / AGENTS.md は SAGE 管理ファイルだが、本 SPEC で human approval 済み変更として例外的に編集 → commit message に「TASK-XXXX: human-approved meta change」と明記

## 契約

- API: なし
- DB: なし
- イベント: なし
- File contract: LICENSE, SECURITY.md, CONTRIBUTING.md は repository 直下に配置 (GitHub が自動認識する標準パス)

## リスク

- リスク1: CLAUDE.md / AGENTS.md の冒頭追記により context window 圧迫 → callout は最大 8 行以内、詳細は SECURITY.md / governance.md へリンクで逃がす (Codex review R7 への対応)
- リスク2: install.sh の dry-run 実装漏れで誤書き込み発生 → 全 mkdir/touch/cp/redirection を `dry_run_guard` 関数経由に統一、テスト (TASK-0097) で全 path をカバー
- リスク3: Apache-2.0 採用が将来の license 変更を妨げる → ATTRIBUTION.md と SECURITY.md に「license は legal review 結果次第で変更可能性あり」と注記
- リスク4: SAGE Scope Boundary 章が「SAGE は弱い」と読まれて adoption が下がる → 章の冒頭で「正直さは長期的な信頼を生む」doctrine を明記、Codex 等 runtime tool との 補完関係 を強調

## 実装メモ（Implementation Agent向け）

- install.sh は scripts/generate-installer.sh から自動生成される。両方を同期して変更すること。
- `.sage/install-state.yaml` の sha256 構造は既存 (install.sh 行 5723-5741) を流用。
- 既存 hook (`templates/hooks/protect-sage-files.sh`) は CLAUDE.md / sage/ の変更を block しうる。本 SPEC では human-approved 例外として、commit message に SPEC-0010 と human approval 旨を含める。
- CLAUDE.md / AGENTS.md の callout は Markdown blockquote (`>`) または Github admonition (`> [!WARNING]`) で実装。
- SECURITY.md の format は GitHub 推奨 ([github.com/.github/SECURITY.md](https://github.com/github/.github/blob/main/SECURITY.md) 参照)。
- 一次ソース引用は ATTRIBUTION.md に集約 (README / SECURITY を肥大化させない)。

## 関連ID

- PLAN-ID: PLAN-0010 (本 SPEC と同時作成)
- TASK-ID: TASK-0094 (License & ATTRIBUTION), TASK-0095 (SECURITY.md), TASK-0096 (CONTRIBUTING.md), TASK-0097 (install.sh hardening), TASK-0098 (CLAUDE/AGENTS callout), TASK-0099 (governance Scope Boundary)
