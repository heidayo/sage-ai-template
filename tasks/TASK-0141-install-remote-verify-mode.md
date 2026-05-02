# TASK-0141: install.sh `--verify-checksum --remote` mode 追加

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0141 |
| SPEC-ID   | SPEC-0018 |
| PLAN-ID   | PLAN-0018 |
| ステータス | Pending |
| 担当Agent | Implementation |
| 並列可否  | No (TASK-0139 完了後、SHA256SUMS URL format 確定が前提) |
| 依存TASK  | TASK-0139 |
| 見積     | 45m |

## 責務

`scripts/generator/07-installer-main.sh` (install.sh の生成元) に `--verify-checksum --remote` mode を追加する。default (no `--remote`) は従来の local 比較を維持し、`--remote` 指定時のみ release artifact の SHA256SUMS を fetch して現状 install.sh と比較する。

## 入力

- SPEC-0018 §「機能要件」FR-05 (`--verify-checksum --remote` 仕様)
- SPEC-0018 §「エラーケース」EC-04 / EC-05 (network 不可 / SHA256SUMS format 不正の挙動)
- TASK-0139 完了で確定する SHA256SUMS URL format (`releases/latest/download/SHA256SUMS`)
- 既存 `_sha256_cmd()` 関数 (TASK-0097 で導入、scripts/generator/07-installer-main.sh 内)

## 出力

1. `scripts/generator/07-installer-main.sh` 内の `--verify-checksum` 処理拡張
2. 動作分岐:
   - `--verify-checksum` (no `--remote`): 従来通り local `.sage/install-state.yaml` の sha256 と現状 file の sha256 を比較
   - `--verify-checksum --remote`: `curl -fsSL https://github.com/heidayo/sage-ai-template/releases/latest/download/SHA256SUMS` を fetch、現状 install.sh の sha256 と比較
3. error handling:
   - 一致: exit 0、`OK: install.sh matches release v$VERSION`
   - 不一致: exit 1、stderr に `FAIL: remote SHA256 mismatch: expected X, got Y`
   - network 不可 (`curl` fail): warning + exit 0、`WARN: remote SHA256SUMS fetch failed; verification skipped`
   - SHA256SUMS format 不正: exit 1、`FAIL: SHA256SUMS line format invalid`

## File Scope

- 変更: `scripts/generator/07-installer-main.sh` (該当 verify-checksum 処理ブロックのみ)

## 禁止事項

- 既存 `--verify-checksum` (no `--remote`) の動作を破壊しない (NFR-01 backward compat)
- `curl` ではなく `wget` などの代替 HTTP クライアントを追加しない (既存 `_sha256_cmd` パターンと整合性維持)
- `--remote` mode で SHA256SUMS 以外のリソースを fetch しない (SEC-06)
- network 不可で script 全体を fail させない (EC-04 graceful)
- `gh` CLI に依存しない (install.sh は SAGE 未導入環境でも動作する必要があるため、curl のみで完結)
- shellcheck error を残さない (R9)
- TASK-0140 の結果を待たずに `02-config.sh` の URL 変更を本 TASK で行わない (責務分離)

## 完了条件

- [ ] `scripts/generator/07-installer-main.sh` の verify-checksum ブロックに `--remote` 分岐
- [ ] `bash scripts/generate-installer.sh > install.sh` で生成された install.sh が `--verify-checksum --remote` を受け付ける
- [ ] `bash install.sh --verify-checksum --remote` 実行で network 利用可能環境では SHA256 比較 (release artifact 存在前提では skip でも可)
- [ ] network 不可環境 (`unshare -n` Linux / mock fail) で warning + exit 0
- [ ] SHA256SUMS 取得 mock で format 不正時に exit 1
- [ ] `bash install.sh --help` に `--remote` 説明追加
- [ ] shellcheck error 0 件 (07-installer-main.sh)
- [ ] commit message に `TASK-0141:` 含む
