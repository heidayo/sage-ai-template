# TASK-0142: doc cross-refs (5 doc + scripts/generator/README.md) + README.md + SECURITY.md §3.1 更新

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0142 |
| SPEC-ID   | SPEC-0018 |
| PLAN-ID   | PLAN-0018 |
| ステータス | Pending |
| 担当Agent | Implementation |
| 並列可否  | No (TASK-0139..0141 完了後) |
| 依存TASK  | TASK-0139, TASK-0140, TASK-0141 |
| 見積     | 45m |

## 責務

SPEC-0018 で実装した配布チャネル変更を documentation に反映する。R7 (CLAUDE/AGENTS 肥大化禁止、各 +3 行以内) を厳守。

## 入力

- SPEC-0018 §「機能要件」FR-08
- TASK-0139..0141 で完成した release.yml / sage-publish.sh / install.sh `--remote` mode
- 既存 5 doc (`sage/governance.md` / `AGENTS.md` / `CLAUDE.md` / `docs/codex-security.md` / `docs/maintainer-guide.md`)
- SECURITY.md §3.1 の現状記述 (`[partial]` row)
- README.md の「インストール」節

## 出力

### 5 doc cross-refs (各 +3 行以内、R7 厳守)

1. **`sage/governance.md` §9.1**: Hooks 表の下に Phase 6.1 supply chain hardening 1 行追加 (SPEC-0018 link)
2. **`AGENTS.md`**: §3 Distribution / Trust 節 (該当箇所) に Releases primary 1 行追記
3. **`CLAUDE.md`**: 同上、AGENTS.md と semantic 整合
4. **`docs/codex-security.md`**: §配布チャネル (該当節) に Releases URL 1 行追記
5. **`docs/maintainer-guide.md`**: release procedure 節に `bash scripts/sage-publish.sh patch` で release.yml 自動発火する旨 1-2 行追記

### README.md 更新

- 「インストール」節を Releases primary に書き換え
  - 旧: `curl -fsSL https://gist.githubusercontent.com/.../raw/install.sh | bash`
  - 新 (primary): `curl -fsSL https://github.com/heidayo/sage-ai-template/releases/latest/download/install.sh | bash`
  - 新 (verification 推奨): `curl -fsSL .../install.sh -o install.sh && curl -fsSL .../SHA256SUMS && shasum -c SHA256SUMS && bash install.sh`
- legacy fallback として Gist URL を残し、移行期間中の選択肢として記述

### SECURITY.md §3.1 更新

- `installer_url` row の対応を `[partial]` → `[improved]` に更新
- 「remote installer URL の pinning / signing / SLSA provenance / GitHub Releases primary distribution は未実装」記述を「pinning + Releases primary distribution + SHA256SUMS 公開を [SPEC-0018](specs/SPEC-0018-installer-supply-chain-hardening.md) で実装。cosign signing は SPEC-0019、SLSA provenance は SPEC-0020 で扱う」に書き換え

### `scripts/generator/README.md` 更新

- Phase 6 で `02-config.sh` の installer_url を Releases に変更した旨 1-2 行追記

## File Scope

- 変更: `sage/governance.md`
- 変更: `AGENTS.md`
- 変更: `CLAUDE.md`
- 変更: `docs/codex-security.md`
- 変更: `docs/maintainer-guide.md`
- 変更: `README.md`
- 変更: `SECURITY.md`
- 変更: `scripts/generator/README.md`

## 禁止事項

- **5 doc 各 +3 行を超えない** (R7 厳守、SPEC-0017 / SPEC-0014 で確立)
- doc 間で記述が矛盾しないこと (semantic alignment)
- README.md 「インストール」節で Gist URL を「廃止された」と書かない (移行期間中、legacy fallback として有効)
- SECURITY.md §3.1 の row 行数を増やさない (cell 内文字列のみ更新)
- CLAUDE.md / AGENTS.md は本来 human-only だが、本 TASK では human-approved meta change として例外編集 (commit message に明記)
- 新規 doc を作成しない (既存 doc への追記のみ)
- 7 doc 合計 +21 行を超えない (5 doc cross-ref +15 行 + README/SECURITY/generator README +6 行が目安)

## 完了条件

- [ ] 5 doc 各 +3 行以内 (`git diff HEAD~1 HEAD --stat -- sage/governance.md AGENTS.md CLAUDE.md docs/codex-security.md docs/maintainer-guide.md` で検証)
- [ ] README.md「インストール」節に Releases URL primary、Gist URL legacy fallback の両方が記述
- [ ] SECURITY.md §3.1 の installer_url row が `[improved]` に更新、SPEC-0018 link 追加
- [ ] `scripts/generator/README.md` に Phase 6 変更点 1-2 行追記
- [ ] `bash scripts/sage-doc-drift.sh` PASS
- [ ] commit message に `TASK-0142: human-approved meta change` 含む (CLAUDE.md / AGENTS.md 編集のため)
