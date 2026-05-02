# PLAN-0022: Codex Delegation Packet and Codex-only Agent Guidance

## メタデータ

| フィールド | 内容 |
|-----------|------|
| PLAN-ID   | PLAN-0022 |
| SPEC-ID   | SPEC-0022 |
| ステータス | Review |
| 作成日    | 2026-05-03 |
| 担当Agent | Planning Agent |

## 変更レイヤ

- [ ] controller
- [ ] usecase
- [ ] domain
- [x] infrastructure
- [ ] frontend
- [x] infra
- [x] test

## 影響範囲

- Codex セッション用 instructions (`AGENTS.md`)
- 新規導入先に注入される AGENTS snippet (`templates/agents-md-snippet.md`)
- Codex 委任テンプレート文書 (`docs/codex-delegation-packet.md`)
- installer generator と生成物 (`scripts/generator/*`, `install.sh`)
- hook tests (`templates/hooks/tests/`)

## 実装方針

Codex 固有の運用差分は、長文を `docs/codex-delegation-packet.md` に集約し、`AGENTS.md` と snippet には短い必須ルールのみを置く。`CLAUDE.md` は本作業では変更しない。installer は新規導入先でも同じ Codex 委任文書を生成できるよう、source doc を embed して `docs/` に write/update する。

## タスク分解

| TASK-ID | 責務 | 担当Agent | 見積 | 依存TASK | 並列可否 |
|---------|------|----------|------|---------|---------|
| TASK-0145 | SPEC/PLAN/TASK と Codex Delegation Packet doc 作成 | Spec / Planning | 45m | none | Yes |
| TASK-0146 | AGENTS.md + templates/agents-md-snippet.md の Codex-only guidance 更新 | Implementation | 30m | TASK-0145 | No |
| TASK-0147 | installer generator に Codex doc を伝播し install.sh 再生成 | Implementation | 45m | TASK-0145 | No |
| TASK-0148 | hook test / RUN log / verification | Test | 45m | TASK-0146, TASK-0147 | No |
| TASK-0149 | Claude 側 semantic alignment follow-up の起票 | Claude Code | 45m | TASK-0145, TASK-0146 | Yes |
| TASK-0150 | Claude review findings の Codex 側反映 | Implementation | 45m | TASK-0148 | No |

## リスク

- `CLAUDE.md` と semantic drift が発生する → AGENTS に新規 H2/H3 を追加せず、doc-drift を実行し、TASK-0149 で Claude 側 follow-up として追跡する
- Codex guidance が長文化する → 詳細は doc、AGENTS は短い bullets に制限する
- installer に doc が入らない → test-codex-delegation-packet.sh と byte-identical diff で検出する

## 必要な検証

- [x] unit test (`templates/hooks/tests/test-codex-delegation-packet.sh`)
- [x] integration test (`bash templates/hooks/tests/run-tests.sh`)
- [x] security scan (`bash scripts/sage-validate.sh`, secret scan)
- [ ] e2e test (Codex Cloud / GitHub App 実行は本 SPEC では対象外)
- [x] architecture boundary check (`bash scripts/sage-doc-drift.sh`)
