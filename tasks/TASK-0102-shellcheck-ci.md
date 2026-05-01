# TASK-0102: shellcheck CI integration in sage-structural-gate.yml

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0102 |
| SPEC-ID   | SPEC-0011 |
| PLAN-ID   | PLAN-0011 |
| ステータス | Pending |
| 担当Agent | Implementation |
| 並列可否  | Yes |
| 依存TASK  | none |
| 見積     | 30m |

## 責務

`.github/workflows/sage-structural-gate.yml` に shellcheck step を追加。新規/変更された shell ファイルは error level で block、既存ファイルは WARN 表示のみ (baseline 保持)。

## 入力

- SPEC-0011 FR-03, NFR-03, OPS-02
- Codex review R9 (shellcheck 通過必須)
- 既存 sage-structural-gate.yml

## 出力

1. `.github/workflows/sage-structural-gate.yml` に shellcheck job 追加 (または既存 structural step に shellcheck command 追加)
2. shellcheck severity を `--severity=error` でゲート (warning は GitHub Annotation のみ)
3. PR で変更された .sh ファイルのみを対象 (`gh pr diff` または `git diff` ベース)、または全 `.sh` を対象に baseline 比較
4. `templates/hooks/*.sh`, `scripts/*.sh`, `templates/hooks/tests/*.sh`, `install.sh` を target に含める

## File Scope（変更許可範囲）

- 変更: `.github/workflows/sage-structural-gate.yml`
- 削除: なし

## 禁止事項

- 既存 structural gate の他チェック (lint, format, schema validation 等) を変更しない
- 新しい workflow ファイルの追加禁止 (既存 gate に統合)
- shellcheck の version pin に commit SHA を使う (tag 直指定は再現性低下、SAGE doctrine に反する)
- 既存 .sh の warning 修正は本 TASK では行わない (scope 外)

## 完了条件

- [ ] `.github/workflows/sage-structural-gate.yml` に `shellcheck` 文字列が含まれる
- [ ] step が `--severity=error` (またはそれと等価な error-only mode) を使用
- [ ] action は commit SHA pin (例: `koalaman/shellcheck-alpine@sha256:...` または `ludeeus/action-shellcheck@<sha>`)
- [ ] CI dry-run (workflow lint) で構文エラーなし: `gh workflow view sage-structural-gate.yml` (PR 上で確認)
- [ ] commit message に `TASK-0102:` を含む
