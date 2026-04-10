# PLAN-0001: SAGE テンプレートリポジトリ初期構築

## メタデータ

| フィールド | 内容 |
|-----------|------|
| PLAN-ID   | PLAN-0001 |
| SPEC-ID   | SPEC-0001 |
| ステータス | Done |
| 作成日    | 2025-04-09 |
| 更新日    | 2026-04-10 |
| 担当Agent | Planning Agent（historical placeholder 補完） |

## 変更レイヤ

- [x] governance / documentation
- [x] infrastructure / CI
- [x] prompt / workflow scaffolding
- [ ] domain
- [ ] frontend

## 影響範囲

- ルート文書: `README.md`, `CLAUDE.md`, `AGENTS.md`, `.gitignore`, `.editorconfig`, `makefile`
- ガバナンス: `sage/`
- テンプレート: `specs/`, `plans/`, `tasks/`
- CI / GitHub: `.github/`
- エージェント資産: `.claude/prompts/`, `.claude/rules/`, `.claude/skills/`
- スクリプト / 設定: `scripts/`, `.sage/config.yaml`
- 導入ガイド: `docs/`

## 実装方針

- 初期導入可能なテンプレート一式を先に揃える
- 仕様・計画・タスクのテンプレートとガバナンス文書を同時に配置する
- CI / 導入スクリプト / エージェント文書を最低限動く状態まで一括整備する

## タスク分解

| TASK-ID | 責務 | 担当Agent | 見積 | 依存TASK | 並列可否 |
|---------|------|----------|------|---------|---------|
| TASK-0001 | リポジトリ基盤ファイルの初期配置 | Implementation | historical | none | Yes |
| TASK-0002 | `CLAUDE.md` 初期ブートストラップ | Implementation | historical | TASK-0001 | Yes |
| TASK-0003 | `AGENTS.md` 初期ブートストラップ | Implementation | historical | TASK-0001 | Yes |
| TASK-0004 | `sage/charter.md` 整備 | Implementation | historical | TASK-0001 | Yes |
| TASK-0005 | `sage/governance.md` 整備 | Implementation | historical | TASK-0001 | Yes |
| TASK-0006 | `sage/quality-gates.md` 整備 | Implementation | historical | TASK-0001 | Yes |
| TASK-0007 | `sage/anti-patterns.md` 整備 | Implementation | historical | TASK-0001 | Yes |
| TASK-0008 | `sage/failures.md` 整備 | Implementation | historical | TASK-0001 | Yes |
| TASK-0009 | `sage/adoption-phases.md` 整備 | Implementation | historical | TASK-0001 | Yes |
| TASK-0010 | `sage/traceability.md` 整備 | Implementation | historical | TASK-0001 | Yes |
| TASK-0011 | `specs/` テンプレート整備 | Implementation | historical | TASK-0001 | Yes |
| TASK-0012 | `plans/` テンプレート整備 | Implementation | historical | TASK-0001 | Yes |
| TASK-0013 | `tasks/` テンプレート整備 | Implementation | historical | TASK-0001 | Yes |
| TASK-0014 | `.sage/config.yaml` 初期定義 | Implementation | historical | TASK-0001 | Yes |
| TASK-0015 | Gate 1 workflow 初期作成 | Implementation | historical | TASK-0014 | No |
| TASK-0016 | Gate 2 workflow 初期作成 | Implementation | historical | TASK-0014 | No |
| TASK-0017 | Gate 3 workflow 初期作成 | Implementation | historical | TASK-0014 | No |
| TASK-0018 | Gate 4 workflow 初期作成 | Implementation | historical | TASK-0014 | No |
| TASK-0019 | Gate 5 workflow 初期作成 | Implementation | historical | TASK-0014 | No |
| TASK-0020 | Claude Code review workflow 初期作成 | Implementation | historical | TASK-0014 | No |
| TASK-0021 | GitHub テンプレート / 設定ファイル整備 | Implementation | historical | TASK-0001 | Yes |
| TASK-0022 | `.claude/prompts/` 整備 | Implementation | historical | TASK-0001 | Yes |
| TASK-0023 | `.claude/rules/` 整備 | Implementation | historical | TASK-0001 | Yes |
| TASK-0024 | `.claude/skills/` 整備 | Implementation | historical | TASK-0001 | Yes |
| TASK-0025 | `scripts/` 導入・検証スクリプト整備 | Implementation | historical | TASK-0014 | Yes |
| TASK-0026 | `docs/` / `README.md` / `makefile` 整備 | Implementation | historical | TASK-0001 | Yes |

## リスク

- 初期構築の粒度が大きくなりやすい -> TASK に分解して責務を明示する
- 言語非依存テンプレートのため Gate 1 / 2 が環境依存で SKIP しやすい -> コメント付きテンプレートとして提供する
- historical artifact の後補完により、当時の完全記録と誤解される -> retrospective placeholder であることを明示する

## 必要な検証

- [x] `make validate`
- [x] `make id-gen TYPE=spec`
- [x] `bash scripts/sage-adopt.sh` を空リポジトリで実行

## 補足

- このファイルは 2026-04-10 に traceability 欠損解消のため retrospective placeholder として補完した
- 元の詳細計画ファイルは保全されておらず、ここでは `SPEC-0001` の責務単位をもとに復元している
