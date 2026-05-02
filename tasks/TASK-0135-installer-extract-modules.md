# TASK-0135: extract scripts/generator/ 7 modules + rewrite generate-installer.sh + byte-identical 確認

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0135 |
| SPEC-ID   | SPEC-0014 |
| PLAN-ID   | PLAN-0014 |
| ステータス | Pending |
| 並列可否  | No (foundation) |
| 依存TASK  | none |
| 見積     | 90m |

## 責務

`scripts/generate-installer.sh` (938 行) を 7 module に分割 → `scripts/generator/` 配下に配置 → parent generate-installer.sh を re-write (約 100-150 行) → 生成 install.sh が **byte-identical** であることを確認。

## 出力

1. `scripts/generator/01-templates.sh`: SPEC/PLAN/TASK/sage governance テンプレ embed (約 130-150 行)
2. `scripts/generator/02-config.sh`: `.sage/config.yaml` / claude-md-snippet / pre-commit hook (約 30-50 行)
3. `scripts/generator/03-rules.sh`: `templates/rules/*.md` (5 file、約 30 行)
4. `scripts/generator/04-hooks-base.sh`: Phase 1-2A hook (5 hook、約 50 行)
5. `scripts/generator/05-hooks-phase2b.sh`: Phase 2B hook (3 hook + sandbox + settings、約 40 行)
6. `scripts/generator/06-hooks-phase5.sh`: Phase 5+ hook + audit (mcp-allowlist / agent-inventory / runlog-* / 3 tests、約 80 行)
7. `scripts/generator/07-installer-main.sh`: install.sh main logic (write_file_if_new / update_file 呼び出し集約、約 250-300 行)
8. `scripts/generate-installer.sh` re-write: header / function 定義 / `for module in scripts/generator/*.sh; do source "$module"; done` (約 100-150 行)

## File Scope

- 作成: `scripts/generator/01-templates.sh` ... `07-installer-main.sh` (7 file)
- 変更: `scripts/generate-installer.sh`

## 禁止事項

- **install.sh の挙動を変更しない** (refactor only、byte-identical 必須)
- embed_file / write_file_if_new / update_file 関数の signature を変更しない
- 新規 file を embed しない (既存 list と完全一致)
- module file を executable にしない (chmod 644、source されるのみ)
- module 単独実行可能にしない (parent 依存設計)
- module 順序を numeric prefix 以外で制御しない (glob sort 保証)
- 各 module 内で環境変数 export しない (parent shell に副作用残さない)
- shellcheck error を残さない (R9)

## 完了条件

- [ ] `scripts/generator/` 配下に 7 module file
- [ ] 各 module `bash -n` で syntax error 0 件
- [ ] `bash scripts/generate-installer.sh > /tmp/install-new.sh && diff install.sh /tmp/install-new.sh` で 0 行 (byte-identical)
- [ ] `time bash scripts/generate-installer.sh > install.sh` < 2s
- [ ] shellcheck error 0 件 (全 module + parent)
- [ ] commit message に `TASK-0135:` 含む
