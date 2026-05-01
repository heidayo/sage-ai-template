# TASK-0096: CONTRIBUTING.md 新規作成

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0096 |
| SPEC-ID   | SPEC-0010 |
| PLAN-ID   | PLAN-0010 |
| ステータス | Pending |
| 担当Agent | Implementation |
| 並列可否  | Yes |
| 依存TASK  | none |
| 見積     | 30m |

## 責務

SAGE への contribution 手順を CONTRIBUTING.md として明文化。SAGE 自身が SAGE プロセス (SPEC + PLAN + TASK) で開発される事実を反映し、hook テスト要求と shellcheck 必須化を Codex review R8/R9 に従って明記する。

## 入力

- SPEC-0010 FR-05
- Codex review R8 (新規 hook には test 必須)
- Codex review R9 (shellcheck 通過必須)
- 既存 SAGE Lifecycle (CLAUDE.md / sage/governance.md)

## 出力

`CONTRIBUTING.md` (新規) に以下のセクション:
1. **Welcome** (短い導入)
2. **SAGE-on-SAGE Development Flow** (SAGE 自身も SPEC → PLAN → TASK で開発される事実、Lane 分類の説明)
3. **Before You Open a PR** (SPEC-ID / TASK-ID 必須、commit format `TASK-XXXX: ...`)
4. **Code Quality Requirements**:
   - shellcheck 必須 (新規 .sh ファイル全件、既存ファイル変更時は変更行)
   - 新規 hook には `templates/hooks/tests/` 以下にテスト追加必須
   - 各種 Gate (1-5) の概要と pass 基準への参照
5. **Documentation Changes** (CLAUDE.md / AGENTS.md / sage/ への変更は human approval 必須、commit に明記)
6. **Reporting Issues** (SECURITY.md への参照)
7. **License of Contributions** (Apache-2.0 への同意)

## File Scope（変更許可範囲）

- 作成: `CONTRIBUTING.md`
- 変更: なし
- 削除: なし

## 禁止事項

- 他のファイルへの変更禁止
- 既存 SAGE governance を矛盾なく参照する (重複説明は最小化、リンクで逃がす)
- contributor に過度な負担を強いる規約は避ける (現実的な最小要求)

## 完了条件

- [ ] `test -f CONTRIBUTING.md`
- [ ] `grep -q "shellcheck" CONTRIBUTING.md`
- [ ] `grep -q "TASK-" CONTRIBUTING.md` (commit format 例示)
- [ ] `grep -qi "hook" CONTRIBUTING.md` (hook test 要求)
- [ ] `grep -q "Apache-2.0\|Apache License" CONTRIBUTING.md`
- [ ] commit message に `TASK-0096:` を含む
