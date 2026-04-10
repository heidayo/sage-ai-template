# SAGE アンチパターン

## 概要

SAGEでは以下を明確に失敗パターンとして定義する。各パターンに**検出シグナル**と**CI検出方法**を付与し、Human-Only Guard（ルールが文章だけで止まらない）を防ぐ。

---

## AP-01: Vibe Merge

**定義**: なんとなく良さそうだから統合する。

**検出シグナル**:
- PRがどの品質ゲートも通過せずにマージされた
- レビューコメントが0件でマージされた

**CI検出方法**:
- GitHub branch protection で必須ステータスチェックを設定
- `sage-structural-gate` + `sage-security-gate` を required に設定

**防止策**: Branch protection の required status checks を有効化

---

## AP-02: Big Bang Prompt

**定義**: 巨大な要求を1回の生成で済ませようとする。

**検出シグナル**:
- 単一コミットで20ファイル以上を変更
- TASK-IDなしで大量変更
- 1つのPRに複数のSPEC-IDが混在

**CI検出方法**:
```bash
# sage-trace-check.sh で検出可能
FILES_CHANGED=$(git diff --name-only HEAD~1 | wc -l)
if [ "$FILES_CHANGED" -gt 20 ]; then
  echo "WARNING: Big Bang Prompt detected ($FILES_CHANGED files in one commit)"
fi
```

**防止策**: Slice フェーズで1タスク1責務に分割

---

## AP-03: Silent Scope Expansion

**定義**: 仕様にない変更をついでに入れる。

**検出シグナル**:
- TASK-IDの File Scope 外のファイルが変更されている
- PRの変更ファイルがTASKの「出力」セクションに列挙されていない

**CI検出方法**:
- Architecture Gate (Gate 4) でファイルスコープをチェック
- PRテンプレートのチェックリストで手動確認

**防止策**: TASK テンプレートの File Scope を厳密に記入

---

## AP-04: AI Monolith

**定義**: 1つのAIに仕様、実装、レビュー、テスト、判断を全部持たせる。

**検出シグナル**:
- 同一セッションで SPEC 作成 → 実装 → レビュー → マージ承認が行われた
- AGENT-ID がすべて同一

**CI検出方法**:
- 実行ログ（.sage/runs/）で AGENT-ID の多様性をチェック
- 実装エージェントとレビューエージェントの分離を検証

**防止策**: CLAUDE.md の Agent Constraints に分離ルールを記載

---

## AP-05: Invisible Development

**定義**: 誰が何をしたか分からない。

**検出シグナル**:
- コミットメッセージに TASK-ID が含まれていない
- PR本文に SPEC-ID が含まれていない
- `.sage/runs/` にログが存在しない

**CI検出方法**:
```bash
# sage-trace-check.sh で検出
git log --oneline -n 1 | grep -qE 'TASK-[0-9]{4}' || echo "WARNING: Invisible Development"
```

**防止策**: Traceability Requirements を CI で強制

---

## AP-06: Human-Only Guard

**定義**: ルールが文章しかなく、違反しても止まらない。

**検出シグナル**:
- `sage/` のルールに対応するCIチェックが存在しない
- `CLAUDE.md` の Forbidden Shortcuts が CI で検証されていない

**CI検出方法**:
- `sage-validate.sh` でルール文書と CI workflow の対応を確認

**防止策**: すべてのルールは CI または pre-commit hook で強制

**現状 (v0.2)**: SPEC-0002 で CI Gate を enforcement 化（WARN→FAIL）、SPEC-0003 で Claude Code hooks を実装（危険コマンドブロック・設定ファイル保護）。AP-06 は部分的に解消。残存リスク: Branch protection の自動設定は未実装（手動設定が必要）。

---

## 昇格ルール

`sage/failures.md` に記録された失敗が**3回以上繰り返された場合**、このファイルに新しいアンチパターンとして追加する。

昇格時の必須項目:
1. AP-XX 番号の採番
2. 定義（1文）
3. 検出シグナル（観測可能な事象）
4. CI検出方法（自動化可能なチェック）
5. 防止策（具体的な対応）
