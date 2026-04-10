# SPEC-0003: Hooks実用化

## メタデータ

| フィールド | 内容 |
|-----------|------|
| SPEC-ID   | SPEC-0003 |
| ステータス | Draft |
| 作成日    | 2026-04-10 |
| 更新日    | 2026-04-10 |
| 担当Agent | Spec Agent |
| 依存SPEC  | SPEC-0001 |
| 権限レベル | system |

## 背景・目的

現在の `.claude/settings.json` には PreToolUse hook が1つだけ存在し、Edit|Write 操作時に `echo 'SAGE: File modification detected'` を実行するのみである。これは通知としても不完全であり、防御メカニズムとして機能していない。

SAGEの原則5「ルールは実行可能でなければならない」に従い、以下の課題を解決する:

1. **危険コマンドの無防備**: `--no-verify`, `--force`, `rm -rf` 等の破壊的操作がフックで阻止されない。CLAUDE.md の Forbidden Shortcuts に記載されているが AP-06 (Human-Only Guard) 状態
2. **設定ファイルの保護なし**: CLAUDE.md, `sage/`, `.sage/config.yaml` 等の SAGE 制御ファイルが意図せず変更される可能性がある
3. **File Scope の非検証**: TASK の許可パス外のファイルを編集しても警告すら出ない。AP-03 (Silent Scope Expansion) を防止できていない
4. **セッション初期化なし**: SessionStart hook が未設定のため、新セッション開始時にコンテキスト（直近RUNログ、保留中TASK、失敗パターン）が読み込まれない
5. **セッション終了時の記録なし**: メトリクスが蓄積されず、開発の観測可能性（原則9）が損なわれている

ECC (everything-claude-code) では PreToolUse で `--no-verify` をブロックし、SessionStart でコンテキストを復元するパターンが確立されている。SAGEはこのパターンを自身の文脈に適応させる。

## 対象ユーザー

SAGEテンプレートで Claude Code を使用する開発者。SAGEテンプレート自身のメンテナ（dogfooding）。

## スコープ（含む）

- `.claude/settings.json` -- 5つのフックの追加（PreToolUse x 3, SessionStart x 1, Stop x 1）
- `templates/hooks/` ディレクトリ（新規作成）-- hook スクリプトの配置場所
  - `templates/hooks/block-dangerous-commands.sh` -- `--no-verify`, `--force`, `rm -rf /`, `git push -f` をブロック
  - `templates/hooks/protect-sage-files.sh` -- CLAUDE.md, `sage/*`, `.sage/config.yaml` への書き込みを制限
  - `templates/hooks/check-file-scope.sh` -- 現在の TASK の File Scope と編集対象ファイルを照合
  - `templates/hooks/session-start.sh` -- 直近の RUN ログ、保留中 TASK、failures.md の要約をコンテキストとして出力
  - `templates/hooks/session-stop.sh` -- セッション中のファイル変更数、経過時間を `.sage/metrics/sessions.jsonl` に追記
- `scripts/generate-installer.sh` -- hook テンプレートの埋め込み追加
- `install.sh` -- hook ファイルの展開と `.claude/settings.json` への hook 登録
- `.sage/config.yaml` -- `hooks.profile` 設定の追加（minimal / standard / strict / none）

## スコープ外（明示的に除外）

- Node.js / Python ベースのフック実装（bash のみ。SAGE のスクリプト群は全て bash）
- Git pre-commit / pre-push hook の追加（既存の `templates/pre-commit-task-id.sh` は変更しない）
- MCP サーバーの hook 連携（Phase D 以降の別 SPEC）
- hook の GUI 設定ツール
- フック実行の非同期化・バックグラウンド実行

## 要件

### 機能要件
- [FR-01] PreToolUse (Bash matcher): コマンド引数に `--no-verify`, `--force` (git push のコンテキスト), `rm -rf /`, `rm -rf ~`, `rm -rf .` が含まれる場合、exit 2 でツール使用を拒否し、理由を stderr に出力する
- [FR-02] PreToolUse (Edit|Write matcher): 対象ファイルパスが `CLAUDE.md`, `sage/*`, `.sage/config.yaml`, `.claude/settings.json` に一致する場合、現在のアクティブTASKファイルに `sage-managed: true` フラグがなければ exit 2 で拒否する
- [FR-03] PreToolUse (Edit|Write matcher): 対象ファイルパスが現在の TASK の File Scope 外の場合、warning メッセージを stderr に出力する（exit 0 -- ブロックはしない。strict モードで exit 2 化を検討）
- [FR-04] SessionStart: `.sage/runs/` の最新3件の RUN ログのサマリー（status, task_id, error_log の先頭行）を標準出力する
- [FR-05] SessionStart: `tasks/` ディレクトリから status が `in-progress` または `blocked` の TASK を一覧表示する
- [FR-06] SessionStart: `sage/failures.md` の最新5件のエントリを表示する
- [FR-07] Stop: セッション開始時刻、ファイル変更数、編集ファイル一覧を `.sage/metrics/sessions.jsonl` に1行のJSONとして追記する
- [FR-08] `.sage/config.yaml` の `hooks.profile` に応じてフックの有効/無効を制御する:
  - `minimal`: SessionStart + Stop のみ（Phase A 向け）
  - `standard`: minimal + dangerous command block + SAGE file protection（Phase B 向け）
  - `strict`: standard + File Scope check を exit 2 化（Phase C 向け）
  - `none`: 全フック無効化

### 非機能要件
- [NFR-01] 各フックの実行時間は 500ms 以内（ローカル実行のため体感速度が重要）
- [NFR-02] フックスクリプトは bash 4.0+ 互換。外部コマンド依存は `jq`, `grep`, `find`, `date` のみ（macOS / Linux 両対応）
- [NFR-03] フックが異常終了（bash エラー）した場合、Claude Code の操作をブロックしない（エラーハンドリングで exit 0 にフォールバック）

### セキュリティ要件
- [SEC-01] protect-sage-files.sh で保護対象に `.claude/settings.json` 自体を含める（フックの無効化を防止）
- [SEC-02] block-dangerous-commands.sh は引数のパターンマッチのみで判定し、コマンドの実行は行わない（静的解析のみ）
- [SEC-03] session-stop.sh が書き込む `.sage/metrics/sessions.jsonl` にはファイルパス以外の機密情報を含めない

### 運用要件
- [OPS-01] hook を無効化したい場合は `.sage/config.yaml` の `hooks.profile: none` で全フック無効化が可能
- [OPS-02] 各フックスクリプトの先頭にコメントで用途と動作を記載する
- [OPS-03] `templates/hooks/` 以下のスクリプトは `install.sh` で配布先にデプロイされる

## 受け入れ条件（Acceptance Criteria）

- [ ] AC-01: `.claude/settings.json` に PreToolUse hook が3件、SessionStart hook が1件、Stop hook が1件、合計5件のフック定義が存在する
- [ ] AC-02: `echo '{"tool_name":"Bash","tool_input":{"command":"git push --no-verify"}}' | bash templates/hooks/block-dangerous-commands.sh` の exit code が 2 である
- [ ] AC-03: SAGE管理TASKが非アクティブ状態で、`echo '{"tool_name":"Edit","tool_input":{"file_path":"CLAUDE.md"}}' | bash templates/hooks/protect-sage-files.sh` の exit code が 2 である
- [ ] AC-04: `bash templates/hooks/session-start.sh` が実行完了し exit code 0 を返す（`.sage/runs/` が空の場合も正常動作）
- [ ] AC-05: `bash templates/hooks/session-stop.sh` 実行後、`.sage/metrics/sessions.jsonl` にJSON行が1行追加される
- [ ] AC-06: `.sage/config.yaml` に `hooks.profile: minimal` と設定した場合、block-dangerous-commands.sh と protect-sage-files.sh が即座に exit 0 する（profile チェックによる early return）
- [ ] AC-07: JSON stdin が空文字列の場合、block-dangerous-commands.sh が exit 0 を返す（安全側フォールバック）
- [ ] AC-08: jq がインストールされていない場合、hook が grep ベースのフォールバック処理で動作し exit 0 を返す

## 異常系

- `.sage/runs/` ディレクトリが存在しない場合: session-start.sh は "No RUN logs found" と表示して正常終了
- `.sage/metrics/` ディレクトリが存在しない場合: session-stop.sh は自動作成して続行
- TASK ファイルが存在しない場合: check-file-scope.sh は "No active TASK found, skipping scope check" と表示して exit 0
- `jq` がインストールされていない場合: hook スクリプトは grep ベースのフォールバック処理を使用
- `.sage/config.yaml` に hooks セクションがない場合: デフォルト profile `standard` として動作
- JSON stdin が不正な形式の場合: jq パースエラーをキャッチし exit 0（hook失敗でClaude停止禁止）

## 契約

- API: なし
- DB: なし
- イベント: `.sage/metrics/sessions.jsonl` -- JSONL形式（1行1セッション記録）

## リスク

- リスク1: PreToolUse hook の exit 2 が Claude Code の UX を損なう可能性 -> 軽減策: 拒否時のメッセージに理由と代替手段を明示する
- リスク2: File Scope チェックの誤検知でワークフローが中断 -> 軽減策: Phase B では warning のみ (exit 0)。strict モード (exit 2) は Phase C 以降でオプトイン
- リスク3: protect-sage-files.sh が SAGE 自身の開発を妨げる -> 軽減策: `sage-managed: true` フラグ付き TASK で明示的に許可

## 実装メモ（Implementation Agent向け）

- Claude Code の hook 仕様: PreToolUse は stdin にツール名 + 引数の JSON を受け取り、exit 0 (許可) / exit 2 (拒否) を返す。stderr がユーザーに表示される
- SessionStart は引数なしで呼ばれ、stdout の内容がコンテキストに追加される
- `.claude/settings.json` の hooks 構造は現在の1件の PreToolUse パターンを踏襲
- block-dangerous-commands.sh は stdin の JSON から `tool_input.command` を jq で抽出しパターンマッチ
- TASK のアクティブ判定: `tasks/` 内の .md ファイルで `ステータス` 行に `実行中` を含むファイルを検索
- install.sh への統合: `generate-installer.sh` の `embed_file` 関数（行18-33）で各 hook スクリプトを埋め込む

### CLAUDE.md追記ルール
- hook スクリプトは必ず bash で実装（Node.js 禁止）
- exit 2 を使用する場合は拒否理由と代替手段を stderr に明記すること
- JSON stdin のパースは jq を使用し、パースエラー時は必ず exit 0（hook 失敗で Claude 停止禁止）
- hook スクリプト先頭に用途・動作・プロファイル要件をコメントで記載すること

### プロファイル昇格条件
- **minimal → standard**: `make report` で SESSIONS >= 10 かつ STATUS: HEALTHY
- **standard → strict**: `make report` で2週間連続 HEALTHY（doctor-history.jsonl で確認）
- **昇格手順**: `.sage/config.yaml` の `hooks.profile` を手動変更 → `make validate` で確認
- **デフォルト**: install 直後は `minimal`（Phase A 向け）

## 関連ID

- PLAN-ID: PLAN-0003
- TASK-ID: TASK-0035 〜 TASK-0044
