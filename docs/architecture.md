# SAGE アーキテクチャ概要

## 5層構造

SAGEは5つのレイヤで構成される。

### Layer 1: Philosophy（哲学層）
仕様中心主義を担う。「何を作るか」「成功とは何か」「何を守るべきか」を定義する。

**成果物**: `sage/charter.md`

### Layer 2: Governance（ガバナンス層）
AI開発の原則、ルール、禁止事項、レビュー責務、セキュリティ境界、トレーサビリティを担う。

**成果物**: `CLAUDE.md`, `sage/governance.md`, `sage/quality-gates.md`, `sage/anti-patterns.md`

### Layer 3: Runtime（ランタイム層）
エージェントがどの順で何を実行するかを担う。マルチエージェント分業と実行フローを定義する。

**成果物**: `.claude/prompts/`, `.sage/config.yaml`, `.sage/runs/`

### Layer 4: Codebase（コードベース層）
AIが触る対象そのものの構造を定義する。API契約、レイヤ、型、DBアクセス経路、生成コード分離が含まれる。

**成果物**: `src/`, `docs/rules.md`

### Layer 5: Tooling（ツーリング層）
どの種類のツールが必要かを定義し、具体製品は後から差し込めるようにする。

**成果物**: `.github/workflows/`, `scripts/`

## ライフサイクル

```
Specify → Plan → Slice → Execute → Verify → Merge → Observe
    ↑                                                   |
    └───────────── Learning Feedback ───────────────────┘
```

7段階の詳細は `sage/governance.md` を参照。

## エージェント体系

8種のエージェント（最小4種）が SDLC を分業する。詳細は `sage/governance.md` §3 を参照。
