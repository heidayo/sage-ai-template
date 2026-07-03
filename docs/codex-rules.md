# Codex Rules Layer（`.codex/rules/`）— 優先順位・読み込み手順・対応表

> [!NOTE]
> 本文書は **SPEC-0029 で新設**された SAGE 管理文書です。新設のみ本 SPEC（Claude 側 task）で行い、**以後の本文修正は Codex 側 task** とします（SPEC-0023 boundary — Codex-specific ファイル群に帰属）。

SAGE installer は `.claude/rules/`（Claude Code 向け）と対称の Codex 向けルール層として、`.codex/rules/` に 5 つの managed ルールファイルを配布します（実体: `templates/codex-rules/`）。本文書はその優先順位規約・読み込み手順・`.claude/rules/` との対応・local overlay の使い方を定めます。

これらのルールは **runtime enforcement ではなく guidance** です。Claude Code の hooks に相当する強制機構は Codex 側には配布されません。runtime での強制が必要な場合は Codex 本体の設定で行ってください（SPEC-0022 SEC-03 と同方針）。

## 1. 優先順位規約

```
.codex/rules/（層別・具体則） > ルート AGENTS.md（一般則）
```

- 具体則が一般則に優先します。`.codex/rules/` の記述とルート `AGENTS.md` の記述が矛盾する場合、Codex セッションは **`.codex/rules/` 側に従って**ください。
- ただし矛盾は放置せず、**矛盾自体を paired-update で解消**します（SPEC-0023 §10 doctrine）。矛盾を発見したら follow-up task として起票してください。
- `.codex/rules/local/`（プロジェクト固有 overlay）は managed ルールをさらに具体化する層であり、プロジェクト内ではこれが最優先です。

## 2. 読み込み手順（Codex config / AGENTS.md 参照機構前提）

Codex は `.codex/rules/` を**自動ロードしません**。Codex の AGENTS.md 参照機構を前提に、ルート `AGENTS.md`（または `.codex/AGENTS.md`）から明示的に参照させます:

1. ルート `AGENTS.md`（または `.codex/AGENTS.md`）に「セッション開始時に `.codex/rules/` 配下の各ルールを読み、該当ディレクトリの作業時に従う」旨の参照を記載する
2. Codex セッションは、編集対象に応じて該当ルール（例: `specs/` を編集するなら `.codex/rules/specs-rules.md`）を参照する
3. プロジェクト固有ルールがある場合は `.codex/rules/local/` も併せて参照する

> [!IMPORTANT]
> `AGENTS.md` への参照追記の実施自体は **Codex follow-up task** です（SPEC-0029 FR-09 — 本 SPEC では AGENTS.md を編集せず、PR 本文に追記案のみ提示）。追記が行われるまで、Codex が `.codex/rules/` を読む保証はありません（SPEC-0029 ASM-02）。

## 3. `.claude/rules/` との対応表

配布対象 5 ファイルは 1:1 対応です（`harness-rules.md` は Claude Code 専用機構のため Codex ミラー対象外）。

| `.claude/rules/`（Claude Code） | `.codex/rules/`（Codex） | 区分 |
|---|---|---|
| `specs-rules.md` | `specs-rules.md` | SHARED（意味的同一） |
| `plans-rules.md` | `plans-rules.md` | SHARED（意味的同一） |
| `tasks-rules.md` | `tasks-rules.md` | SHARED（意味的同一） |
| `src-rules.md` | `src-rules.md` | SHARED（Codex 版は guidance であることを明記） |
| `sage-governance-rules.md` | `sage-governance-rules.md` | SHARED（意味的同一） |
| `harness-rules.md`（配布対象外） | —（ミラーなし） | CLI-specific（Claude Code 専用） |

両側の実体はそれぞれ `templates/rules/` / `templates/codex-rules/` にあり、semantic alignment は SPEC-0023 §10 の paired-update doctrine とテスト（ファイル集合の 1:1 対応検証）で維持します。バイト同一は要求されません（CLI-specific 文言調整を許容 — SPEC-0029 NFR-03）。

## 4. `.codex/rules/local/` overlay の使い方

`.codex/rules/` の managed 5 ファイルは `install.sh` 更新時に**全置換**されます。プロジェクト固有ルールは managed ファイルに直接書かず、installer 絶対不可侵の overlay に置いてください（SPEC-0025）:

```bash
mkdir -p .codex/rules/local
echo "# My project Codex rules" > .codex/rules/local/my-rules.md
bash install.sh   # 何度更新しても local/ は不変
```

| プロジェクト固有ルールの置き方 | `bash install.sh` 更新時 |
|:---|:---|
| managed ファイル（`.codex/rules/specs-rules.md` 等）に直接追記 | ❌ 全置換され**消える** |
| `.codex/rules/local/` にファイルを配置 | ✅ **保持される** |

**既存導入先向けの移行案内**: SPEC-0029 以前に `.codex/rules/` 直下へ自作ルールを置いていた場合、SAGE 管理名 5 件（`specs/plans/tasks/src/sage-governance-rules.md`）と同名のファイルは初回 `--update` で SAGE テンプレートに上書きされます。適用前に自作ルールを `.codex/rules/local/` へ退避してください。別名ファイルは installer が触りません（書き込み対象は固定 5 パスのみ）。

## 関連

- SPEC-0029（本レイヤの新設）/ SPEC-0025（local overlay 不可侵）/ SPEC-0023（AGENTS/CLAUDE pairing doctrine）/ SPEC-0022（Codex delegation packet / boundary）
- `docs/codex-security.md` — Codex 利用時のセキュリティ設定
- `docs/codex-delegation-packet.md` — Codex への委任 packet
