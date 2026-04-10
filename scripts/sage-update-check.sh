#!/bin/bash
# sage-update-check.sh — 1日1回、Gist から最新バージョンを確認して更新通知する
# エラーが発生しても開発を止めない（警告のみ）

SAGE_DIR=".sage"
VERSION_FILE="$SAGE_DIR/version"
LAST_CHECK_FILE="$SAGE_DIR/last-update-check"
CONFIG_FILE="$SAGE_DIR/config.yaml"

# installer_url 未設定チェック（AC-4）
if [ ! -f "$CONFIG_FILE" ]; then
  echo "SAGE: config.yaml が見つかりません。バージョンチェックをスキップします。"
  exit 0
fi

GIST_URL=$(grep 'installer_url:' "$CONFIG_FILE" 2>/dev/null | awk '{print $2}' | tr -d '"')

if [ -z "$GIST_URL" ] || echo "$GIST_URL" | grep -qF "YOUR_USER/GIST_ID"; then
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

# 最新バージョンを取得（AC-3: curl失敗時は警告のみ）
REMOTE_VERSION=$(curl -fsSL --connect-timeout 5 "$GIST_URL" 2>/dev/null | grep -m1 'SAGE_VERSION=' | cut -d'"' -f2)

if [ -z "$REMOTE_VERSION" ]; then
  echo "SAGE: 最新バージョンの取得に失敗しました（ネットワークエラーまたはURL無効）。スキップします。"
  date +%Y-%m-%d > "$LAST_CHECK_FILE"
  exit 0
fi

LOCAL_VERSION=$(cat "$VERSION_FILE" 2>/dev/null || echo "0.0.0")

# 今日の日付を記録
date +%Y-%m-%d > "$LAST_CHECK_FILE"

# バージョン比較（AC-2）
if [ "$REMOTE_VERSION" = "$LOCAL_VERSION" ]; then
  echo "SAGE v${LOCAL_VERSION} は最新です。"
  exit 0
fi

# 更新通知（AC-5）
echo "SAGE 更新があります: v${LOCAL_VERSION} → v${REMOTE_VERSION}"
echo "install.sh を確認してから手動で更新してください。"
echo "推奨: bash install.sh --update"
