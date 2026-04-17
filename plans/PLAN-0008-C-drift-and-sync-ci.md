# PLAN-0008-C: Drift 検知 + 配布経路同期 CI

## メタデータ

| フィールド | 内容 |
|-----------|------|
| PLAN-ID   | PLAN-0008-C |
| SPEC-ID   | SPEC-0008 |
| ステータス | Active |
| 作成日    | 2026-04-17 |
| 担当Agent | Planning Agent |

## 変更レイヤ

- [ ] controller
- [ ] usecase
- [ ] domain
- [x] infra (scripts + CI workflow)
- [ ] frontend
- [ ] test

## 影響範囲

CLAUDE.md と AGENTS.md の整合性、`install.sh` の 3 経路 (repo / generator / Gist) 同期、templates/ から .claude/ へのコピー、.gitignore と tracked ファイルの整合性。`scripts/sage-validate.sh` と `scripts/sage-doc-drift.sh` (新規)、`scripts/sage-installer-reproduce.sh` (新規)。

## 実装方針

- **双子文書 drift (TASK-0077)**: pre-marker 領域の H2/H3 見出し集合比較 + 意図的差異 (Claude Code ↔ Codex 等) の正規化。LLM は非決定的なので使わない。
- **install.sh 再現性 (TASK-0078)**: `bash scripts/generate-installer.sh` の出力と tracked install.sh の byte-level diff をチェック。templates 編集後の regen 忘れを検出。
- **templates → .claude コピー検証 (TASK-0079)**: `sage-publish.sh --dry-run` (新規 flag) 実行後 `git diff --exit-code .claude/` = 0 の CI job を追加。
- **.gitignore/tracked 整合 (TASK-0080)**: `git ls-files -ci --exclude-standard` が非空で FAIL。`sage-validate.sh` の Check 8 として組み込み。
- **installer_url 3 経路同期 (TASK-0081)**: `sage-validate.sh` Check 9 で Gist URL 到達性 + sha256 比較。オフライン CI は SKIP、main 直コミットのみ FAIL。

## タスク分解

| TASK-ID | 責務 | 担当Agent | 見積 | 依存TASK | 並列可否 |
|---------|------|----------|------|---------|---------|
| TASK-0077 | CLAUDE.md ↔ AGENTS.md drift 検知 script | Implementation | 1h | TASK-0085 | No |
| TASK-0078 | install.sh 再現性 CI script + regen | Implementation | 0.5h | - | Yes |
| TASK-0079 | templates → .claude copy 検証 | Implementation | 1h | - | Yes |
| TASK-0080 | .gitignore/tracked 整合 Check 8 追加 | Implementation | 0.3h | TASK-0086 | No |
| TASK-0081 | installer_url 3 経路 sha256 検証 Check 9 | Implementation | 1h | - | Yes |

## リスク

- リスク 1: Gist sha256 検証が CI の外部ネットワークに依存 → 軽減策: オフライン時 SKIP fallback
- リスク 2: 双子文書 drift 検知の偽陰性 (本文が乖離しても見出しが一致) → 軽減策: 共通節本文の正規化 diff を将来追加、本 PLAN では見出しレベルで留める

## 必要な検証

- [x] unit test (各 script に negative case テスト済)
- [ ] integration test
- [ ] security scan
- [ ] e2e test
- [ ] architecture boundary check
