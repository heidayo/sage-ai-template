# SAGE テンプレート管理者ガイド

このドキュメントは **SAGE テンプレートリポジトリの管理者** 向けです。
SAGEを利用するプロジェクト開発者は [README.md](../README.md) を参照してください。

---

## Gist の設定

### 初回セットアップ

```bash
# 1. GitHub CLI 認証
gh auth login

# 2. install.sh を生成 & Gist 作成
bash scripts/generate-installer.sh > install.sh
gh gist create install.sh --desc "SAGE Development System Installer"

# 3. Gist ID を保存
echo "YOUR_GIST_ID" > .sage/gist-id
```

### 更新（ワンコマンド）

```bash
bash scripts/sage-publish.sh 0.3.0
```

```
=========================================
  SAGE Publish: v0.2.0 → v0.3.0
=========================================
[1/3] バージョン更新...     OK
[2/3] install.sh 再生成...  OK
[3/3] Gist 更新...          OK
=========================================
各プロジェクトは次回セッション開始時に自動更新されます。
```

---

## 管理者コマンド

```bash
# install.sh を再生成
bash scripts/generate-installer.sh > install.sh

# バージョン更新 + Gist公開
bash scripts/sage-publish.sh 0.3.0

# テンプレートの構造検証
bash scripts/sage-validate.sh
```

---

## リリースフロー

1. テンプレートの変更を行う
2. `bash scripts/sage-validate.sh` で検証
3. `.sage-version` のバージョンを更新
4. `bash scripts/sage-publish.sh X.Y.Z` で公開
5. 各プロジェクトは次回セッション開始時に自動更新される
