# TASK-0139: `.github/workflows/release.yml` 新規 (tag push trigger + byte-identical 検証 + SHA256SUMS 生成 + release artifact attach)

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0139 |
| SPEC-ID   | SPEC-0018 |
| PLAN-ID   | PLAN-0018 |
| ステータス | Pending |
| 担当Agent | Implementation |
| 並列可否  | Yes (TASK-0140 と並列可) |
| 依存TASK  | none |
| 見積     | 60m |

## 責務

GitHub Actions workflow `.github/workflows/release.yml` を新規作成する。tag push (`v*.*.*`) で発火し、install.sh の byte-identical 検証 → SHA256 計算 → SHA256SUMS 生成 → `gh release create` で install.sh + SHA256SUMS を release artifact として attach する。

## 入力

- SPEC-0018 §「機能要件」FR-01 / FR-02 (workflow 仕様 + SHA256SUMS format)
- SPEC-0018 §「セキュリティ要件」SEC-01..06 (least privilege / no secret / tag protection)
- 既存 `scripts/generate-installer.sh` (byte-identical 検証の被参照)

## 出力

1. `.github/workflows/release.yml` (約 60-90 行、shellcheck pass、actionlint pass)
2. workflow 構造:
   - `name: Release`
   - `on: push: tags: ['v*.*.*']`
   - `permissions: contents: write` (一行明記、SEC-01)
   - `jobs.release.runs-on: ubuntu-latest`
   - steps: checkout → setup tools → byte-identical check → SHA256SUMS 生成 → release notes 生成 → `gh release create`

## File Scope

- 作成: `.github/workflows/release.yml`
- 変更: なし

## 禁止事項

- **`permissions:` を `contents: write` 以外に拡張しない** (SEC-01、cosign は SPEC-0019 で `id-token: write` 追加)
- 外部 action を `@latest` 参照しない (TASK-0120 で確立した SHA pin doctrine 遵守、`actions/checkout@<full-sha>` 形式)
- 外部 URL から code を fetch しない (SEC-06、supply chain pollution 防止)
- secrets を参照しない (`GITHUB_TOKEN` default のみ、SEC-02)
- branch push で発火する trigger を追加しない (`tags: v*.*.*` 限定、SEC-03)
- `--no-verify` / `--force` 系の git flag を使わない
- workflow 内で git commit / push しない (release 作成のみ、副作用なし)
- shellcheck error を残さない (R9)

## 完了条件

- [ ] `.github/workflows/release.yml` 存在、`tags: v*.*.*` trigger、`permissions: contents: write` 限定
- [ ] `actionlint .github/workflows/release.yml` で error 0 件
- [ ] workflow shell step に対し `shellcheck` で error 0 件
- [ ] 外部 action 参照は SHA pin (full 40-char hex)
- [ ] byte-identical step が `bash scripts/generate-installer.sh > /tmp/install.sh && diff install.sh /tmp/install.sh` を含む
- [ ] SHA256SUMS step が POSIX format (`<sha256>  install.sh`) で出力
- [ ] `gh release create` step が install.sh + SHA256SUMS を attach
- [ ] **(AC-15 invalid tag)** tag が `v<semver>` 形式でない場合 (`v1.0` / `1.6.0` / `vX.Y.Z-rc1` 等) に validation step で exit 1 (regex check)
- [ ] **(AC-17 release 重複)** `gh release create` が `release already exists` で fail した時、workflow が clean exit 1 (既存 release artifact を上書きしない)
- [ ] commit message に `TASK-0139:` 含む
