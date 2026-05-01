# TASK-0115: cross-references update for docs/codex-security.md

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0115 |
| SPEC-ID   | SPEC-0013 |
| PLAN-ID   | PLAN-0013 |
| ステータス | Pending |
| 担当Agent | Implementation |
| 並列可否  | No (TASK-0114 後) |
| 依存TASK  | TASK-0114 |
| 見積     | 30m |

## 責務

TASK-0114 で作成した `docs/codex-security.md` への cross-reference を AGENTS.md / SECURITY.md / sage/governance.md / README.md の 4 doc に追加 (各 1-3 行)。doc-drift / validate / doctor で regression なし確認。

## 入力

- SPEC-0013 FR-06 〜 FR-09, NFR-03, NFR-04
- Phase 2A AGENTS.md §2.1 (Codex specificity, 12行)
- Phase 1 SECURITY.md §3 / §4
- Phase 2B governance §9.2 / §9.6
- README.md の関連リンク節

## 出力

### AGENTS.md

§2.1 末尾 (既存最終段落の後) に 1 行追加:

```
> 詳細手順は [docs/codex-security.md](docs/codex-security.md) を参照。
```

### SECURITY.md

§3.1 (Template Supply Chain) または §3.2 (AI Agent Configuration Attacks) の Codex 関連行に `docs/codex-security.md` への link を 1 件追加。
§4 (Out of Scope) の "Codex sandbox / approval policy" 行に同様に link 追加。

### sage/governance.md §9.2

「Codex セッションでの hook 実行」行の末尾の AGENTS.md §2.1 link の後に `+ docs/codex-security.md` を併記。

### sage/governance.md §9.6 関連ドキュメント

既存 list (SECURITY.md / CONTRIBUTING.md / ATTRIBUTION.md / CLAUDE.md / AGENTS.md callout) の末尾に:

```
- [docs/codex-security.md](../docs/codex-security.md) — Codex 利用者向け詳細セキュリティガイド (Phase 3)
```

### README.md

関連リンク (もしくは「ドキュメント」section) に 1 行追加:

```
- [docs/codex-security.md](docs/codex-security.md) — Codex 利用者向けセキュリティガイド
```

## File Scope（変更許可範囲）

- 変更: `AGENTS.md` (§2.1 末尾 1 行追加のみ), `SECURITY.md` (該当 2 行 link 追加), `sage/governance.md` (§9.2 と §9.6 各 1 行追加), `README.md` (1 行追加)
- 削除: なし
- 作成: なし (本体は TASK-0114)

## 禁止事項

- AGENTS.md §2.1 以外の section 変更禁止
- SECURITY.md / governance.md / README.md の他 section 変更禁止
- AGENTS.md 増分 3 行超過禁止 (NFR-04)
- CLAUDE.md は触らない (NFR-03)
- protect-sage-files hook が AGENTS.md / governance.md 編集を block する場合は本 TASK-0115 を sage-managed: true で起票

## 完了条件

- [ ] `grep -F "docs/codex-security.md" AGENTS.md SECURITY.md sage/governance.md README.md | wc -l` >= 4
- [ ] AGENTS.md 行数増分 ≤ 3 (NFR-04)
- [ ] CLAUDE.md 不変 (NFR-03)
- [ ] `bash scripts/sage-doc-drift.sh` PASS (CLAUDE.md / AGENTS.md alignment 維持)
- [ ] `bash scripts/sage-validate.sh` PASS
- [ ] `bash scripts/sage-doctor.sh` 0 FAIL
- [ ] commit message に `TASK-0115:` を含む
