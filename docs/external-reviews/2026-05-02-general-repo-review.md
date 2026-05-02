# 外部レビュー triage — 2026-05-02 (general repo review)

| フィールド | 内容 |
|---|---|
| 受領日 | 2026-05-02 |
| レビュアー | 外部 (general repo review、Codex 由来ではない一般評価) |
| 対象 SAGE_VERSION | v1.5.0 |
| 総合スコア | 78 / 100 |
| 担当 Agent | Spec Agent (本 triage) → 各 SPEC で分担 |
| 関連 PR | #26 (TASK-0138) までを評価対象 |

## 1. レビュー位置づけ

本レビューは Codex の cross-model adversarial review (TASK-0100/0106/0112/0113/0116) とは異なり、汎用的な OSS リポジトリ評価の観点から実施された。スコア配分:

| 観点 | スコア | 主要コメント |
|---|---|---|
| 問題設定 | 9.0 | AI 並列開発の構造問題を正しく捉えている |
| アーキテクチャ | 8.5 | L1-L4 多層ガードレール、Lane 設計が整理 |
| セキュリティ意識 | 8.5 | Threat Model / Out of Scope を正直に明示 |
| 実効性 | 7.0 | instruction file 依存、runtime sandbox ではない |
| OSS 成熟度 | 4.5 | Star 1、Contributor 1、外部検証不足 |
| 導入安全性 | 5.5 | install.sh 364KB / 9429 行、署名・SLSA 未整備 |
| ドキュメント品質 | 8.5 | README / SECURITY / ATTRIBUTION / codex-security |
| 実務導入しやすさ | 7.0 | Lane 設計は良いが既存フローとの調整が必要 |

## 2. Triage 方針

レビュー指摘を 3 つに分類:

- **(A) 既存資産でカバー済み** — レビュアーが認識していなかった既存 SPEC/TASK で対応済
- **(B) 部分対応** — local 機能はあるが remote / 配布側に未対応
- **(C) 真のギャップ** — 既存資産になく新規 SPEC が必要

### 2.1 (A) 既存資産でカバー済み

| レビュー指摘 | 既存対応 |
|---|---|
| Installer 巨大化 (Shell 98.4%、保守困難) | [SPEC-0014](../../specs/SPEC-0014-installer-modularize.md) — `scripts/generator/` 7 モジュール化、`test-installer-modularize.sh` |
| MCP 供給網リスク (`@latest` 差し替え、未承認 server) | [SPEC-0015](../../specs/SPEC-0015-mcp-allowlist-audit-and-agent-identity.md) — allowlist + transport-aware audit |
| Agent identity drift (declared vs observed mismatch) | [SPEC-0017](../../specs/SPEC-0017-agent-identity-inventory.md) — RUN log runtime field + validator drift |
| Hook テスト不足 | `templates/hooks/tests/` 16 ファイル + `run-tests.sh` (custom shell harness) |
| Threat Model 不在 | [SECURITY.md §3-4](../../SECURITY.md) — Out of Scope 明示済 |
| Installer 再現性 (byte-level reproducibility) | TASK-0078 (進行中) |
| Installer URL ドリフト検出 | TASK-0081 + `--print-provenance` / `--verify-checksum` (TASK-0097) |
| Recursive hallucination spiral | sage/anti-patterns.md AP-07 (SPEC-0007) |
| Codex CLI / Codex Cloud / codex-action 固有脅威 | [docs/codex-security.md](../codex-security.md) (SPEC-0013) |
| RUN log 検索効率 | [SPEC-0016](../../specs/SPEC-0016-runlog-sqlite-fts.md) — SQLite FTS5 |

### 2.2 (B) 部分対応

| レビュー指摘 | 現状 | ギャップ |
|---|---|---|
| Installer 署名 / SHA256SUMS 配布 | local `--print-provenance` / `--verify-checksum` のみ (TASK-0097) | リモート SHA256SUMS 公開なし、cosign 署名なし |
| Visual Threat Model | テキストのみ (SECURITY.md §3) | mermaid / SVG 図なし |
| Adoption guide | docs/setup.md / maintainer-guide.md は存在 | Next.js / Go / monorepo / OSS 別の移植例なし |

### 2.3 (C) 真のギャップ (新規 SPEC 候補)

| 優先度 | レビュー指摘 | 対応 |
|---|---|---|
| **HIGH** | GitHub Releases primary distribution (Gist 単独脱却) | **SPEC-0018** Installer Supply Chain Hardening Phase 1 |
| **HIGH** | URL pinning (immutable artifact per version) | **SPEC-0018** に統合 |
| **HIGH** | SHA256SUMS の公開配布 | **SPEC-0018** に統合 |
| MED | cosign keyless signing | SPEC-0019 (Phase 2 として後続) |
| MED | SLSA provenance | SPEC-0020 (Phase 3 として後続) |
| MED | Adoption guide (Next.js / Go / monorepo) | SPEC-0021 候補 (docs lane) |
| LOW | Visual threat model 図 | SPEC-0018 docs 範囲で同梱検討 |
| LOW | bats への移行 | **SKIP** — 既存 16 ファイルの custom harness で機能十分 |
| LOW | SAGE on/off ベンチマーク (逸脱率測定) | **SKIP** — 探索的、vibe レーン向け、本テンプレ範囲外 |

## 3. 着手順序と理由

### Phase 6.1: SPEC-0018 (Installer Supply Chain Hardening) — 本レビューで起票

**起票理由**:
1. レビュアーの最大懸念 (`curl ... | bash` 推奨しない、署名・SLSA 未整備) に直撃
2. SECURITY.md §3.1 で既に "Phase 6+ で別途起票予定" として明示済 (位置づけ整合)
3. Phase 1-5 の既存資産 (TASK-0097 `--verify-checksum`, TASK-0081 URL sync) と接続可能
4. cosign / SLSA より複雑度が低く、単一 PR で完結可能

**スコープ**:
- ✅ GitHub Releases primary distribution (release workflow + tag-triggered publish)
- ✅ SHA256SUMS の公開配布 (リリース成果物として添付)
- ✅ URL pinning (`releases/download/vX.Y.Z/install.sh` 形式の immutable URL)
- ✅ SECURITY.md §3.1 status 更新 (`partial` → `improved`)
- ⏸️ cosign 署名 (SPEC-0019 Phase 6.2 で扱う)
- ⏸️ SLSA provenance (SPEC-0020 Phase 6.3 で扱う)

### Phase 6.2: SPEC-0019 (cosign keyless signing) — 後続

GitHub Actions OIDC + Sigstore Fulcio の keyless 署名を install.sh に付与。SPEC-0018 の Releases 配布が前提。

### Phase 6.3: SPEC-0020 (SLSA provenance) — 後続

`slsa-framework/slsa-github-generator` で build attestation を生成。SPEC-0018/0019 完了後に着手。

### Phase 7+: SPEC-0021 (Adoption guide) — 別レーン

Next.js / Go / monorepo / 既存 CLAUDE.md ありリポジトリへの段階導入手順。docs lane で対応可能。

## 4. SKIP 判定根拠

### 4.1 bats 移行を見送る理由

- 既存 `templates/hooks/tests/` 16 ファイル + `run-tests.sh` で既に 138+ テストが運用中
- bats は外部依存追加 (Homebrew / apt 経由インストール) を要求し、SAGE の "self-contained" 原則と衝突
- レビュアー指摘は style preference であり、機能的問題は提示されていない
- 移行コスト >> 改善価値

### 4.2 SAGE on/off ベンチマークを見送る理由

- 「逸脱率測定」は科学的設計 (controlled study, sample size, statistical significance) を要求
- 単独 maintainer / Star 1 OSS で実施するには規模が過大
- 本質的に研究プロジェクトであり、テンプレート供給の責任範囲外
- 採用希望者は自社リポジトリで A/B 検証可能 (テンプレート側で支援する性質ではない)

## 5. 関連メタ

- 本 triage doc は SAGE governance 範囲外の **docs/external-reviews/** に配置 (sage/ は人間専用)
- 将来の外部レビューも同パターン (`docs/external-reviews/YYYY-MM-DD-<source>.md`) で蓄積
- 各 SPEC の進捗は `specs/SPEC-XXXX-*.md` で追跡、本 doc はインデックス役

## 6. 更新履歴

- 2026-05-02: 初版 (SPEC-0018 起票根拠を整理)
