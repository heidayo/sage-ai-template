# TASK-0140: sage-publish.sh + sage-validate.sh + sage-update-check.sh + scripts/generator/02-config.sh 拡張

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0140 |
| SPEC-ID   | SPEC-0018 |
| PLAN-ID   | PLAN-0018 |
| ステータス | Pending |
| 担当Agent | Implementation |
| 並列可否  | Yes (TASK-0139 と並列可) |
| 依存TASK  | none |
| 見積     | 75m |

## 責務

配布チャネル変更に伴う既存 4 script の拡張:

1. **`scripts/sage-publish.sh`**: 既存 (version bump + Gist 更新) に加え、`git tag v$NEW_VERSION && git push --tags` で release.yml をトリガー。`--no-release` flag で legacy mode、`--no-gist` flag で Releases-only mode を提供
2. **`scripts/sage-validate.sh` Check 9**: 既存は Gist URL pattern 限定で Releases URL では SKIP に倒れていた。両 pattern を許可し、URL 種別を判定して適切な sync check を実施
3. **`scripts/sage-update-check.sh`**: 既存は Gist URL から install.sh を fetch して SAGE_VERSION 抽出。Releases URL の場合は `gh api repos/heidayo/sage-ai-template/releases/latest` で tag_name 取得して比較
4. **`scripts/generator/02-config.sh`**: template `.sage/config.yaml` 生成箇所の `installer_url` default を Releases URL に変更

## 入力

- SPEC-0018 §「機能要件」FR-03 / FR-04 / FR-06 / FR-07
- 既存 4 script の現状動作 (Gist URL 前提のロジック)

## 出力

1. `scripts/sage-publish.sh`: `--no-release` / `--no-gist` flag 追加、`git tag` + `git push --tags` step 追加、SHA256SUMS local 生成 + `.sage/install-state.yaml` 記録
2. `scripts/sage-validate.sh`: Check 9 拡張、Gist + Releases 両 pattern 認識、URL 種別判定 → 適切な sync check
3. `scripts/sage-update-check.sh`: Releases URL 検出 → `gh api` で latest tag 取得 → version 比較
4. `scripts/generator/02-config.sh`: installer_url default を `https://github.com/heidayo/sage-ai-template/releases/latest/download/install.sh` に変更

## File Scope

- 変更: `scripts/sage-publish.sh`
- 変更: `scripts/sage-validate.sh`
- 変更: `scripts/sage-update-check.sh`
- 変更: `scripts/generator/02-config.sh`

## 禁止事項

- **既存 `.sage/config.yaml` の installer_url を強制書き換えない** (NFR-01 backward compat)
- Gist URL の動作を破壊しない (利用者影響回避)
- `--no-release` / `--no-gist` 同時指定時の優先順位を曖昧にしない (明示 error or 明示 priority)
- `gh api` 呼び出しが network 不可で fail しても script 全体を fail させない (graceful、warning + skip)
- shellcheck error を残さない (R9)
- 既存 sage-publish.sh の `trap rollback_version_file EXIT` を破壊しない (rollback safety 維持)

## 完了条件

- [ ] `scripts/sage-publish.sh --help` に `--no-release` / `--no-gist` 表示
- [ ] `bash scripts/sage-publish.sh patch --no-release` で git tag が作られない (legacy mode)
- [ ] `bash scripts/sage-validate.sh` Check 9 が Gist URL / Releases URL fixture 両方で `OK:` 表示 (`SKIPPED:` でない)
- [ ] `bash scripts/sage-update-check.sh` が Releases URL 設定環境で `gh api` 呼び出し → version 比較 (network 不可時 graceful)
- [ ] `scripts/generator/02-config.sh` の installer_url default が Releases URL
- [ ] `bash scripts/generate-installer.sh > install.sh` で生成された install.sh の template `.sage/config.yaml` 部分の installer_url が Releases URL
- [ ] **(AC-16 backward compat)** 既存 Gist URL fixture (`installer_url: https://gist.githubusercontent.com/...`) で `bash install.sh --update` が exit 0、`.sage/config.yaml` の installer_url 行が変更されないこと (`diff` で 0 行)
- [ ] shellcheck error 0 件 (4 script)
- [ ] commit message に `TASK-0140:` 含む
