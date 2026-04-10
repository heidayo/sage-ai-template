#!/bin/bash
# sage-publish.sh — バージョン更新・install.sh再生成・Gist更新をワンコマンドで実行
# Usage: bash scripts/sage-publish.sh <new-version>
#   例: bash scripts/sage-publish.sh 0.2.0
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(dirname "$SCRIPT_DIR")"
GIST_ID_FILE="$ROOT/.sage/gist-id"
VERSION_FILE="$ROOT/.sage-version"

# --- セマンティックバージョニング自動インクリメント ---
increment_version() {
  local version="$1"
  local part="$2"
  local major minor patch
  IFS='.' read -r major minor patch <<< "$version"
  major=${major:-0}; minor=${minor:-0}; patch=${patch:-0}

  case "$part" in
    major) echo "$((major + 1)).0.0" ;;
    minor) echo "${major}.$((minor + 1)).0" ;;
    patch) echo "${major}.${minor}.$((patch + 1))" ;;
    *) echo "" ;;
  esac
}

# --- 引数チェック ---
if [ $# -lt 1 ]; then
  echo "Usage: bash scripts/sage-publish.sh <version|major|minor|patch>"
  echo ""
  echo "  セマンティックバージョニング:"
  echo "    bash scripts/sage-publish.sh major   # 0.3.0 → 1.0.0"
  echo "    bash scripts/sage-publish.sh minor   # 0.3.0 → 0.4.0"
  echo "    bash scripts/sage-publish.sh patch   # 0.3.0 → 0.3.1"
  echo ""
  echo "  直接指定:"
  echo "    bash scripts/sage-publish.sh 0.4.0"
  echo ""
  echo "事前準備:"
  echo "  1. gh auth login （GitHub CLI の認証）"
  echo "  2. echo 'YOUR_GIST_ID' > .sage/gist-id （Gist IDを保存）"
  exit 1
fi

OLD_VERSION=$(cat "$VERSION_FILE" 2>/dev/null || echo "0.0.0")

# major / minor / patch なら自動インクリメント、それ以外は直接指定
case "$1" in
  major|minor|patch)
    NEW_VERSION=$(increment_version "$OLD_VERSION" "$1")
    if [ -z "$NEW_VERSION" ]; then
      echo "Error: バージョン計算に失敗しました。現在: $OLD_VERSION"
      exit 1
    fi
    echo "Auto-increment: $OLD_VERSION → $NEW_VERSION ($1)"
    ;;
  *)
    NEW_VERSION="$1"
    ;;
esac

# --- バージョン確認 ---
if [ "$NEW_VERSION" = "$OLD_VERSION" ]; then
  echo "Error: バージョン $NEW_VERSION は現在と同じです。新しいバージョンを指定してください。"
  exit 1
fi

echo "========================================="
echo "  SAGE Publish: v${OLD_VERSION} → v${NEW_VERSION}"
echo "========================================="
echo ""

# --- Step 1: バージョン更新 ---
echo "[1/3] バージョン更新..."
echo "$NEW_VERSION" > "$VERSION_FILE"
echo "  OK: .sage-version = $NEW_VERSION"

# --- Step 2: install.sh 再生成 ---
echo ""
echo "[2/3] install.sh 再生成..."
bash "$SCRIPT_DIR/generate-installer.sh" > "$ROOT/install.sh"
LINES=$(wc -l < "$ROOT/install.sh" | tr -d ' ')
echo "  OK: install.sh ($LINES lines)"

# --- Step 3: Gist 更新 ---
echo ""
echo "[3/3] Gist 更新..."

if [ ! -f "$GIST_ID_FILE" ]; then
  echo "  SKIP: .sage/gist-id が見つかりません。"
  echo ""
  echo "  Gist を初めて作成する場合:"
  echo "    gh gist create install.sh --desc 'SAGE Development System Installer'"
  echo "    echo 'GIST_ID' > .sage/gist-id"
  echo ""
  echo "  手動で Gist を更新する場合:"
  echo "    gh gist edit GIST_ID install.sh"
  echo ""
  echo "  install.sh の再生成は完了しています。配布してください。"
  exit 0
fi

GIST_ID=$(cat "$GIST_ID_FILE" | tr -d '[:space:]')

if [ -z "$GIST_ID" ]; then
  echo "  Error: .sage/gist-id が空です。Gist IDを書き込んでください。"
  exit 1
fi

# gh コマンドの存在確認
if ! command -v gh &> /dev/null; then
  echo "  Error: GitHub CLI (gh) がインストールされていません。"
  echo "  https://cli.github.com/ からインストールしてください。"
  echo ""
  echo "  install.sh の再生成は完了しています。手動で配布してください。"
  exit 1
fi

# Gist 更新実行
if gh gist edit "$GIST_ID" "$ROOT/install.sh" 2>/dev/null; then
  echo "  OK: Gist $GIST_ID を更新しました"
else
  echo "  Error: Gist の更新に失敗しました。"
  echo "  以下を確認してください:"
  echo "    - gh auth login で認証済みか"
  echo "    - Gist ID ($GIST_ID) が正しいか"
  echo ""
  echo "  install.sh の再生成は完了しています。手動で配布してください。"
  exit 1
fi

# --- 完了 ---
echo ""
echo "========================================="
echo "  SAGE v${NEW_VERSION} — Published"
echo "========================================="
echo ""
echo "各プロジェクトは次回セッション開始時に自動更新されます。"
echo "（.sage/config.yaml の installer_url が設定されている場合）"
