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
echo "[1/8] ディレクトリ作成..."
mkdir -p specs plans tasks sage .sage/runs .sage/metrics docs scripts .claude/rules .claude/skills/sage-spec .claude/skills/sage-plan .claude/skills/sage-review .claude/skills/sage-evaluate/references
echo "  OK: specs/ plans/ tasks/ sage/ .sage/ docs/ scripts/ .claude/rules/ .claude/skills/"

# -----------------------------------------------
# 2. テンプレートコピー（存在しない場合のみ）
# -----------------------------------------------
echo ""
echo "[2/8] テンプレートコピー..."
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
for f in scripts/sage-validate.sh scripts/sage-id-gen.sh scripts/sage-trace-check.sh scripts/sage-update-check.sh; do
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
# 3. .claude/rules/ コピー
# -----------------------------------------------
echo ""
echo "[3/8] .claude/rules/ コピー..."
for f in templates/rules/specs-rules.md templates/rules/plans-rules.md templates/rules/tasks-rules.md templates/rules/src-rules.md templates/rules/sage-governance-rules.md; do
  target=".claude/rules/$(basename "$f")"
  if [ -f "$target" ]; then
    echo "  SKIP: $target (already exists)"
  elif [ -f "$TEMPLATE_DIR/$f" ]; then
    cp "$TEMPLATE_DIR/$f" "$target"
    echo "  COPY: $target"
  else
    echo "  SKIP: $target (source not found)"
  fi
done

# -----------------------------------------------
# 4. .claude/skills/ コピー
# -----------------------------------------------
echo ""
echo "[4/8] .claude/skills/ コピー..."
for skill in sage-spec sage-plan sage-review; do
  target=".claude/skills/$skill/SKILL.md"
  source="$TEMPLATE_DIR/templates/skills/$skill/SKILL.md"
  if [ -f "$target" ]; then
    echo "  SKIP: $target (already exists)"
  elif [ -f "$source" ]; then
    cp "$source" "$target"
    echo "  COPY: $target"
  else
    echo "  SKIP: $target (source not found)"
  fi
done

# sage-evaluate（SKILL.md + references/）
for f in SKILL.md references/scoring-rubric.md references/knowledge-base.md; do
  target=".claude/skills/sage-evaluate/$f"
  source="$TEMPLATE_DIR/templates/skills/sage-evaluate/$f"
  if [ -f "$target" ]; then
    echo "  SKIP: $target (already exists)"
  elif [ -f "$source" ]; then
    cp "$source" "$target"
    echo "  COPY: $target"
  else
    echo "  SKIP: $target (source not found)"
  fi
done

# -----------------------------------------------
# Audit function for existing CLAUDE.md
# -----------------------------------------------
audit_existing_claude_md() {
  local file="$1"
  local report=".sage/adoption-audit.md"

  echo "# SAGE Adoption Audit" > "$report"
  echo "Generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$report"
  echo "" >> "$report"

  local rules=$(grep -E "^[\t ]*[-*]" "$file" | grep -v "^#" | grep -v '^\s*$')

  echo "## Analysis" >> "$report"
  echo "" >> "$report"

  echo "### SAFE_AUTO_APPLY" >> "$report"
  echo "These rules do not conflict with SAGE. No action needed." >> "$report"
  echo "$rules" | while IFS= read -r line; do
    if [ -n "$line" ] && ! echo "$line" | grep -qiE "commit|task|spec|todo|fixme|test|scope|review"; then
      echo "- $line" >> "$report"
    fi
  done
  echo "" >> "$report"

  echo "### NEEDS_REVIEW" >> "$report"
  echo "These rules may overlap with SAGE. Review recommended." >> "$report"
  echo "$rules" | while IFS= read -r line; do
    if [ -n "$line" ] && echo "$line" | grep -qiE "spec|scope|review|test|coverage"; then
      if ! echo "$line" | grep -qiE "commit.*id|task.*id|no commit|skip test"; then
        echo "- $line" >> "$report"
      fi
    fi
  done
  echo "" >> "$report"

  echo "### CONFLICT" >> "$report"
  echo "These rules may conflict with SAGE. Do NOT auto-merge." >> "$report"
  echo "$rules" | while IFS= read -r line; do
    if [ -n "$line" ] && echo "$line" | grep -qiE "commit.*message|commit.*format|task.*id|ticket.*id|todo.*ok|fixme.*allow|skip.*test"; then
      echo "- $line (conflicts with SAGE commit/test rules)" >> "$report"
    fi
  done
  echo "" >> "$report"

  echo "## Recommendation" >> "$report"
  echo "- SAFE_AUTO_APPLY items: no action needed" >> "$report"
  echo "- NEEDS_REVIEW items: check if your project rules and SAGE rules overlap. Remove duplicates." >> "$report"
  echo "- CONFLICT items: resolve manually before relying on SAGE enforcement." >> "$report"

  echo "  AUDIT: Report written to $report"
}

# -----------------------------------------------
# 5. CLAUDE.md — SAGEルール自動追記
# -----------------------------------------------
echo ""
echo "[5/8] CLAUDE.md 設定..."
SAGE_MARKER="<!-- === SAGE Development System (auto-injected) === -->"

if [ -f CLAUDE.md ]; then
  if grep -qF "$SAGE_MARKER" CLAUDE.md; then
    echo "  SKIP: CLAUDE.md (SAGE section already present)"
  else
    # Existing CLAUDE.md without SAGE — run audit first
    if [ -s CLAUDE.md ]; then
      audit_existing_claude_md CLAUDE.md
    fi
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
# 6. AGENTS.md — Codex 対応
# -----------------------------------------------
echo ""
echo "[6/8] AGENTS.md 設定 (Codex対応)..."

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
# 7. Pre-commit hook（TASK-ID 必須チェック）
# -----------------------------------------------
echo ""
echo "[7/8] Pre-commit hook 設定..."

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
# 8. .gitignore 更新
# -----------------------------------------------
echo ""
echo "[8/8] .gitignore 更新..."
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
echo "  - .claude/rules/          パス別ルール（5ファイル）"
echo "  - .claude/skills/         ワークフロー（/sage-spec, /sage-plan, /sage-review）"
echo "  - CLAUDE.md               AIが自動でSAGEを守るルール（最小ブートストラップ）"
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
