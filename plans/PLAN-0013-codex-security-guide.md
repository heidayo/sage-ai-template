# PLAN-0013: Codex Security Guide (Phase 3)

## メタデータ

| フィールド | 内容 |
|-----------|------|
| PLAN-ID   | PLAN-0013 |
| SPEC-ID   | SPEC-0013 |
| ステータス | Active |
| 作成日    | 2026-05-02 |
| 担当Agent | Planning Agent |

## 変更レイヤ

- [x] doc (docs/codex-security.md, AGENTS.md, SECURITY.md, sage/governance.md, README.md)
- [ ] infra / controller / usecase / domain / frontend / test / CI (該当なし)

## 影響範囲

- **Codex 利用者**: 散在情報を一元参照可能に。adoption 障壁低下
- **AGENTS.md 読者**: §2.1 から詳細リンクで移動可能 (本文は短いまま)
- **影響を受けない**: hook / install.sh / .claude/settings.json / src/ / CI workflow

## 実装方針

### 全体方針
1. **doc-only PR**: hook / installer / CI 変更なし。doc レビューに集中
2. **既存 doc は touch しない**: AGENTS.md / SECURITY.md / governance.md / README.md は **追記のみ** (各 1-3 行)、Codex review R7 厳守
3. **一次ソース引用の正確性**: TASK-0115 で References を spot-check (URL 200 OK 確認)

### TASK 順序と依存
1. TASK-0114 (`docs/codex-security.md` 本体作成) — 独立、まず本体作成
2. TASK-0115 (cross-references update + verify) — TASK-0114 後

## タスク分解

| TASK-ID | 責務 | 担当Agent | 見積 | 依存TASK | 並列可否 |
|---------|------|----------|------|---------|---------|
| TASK-0114 | `docs/codex-security.md` 8 セクション作成 (TL;DR + 詳細 + 一次ソース link 構成) | Implementation | 90m | none | Yes (start first) |
| TASK-0115 | AGENTS.md §2.1 + SECURITY.md §3/§4 + governance §9 + README.md cross-references + verify | Implementation | 30m | TASK-0114 | No |

## リスク

- リスク1: Codex CLI 公式 schema 確認のため WebFetch (`developers.openai.com/codex/config-reference`) が必要 — 確認が公式 URL に対して 200 OK か事前に確認
- リスク2: doc が膨らんで 600 行 (NFR-02) を超える → セクションごとに行数モニタリング、超過時は補足を別 doc に分割
- リスク3: AGENTS.md 増分 3 行 (NFR-04) を超える → 1 行リンクのみに厳守、test に grep -c で行数増分の上限確認
- リスク4: governance §9 が肥大化 — §9.2 既存行への追記のみ、新規 sub-section 追加禁止

## 必要な検証

- [x] structural: `bash scripts/sage-validate.sh`
- [x] structural: `bash scripts/sage-doc-drift.sh` (CLAUDE.md と AGENTS.md の section header 整合)
- [x] structural: `bash scripts/sage-doctor.sh`
- [x] doc: 一次ソース URL 全件 200 OK (TASK-0115 で `gh api` または `curl -I` で spot-check)
- [x] AC-01〜AC-13 全件 (SPEC-0013 受け入れ条件)
