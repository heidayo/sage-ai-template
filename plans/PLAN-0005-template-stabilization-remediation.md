# PLAN-0005: テンプレート安定化 + セキュリティ是正

## メタデータ

| フィールド | 内容 |
|-----------|------|
| PLAN-ID   | PLAN-0005 |
| SPEC-ID   | SPEC-0005 |
| ステータス | Done |
| 作成日    | 2026-04-10 |
| 担当Agent | Planning Agent |

## 変更レイヤ

- [x] infrastructure（scripts/, templates/hooks/, .sage/config.yaml）
- [x] infra（.github/workflows/, install.sh generation, publish/update flow）
- [x] governance/documentation（README.md, CLAUDE.md, AGENTS.md, sage/traceability.md）
- [ ] domain
- [ ] frontend

## 影響範囲

- CI 安全性: `.github/workflows/`
- ローカルガードレール: `templates/hooks/`, `.claude/settings.json`
- 配布整合性: `scripts/generate-installer.sh`, `scripts/sage-adopt.sh`, `install.sh`, `.claude/skills/sage-review/`
- 運用スクリプト: `sage-update-check.sh`, `sage-report.sh`, `sage-validate.sh`, `sage-doctor.sh`, `sage-publish.sh`
- 公開文書: `README.md`, `CLAUDE.md`, `AGENTS.md`, `sage/traceability.md`, `specs/SPEC-0001-*`
- historical traceability artifact: `plans/PLAN-0001-*`, `tasks/TASK-0001`〜`TASK-0026`, `tasks/done-def-*`

## 実装方針

### 1. Security-first, compatibility-first

- 危険な実行経路を先に閉じる
- 利用者の入力フォーマットは壊さず、実装側を両対応に寄せる
- 自動更新は継続チェックするが、自動実行は廃止して通知-only にする

### 2. Generated / source の整合を保つ

- `install.sh` は手編集せず、`scripts/generate-installer.sh` から再生成する
- review rubric は `templates/skills/` を source of truth とし、配布スクリプトと現行 `.claude/skills/` に反映する

### 3. 文書矛盾は定義の一本化で解消する

- CLAUDE.md / AGENTS.md は「ツール別 canonical」を明示する
- Gate 定義は 5 gates に揃え、Gate 5 は conditional として扱う
- AGENT-ID は run log の `agent_id` フィールドに記録する定義へ寄せる

### 4. 欠損履歴は retrospective placeholder として補完する

- 存在しない `PLAN-0001` と `TASK-0001`〜`TASK-0026` は、元の粒度を偽装せず historical placeholder として作成する
- `SPEC-0001` の関連IDは補完後の artifact を参照させ、未検証の AC は実測に合わせて更新する
- Done Definition は SPEC 単位で round-1 の骨格を作り、参照切れを解消する

## タスク分解

| TASK-ID | 責務 | 担当Agent | 見積 | 依存TASK | 並列可否 |
|---------|------|----------|------|---------|---------|
| TASK-0054 | workflow / hook / packaging / documentation を含む一括安定化修正 | Implementation | 1 turn | none | No |

## リスク

- action SHA pin の更新忘れ -> 元 tag をコメントに残す
- install/update 行動変更への戸惑い -> README と script メッセージを揃える
- 保護文書修正の範囲逸脱 -> 定義の衝突解消に必要な最小差分に限定する
- retrospective placeholder が「当時の完全な実装記録」と誤解される -> placeholder であることを各ファイルに明記する

## 残留制約

- `PLAN-0001` と `TASK-0001`〜`TASK-0026` の補完は traceability 欠損を埋める retrospective placeholder であり、失われた原本の復元ではない
- この limitation は historical artifact の説明責任に限定され、現行の Gate / hook / packaging / documentation の挙動には影響しない

## 必要な検証

- [x] structural: `bash -n` 対象 scripts / hooks / regenerated install.sh
- [x] functional: targeted command checks for hook profile, force-with-lease, report, validate, update-check
- [x] security: heredoc injection regression, action pinning, remote execution removal
- [x] architecture: traceability docs / gate definitions / agent-id mapping consistency
