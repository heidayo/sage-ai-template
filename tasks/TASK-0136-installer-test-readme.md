# TASK-0136: test-installer-modularize.sh (6 シナリオ) + scripts/generator/README.md

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0136 |
| SPEC-ID   | SPEC-0014 |
| PLAN-ID   | PLAN-0014 |
| ステータス | Pending |
| 並列可否  | No |
| 依存TASK  | TASK-0135 |
| 見積     | 45m |

## 責務

`templates/hooks/tests/test-installer-modularize.sh` 6 シナリオ + `scripts/generator/README.md` 構造説明 + 新 SPEC 追加手順。

## 出力

1. `templates/hooks/tests/test-installer-modularize.sh` (6 シナリオ):
   - Scenario 1: byte-identical (`diff install.sh /tmp/new.sh | wc -l` で 0)
   - Scenario 2: 7 module 全 `bash -n` syntax PASS
   - Scenario 3: 新 hook 追加 simulation (06-hooks-phase5.sh に embed_file 1 行追加 → 再生成 → 1 行 diff、他 module 不変)
   - Scenario 4: install.sh 削除後の再生成成功
   - Scenario 5: module source 順序 (numeric prefix 01..07)
   - Scenario 6: `time` で perf < 2s

2. `scripts/generator/README.md`:
   - 各 module の責務一覧
   - 新 SPEC 追加時の手順 (どの module を編集するか Phase 別に明示)
   - 命名規則 (numeric prefix 01..NN)
   - 禁止事項 (executable bit / 単独実行 / 環境変数 export)

## File Scope

- 作成: `templates/hooks/tests/test-installer-modularize.sh`
- 作成: `scripts/generator/README.md`

## 禁止事項

- test 内で `install.sh` を **書き換えない** (read-only、`/tmp/` で生成して比較のみ)
- README で実装詳細を冗長に書かない (簡潔に、SPEC/PLAN へのリンクで十分)
- test シナリオ 3 (新 hook 追加 simulation) で実 module file を変更しない (sandbox copy で実施)
- shellcheck error を残さない

## 完了条件

- [ ] 6 シナリオ全 PASS
- [ ] README に Phase 別 module mapping table
- [ ] commit message に `TASK-0136:` 含む
