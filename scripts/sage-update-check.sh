#!/bin/bash
# sage-update-check.sh — 1日1回、installer_url から最新バージョンを確認して更新通知する
# エラーが発生しても開発を止めない（警告のみ）
# SPEC-0008 / SPEC-0018 (URL flavor 検出 + Releases / Gist 両対応)

SAGE_DIR=".sage"
VERSION_FILE="$SAGE_DIR/version"
LAST_CHECK_FILE="$SAGE_DIR/last-update-check"
CONFIG_FILE="$SAGE_DIR/config.yaml"

# installer_url 未設定チェック（AC-4）
if [ ! -f "$CONFIG_FILE" ]; then
  echo "SAGE: config.yaml が見つかりません。バージョンチェックをスキップします。"
  exit 0
fi

INSTALLER_URL=$(grep 'installer_url:' "$CONFIG_FILE" 2>/dev/null | awk '{print $2}' | tr -d '"')

if [ -z "$INSTALLER_URL" ] || echo "$INSTALLER_URL" | grep -qF "YOUR_USER/GIST_ID"; then
  echo "SAGE: installer_url が未設定です。バージョンチェックをスキップします。"
  exit 0
fi

# 1日1回チェック制限（AC-1）
if [ -f "$LAST_CHECK_FILE" ]; then
  last_check=$(cat "$LAST_CHECK_FILE")
  today=$(date +%Y-%m-%d)
  if [ "$last_check" = "$today" ]; then
    exit 0  # 今日はチェック済み（出力なし）
  fi
fi

LOCAL_VERSION=$(cat "$VERSION_FILE" 2>/dev/null || echo "0.0.0")

# SPEC-0018: URL flavor 検出
# - tag-pinned (releases/download/vX.Y.Z/install.sh): immutable URL — skip auto-check (always returns same version)
# - releases/latest/...: GitHub が常に latest にリダイレクト → fetch + grep で SAGE_VERSION 取得可能
# - Gist: 従来通り fetch + grep
URL_FLAVOR=""
case "$INSTALLER_URL" in
  *github.com*releases/download/v*)
    URL_FLAVOR="tag-pinned"
    echo "SAGE: installer_url is tag-pinned (immutable per version). Auto-update check is skipped."
    echo "  To get notified about new releases, change installer_url in .sage/config.yaml to:"
    echo "    https://github.com/heidayo/sage-ai-template/releases/latest/download/install.sh"
    date +%Y-%m-%d > "$LAST_CHECK_FILE"
    exit 0
    ;;
  *github.com*releases/latest/*) URL_FLAVOR="releases-latest" ;;
  *gist.githubusercontent.com*)  URL_FLAVOR="gist" ;;
  *)                             URL_FLAVOR="custom" ;;
esac

# 最新バージョンを取得（AC-3: curl失敗時は警告のみ）
REMOTE_VERSION=$(curl -fsSL --connect-timeout 5 "$INSTALLER_URL" 2>/dev/null | grep -m1 'SAGE_VERSION=' | cut -d'"' -f2)

if [ -z "$REMOTE_VERSION" ]; then
  echo "SAGE: 最新バージョンの取得に失敗しました（ネットワークエラーまたはURL無効）。スキップします。"
  echo "  URL flavor: ${URL_FLAVOR}"
  date +%Y-%m-%d > "$LAST_CHECK_FILE"
  exit 0
fi

# 今日の日付を記録
date +%Y-%m-%d > "$LAST_CHECK_FILE"

# バージョン比較（AC-2）
if [ "$REMOTE_VERSION" = "$LOCAL_VERSION" ]; then
  echo "SAGE v${LOCAL_VERSION} は最新です。(${URL_FLAVOR})"
  exit 0
fi

# 更新通知（AC-5）
echo "SAGE 更新があります: v${LOCAL_VERSION} → v${REMOTE_VERSION} (${URL_FLAVOR})"
echo "install.sh を確認してから手動で更新してください。"
echo "推奨: bash install.sh --update"
if [ "$URL_FLAVOR" = "releases-latest" ] || [ "$URL_FLAVOR" = "gist" ]; then
  echo "推奨 (verification): bash install.sh --verify-checksum --remote"
fi
