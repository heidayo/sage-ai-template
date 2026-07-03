# TypeScript Enforcement プリセット（SPEC-0030）

TypeScript プロジェクト向けの型安全 enforcement 一式です。「`as any` 禁止」「`@ts-ignore` 禁止」を文書ルール（Human-Only Guard, AP-06）で終わらせず、lint の error 化と tsc エラー数ラチェットで機械的に強制します。

構成要素:

- `scripts/sage-tsc-ratchet.sh` — tsc エラー数ラチェット（baseline との比較で「増加」を CI で FAIL させる）
- `templates/ts-enforcement/` — 型抑制コメント・`any` を error 化する ESLint 設定断片 3 ファイル
- 本ドキュメント — 導入手順と運用規約

全て **opt-in** です。使わなければ何も起きません（非 TS プロジェクト・既存導入先への影響ゼロ）。

## 1. 導入手順（ファイルコピー）

本機構は installer（`install.sh`）の配布対象に**含まれません**。TS 専用の追加ツールであり、非 TS 導入先へ配布する意味がないためです（SPEC-0030 §installer 配布判断）。導入は SAGE テンプレートリポジトリからのファイルコピーで行います:

```bash
# SAGE テンプレートリポジトリを取得済みの前提
cp <sage-ai-template>/scripts/sage-tsc-ratchet.sh scripts/
cp -r <sage-ai-template>/templates/ts-enforcement/ .
chmod +x scripts/sage-tsc-ratchet.sh
```

前提: bash 3.2+ / POSIX ツール（grep/sed 等）が利用可能であること。jq / node / python には依存しません（ESLint 断片の適用には当然 Node.js / ESLint が必要です）。

## 2. ESLint 断片の適用

`templates/ts-enforcement/` の 3 ファイルから、プロジェクトの ESLint 構成に合うものを選んで組み込みます。前提バージョン: @typescript-eslint v6+。

| ファイル | 対象 | `ban-ts-comment` | `no-explicit-any` |
|----------|------|------------------|-------------------|
| `eslint-flat.mjs` | flat config（標準） | error | error |
| `eslint-flat-transitional.mjs` | flat config（レガシー移行用） | error | **warn** |
| `eslintrc-fragment.json` | legacy `.eslintrc`（error バリアント） | error | error |

- **flat config**: ファイルを `eslint.config.mjs` の隣にコピーし、spread で取り込みます（各ファイル冒頭のコメント参照）:

  ```js
  import sageTsEnforcement from './eslint-flat.mjs';
  export default [...tseslint.configs.recommended, ...sageTsEnforcement];
  ```

- **legacy `.eslintrc`**: `eslintrc-fragment.json` の `rules` オブジェクトを既存 `.eslintrc(.json)` の `rules` にマージします。transitional 相当にしたい場合は `@typescript-eslint/no-explicit-any` の値を `"warn"` に差し替えてください（`ban-ts-comment` は全バリアント error のまま維持）。

- `@ts-expect-error` は `allow-with-description`（説明必須）で許容します。正当な抑制には理由の明文化を強制する設計です。`@ts-ignore` / `@ts-nocheck` は全バリアントで禁止です。
- 断片が導入先の @typescript-eslint バージョンと不整合な場合（ルール名変更等）は、導入先の lint 実行で顕在化します（実行検証は本 SPEC のスコープ外）。

## 3. ラチェット運用（sage-tsc-ratchet.sh）

### 基本コマンド

```bash
# 初回: baseline を現在のエラー数で作成（既存 baseline があれば exit 1）
bash scripts/sage-tsc-ratchet.sh --init

# 検査モード（CI で実行）: baseline 超過で exit 1
bash scripts/sage-tsc-ratchet.sh

# エラーを減らしたら baseline を下げる（唯一の正規更新経路）
bash scripts/sage-tsc-ratchet.sh --update
```

- 検査モードの判定: 現在数 > baseline → 現在数・baseline・増分を stderr に出力して **exit 1**。同数 → exit 0。減少 → exit 0 + `--update` 推奨 INFO。
- エラー数は tsc 出力（stdout/stderr 両方）の `error TS<番号>` パターン行数でカウントします（`path(line,col): error TS1234: message` 形式が前提）。tsc の出力フォーマットが変わると誤カウントし得るため、パターンをここに明記しています。
- **同数だがエラー内容が入れ替わったケースは exit 0 です**（総数のみを管理する仕様。種別別 baseline はスコープ外）。
- tsc コマンド自体が失敗した場合（`error TS` パターン 0 件 + 非 0 exit、例: コマンド不在）は「tsc 実行失敗」として exit 1 とし、出力全文を stderr へ透過します。エラー 0 件と誤認しません（fail-closed）。

### tsc コマンドの注入

優先順位: 環境変数 `SAGE_TSC_COMMAND` > 引数 `--tsc-command "<cmd>"` > デフォルト `npx tsc --noEmit`。

```bash
# pnpm monorepo の例
SAGE_TSC_COMMAND="pnpm --filter app exec tsc --noEmit" bash scripts/sage-tsc-ratchet.sh
```

**セキュリティ注意（SEC-01）**: `SAGE_TSC_COMMAND` / `--tsc-command` はシェル経由で実行されます。**信頼できる値のみ**を設定してください。CI secrets や外部入力（PR タイトル・issue 本文等）を渡してはいけません。本スクリプトは「ユーザーが自分の tsc を自分の環境で実行する」ツールであり、信頼境界を跨ぎません。

### CI への組込み例

```yaml
# GitHub Actions のステップ例（CI 強制の構成は導入先の責任範囲）
- name: tsc error ratchet
  run: SAGE_TSC_COMMAND="pnpm exec tsc --noEmit" bash scripts/sage-tsc-ratchet.sh
```

### .tsc-baseline.json の手動編集禁止

`.tsc-baseline.json`（固定スキーマ `{"errors": <非負整数>, "updated_at": "<ISO8601>"}`）の更新は `--update` / `--init` **のみ**が正規経路です。手動編集は禁止です。

- フォーマット逸脱（負数・非数値・欠損・パース不能）はスクリプトの整合検証が検出し exit 1 で fail-closed します。
- 正しいフォーマットのまま数値だけを改竄する手動編集は機械検出できません。`.tsc-baseline.json` を変更するコミットには ratchet 実行ログの添付を PR レビューで要求してください（残存リスクとして SPEC-0030 リスク2 に記録済み）。

## 4. tsconfig 変更時の検証証跡規約

`tsconfig*.json` を変更する PR には、以下の検証証跡を PR 本文に添付してください:

1. ratchet 実行ログ（`bash scripts/sage-tsc-ratchet.sh` の出力 — エラー数が baseline 以下であること）
2. build / typecheck の実行結果（変更後の設定で型検査が通ること）

tsconfig の変更（`strict` 系フラグの緩和等）はエラー数を静かに変動させ得るため、証跡でレビュー可能にします。**この規約の CI 強制はスコープ外です**（導入先の CI 構成に依存するため、運用規約 + レビューで担保します）。

## 5. SPEC-0028 ts-pnpm プリセットとの関係

[docs/stack-presets.md](stack-presets.md) の `ts-pnpm` プリセット（`templates/project-checks/ts-pnpm.yaml`）は、`.sage/config.yaml` の `project_checks.type_check` に `pnpm exec tsc --noEmit` を設定します。これは Gate 1 での「型チェックの実行」を担います。

本機構はその一歩先の「型品質の段階的強制」を担います:

- プリセット（SPEC-0028）= 型チェックコマンドの設定（エラーがあれば FAIL）
- 本機構（SPEC-0030）= 既存エラーを抱えたまま「増やさない」を強制し、ゼロへ向かうラチェット + 型抑制の lint 禁止

既存 tsc エラーが 0 のプロジェクトはプリセットの `type_check` だけで十分です。エラーを抱えたレガシープロジェクトが本機構の主対象です。

## 6. 段階的昇格（graduation）

レガシープロジェクトは以下の 2 段階で強制レベルを引き上げます。

### (a) transitional → error の切替

`eslint-flat-transitional.mjs`（`no-explicit-any`: warn）で開始した場合:

1. lint を全体実行し、`no-explicit-any` の **warn 検出が 0 件**であることを確認する
2. 確認後、`eslint-flat.mjs`（または legacy fragment の error 版）へ切り替える

warn が残ったまま切り替えると CI が即 FAIL するため、必ず 0 件確認を先に行います。

### (b) baseline 0 到達後の zero-tolerance 運用

ratchet の baseline が 0 に到達したら:

1. `bash scripts/sage-tsc-ratchet.sh --update` で baseline を 0 に固定する
2. 以後、検査モードはエラー 1 件以上（0 からの増加）を即 FAIL とする — 事実上の zero-tolerance 運用

この時点で「ラチェット」は「型エラー完全禁止ゲート」として機能し続けます。baseline を 0 から引き上げる `--update` は行わない運用としてください。

## 関連

- SPEC: `specs/SPEC-0030-ts-enforcement.md`
- スタックプリセット（型チェックコマンド設定）: [docs/stack-presets.md](stack-presets.md)
- 断片実体: `templates/ts-enforcement/`
- ロールバック: 本機構は opt-in のため、CI から ratchet ステップを外す / ESLint config から断片を除去するだけで無効化できます
