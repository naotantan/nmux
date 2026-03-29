# Feature A: スキル自動判別・学習機能 設計書

**作成日**: 2026-03-30
**対象スクリプト**: `~/.nmux/bin/nmux-converse`
**ステータス**: 設計承認済み

---

## 概要

nmux-converse の各ターンで、AIへ送るメッセージ内容をキーワード分析し、
対応する Claude Code スキル（`~/.claude/skills/`）を自動検出・表示する機能。
スキルが存在しない場合は選択式ダイアログで作成を促し、ユーザの操作を最小化する。

---

## アーキテクチャ

```
_run_loop
  └─ 各ターン、AIへ送信前 → _skill_detect(message)
       ├─ ~/.nmux/skill-map.json 読み込み（キャッシュ）
       ├─ キーワードマッチング（メッセージ内容 × mappings）
       ├─ スキル存在確認（~/.claude/skills/<skill_path>/）
       │   ├─ 存在する → [skill: <name> ✓] 表示（緑）
       │   └─ 存在しない → _prompt_create_skill() へ
       └─ 未検出 → [skill: ? 汎用モード] 表示（黄）
```

---

## データ構造

### `~/.nmux/skill-map.json`

```json
{
  "version": "1.0",
  "mappings": {
    "brainstorming": {
      "keywords": ["設計", "アーキテクチャ", "提案", "アイデア", "ブレスト", "どう思う"],
      "skill_path": "brainstorming"
    },
    "writing-plans": {
      "keywords": ["実装計画", "タスク分解", "ステップ", "手順", "計画"],
      "skill_path": "writing-plans"
    },
    "code-reviewer": {
      "keywords": ["レビュー", "コード確認", "品質", "バグ", "チェック"],
      "skill_path": "code-reviewer"
    },
    "research": {
      "keywords": ["調査", "調べて", "比較", "リサーチ", "市場"],
      "skill_path": "research"
    },
    "weekly-report": {
      "keywords": ["週次", "週報", "サマリー", "振り返り", "週まとめ"],
      "skill_path": "weekly-report"
    }
  },
  "skip": []
}
```

- `skip` 配列: 「今後表示しない」を選んだスキル名を追記（自動管理）
- インストール時にデフォルト版を配置。ユーザは直接編集不要

---

## リアルタイム表示

各ターン開始時に1行表示：

```
Turn 3/10 — agent-a
[skill: brainstorming ✓]
（エージェントの応答...）
```

| 状態 | 表示 | 色 |
|---|---|---|
| スキル検出・存在確認済み | `[skill: brainstorming ✓]` | 緑 |
| スキル検出・未インストール | `[skill: code-reviewer ✗]` | 赤（→ダイアログへ） |
| キーワード未マッチ | `[skill: ? 汎用モード]` | 黄 |

---

## スキル未存在時のダイアログ（選択式）

```
[skill: code-reviewer ✗]
"code-reviewer" スキルが見つかりません。どうしますか？

  1) 最小テンプレートを自動生成して使う（推奨）
  2) このセッションはスキルなしで続ける
  3) 今後このキーワードでは表示しない

選択 (1-3, デフォルト=1):
```

- Enter のみ入力 → 選択肢1が実行される
- 選択肢3 → `skill-map.json` の `skip` 配列に追記

---

## スキルテンプレート生成（選択肢1選択時のみ）

```
スキルのベースを選んでください:

  1) 汎用アシスタント（コーディング・相談・分析に適用）
  2) コードレビュー特化（品質・セキュリティ・テスト重視）
  3) 設計・ブレスト特化（アーキテクチャ・提案・議論重視）

選択 (1-3):
```

選択後、`~/.claude/skills/<skill_name>/` に最小構成を生成：

```
~/.claude/skills/code-reviewer/
└── code-reviewer.md     ← スキル本体（テンプレートから生成）
```

生成後、`skill-map.json` に当該スキルのエントリを確定として記録。

---

## 学習フロー

| ユーザ操作 | skill-map.json への反映 |
|---|---|
| 選択肢1でスキル生成 | マッピングを永続化（既存なら上書きなし） |
| 選択肢3で非表示 | `skip` 配列に追記 |
| 同セッション中の再確認 | スキップ（同セッション内フラグで管理） |

---

## 管理コマンド

```bash
nmux-converse skill-map          # 現在のマッピング一覧を表示
```

出力例：
```
SKILL            KEYWORDS                        INSTALLED
brainstorming    設計, アーキテクチャ, 提案...   ✓
code-reviewer    レビュー, バグ, チェック...      ✗
writing-plans    実装計画, タスク分解...          ✓
```

---

## エラーハンドリング

| エラー | 対応 |
|---|---|
| skill-map.json が破損 | デフォルト設定で動作継続、ワーニング表示 |
| ~/.claude/skills/ が存在しない | ディレクトリ自動作成 |
| スキルテンプレート生成失敗 | エラー表示、汎用モードで続行 |

---

## 実装対象ファイル

- `scripts/nmux-converse` — `_skill_detect`, `_prompt_create_skill`, `_generate_skill_template`, `cmd_skill_map` 関数を追加
- `install.sh` — `~/.nmux/skill-map.json` のデフォルト配置処理を追加
- `scripts/skill-map.json` — デフォルトマッピングファイル（新規追加）

---

## 成功基準

- [ ] キーワードマッチ時にリアルタイムで色付きラベルが表示される
- [ ] スキル未存在時に選択式ダイアログが表示される
- [ ] Enter のみでデフォルト選択（1）が実行される
- [ ] 選択肢3で以後そのスキルの通知が出なくなる
- [ ] `nmux-converse skill-map` でマッピング一覧が確認できる
- [ ] 生成されたスキルが次ターンから `✓` 表示になる
