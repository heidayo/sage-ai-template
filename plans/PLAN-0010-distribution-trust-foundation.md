# PLAN-0010: Distribution & Trust Foundation

## メタデータ

| フィールド | 内容 |
|-----------|------|
| PLAN-ID   | PLAN-0010 |
| SPEC-ID   | SPEC-0010 |
| ステータス | Active |
| 作成日    | 2026-05-01 |
| 担当Agent | Planning Agent |

## 変更レイヤ

- [x] infra (LICENSE, SECURITY.md, CONTRIBUTING.md, install.sh)
- [x] doc (README.md, ATTRIBUTION.md, sage/governance.md, CLAUDE.md, AGENTS.md)
- [ ] controller / usecase / domain / infrastructure / frontend / test (該当なし)

## 影響範囲

- **法的**: 業務利用可否を変える (ライセンス確定)
- **AI agent runtime**: CLAUDE.md / AGENTS.md 冒頭追記により agent の context 開始位置が変わる
- **install workflow**: install.sh に新規フラグ 3 つ追加 (既存挙動は維持)
- **governance**: scope boundary 章追加により外部評価軸が明確化
- **影響を受けない**: src/, tests/, .github/workflows/ (Phase 1 では一切触らない), specs/0001-0009 (既存 SPEC は変更なし)

## 実装方針

### 全体方針
1. **Codex review (cross-model adversarial review) の指摘 R1-R10 を反映済みの Phase 1 を 1 PR で完結**
2. **既存 hook (protect-sage-files) と File Scope ルールを尊重**: CLAUDE.md / sage/ への変更は human-approved 例外として commit message に明記
3. **install.sh 直接編集ではなく generator 経由を理想とするが、Phase 1 では install.sh 末尾に option parser を追加する最小変更パターンを採用**。generator は次 PR で同期

### TASK 順序と依存
1. TASK-0094 (License) → 法的ブロッカー解消が最優先、独立
2. TASK-0095 (SECURITY.md) → 並列可能 (TASK-0094 と独立)
3. TASK-0096 (CONTRIBUTING.md) → 並列可能
4. TASK-0097 (install.sh hardening) → 並列可能だが install.sh が大きいため最後にやって他と衝突回避
5. TASK-0098 (CLAUDE/AGENTS callout) → 並列可能
6. TASK-0099 (governance Scope Boundary) → SECURITY.md と整合させたいので TASK-0095 後

## タスク分解

| TASK-ID | 責務 | 担当Agent | 見積 | 依存TASK | 並列可否 |
|---------|------|----------|------|---------|---------|
| TASK-0094 | LICENSE (Apache-2.0) 作成 + README ライセンス節修正 + ATTRIBUTION 拡張 | Implementation | 30m | none | Yes |
| TASK-0095 | SECURITY.md 新規作成 (vuln report / supported versions / threat model / non-coverage) | Implementation | 45m | none | Yes |
| TASK-0096 | CONTRIBUTING.md 新規作成 (PR process / hook tests / shellcheck / commit format) | Implementation | 30m | none | Yes |
| TASK-0097 | install.sh に --dry-run / --verify-checksum / --print-provenance オプション追加 | Implementation | 90m | none | Yes (大きいので最後) |
| TASK-0098 | CLAUDE.md / AGENTS.md 冒頭に template-trust callout 追加 | Implementation | 20m | TASK-0095 (SECURITY.md にリンクするため) | No |
| TASK-0099 | sage/governance.md に「SAGE Scope Boundary」章追加 | Implementation | 30m | TASK-0095 (整合させるため) | No |

## リスク

- リスク1: install.sh 編集中に既存ロジックを破壊 → 既存挙動はフラグなし呼び出しで完全保持、新規パスは早期 return パターンで切り分け
- リスク2: protect-sage-files hook が CLAUDE.md / sage/ 編集を block → commit 前に hook 動作を確認、必要なら hook 内部で SPEC-0010 例外条件を追加 (今回は本体 hook を変更せず、commit message での説明と承認証跡で対応)
- リスク3: Apache-2.0 LICENSE 全文の貼り付け誤り → 公式テキスト ([apache.org/licenses/LICENSE-2.0.txt](https://www.apache.org/licenses/LICENSE-2.0.txt)) からの完全コピー、改変禁止
- リスク4: shellcheck で install.sh の既存 warning が大量に出る → 既存 warning は本 PR 範囲外として SARIF baseline 化を検討 (今回はフルパスを通す)

## 必要な検証

- [x] structural: shellcheck install.sh
- [x] structural: bash scripts/sage-validate.sh
- [x] structural: bash scripts/sage-doctor.sh
- [x] functional: bash install.sh --dry-run (副作用なし確認)
- [x] functional: bash install.sh --print-provenance (出力検証)
- [x] functional: bash install.sh --verify-checksum (state あり/なしの両方)
- [x] security: gitleaks detect --no-git
- [x] doc consistency: CLAUDE.md と AGENTS.md の callout が同じ意味の内容になっているか
- [x] AC-01〜AC-12 全件 (SPEC-0010 受け入れ条件)
