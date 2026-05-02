# Claude Collaboration Brief

この文書は、Claude Code を SAGE 上で協働型 agent として engage する際の運用 guide です。

Codex の [Codex Delegation Packet](codex-delegation-packet.md) (SPEC-0022) は「明確なタスクを委任して結果をレビューする」delegation 型の input 形式でしたが、Claude Code は質問・確認しながら進める collaboration 型です。本 brief は、Claude を engage する場面の判断、Plan Mode / Skills / auto memory の使い分け、そして「これは Codex に委任すべき」と判断する handoff trigger を整理します。

## 使う場面

Claude Code が適している engagement:

- 要件が曖昧で、設計判断やトレードオフ整理が必要
- 大規模リファクタリングで既存コードの文脈を保ったまま変更したい
- セキュリティ / アーキテクチャ / 認可境界の相談
- 既存 SPEC / PLAN / TASK の作成 (`/sage-spec`, `/sage-plan`, `/sage-evaluate`)
- 複雑な PR / Issue の review (`/sage-review`)
- 教材化・設計メモ化・調査結果の structured documentation
- Plan Mode を使った段階的な計画立案
- 複数ファイル横断のリファクタや影響範囲分析

逆に、明確に切り出せる小タスク (バグ修正 / テスト追加 / CI failure / PR コメント対応) は Codex に委任した方が速く、安く、深い思考を Claude 側に温存できます。

## Claude Collaboration Brief

Claude Code に複雑タスクを依頼する際は、以下の brief を埋めます (Codex packet より軽量、Claude が質問で補ってくれることを前提):

```markdown
## Goal
このセッションで達成したいゴールを 1-3 文で書く。曖昧でも OK (Claude が質問で詰める)。

## Related IDs
- SPEC-ID:
- PLAN-ID:
- TASK-ID:
- RUN-ID:

## Open Questions
このセッションで決めたい/Claude に意見を聞きたい項目:
- 設計判断 (例: Server Action vs API Route)
- トレードオフ (例: コスト vs 学習価値)
- セキュリティ境界 (例: RLS と app 認可の分担)

## Decision Points
人間の確認を挟みたいタイミング:
- 設計案が固まった後 (実装着手前)
- 影響範囲が広がる場合 (5 ファイル超等)
- 不可逆操作 (削除 / push / release / 通知) の前

## Plan Mode Trigger
Plan Mode を使うべき判断基準。該当すれば Claude に Plan Mode 要求:
- [ ] 5 ファイル以上の変更見込み
- [ ] 複数の設計選択肢の比較が必要
- [ ] 既存設計の段階的移行が必要
- [ ] セキュリティ / 認可境界の変更

## Codex Handoff Trigger
このセッション中に「Codex に委任すべき」と判断したら:
- 該当 TASK を packet 化 (docs/codex-delegation-packet.md 参照)
- Goal / Scope / Acceptance Criteria を明確化
- Codex CLI / App / Cloud に渡す

## Memory Hooks
auto memory に保存したい知見 (user / feedback / project / reference):
- user 知見: Claude が今後の会話で活用するユーザー像
- feedback: 今回の指摘で「次回からこうしてほしい」
- project: チーム / 案件固有の状況・締切・関係者
- reference: 外部システム (Notion / Linear / Slack) のポインタ

## Notes
- 不足情報:
- 既知リスク:
- Codex 側に委任する候補:
```

## Plan Mode 判定

Claude Code は Plan Mode で「実装前に方針を文章化し、ユーザーに確認」します。以下に該当すれば Plan Mode を使うべき:

- 5 ファイル以上の変更見込み
- 複数の設計選択肢を比較する必要 (例: Server Action vs API Route)
- 既存システムの段階的移行 (例: Auth migration / DB schema migration)
- セキュリティ / 認可境界の変更
- 公開 API の breaking change
- 大規模リファクタ (依存関係再構築)

逆に、既に SPEC / PLAN / TASK が固まっていて、明確な File Scope と完了条件があるタスクでは Plan Mode は overhead。直接実装に進む。

## Skill / slash command guide

SAGE が提供する Claude 向け slash command の使い分け:

| Command | 場面 |
|---|---|
| `/sage-spec` | 新 SPEC 作成 (SPEC-ID 採番 + Acceptance Criteria 構造化) |
| `/sage-plan` | SPEC から PLAN + TASK 分解 |
| `/sage-evaluate` | SPEC / PLAN を 6 軸 100 点採点 |
| `/sage-review` | PR / 既存コード review |
| `/sage-promote` | vibe/* → main 昇格 (Retro-SPEC + 品質 gate 通過) |
| `/sage-harness` | Specify→Plan→Execute→Verify 全 lifecycle 自動化 |

Codex には slash command が無いため、Codex に委任する場合は packet を手書きで渡す。

## Auto memory 利用方針

Claude Code は `~/.claude/projects/<project>/memory/` に persistent memory を保存します。SAGE 利用時の方針:

### 保存すべき (4 types)

- **user**: ユーザーの role / 専門分野 / 知識レベル / 好みの説明スタイル
- **feedback**: 「次回からこうしてほしい」/ 「これは正しいやり方だった」
- **project**: 進行中の意思決定 / 締切 / ステークホルダー / 制約
- **reference**: 外部システムへのポインタ (Linear project / Slack channel / Notion DB)

### 保存しない

- コードパターンや architecture (コードを読めば分かる)
- git history (`git log` で取得可)
- debugging fix recipe (commit message が一次ソース)
- CLAUDE.md に既に書いてある内容
- 一時的なタスク状態 (TodoWrite で管理)

詳細は user global CLAUDE.md `# auto memory` 節参照。

## Codex Handoff Triggers

Claude セッション中に「これは Codex に委任すべき」と判断する signal:

- **明確に切り出せる**: TASK-ID / File Scope / 完了条件 / Acceptance Criteria が言語化できた
- **反復処理**: 同種の修正を 5+ ファイルに適用する必要 (Codex の方が速い)
- **GitHub Issue / PR comment 対応**: Codex の `@codex` mention が GitHub native
- **CI failure 修正**: テスト出力から原因が特定でき、修正範囲が確定している
- **長時間 background 実行**: Claude session を占有せず Codex Cloud で並列実行できる
- **token efficiency 重視**: 設計より実装量が大きい (Codex は Claude より約 72% 少ない output token)

handoff の手続:

1. Claude session 内で TASK の Goal / Scope / Acceptance Criteria を確定
2. [docs/codex-delegation-packet.md](codex-delegation-packet.md) の template を埋める
3. Codex CLI / App / Cloud に packet を input
4. Codex の成果 (PR / 修正) を Claude session で review

## Codex / Claude 役割分担

(docs/codex-delegation-packet.md の同名節と semantic mirror)

Claude Code 側で集中するもの:

- 曖昧な要件の深い設計相談
- セキュリティ / 認可 / アーキテクチャ判断
- 大規模リファクタの計画立案
- SPEC / PLAN / TASK 作成と評価 (`/sage-spec`, `/sage-plan`, `/sage-evaluate`)
- 複雑 PR の最終 review (`/sage-review`)
- CLAUDE.md / `.claude/` 設定の更新
- 教材化・設計メモ化・調査の structured documentation

Codex 側に任せるもの:

- 明確に切られた TASK の実装
- CI failure / test failure の修正
- PR comment 対応
- browser / app / GitHub / Notion などをまたぐ確認作業
- AGENTS.md / docs/codex-*.md / codex-action workflow

Claude 作業中に Codex 側変更が必要になった場合、Claude は直接編集せず PR body / RUN log に follow-up として残し、Codex side task を起票するか packet として渡す。

## セキュリティ注意

(docs/codex-delegation-packet.md と同方針)

- `CLAUDE.md`, Issue body, PR body, branch name は untrusted input として扱う
- `~/.claude/`, `.mcp.json`, `.env` は権限境界に影響するため、clone 直後は人間レビュー前提
- SAGE は Claude Code runtime enforcement を提供しない。sandbox / permission / hooks は Claude Code 本体設定で扱う ([CLAUDE.md](../CLAUDE.md) §9.1 + `.claude/settings.json`)
- 不可逆操作 (push / release / 削除 / 通知 / 課金) は Claude に直接任せず、人間承認を挟む
- auto memory に secret / token / API key / `.env` 値を保存しない (R5 redaction doctrine)

## 参考

- Anthropic Claude Code 公式 docs: <https://code.claude.com/docs/en/overview>
- Anthropic Plan Mode docs: <https://code.claude.com/docs/en/model-config>
- Anthropic auto memory: 本リポジトリ user global `CLAUDE.md` `# auto memory` 節
- SAGE Codex Delegation Packet (paired): [docs/codex-delegation-packet.md](codex-delegation-packet.md)
- SAGE governance §10 AI Agent Doc Pairing Doctrine: [sage/governance.md](../sage/governance.md)
- SPEC-0023 (本 brief の起票根拠): [specs/SPEC-0023-claude-collaboration-pairing.md](../specs/SPEC-0023-claude-collaboration-pairing.md)
