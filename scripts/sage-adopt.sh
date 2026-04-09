#!/bin/bash
# sage-adopt.sh — 既存リポジトリへのSAGE導入（非破壊）
# Usage: bash sage-adopt.sh [target-dir]
#   target-dir を省略した場合はカレントディレクトリに適用
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DIR="$(dirname "$SCRIPT_DIR")"
TARGET_DIR="${1:-.}"

# Move to target directory
cd "$TARGET_DIR"
echo "=== SAGE Phase A: Foundation Setup ==="
echo "対象: $(pwd)"
echo "既存ファイルの内容は変更しません。"
echo ""

# -----------------------------------------------
# 1. ディレクトリ作成
# -----------------------------------------------
echo "[1/6] ディレクトリ作成..."
mkdir -p specs plans tasks sage .sage/runs .sage/metrics docs scripts
echo "  OK: specs/ plans/ tasks/ sage/ .sage/ docs/ scripts/"

# -----------------------------------------------
# 2. テンプレートコピー（存在しない場合のみ）
# -----------------------------------------------
echo ""
echo "[2/6] テンプレートコピー..."
for f in specs/_template.md plans/_template.md tasks/_template.md; do
  if [ -f "$f" ]; then
    echo "  SKIP: $f (already exists)"
  elif [ -f "$TEMPLATE_DIR/$f" ]; then
    cp "$TEMPLATE_DIR/$f" "$f"
    echo "  COPY: $f"
  else
    echo "  WARN: $f (source not found in template)"
  fi
done

# sage/ ガバナンス文書コピー
for f in sage/charter.md sage/governance.md sage/failures.md sage/anti-patterns.md sage/quality-gates.md sage/adoption-phases.md sage/traceability.md; do
  if [ -f "$f" ]; then
    echo "  SKIP: $f (already exists)"
  elif [ -f "$TEMPLATE_DIR/$f" ]; then
    cp "$TEMPLATE_DIR/$f" "$f"
    echo "  COPY: $f"
  else
    echo "  SKIP: $f (source not found)"
  fi
done

# .sage/config.yaml
if [ -f ".sage/config.yaml" ]; then
  echo "  SKIP: .sage/config.yaml (already exists)"
elif [ -f "$TEMPLATE_DIR/.sage/config.yaml" ]; then
  cp "$TEMPLATE_DIR/.sage/config.yaml" ".sage/config.yaml"
  echo "  COPY: .sage/config.yaml"
fi

# scripts コピー
for f in scripts/sage-validate.sh scripts/sage-id-gen.sh scripts/sage-trace-check.sh; do
  if [ -f "$f" ]; then
    echo "  SKIP: $f (already exists)"
  elif [ -f "$TEMPLATE_DIR/$f" ]; then
    cp "$TEMPLATE_DIR/$f" "$f"
    chmod +x "$f"
    echo "  COPY: $f"
  else
    echo "  SKIP: $f (source not found)"
  fi
done

# -----------------------------------------------
# 3. CLAUDE.md — SAGEルール自動追記
# -----------------------------------------------
echo ""
echo "[3/6] CLAUDE.md 設定..."
SAGE_MARKER="<!-- === SAGE Development System (auto-injected) === -->"

if [ -f CLAUDE.md ]; then
  if grep -qF "$SAGE_MARKER" CLAUDE.md; then
    echo "  SKIP: CLAUDE.md (SAGE section already present)"
  else
    echo "" >> CLAUDE.md
    cat "$TEMPLATE_DIR/templates/claude-md-snippet.md" >> CLAUDE.md
    echo "  APPEND: CLAUDE.md (SAGE workflow rules added)"
  fi
else
  # 新規作成：プロジェクト名を取得して基本構造 + SAGEルール
  PROJECT_NAME=$(basename "$(pwd)")
  cat > CLAUDE.md <<HEADER
# ${PROJECT_NAME}

## Project Rules

<!-- Add your project-specific rules here -->

HEADER
  cat "$TEMPLATE_DIR/templates/claude-md-snippet.md" >> CLAUDE.md
  echo "  CREATE: CLAUDE.md (with SAGE workflow rules)"
fi

# -----------------------------------------------
# 4. AGENTS.md — Codex 対応
# -----------------------------------------------
echo ""
echo "[4/6] AGENTS.md 設定 (Codex対応)..."

if [ -f AGENTS.md ]; then
  if grep -qF "$SAGE_MARKER" AGENTS.md; then
    echo "  SKIP: AGENTS.md (SAGE section already present)"
  else
    echo "" >> AGENTS.md
    cat "$TEMPLATE_DIR/templates/agents-md-snippet.md" >> AGENTS.md
    echo "  APPEND: AGENTS.md (SAGE workflow rules added)"
  fi
else
  cat "$TEMPLATE_DIR/templates/agents-md-snippet.md" > AGENTS.md
  echo "  CREATE: AGENTS.md"
fi

# -----------------------------------------------
# 5. Pre-commit hook（TASK-ID 必須チェック）
# -----------------------------------------------
echo ""
echo "[5/6] Pre-commit hook 設定..."

# Git リポジトリかチェック
if [ -d .git ]; then
  HOOK_DIR=".git/hooks"
  # husky がある場合は .husky を使う
  if [ -d .husky ]; then
    HOOK_DIR=".husky"
  fi

  HOOK_FILE="$HOOK_DIR/commit-msg"

  if [ -f "$HOOK_FILE" ] && grep -qF "SAGE" "$HOOK_FILE"; then
    echo "  SKIP: $HOOK_FILE (SAGE hook already present)"
  elif [ -f "$HOOK_FILE" ]; then
    # 既存のhookがある場合は末尾に追記
    echo "" >> "$HOOK_FILE"
    echo "# --- SAGE: TASK-ID check ---" >> "$HOOK_FILE"
    cat "$TEMPLATE_DIR/templates/pre-commit-task-id.sh" >> "$HOOK_FILE"
    echo "  APPEND: $HOOK_FILE (SAGE TASK-ID check added)"
  else
    cp "$TEMPLATE_DIR/templates/pre-commit-task-id.sh" "$HOOK_FILE"
    chmod +x "$HOOK_FILE"
    echo "  CREATE: $HOOK_FILE"
  fi
else
  echo "  SKIP: not a git repository"
fi

# -----------------------------------------------
# 6. .gitignore 更新
# -----------------------------------------------
echo ""
echo "[6/6] .gitignore 更新..."
if [ ! -f .gitignore ]; then
  touch .gitignore
fi
grep -qxF '.sage/runs/' .gitignore 2>/dev/null || echo '.sage/runs/' >> .gitignore
grep -qxF '.sage/metrics/' .gitignore 2>/dev/null || echo '.sage/metrics/' >> .gitignore
echo "  OK: .sage/runs/ と .sage/metrics/ を .gitignore に追加"

# -----------------------------------------------
# 完了サマリー
# -----------------------------------------------
echo ""
echo "========================================="
echo "  SAGE Phase A: Setup Complete"
echo "========================================="
echo ""
echo "導入されたもの:"
echo "  - specs/, plans/, tasks/  テンプレート"
echo "  - sage/                   ガバナンス文書"
echo "  - CLAUDE.md               AIが自動でSAGEを守るルール"
echo "  - AGENTS.md               Codex用ルール"
echo "  - commit-msg hook         TASK-IDなしコミット防止"
echo ""
echo "これで AI エージェントは:"
echo "  1. セッション開始時にCLAUDE.md/AGENTS.mdを自動で読み"
echo "  2. SPECなしのコード実装を拒否し"
echo "  3. TASK-IDなしのコミットが弾かれます"
echo ""
echo "次のステップ:"
echo "  1. CLAUDE.md にプロジェクト固有ルールがあれば確認"
echo "  2. 次の機能開発で SPEC を書いてみる"
echo "     bash scripts/sage-id-gen.sh spec"
echo ""
