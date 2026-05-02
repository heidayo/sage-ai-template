# TASK-0122: MCP allowlist registry schema + template

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0122 |
| SPEC-ID   | SPEC-0015 |
| PLAN-ID   | PLAN-0015 |
| ステータス | Pending |
| 担当Agent | Implementation |
| 並列可否  | No (基盤) |
| 依存TASK  | none |
| 見積     | 30m |

## 責務

`.sage/mcp-allowlist.yaml` の YAML schema を確定し、`templates/sage/mcp-allowlist-template.yaml` として user 配布可能な雛形を作成する。後続 TASK-0123 / 0124 が schema を前提にロジックを書けるよう、本 TASK で schema を **immutable な基盤** として確定する。

## 入力

- SPEC-0015 FR-01 (registry schema 必須 field)
- SPEC-0015 SEC-02 (positive list 原則)
- 既存 `templates/mcp-json-template.json` の構造 (参考のみ)
- Codex CLI `~/.codex/config.toml` の `[mcp_servers]` 構造 (参考のみ)

## 出力

1. `templates/sage/mcp-allowlist-template.yaml` 新規:
   - 必須 field 6 個 (`name`, `command`, `args`, `approved_by`, `approved_at`, `expires_at` は推奨で省略可)
   - optional field 1 個 (`notes`)
   - top-level `version: "1.0"` + `bypass: { enabled: false }` (default)
   - 例として 2 server entry (`playwright` / `filesystem`) — 各々 SPEC-ID + 日付 + 期限を記入
   - inline コメントで「positive list」「server 追加時は SPEC-ID または PR URL を `approved_by` に記録」を案内

2. `templates/sage/README.md` 新規 (もし不在なら):
   - `templates/sage/` ディレクトリの位置づけ (registry / inventory 雛形配布元)
   - 各 template の目的と使用方法 1 行
   - SPEC-0015 へのリンク

## File Scope（変更許可範囲）

- 作成: `templates/sage/mcp-allowlist-template.yaml`
- 作成: `templates/sage/README.md` (既存しない場合)
- 削除: なし

## 禁止事項

- `.sage/mcp-allowlist.yaml` (実 user データ) を作成しない (本 TASK は template のみ)
- schema に runtime enforcement を示唆する field (`block_on_drift`, `kill_process` 等) を含めない (SAGE doctrine §9.2 違反)
- `expires_at` に default 自動計算ロジックを template に含めない (静的 example でのみ示す)

## 完了条件

- [ ] `templates/sage/mcp-allowlist-template.yaml` 存在
- [ ] `version`, `servers`, `bypass` の 3 top-level key 存在
- [ ] `servers` に 2+ example entry、各々 `name`/`command`/`args`/`approved_by`/`approved_at`/`expires_at`/`notes` 全揃い
- [ ] inline コメントで positive list 原則 / SPEC-ID 記入ルールを案内
- [ ] yaml lint で error 0 件 (`python3 -c "import yaml; yaml.safe_load(open('templates/sage/mcp-allowlist-template.yaml'))"`)
- [ ] commit message に `TASK-0122:` を含む
