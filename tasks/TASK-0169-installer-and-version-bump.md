# TASK-0169: scripts/generator embed + install.sh regen + .sage-version 1.7.0→1.8.0

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0169 |
| SPEC-ID   | SPEC-0024 |
| PLAN-ID   | PLAN-0024 |
| ステータス | Pending |
| 担当Agent | Implementation (shared-core) |
| 並列可否  | No (全 doctrine 確定後に installer 同期) |
| 依存TASK  | TASK-0163, TASK-0164, TASK-0165, TASK-0166, TASK-0167, TASK-0168 |
| 見積     | 75m |

## 責務

`scripts/generator/03-rules.sh` に Property template embed 追加 + `scripts/generator/07-installer-main.sh` に新 hook (test-property-section.sh) write entry 追加 + `install.sh` 再生成 + `.sage-version` 1.7.0 → 1.8.0 + **PR 内で `SHA256SUMS` を `shasum -a 256 install.sh > SHA256SUMS` で再計算 + commit** (SPEC-0018 / SPEC-0023 と同 pattern、PR レベル整合性を保つ)。

## 入力

- SPEC-0024 FR-10 (installer 伝播仕様)
- TASK-0162 確定の specs/_template.md Properties schema (embed 対象)
- TASK-0168 完了の templates/hooks/tests/test-property-section.sh (write 対象)
- 既存 scripts/generator/03-rules.sh (TMPL_* heredoc 配置)
- 既存 scripts/generator/07-installer-main.sh (managed_files / write_file_if_new / update_file)
- 既存 install.sh (現 1.7.0 ベース、再生成対象)
- 既存 .sage-version (現値)

## 出力

### scripts/generator/03-rules.sh

`TMPL_CLAUDE_COLLABORATION_BRIEF` (SPEC-0023) 隣接行に `TMPL_PROPERTY_TEMPLATE` を heredoc で追加 (specs/_template.md の Properties セクション content と同期):

```bash
TMPL_PROPERTY_TEMPLATE=$(cat <<'EOF'
## Properties

SPEC が満たすべき意味論的性質を declarative に列挙。Verify / Review phase で機械的に proof-attempt が行われる。

権限レベル別の下限:
- system / platform + Security 要件あり: 5 件以上必須
- platform (Security 要件なし): 3 件以上推奨
- feature (低リスク): 任意、`Properties: not applicable + 理由` 許容

### Invariants
- [INV-01] (Gate N) <内容>

### Pre-conditions
- [PRE-01] (Gate N) <内容>

### Post-conditions
- [POST-01] (Gate N) <内容>

### Assumptions
- [ASM-01] (Gate 横断) <内容>
EOF
)
```

### scripts/generator/07-installer-main.sh

managed_files に `templates/hooks/tests/test-property-section.sh` 追加、write_file_if_new + update_file の両 mode 対応 (SPEC-0023 同 pattern)。

### install.sh

`bash scripts/generate-installer.sh > install.sh` で再生成 (TMPL_PROPERTY_TEMPLATE + test-property-section.sh embed が含まれる)。

### .sage-version

`1.7.0` → `1.8.0` (minor bump、新 hook + 新 verdict 追加 = 後方互換あり minor 機能追加)。

### SHA256SUMS

`install.sh` 再生成後、`shasum -a 256 install.sh > SHA256SUMS` で再計算し commit。SPEC-0018 / SPEC-0023 同 pattern (PR 内整合性)。release tag push 時の `bash scripts/sage-publish.sh` は別途 release artifact 用の SHA を生成する。

## File Scope（変更許可範囲）

- 変更: `scripts/generator/03-rules.sh` (TMPL_PROPERTY_TEMPLATE embed 追加のみ)
- 変更: `scripts/generator/07-installer-main.sh` (managed_files + write/update entry 追加のみ)
- 変更: `install.sh` (regen のみ、手編集禁止)
- 変更: `.sage-version` (1.7.0 → 1.8.0)
- 変更: `SHA256SUMS` (`shasum -a 256 install.sh > SHA256SUMS` で再計算、手書き禁止)

## 禁止事項

- install.sh を手編集しない (`bash scripts/generate-installer.sh > install.sh` のみ)
- SHA256SUMS を手書きしない (`shasum -a 256 install.sh > SHA256SUMS` の出力のみ)
- 既存 generator module (00-header / 01-config / 02-templates / 04-skills / 05-hooks / 06-scripts) を変更しない (本 TASK は 03-rules.sh + 07-installer-main.sh のみ)
- managed_files の既存 entry を変更しない (additive)
- shellcheck error を残さない (R9)
- byte-identical 検証 skip しない
- patch bump (1.7.1) で済ませない (新 verdict 追加 = minor、SemVer 厳守)

## 完了条件

- [ ] `grep -c "TMPL_PROPERTY_TEMPLATE" scripts/generator/03-rules.sh` で 2+ (定義 + 利用)
- [ ] `grep -c "test-property-section" scripts/generator/07-installer-main.sh` で 2+ (write_file_if_new + update_file)
- [ ] `bash scripts/generate-installer.sh > /tmp/new && diff install.sh /tmp/new` で 0 行 (byte-identical)
- [ ] `grep -c "TMPL_PROPERTY_TEMPLATE\|test-property-section" install.sh` で 3+
- [ ] `grep -F "1.8.0" .sage-version` で 1 件 hit
- [ ] `shasum -a 256 -c SHA256SUMS` で `install.sh: OK`
- [ ] `shellcheck scripts/generator/03-rules.sh scripts/generator/07-installer-main.sh` で error 0 件
- [ ] `bash scripts/sage-validate.sh` PASS
- [ ] commit message に `TASK-0169:` 含む
