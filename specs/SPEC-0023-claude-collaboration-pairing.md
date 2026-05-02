# SPEC-0023: Claude Collaboration Brief and AGENTS/CLAUDE Pairing Doctrine (paired with SPEC-0022)

## メタデータ

| フィールド | 内容 |
|-----------|------|
| SPEC-ID   | SPEC-0023 |
| ステータス | Review |
| 作成日    | 2026-05-03 |
| 更新日    | 2026-05-03 |
| 担当Agent | Spec Agent |
| 依存SPEC  | SPEC-0010, SPEC-0017, SPEC-0018, SPEC-0022 |
| 権限レベル | platform |
| 予約Phase | Phase 6.2 (SPEC-0022 paired follow-up) |

## 背景・目的

[SPEC-0022](SPEC-0022-codex-delegation-packet.md) で Codex Delegation Packet と Codex-only AGENTS.md 追記が導入された。SPEC-0022 OPS-01 は「Claude 固有修正は Claude 側 task に分離」と宣言したが、(a) その Claude 側 task の起票、(b) [CLAUDE.md](../CLAUDE.md) §2 「AGENTS.md is the Codex-specific counterpart. The two documents must stay semantically aligned.」の doctrine と SPEC-0022 の意図的 Codex-only divergence の不整合解消、(c) Claude Code 利用者向け delegation handoff guidance — の 3 点が未対応のまま残る。

外部レビュー (本リポ Claude セッションが実施した SPEC-0022 review) の Major #2 でも同点が指摘されている: 「AGENTS.md / CLAUDE.md semantic alignment intentional break, no follow-up TASK」。本 SPEC はそのレビュー指摘の正面対応である。

並行して 8 件の Notion 教材 (Riley Brown / Builder.io / Composio / DataCamp / XDA / OpenAI Codex 公式 / Anthropic Claude Code 公式 / GPT-5.5 vs Opus 4.7 比較) は **Codex = delegation, Claude Code = collaboration** という役割分担を統一見解として示している。Codex 側に packet があるなら、Claude 側には対応する collaboration guidance が必要。

本 SPEC はこの 3 点を 1 PR で解消する:
1. Claude side counterpart doc (`docs/claude-collaboration-brief.md`) を新規作成
2. CLAUDE.md と templates/claude-md-snippet.md に parallel guidance を追加
3. governance.md §10 に「AI Agent Doc Pairing Doctrine」を新設し、CLI-specific divergence を formalize する

## 対象ユーザー

- Claude Code を SAGE と併用する開発者
- Codex / Claude Code を CLI 並用する team
- 新規 SAGE 導入リポジトリ (snippet 経由で両 CLI の guidance を受け取る)
- 将来の Spec Agent (CLI-specific 追記時の手続を formalize された doctrine で参照)

## スコープ（含む）

- `docs/claude-collaboration-brief.md` 新規作成 (Claude-side counterpart to docs/codex-delegation-packet.md、Plan Mode / Skills / handoff triggers / 役割分担を含む)
- `CLAUDE.md` §2 「semantic alignment」doctrine の更新と、§2.1 への parallel guidance 3 bullets 追加 (R7 ≤+5 行)
- `AGENTS.md` §2 「semantic alignment」doctrine の同期更新 (CLI-specific divergence 許容を 1 行追記)
- `templates/claude-md-snippet.md` への parallel guidance 2 bullets 追加 (snippet で新規導入先に伝播)
- `sage/governance.md` §10「AI Agent Doc Pairing Doctrine」新設 (CLI-specific divergence と paired-update 要件の規範化)
- `scripts/generator/03-rules.sh` に `TMPL_CLAUDE_COLLABORATION_BRIEF` embed 追加
- `scripts/generator/07-installer-main.sh` に `docs/claude-collaboration-brief.md` write/update + managed_files 追加
- `templates/hooks/tests/test-claude-collaboration-pairing.sh` 新規 (paired update 検証)
- `install.sh` 再生成、`SHA256SUMS` 同期、`.sage-version` 1.6.0→1.7.0
- **(Codex review M3 fix)**: `bash install.sh --update` 経由の AGENTS.md / CLAUDE.md SAGE-managed section (auto-injected snippet block, 通常 L300+) propagation を本 SPEC scope に含む。これは template snippet を編集すると install --update で実体ファイルへ自動反映される設計上の挙動であり、TASK-0153 の File Scope 「変更: AGENTS.md」は §2 doctrine sync + L300+ snippet propagation の両方を含む
- **(Codex review M1/M2/M4 paired-fix)**: `templates/hooks/tests/test-codex-delegation-packet.sh` の branch detection 強化 (TASK-0156/0158)、SPEC-0022 territory への paired-update 拡張も本 SPEC scope に含む

## スコープ外（明示的に除外）

- `docs/codex-delegation-packet.md` の修正 (SPEC-0022 territory、本 SPEC は読み取りのみ)
- `AGENTS.md` の Codex-specific bullets (§2.1 末尾の 3 行) の修正 (SPEC-0022 で確定済)
- 新 skill 作成 (`/sage-codex-handoff` 等は別 SPEC、Phase 6.3 候補)
- runtime CLI detection hook 追加 (SPEC-0017 inventory で代替可能)
- Codex 側 RUN log の `approval_policy: never` 等 runtime config 是正 (Codex-side 運用判断、Claude SPEC で扱わない)
- AGENTS.md / CLAUDE.md の section header 全面再編 (R7 厳守、既存節内追記のみ)
- 旧 doctrine の削除 (互換維持: 「semantic alignment」表現は残し、divergence 許容を append)

## 要件

### 機能要件

- **[FR-01] `docs/claude-collaboration-brief.md`** は以下 7 セクションを含む:
  1. 使う場面 (when Claude Code is the right engagement)
  2. Claude Collaboration Brief template (Goal / Open Questions / Decision Points / Plan Mode trigger / Codex Handoff trigger / Memory Hooks)
  3. Plan Mode 判定 (when to enter Plan Mode)
  4. Skill / slash command guide (`/sage-spec`, `/sage-plan`, `/sage-evaluate`, `/sage-review`)
  5. Auto memory 利用方針 (what to save, what NOT to save)
  6. Codex Handoff Triggers (when Claude should write a delegation packet and delegate)
  7. Codex / Claude 役割分担 (mirror docs/codex-delegation-packet.md, semantic 整合)

- **[FR-02] CLAUDE.md §2 doctrine 更新**: 「The two documents must stay semantically aligned.」を「The two documents must stay semantically aligned for SHARED rules. CLI-specific guidance (Codex Delegation Packet, Claude Collaboration Brief) may diverge but requires a paired update under SPEC-0023 §10 doctrine.」に更新。AGENTS.md §2 にも同期更新。

- **[FR-03] CLAUDE.md §2.1 parallel guidance 3 bullets 追加** (R7 ≤+5 行内):
  - Claude Code は協働型 agent として扱う。詳細は [docs/claude-collaboration-brief.md](docs/claude-collaboration-brief.md) を参照
  - Well-scoped task は Codex に委任する判断をする (packet を書いて [docs/codex-delegation-packet.md](docs/codex-delegation-packet.md) に従う)
  - Codex-specific ファイル (`AGENTS.md`, `docs/codex-*.md`) の修正は Codex 側 task に分離し、Claude は直接編集しない

- **[FR-04] templates/claude-md-snippet.md parallel guidance 2 bullets**:
  - Claude collaboration brief: reference docs/claude-collaboration-brief.md for engagement patterns; well-scoped tasks may be delegated to Codex via packet
  - Claude-only boundary: do not edit Codex-specific files (`AGENTS.md`, `docs/codex-*.md`) unless human explicitly assigns. Record as Codex follow-up otherwise

- **[FR-05] sage/governance.md §10 「AI Agent Doc Pairing Doctrine」新設**:
  - Shared rules: lifecycle / lanes / traceability / quality gates 等は CLAUDE.md ↔ AGENTS.md で identical 維持必須
  - CLI-specific rules: Codex Delegation Packet / Claude Collaboration Brief / hook implementation 等は意図的 divergence 可
  - Paired-update 要件: CLI-specific guidance を片方に追加する SPEC は、対側の SPEC を同 PR または follow-up として明示起票する必要がある (SPEC-0022 → SPEC-0023 が最初の事例)
  - Drift 検知: `templates/hooks/tests/test-claude-collaboration-pairing.sh` で paired update 完了を CI 検証

- **[FR-06] installer 伝播**: `scripts/generator/03-rules.sh` の `TMPL_CODEX_DELEGATION_PACKET` 隣接行に `TMPL_CLAUDE_COLLABORATION_BRIEF` 追加。`scripts/generator/07-installer-main.sh` に write_file_if_new / update_file 両モード + managed_files 追加。

- **[FR-07] 検証 hook**: `templates/hooks/tests/test-claude-collaboration-pairing.sh` 新規 (6+ scenarios):
  1. docs/claude-collaboration-brief.md 必須セクション存在
  2. CLAUDE.md に collaboration brief reference 存在
  3. CLAUDE.md に Codex-specific files boundary 存在
  4. claude-md-snippet.md に parallel content 存在
  5. CLAUDE.md ↔ AGENTS.md doctrine 文言が semantically aligned (両者とも CLI-specific divergence を認める文言)
  6. governance.md §10 が「AI Agent Doc Pairing Doctrine」を含む
  7. install.sh に `TMPL_CLAUDE_COLLABORATION_BRIEF` および書き込みパスが含まれる

### 非機能要件

- **[NFR-01] backward compat**: 既存 SAGE 利用者の `.sage/config.yaml` / hooks / scripts は触らない。新規 doc + governance §10 + installer は additive
- **[NFR-02] R7 厳守**: CLAUDE.md / AGENTS.md / claude-md-snippet.md / agents-md-snippet.md それぞれ ≤+5 行 (governance.md §10 は新設のため例外)
- **[NFR-03] portability**: macOS / Linux 両対応。新規 doc は日本語 user-facing documentation
- **[NFR-04] パフォーマンス**: 既存 hook tests 実行時間を 5% 以上増やさない (新 test は 10 秒以内)
- **[NFR-05] auditability**: paired update doctrine を governance.md §10 に明文化、SPEC-ID 追跡可能

### セキュリティ要件

- **[SEC-01] no runtime enforcement**: SPEC-0023 は doctrine + doc + test のみ。Claude Code の sandbox / permission 強制は本 SPEC で行わない (Claude Code 本体機能)
- **[SEC-02] untrusted input 警告継承**: docs/claude-collaboration-brief.md の「セキュリティ注意」節で AGENTS.md / Issue body / PR body / branch name を untrusted として扱う旨を明記 (docs/codex-delegation-packet.md と semantic 整合)
- **[SEC-03] CLAUDE.md 編集の人間承認**: CLAUDE.md は本 SPEC で例外的に編集する (SPEC-0010 TASK-0098 precedent)。commit message に「TASK-XXXX: human-approved meta change」と明記
- **[SEC-04] no secret in template**: 新規 doc / governance 追記に secret / token / API key / `.env` 例値を含めない (gitleaks 通過必須)

### 運用要件

- **[OPS-01] paired-update 強制**: 今後 CLI-specific guidance を片側に追加する SPEC は、対側の SPEC-ID を本 SPEC 起票時に明示する (SPEC-0023 が SPEC-0022 を参照する pattern)
- **[OPS-02] Claude Collaboration Brief の運用 phase**:
  - Phase 1 (本 SPEC): doc + doctrine + snippet 配信のみ。template-only、ツール無し
  - Phase 2 (将来 SPEC): `/sage-claude-brief` skill / `bash scripts/sage-claude-brief.sh > /tmp/brief.md` 等の生成ツール追加検討
- **[OPS-03] paired update test の運用**: `test-claude-collaboration-pairing.sh` を `run-tests.sh` に組み込み、CI で常時実行
- **[OPS-04] 段階採用昇格条件**:

  | 昇格 | 条件 | 検証コマンド |
  |---|---|---|
  | none → Phase 1 (本 SPEC) | Claude Collaboration Brief doc / governance §10 / paired test 全件 PASS | `bash templates/hooks/tests/test-claude-collaboration-pairing.sh` で 7/7 |
  | Phase 1 → Phase 2 (生成ツール) | 14 日運用後、Claude セッションが手動で brief を埋める実例が 5+ 件 RUN log に記録 | `bash scripts/sage-runlog-search.sh --keyword "claude-collaboration-brief"` で 5+ |

## 受け入れ条件 (AC)

- [ ] AC-01: `docs/claude-collaboration-brief.md` が存在し、FR-01 の 7 セクション全てを含む (`grep -F "## 使う場面" docs/claude-collaboration-brief.md && grep -F "## Codex Handoff Triggers"` 等)
- [ ] AC-02: `CLAUDE.md` §2 の doctrine 文言が更新され、SPEC-0023 reference + paired-update 要件を含む (`grep -F "SPEC-0023" CLAUDE.md && grep -F "may diverge" CLAUDE.md`)
- [ ] AC-03: `CLAUDE.md` §2.1 (または近接) に parallel guidance 3 bullets が追加 (`grep -F "Claude Code は協働型" CLAUDE.md && grep -F "Codex-specific" CLAUDE.md`)
- [ ] AC-04: `AGENTS.md` §2 doctrine が CLAUDE.md と semantic 整合 (`grep -F "may diverge" AGENTS.md`)
- [ ] AC-05: `templates/claude-md-snippet.md` に parallel 2 bullets が追加
- [ ] AC-06: `sage/governance.md` §10「AI Agent Doc Pairing Doctrine」が新設
- [ ] AC-07: `scripts/generator/03-rules.sh` に `TMPL_CLAUDE_COLLABORATION_BRIEF` embed 追加
- [ ] AC-08: `scripts/generator/07-installer-main.sh` に write/update/managed_files 3 箇所追加
- [ ] AC-09: `bash scripts/generate-installer.sh > /tmp/new.sh && diff install.sh /tmp/new.sh` で 0 行 (byte-identical)
- [ ] AC-10: `install.sh` に `TMPL_CLAUDE_COLLABORATION_BRIEF` および `docs/claude-collaboration-brief.md` 書き込みパスを含む
- [ ] AC-11: `bash templates/hooks/tests/test-claude-collaboration-pairing.sh` 7/7 PASS
- [ ] AC-12: `bash templates/hooks/tests/run-tests.sh` 全 PASS (180 既存 + 7 新規 = 187+)
- [ ] AC-13: `bash scripts/sage-validate.sh` PASS
- [ ] AC-14: `bash scripts/sage-doctor.sh` 0 FAIL (after install.sh --update refresh)
- [ ] AC-15: `bash scripts/sage-doc-drift.sh` PASS
- [ ] AC-16 (異常系 - paired update 不在): test-claude-collaboration-pairing.sh で CLAUDE.md doctrine 文言を意図的に削除した fixture で test が FAIL を返す (test 内で mutation simulate)
- [ ] AC-17 (異常系 - section drift): docs/claude-collaboration-brief.md の必須セクション (例「## Codex Handoff Triggers」) を rename した fixture で test が FAIL を返す
- [ ] AC-18 (backward compat): 既存 .sage/config.yaml / hooks / RUN log に変更なし、`bash install.sh --update` で既存 .sage/config.yaml installer_url が書き換わらない
- [ ] AC-19: `.sage-version` が `1.7.0` に更新、SHA256SUMS が再生成 install.sh と一致
- [ ] AC-20: shellcheck error 0 件 (新規 test + 既存 modified scripts)

### Quality Gate との対応

| AC | 検証 Gate | 検証コマンド (CI) |
|---|---|---|
| AC-01..08, AC-19 | Gate 1 (Structural: file 存在 + grep pattern) | `test -f docs/claude-collaboration-brief.md && grep -qE "..." CLAUDE.md` 等 |
| AC-09, AC-11, AC-12 | Gate 2 (Functional: byte-identical + tests) | `diff install.sh /tmp/new.sh && bash run-tests.sh` |
| AC-10 | Gate 2 (Functional: install.sh embed verification) | `grep -c "TMPL_CLAUDE_COLLABORATION_BRIEF" install.sh` |
| AC-16, AC-17 | Gate 2 (Functional: 異常系 fixture) | `test-claude-collaboration-pairing.sh` 内 mutation scenario |
| AC-18, AC-20 | Gate 3 (Security: backward compat + shellcheck) | `git diff` + `shellcheck` |
| AC-13, AC-14, AC-15 | Gate 4 (Architecture: validate / doctor / doc-drift) | 各 script 直接実行 |

Gate 5 (Release) は本 SPEC 単独では発火しない (release.yml は v1.7.0 tag push で発火、別 verification)。

## エラーケース

- **EC-01** (paired update 漏れ): 将来 SPEC が AGENTS.md にのみ guidance を追加し CLAUDE.md 未更新 → test-claude-collaboration-pairing.sh が CI で FAIL
- **EC-02** (doctrine 文言 drift): CLAUDE.md / AGENTS.md の §2 doctrine が片方のみ更新 → test の semantic alignment scenario で FAIL
- **EC-03** (claude-collaboration-brief.md 必須セクション欠落): rename / 削除 → AC-01 + test scenario 1 で FAIL
- **EC-04** (governance.md §10 削除): doctrine が消えた状態で CLI-specific 追加が起きる → test の §10 存在 scenario で FAIL
- **EC-05** (installer embed 漏れ): generator 再生成で TMPL_CLAUDE_COLLABORATION_BRIEF 不在 → AC-09 byte-identical で FAIL
- **EC-06** (Codex side files への意図せぬ編集): Claude が AGENTS.md / docs/codex-*.md を編集 → CI 上で paired test の reverse boundary check で WARN (本 SPEC では FAIL までは行わず WARN-only、運用 phase で昇格判断)

## 依存関係 / リスク

### 依存

- 既存 SPEC-0022 成果物 (docs/codex-delegation-packet.md / AGENTS.md L41-43 / agents-md-snippet.md / installer 伝播)
- 既存 SPEC-0010 (CLAUDE.md / AGENTS.md trust callout、本 SPEC で文言更新する箇所の base)
- 既存 SPEC-0014 (scripts/generator/ modular structure、本 SPEC で 03-rules.sh / 07-installer-main.sh 拡張)
- 既存 SPEC-0017 (run log runtime field、Claude セッションの runtime 記録に活用)
- 既存 SPEC-0018 (sage-publish.sh + release.yml、v1.7.0 tag push で発火)

### リスク

| # | リスク | Mitigation | 検証コマンド |
|---|---|---|---|
| 1 | doctrine 文言が長すぎて R7 違反 | NFR-02 で R7 ≤+5 行明示、CLAUDE/AGENTS は §2 既存節内追記 | `git diff main HEAD --stat -- CLAUDE.md AGENTS.md` で各 ≤+5 行 |
| 2 | Claude Collaboration Brief が Codex Delegation Packet と semantic drift | docs 内「Codex / Claude 役割分担」節を semantic mirror として明示、test scenario 5 で両 doc cross-reference 検証 | `diff <(grep "^- " docs/codex-delegation-packet.md) <(grep "^- " docs/claude-collaboration-brief.md)` で 役割分担節の相互参照確認 |
| 3 | governance.md §10 新設で既存 §1-9 番号衝突 | §9.x の sub-section が既存最後、§10 として追加で衝突なし | `grep -c "^## " sage/governance.md` で section count 確認 |
| 4 | installer byte-identical fail | TASK-0154 で generator → install.sh → diff の順で必ず検証 | `bash scripts/generate-installer.sh > /tmp/new.sh && diff install.sh /tmp/new.sh` 0 行 |
| 5 | snippet 追記で新規 install 後の挙動 regression | NFR-01 backward compat、新規 install のみ snippet 追加分受け取り | 既存 .sage/config.yaml + `bash install.sh --update` で installer_url 不変 |
| 6 | paired update doctrine が overhead を増やす | OPS-02 phased adoption (Phase 1 manual / Phase 2 tooling)、強制は CI test のみ | doctrine 導入後の SPEC 起票時間 (paired SPEC 含む) が単独 SPEC の 1.5 倍以内 |
| 7 | Claude Code 運用が docs/claude-collaboration-brief.md を読まない | CLAUDE.md §2.1 で reference を auto-load context に置く、snippet で新規導入先にも propagate | CLAUDE.md grep -c で 1+ reference 確認 |
| 8 | Codex review で予期せぬ finding | Phase 6.1 / SPEC-0022 と同 pattern で 1-2 round 収束見込み、3+ round で SPEC へ巻き戻し | review 履歴で converge 確認 |

## 失敗時の知識蓄積

### 知識蓄積フロー (3 ステップ)

```
Step 1 [検出]
  test-claude-collaboration-pairing.sh fail / paired update 漏れ / governance §10 削除 が発生
  ↓
Step 2 [記録]
  同 root cause で 2 回以上発生 → sage/failures.md に FAIL-PAIRING-XXXX として追記
  ↓
Step 3 [昇格]
  同 root cause で 3 回以上発生 → sage/anti-patterns.md に追記、SPEC paired-update 強制を governance §10 に格上げ
```

### sage/failures.md 連携

- **誰が**: paired test fail を観測した CI / reviewer
- **いつ**: 同 root cause (CLAUDE 側未更新 / AGENTS 側未更新 / governance §10 削除 / brief doc rename) で 2 回以上発生時
- **どの手順で**: CI log + 該当 commit SHA + SPEC-ID を抽出 → `sage/failures.md` に FAIL-PAIRING-XXXX として 6 elements (発生日 / 影響 / 検出経路 / 一次原因 / 再発防止 / 関連 SPEC-ID) で追記

### sage/anti-patterns.md への昇格

3 回以上発生で `sage/anti-patterns.md` に「PAIRING-XXXX: CLI-specific guidance one-sided update」追記。governance §10 に「paired SPEC ID 必須化」「未対応で merge 禁止」を昇格。

### Error Resolution 手順

| EC | エラー時メッセージ例 | Resolution |
|---|---|---|
| EC-01 (paired update 漏れ) | `not ok CLAUDE.md missing parallel guidance for AGENTS.md addition` | 該当 SPEC で CLAUDE.md 側 parallel update を追加するか、別 SPEC を起票 |
| EC-02 (doctrine drift) | `not ok CLAUDE.md / AGENTS.md doctrine semantically misaligned` | 両ファイルの §2 文言を governance §10 規範に合わせて同期 |
| EC-03 (brief doc 必須セクション欠落) | `not ok docs/claude-collaboration-brief.md missing sections: ...` | 削除されたセクションを復元、または FR-01 を更新して SPEC 改訂 |
| EC-04 (governance §10 削除) | `not ok sage/governance.md missing §10 AI Agent Doc Pairing Doctrine` | §10 を復元、削除した SPEC を revert |
| EC-05 (installer embed 漏れ) | `FAIL: install.sh diff: N lines (TMPL_CLAUDE_COLLABORATION_BRIEF missing)` | `bash scripts/generate-installer.sh > install.sh && git commit` |
| EC-06 (Codex side files 編集) | `WARN: Claude session edited Codex-specific file: AGENTS.md` | 該当変更を git restore、Codex side task として分離起票 |

## ロールバック手順

本 SPEC の各機能は段階的にロールバック可能:

| レベル | 手順 | 影響範囲 |
|---|---|---|
| 1. brief doc 一時 disable | `docs/claude-collaboration-brief.md` を rename → installer は WOULD-CREATE で skip | 新規 install で brief doc 不在、既存 install は影響なし |
| 2. CLAUDE.md doctrine revert | `CLAUDE.md` §2 を SPEC-0022 merge 前の文言に戻す → AGENTS.md §2 も同期 revert | doctrine が「strict alignment」に戻るが、CLI-specific divergence は SPEC-0022 で既存のため警告状態 |
| 3. governance §10 削除 | `sage/governance.md` §10 を削除 | paired-update doctrine 喪失、test fail (意図的、警告として機能) |
| 4. 完全 revert | 本 SPEC 導入 PR を `git revert` | brief doc / governance §10 / CLAUDE.md / snippet / installer / test 全て巻き戻り、SPEC-0022 単独状態に戻る |

各ロールバック後の検証:
- `bash scripts/sage-doctor.sh` 0 FAIL
- `bash templates/hooks/tests/run-tests.sh` 180/180 (SPEC-0022 base line) PASS
- `bash install.sh --update` で既存 .sage/config.yaml installer_url 不変

## 関連 Doctrine

- **R5 (RUN log redaction)**: 本 SPEC は RUN log に SPEC-ID / TASK-ID / 文言要約のみ記録、secret 値なし
- **R7 (CLAUDE/AGENTS 肥大化禁止)**: NFR-02 で各 ≤+5 行明示、長文は docs/claude-collaboration-brief.md に集約
- **R8 (hook tests required)**: AC-11 で 7+ scenario test 必須、AC-16/17 で異常系 fixture 含む
- **R9 (shellcheck required)**: AC-20 で test + 既存 modified scripts に shellcheck error 0 件必須
- **R10 (一次ソース引用)**: docs/claude-collaboration-brief.md は Anthropic Claude Code 公式 docs (Plan Mode / Skills / auto memory) を一次ソースとして引用

## Phase 6 全体での position

| SPEC | スコープ | 状態 |
|---|---|---|
| SPEC-0018 | Releases + SHA256SUMS + URL pinning (Phase 6.1) | merged (PR #27) |
| SPEC-0022 | Codex Delegation Packet (Phase 6.1, paired with SPEC-0023) | merged (PR #28) |
| **SPEC-0023** | **Claude Collaboration Brief + Pairing Doctrine** ← 本 SPEC | Draft |
| SPEC-0019 | cosign keyless signing (Phase 6.2) | 未起票 |
| SPEC-0020 | SLSA provenance (Phase 6.3) | 未起票 |
| SPEC-0021 | CLI Role Doctrine + Lane × CLI Matrix (rescoped after SPEC-0022/0023) | 未起票 |

本 SPEC で Phase 6.1 の AGENTS / CLAUDE pairing 整備が完了。SPEC-0021 は本 SPEC 後に Lane × CLI matrix と inventory template Codex 並用 default に再スコープ。

## 関連ID

- PLAN-ID: PLAN-0023 (本 SPEC と同時作成)
- TASK-ID: TASK-0151 (SPEC + PLAN + 5 TASK draft) / TASK-0152 (claude-collaboration-brief.md 新規) / TASK-0153 (CLAUDE.md + claude-md-snippet.md update + AGENTS.md doctrine sync) / TASK-0154 (governance.md §10 + generator + installer regen + version bump) / TASK-0155 (test-claude-collaboration-pairing.sh + RUN-0008 + final verification) / TASK-0156 (SPEC-0022 test branch-aware fix) / TASK-0157 (Codex review B1: RUN-ID collision fix RUN-0007 restore + RUN-0008 NEW) / TASK-0158 (Codex review M1: detached HEAD fallback) / TASK-0159 (Codex review M2/M3/M4: SPEC scope expansion + governance §10.5 wording + Scenario 5 強化) / TASK-0160 (Codex review m1/m2/m3/n1: status update + qualifications + final regen)
- RUN-ID: RUN-0008 (Claude side、TASK-0155+0156 implementation log)
