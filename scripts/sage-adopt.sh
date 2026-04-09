#!/bin/bash
# sage-adopt.sh — 既存リポジトリへのSAGE Phase A適用（非破壊）
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DIR="$(dirname "$SCRIPT_DIR")"

echo "=== SAGE Phase A: Foundation Setup ==="
echo "既存ファイルは一切変更しません。"
echo ""

# ディレクトリ作成
echo "ディレクトリ作成..."
mkdir -p specs plans tasks sage .sage/runs .sage/metrics docs scripts
echo "  OK: specs/ plans/ tasks/ sage/ .sage/ docs/ scripts/"

# テンプレートコピー（存在しない場合のみ）
echo ""
echo "テンプレートコピー..."
for f in specs/_template.md plans/_template.md tasks/_template.md; do
  if [ -f "$f" ]; then
    echo "  SKIP: $f (already exists)"
  elif [ -f "$TEMPLATE_DIR/$f" ]; then
    cp "$TEMPLATE_DIR/$f" "$f"
    echo "  COPY: $f"
  else
    echo "  SKIP: $f (source not found)"
  fi
done

# sage/ ファイルコピー（存在しない場合のみ）
for f in sage/charter.md sage/governance.md sage/failures.md; do
  if [ -f "$f" ]; then
    echo "  SKIP: $f (already exists)"
  elif [ -f "$TEMPLATE_DIR/$f" ]; then
    cp "$TEMPLATE_DIR/$f" "$f"
    echo "  COPY: $f"
  else
    echo "  SKIP: $f (source not found)"
  fi
done

# .sage/config.yaml コピー
if [ -f ".sage/config.yaml" ]; then
  echo "  SKIP: .sage/config.yaml (already exists)"
elif [ -f "$TEMPLATE_DIR/.sage/config.yaml" ]; then
  cp "$TEMPLATE_DIR/.sage/config.yaml" ".sage/config.yaml"
  echo "  COPY: .sage/config.yaml"
fi

# CLAUDE.md（存在しない場合のみスタブ作成）
echo ""
if [ -f CLAUDE.md ]; then
  echo "CLAUDE.md: already exists (not modified)"
else
  echo "# CLAUDE.md — SAGE Development System" > CLAUDE.md
  echo "" >> CLAUDE.md
  echo "このファイルにSAGE準拠のAIエージェントルールを記述してください。" >> CLAUDE.md
  echo "テンプレートは sage-ai-template の CLAUDE.md を参照。" >> CLAUDE.md
  echo "CLAUDE.md: stub created"
fi

# .gitignore追記（重複防止）
echo ""
echo ".gitignore 更新..."
if [ ! -f .gitignore ]; then
  touch .gitignore
fi
grep -qxF '.sage/runs/' .gitignore 2>/dev/null || echo '.sage/runs/' >> .gitignore
grep -qxF '.sage/metrics/' .gitignore 2>/dev/null || echo '.sage/metrics/' >> .gitignore
echo "  OK: .sage/runs/ と .sage/metrics/ を追加"

echo ""
echo "=== 完了 ==="
echo "SAGE Phase A: Foundation files created."
echo "既存ファイルは変更されていません。"
echo ""
echo "次のステップ:"
echo "  1. CLAUDE.md にプロジェクト固有ルールを記述"
echo "  2. 最初の SPEC を specs/SPEC-0001-*.md として作成"
echo "  3. make validate で構造検証"
