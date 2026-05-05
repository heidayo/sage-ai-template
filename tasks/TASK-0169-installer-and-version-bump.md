# TASK-0169: scripts/generator embed + install.sh regen + .sage-version 1.7.1→1.8.0

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0169 |
| SPEC-ID   | SPEC-0024 |
| PLAN-ID   | PLAN-0024 |
| ステータス | Done |
| 担当Agent | Implementation (shared-core) |
| 並列可否  | No (全 doctrine 確定後に installer 同期) |
| 依存TASK  | TASK-0163, TASK-0164, TASK-0165, TASK-0166, TASK-0167, TASK-0168 |
| 見積     | 75m |

## 責務

`scripts/generator/06-hooks-phase5.sh` に新 hook (test-property-section.sh) embed 追加 + `scripts/generator/07-installer-main.sh` に write/update entry 追加 + `install.sh` 再生成 + `.sage-version` 1.7.1 → 1.8.0 + **PR 内で `SHA256SUMS` を `shasum -a 256 install.sh > SHA256SUMS` で再計算 + commit** (SPEC-0018 / SPEC-0023 と同 pattern、PR レベル整合性を保つ)。`specs/_template.md` の Properties セクションは既存 `scripts/generator/01-templates.sh` の `TMPL_SPEC` embed で伝播する。

## 入力

- SPEC-0024 FR-10 (installer 伝播仕様)
- TASK-0162 確定の specs/_template.md Properties schema (embed 対象)
- TASK-0168 完了の templates/hooks/tests/test-property-section.sh (write 対象)
- 既存 scripts/generator/06-hooks-phase5.sh (Phase 5+ hook/test embed 配置)
- 既存 scripts/generator/07-installer-main.sh (write_file_if_new / update_file)
- 既存 install.sh (現 1.7.1 ベース、再生成対象)
- 既存 .sage-version (現値)

## 出力

### scripts/generator/06-hooks-phase5.sh

`TMPL_TEST_RUNLOG_DB_DOCTOR` の後に `TMPL_TEST_PROPERTY_SECTION` を embed 追加:

```bash
embed_file "TMPL_TEST_PROPERTY_SECTION" "$ROOT/templates/hooks/tests/test-property-section.sh"
echo ""
```

### scripts/generator/07-installer-main.sh

`templates/hooks/tests/test-property-section.sh` の write_file_if_new + update_file 両 mode 対応 (SPEC-0023 同 pattern)。

### install.sh

`bash scripts/generate-installer.sh > install.sh` で再生成 (`TMPL_SPEC` payload 内の Properties セクション + `TMPL_TEST_PROPERTY_SECTION` embed が含まれる)。

### .sage-version

`1.7.1` → `1.8.0` (minor bump、新 hook + 新 verdict 追加 = 後方互換あり minor 機能追加)。

### SHA256SUMS

`install.sh` 再生成後、`shasum -a 256 install.sh > SHA256SUMS` で再計算し commit。SPEC-0018 / SPEC-0023 同 pattern (PR 内整合性)。release tag push 時の `bash scripts/sage-publish.sh` は別途 release artifact 用の SHA を生成する。

## File Scope（変更許可範囲）

- 変更: `scripts/generator/06-hooks-phase5.sh` (TMPL_TEST_PROPERTY_SECTION embed 追加のみ)
- 変更: `scripts/generator/07-installer-main.sh` (write/update entry 追加のみ)
- 変更: `install.sh` (regen のみ、手編集禁止)
- 変更: `.sage-version` (1.7.1 → 1.8.0)
- 変更: `SHA256SUMS` (`shasum -a 256 install.sh > SHA256SUMS` で再計算、手書き禁止)

## 禁止事項

- install.sh を手編集しない (`bash scripts/generate-installer.sh > install.sh` のみ)
- SHA256SUMS を手書きしない (`shasum -a 256 install.sh > SHA256SUMS` の出力のみ)
- 既存 generator module (01-templates / 02-config / 03-rules / 04-hooks-base / 05-hooks-phase2b) を変更しない (本 TASK は 06-hooks-phase5.sh + 07-installer-main.sh のみ)
- 既存 write/update entry を変更しない (additive)
- shellcheck error を残さない (R9)
- byte-identical 検証 skip しない
- patch bump (1.7.2) で済ませない (新 verdict 追加 = minor、SemVer 厳守)

## 完了条件

- [ ] `grep -c "TMPL_TEST_PROPERTY_SECTION" scripts/generator/06-hooks-phase5.sh` で 1+ (embed)
- [ ] `grep -c "test-property-section" scripts/generator/07-installer-main.sh` で 2+ (write_file_if_new + update_file)
- [ ] `bash scripts/generate-installer.sh > /tmp/new && diff install.sh /tmp/new` で 0 行 (byte-identical)
- [ ] `grep -F "read -r -d '' TMPL_SPEC" install.sh && awk 'BEGIN{p=0} /^read -r -d .* TMPL_SPEC /{p=1; next} /^__EOF_TMPL_SPEC__$/ && p{exit} p{print}' install.sh | grep -F "## Properties" && grep -F "templates/hooks/tests/test-property-section.sh" install.sh`
- [ ] `grep -F "1.8.0" .sage-version` で 1 件 hit
- [ ] `shasum -a 256 -c SHA256SUMS` で `install.sh: OK`
- [ ] `shellcheck scripts/generator/06-hooks-phase5.sh scripts/generator/07-installer-main.sh` で error 0 件
- [ ] `bash scripts/sage-validate.sh` PASS
- [ ] commit message に `TASK-0169:` 含む
