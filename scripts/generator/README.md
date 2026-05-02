# `scripts/generator/` — installer generation modules

`scripts/generate-installer.sh` を機能別 module に分割した構造 (SPEC-0014)。各 module は parent generator から source されて `embed_file` を呼び出すか、install.sh main heredoc を emit する。

## 設計原則

- **byte-identical 必須**: parent + 全 module の出力が refactor 前の install.sh と完全一致 (diff = 0 lines)
- **numeric prefix で順序保証**: `01-...sh` ... `07-...sh` の bash glob sort で source 順固定
- **single-purpose**: 各 module は 1 phase 分の embed_file 呼び出しのみ
- **executable bit 不要**: 644 permission、source されるのみ (chmod +x 禁止)
- **環境変数 export 禁止**: parent shell に副作用残さない

## Module 一覧

| # | Module | 責務 | 主な内容 |
|---|---|---|---|
| 01 | `01-templates.sh` | SPEC/PLAN/TASK + sage governance テンプレ | TMPL_SPEC / TMPL_PLAN / TMPL_TASK / TMPL_CHARTER / TMPL_GOVERNANCE / TMPL_FAILURES / TMPL_ANTIPATTERNS / TMPL_QUALITY_GATES / TMPL_ADOPTION / TMPL_TRACEABILITY |
| 02 | `02-config.sh` | .sage/config.yaml + claude/agents snippets + commit hook (Phase 6.1: TMPL_CONFIG installer_url を Releases URL に sed substitute、SPEC-0018 FR-04) | TMPL_CONFIG / TMPL_CLAUDE_SNIPPET / TMPL_AGENTS_SNIPPET / TMPL_COMMIT_HOOK |
| 03 | `03-rules.sh` | rules + skills + base scripts | TMPL_RULES_* (5) / TMPL_SKILL_* (8) / TMPL_VALIDATE / TMPL_ID_GEN / TMPL_TRACE_CHECK / TMPL_UPDATE_CHECK / TMPL_PROMOTE / TMPL_RETRO_SPEC |
| 04 | `04-hooks-base.sh` | Phase 1-2A hooks (5) | TMPL_HOOK_BLOCK_DANGEROUS / PROTECT_SAGE / CHECK_SCOPE / SESSION_START / SESSION_STOP |
| 05 | `05-hooks-phase2b.sh` | Phase 2B hooks (3) | TMPL_HOOK_LETHAL_TRIFECTA / SECRET_READ / SECURITY_FILTER |
| 06 | `06-hooks-phase5.sh` | Phase 5+ hooks + audit + scripts + tests + settings | TMPL_HOOK_MCP_ALLOWLIST_AUDIT / SAGE_MCP_ALLOWLIST_TEMPLATE / TEST_* / MEASURE_HOOK_TIME / SCRIPT_MCP_ALLOWLIST_AUDIT / SAGE_AGENT_INVENTORY / TEST_AGENT_INVENTORY / SCRIPT_AGENT_INVENTORY / SCRIPT_RUNLOG_INDEX / SEARCH / DB_AUDIT / TEST_RUNLOG_* (3) / SETTINGS_SANDBOX / SETTINGS_README / SETTINGS_JSON |
| 07 | `07-installer-main.sh` | install.sh main heredoc body | `cat <<'MAIN_LOGIC' ... MAIN_LOGIC` で install.sh 本体 (746 行) |

## 新 SPEC 追加時の手順

| 追加内容 | 編集対象 module | 例 |
|---|---|---|
| 新 hook (Phase 1-2A 拡張) | `04-hooks-base.sh` | `embed_file "TMPL_HOOK_NEW" "$ROOT/templates/hooks/new.sh"` |
| 新 hook (Phase 2B 拡張) | `05-hooks-phase2b.sh` | 同上 |
| 新 hook / template (Phase 5+ 拡張) | `06-hooks-phase5.sh` | 同上 |
| 新 base script | `03-rules.sh` の Base SAGE scripts セクション | `embed_file "TMPL_NEW_SCRIPT" "$ROOT/scripts/new.sh"` |
| 新 rule / skill | `03-rules.sh` の対応セクション | 同上 |
| 新 SAGE governance template | `01-templates.sh` | 同上 |

**install.sh 本体 logic 変更時** (write_file_if_new / update_file 呼び出し追加など): `07-installer-main.sh` の heredoc 内を編集。新 TMPL_VAR 追加時は対応 hook で配置することを忘れないこと。

## 禁止事項

- module を chmod +x しない (source されるのみ)
- module を単独実行可能にしない (parent に embed_file 関数依存)
- module 間で環境変数 export しない
- numeric prefix 以外で順序を制御しない (glob sort 保証)
- 新 file embed 時に既存 module を rename しない (順序破壊)
- byte-identical CI を skip しない (`bash scripts/generate-installer.sh > /tmp/new.sh && diff install.sh /tmp/new.sh \| wc -l` で 0)

## ロールバック手順

| レベル | 手順 |
|---|---|
| 1. 一時 disable | `mv scripts/generator scripts/generator.bak && git checkout scripts/generate-installer.sh~1` |
| 2. module 単独 revert | `git revert <module-commit>` |
| 3. 完全 revert | SPEC-0014 PR 全体を `git revert` |

詳細は [SPEC-0014](../../specs/SPEC-0014-installer-modularize.md) §「ロールバック手順」参照。
