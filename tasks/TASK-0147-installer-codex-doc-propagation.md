# TASK-0147: installer propagation for Codex delegation doc

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0147 |
| SPEC-ID   | SPEC-0022 |
| PLAN-ID   | PLAN-0022 |
| ステータス | Done |
| 担当Agent | Implementation |
| 並列可否  | No |
| 依存TASK  | TASK-0145 |
| 見積     | 45m |

## 責務

`docs/codex-delegation-packet.md` を install.sh に埋め込み、新規導入先でも生成・更新されるようにする。

## 入力

- `docs/codex-delegation-packet.md`
- `scripts/generator/03-rules.sh`
- `scripts/generator/07-installer-main.sh`

## 出力

- generator に `TMPL_CODEX_DELEGATION_PACKET` embed 追加
- installer main に `docs/codex-delegation-packet.md` write/update 追加
- `install.sh` 再生成

## File Scope（変更許可範囲）

- 変更: `scripts/generator/03-rules.sh`
- 変更: `scripts/generator/07-installer-main.sh`
- 変更: `install.sh`

## 禁止事項

- 生成物 `install.sh` を手編集しない
- docs 以外の新規 runtime enforcement を追加しない

## 完了条件

- [x] `bash scripts/generate-installer.sh > /tmp/new.sh && diff install.sh /tmp/new.sh` が PASS
- [x] `install.sh` に `TMPL_CODEX_DELEGATION_PACKET` が含まれる
- [x] installer main が `docs/codex-delegation-packet.md` を write/update する
