# TASK-0094: LICENSE (Apache-2.0) 採用 + README ライセンス節修正 + ATTRIBUTION 拡張

## メタデータ

| フィールド | 内容 |
|-----------|------|
| TASK-ID   | TASK-0094 |
| SPEC-ID   | SPEC-0010 |
| PLAN-ID   | PLAN-0010 |
| ステータス | Pending |
| 担当Agent | Implementation |
| 並列可否  | Yes |
| 依存TASK  | none |
| 見積     | 30m |

## 責務

SAGE のライセンスを Apache-2.0 として法的に確定し、外部知識統合源 (Phase 1 で参照した 65 資料) を ATTRIBUTION.md に列挙する。

## 入力

- SPEC-0010 FR-01, FR-02, FR-03
- 既存 README.md 行 531 (`All Rights Reserved. ライセンスは未定です。`)
- 既存 ATTRIBUTION.md (5 inspiration sources 列挙済み)
- Apache-2.0 公式テキスト: https://www.apache.org/licenses/LICENSE-2.0.txt

## 出力

1. `LICENSE` (新規, Apache-2.0 フルテキスト, Copyright (c) 2026 heidayo)
2. README.md ライセンス節 (Apache-2.0 表記 + ATTRIBUTION.md 参照 + LICENSE リンク)
3. ATTRIBUTION.md に「External Knowledge Integration Sources (Phase 1)」セクション追加

## File Scope（変更許可範囲）

- 作成: `LICENSE`
- 変更: `README.md` (行 527-531 のライセンス節のみ), `ATTRIBUTION.md` (末尾追記)
- 削除: なし

## 禁止事項

- LICENSE テキストの改変禁止 (Apache-2.0 公式テキストをそのままコピー)
- README.md の他の節は変更しない
- ATTRIBUTION.md の既存 5 sources の表記は変更しない (追記のみ)
- src/, tests/, .github/, .claude/ への変更禁止

## 完了条件

- [ ] `test -f LICENSE && head -1 LICENSE | grep -q "Apache License"`
- [ ] `! grep -q "All Rights Reserved" README.md`
- [ ] `grep -q "Apache-2.0\|Apache License" README.md`
- [ ] `grep -q "External Knowledge Integration Sources" ATTRIBUTION.md`
- [ ] commit message に `TASK-0094:` を含む
