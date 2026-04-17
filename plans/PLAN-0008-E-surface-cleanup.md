# PLAN-0008-E: 表層クリーンアップ (低コスト・高 ROI)

## メタデータ

| フィールド | 内容 |
|-----------|------|
| PLAN-ID   | PLAN-0008-E |
| SPEC-ID   | SPEC-0008 |
| ステータス | Active |
| 作成日    | 2026-04-17 |
| 担当Agent | Planning Agent |

## 変更レイヤ

- [ ] controller
- [ ] usecase
- [ ] domain
- [x] infra (config + hooks + docs)
- [ ] frontend
- [ ] test

## 影響範囲

`.sage/config.yaml`、`templates/hooks/block-dangerous-commands.sh`、CLAUDE.md / AGENTS.md、tasks/ 配下の命名、.DS_Store の git index 状態。

## 実装方針

Sprint 1 で先行投入して信頼性基盤を整える。各 TASK は小粒で単独投入可。TASK-0086 のみ他 PR のノイズ防止で最先行単独マージ。

- **双子文書 drift 埋め (TASK-0085)**: CLAUDE.md ↔ AGENTS.md で片方にしかない 3 節を対称化。
- **.DS_Store untrack + ブロック (TASK-0086)**: `git rm --cached .DS_Store` + hook に `git add -f .DS_Store` 検出パターン追加。最先行単独マージ。
- **TASK ファイル命名修正 (TASK-0087)**: `TASK-0064〜0069-spec0007.md` を H1 準拠サフィックスに git mv。
- **hooks profile default 変更 (TASK-0088)**: config.yaml の `hooks.profile` を minimal → standard にして block-dangerous と protect-sage が install 直後から有効。
- **危険コマンド検知パターン拡充 (TASK-0089)**: 7 パターン (find -delete / curl|sh / wget|sh / shutil.rmtree / dd of=/dev/ / mkfs / chmod -R world-writable on root) を追加。

## タスク分解

| TASK-ID | 責務 | 担当Agent | 見積 | 依存TASK | 並列可否 |
|---------|------|----------|------|---------|---------|
| TASK-0085 | AGENTS.md 4.1/9.1 + CLAUDE.md sub-agent 節追加 | Implementation | 0.5h | - | Yes |
| TASK-0086 | .DS_Store untrack + force-add ブロック hook | Implementation | 0.5h | - | 最先行単独 |
| TASK-0087 | TASK-0064〜0069 命名 rename | Implementation | 0.3h | - | Yes |
| TASK-0088 | hooks profile default 変更 | Implementation | 0.2h | TASK-0078 | Yes after 0078 |
| TASK-0089 | dangerous-commands パターン 7 件追加 | Implementation | 0.5h | - | Yes |

## リスク

- リスク 1: hooks profile=standard で commit message 中のリテラルパターンが block されるケース発生 → 軽減策: パラフレーズで対応、pattern 改善は後続
- リスク 2: TASK 命名 rename で外部からの URL 参照が壊れる → 軽減策: git log で rename が追跡可能、参照は README/docs には未記載

## 必要な検証

- [x] unit test (hook テスト 13/13 PASS、drift script 確認)
- [ ] integration test
- [ ] security scan
- [ ] e2e test
- [ ] architecture boundary check
