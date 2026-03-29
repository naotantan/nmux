# nmux v2.0.0

**smux の強化フォーク** — tmux 上で複数の AI エージェントを連携・会話・並列実行するオーケストレーションツール

[English](README.en.md) | [中文](README.zh.md)

---

## 概要

nmux は tmux ペインで動く AI エージェント（Claude Code など）を制御するツールです。
1台のマシンで複数エージェントを並べたり、SSH 経由で別マシンのエージェントを操作したり、エージェント同士にリアルタイムで会話させることができます。

```
┌─────────────────────────────────────────────────────┐
│  nmux エコシステム                                    │
│                                                     │
│  nmux-bridge  ←→  ローカルペイン通信（基盤）          │
│  nmux-remote  ←→  SSH クロスマシン通信               │
│  nmux-converse ─→  AI-to-AI リアルタイム会話         │
│  nmux-dispatch ─→  JSON タスク並列分散実行            │
│  nmux-api     ←→  HTTP REST API（外部ツール連携）     │
│  nmux-tui      ─→  TUI ダッシュボード（監視）         │
│  nmux-heartbeat ─→ サブ機死活監視                    │
└─────────────────────────────────────────────────────┘
```

### 対応環境

| メイン機 | サブ機 |
|---------|--------|
| macOS   | macOS  |
| macOS   | Ubuntu |
| Ubuntu  | macOS  |
| Ubuntu  | Ubuntu |

---

## インストール

```bash
curl -fsSL https://raw.githubusercontent.com/naotantan/nmux/main/install.sh | bash
```

インストール時にモードを選択します：

```
1) スタンドアロン  — このマシン単体で使う
2) クロスマシン    — メイン機 ＋ サブ機（SSH接続）
```

Python 3.6+ がある場合、nmux-dispatch / nmux-api / nmux-tui / nmux-converse も自動インストールされます。

---

## クイックスタート（5分）

### Step 1: tmux でペインを開いてラベルを付ける

```bash
# tmux 内でペインを分割して各AIにラベルを付ける
nmux-bridge name nmux:1.1 agent-a
nmux-bridge name nmux:1.2 agent-b

# ラベル一覧を確認
nmux-bridge list
```

### Step 2: AI-B にメッセージを送る

```bash
nmux-bridge type agent-b "こんにちは、テストメッセージです"
nmux-bridge keys agent-b Enter
nmux-bridge read agent-b 20
```

### Step 3: 2エージェントを会話させる

```bash
nmux-converse agent-a agent-b "AIの未来について議論して"
```

---

## 主な機能

| 機能 | コマンド | 説明 |
|------|---------|------|
| ローカルペイン通信 | `nmux-bridge` | tmux ペインへの入出力制御（全機能の基盤） |
| クロスマシン通信 | `nmux-remote` | SSH 経由でサブ機のペインを遠隔操作 |
| AI-to-AI 会話 | `nmux-converse` | エージェント同士のリアルタイム会話・スキル自動判別 |
| タスク並列分散 | `nmux-dispatch` | JSON 定義で依存関係を解決しながら並列実行 |
| REST API | `nmux api` | HTTP 経由で外部ツール（n8n/GitHub Actions等）と連携 |
| TUI 監視 | `nmux tui` | 全ペインのリアルタイム状態ダッシュボード |
| 死活監視 | `nmux heartbeat` | サブ機の生存確認（1秒間隔・ステータスバー表示） |
| バージョン管理 | `nmux update / rollback` | 最新版への更新・前バージョンへの復元 |

---

## nmux CLI

```
nmux install                     # インストール（モード選択あり）
nmux update                      # 最新版に更新
nmux rollback                    # 前の設定に戻す
nmux uninstall                   # 完全削除
nmux status                      # 状態確認
nmux heartbeat start/stop/status # 死活監視の管理
nmux api start/stop/status       # REST API サーバー管理
nmux tui                         # TUI ダッシュボード起動
nmux converse [opts]             # AI-to-AI リアルタイム会話
nmux log [N]                     # ログ表示（デフォルト: 最新100行）
nmux version                     # バージョン確認
```

---

## エージェント構成

### 同一マシン（台数制限なし）

```bash
# tmux ペインを開いた数だけエージェントを登録できる
nmux-bridge name nmux:1.1 agent-a
nmux-bridge name nmux:1.2 agent-b
nmux-bridge name nmux:1.3 agent-c

nmux-bridge list   # 登録済みエージェント一覧
```

### 複数マシン（SSH 経由）

```bash
# ~/.ssh/config に Host エイリアスを登録しておくと便利
# Host sub1  HostName 192.168.1.101
# Host sub2  HostName 192.168.1.102

# サブ機のエージェント一覧を確認
ssh sub1 "~/.nmux/bin/nmux-bridge list"

# サブ機のエージェントにメッセージを送る
ssh sub1 "~/.nmux/bin/nmux-bridge type agent-c 'タスクを実行してください'"
ssh sub1 "~/.nmux/bin/nmux-bridge keys agent-c Enter"
```

`nmux-remote` コマンドを使うと `~/.nmux/nmux.conf` の `REMOTE_HOST` に設定した1台をより簡単に操作できます。

### AI-A が AI-B に指示を出す（基本パターン）

```bash
# 1. Read Guard を取得（前の出力との区切り）
nmux-bridge read agent-b 20

# 2. テキストを送信
nmux-bridge type agent-b "次のタスクを実行してください: ..."
nmux-bridge keys agent-b Enter

# 3. 完了まで待機（プロンプト $ が出るまで最大60秒）
nmux-bridge wait agent-b '\$' 60

# 4. 結果を読む
nmux-bridge read agent-b 50
```

---

## nmux-bridge（ローカルペイン通信）

全機能の基盤。tmux ペインへの入力・出力・待機を制御します。

```
nmux-bridge list [--json]                              # ペイン一覧（--json で JSON 出力）
nmux-bridge read  <target> [lines]                     # ペイン内容を読む
nmux-bridge type  <target> <text>                      # テキスト入力（Enter なし）
nmux-bridge keys  <target> <key>...                    # 特殊キー送信（Enter, Tab, Escape など）
nmux-bridge message <target> <text>                    # 送信元情報付きメッセージ
nmux-bridge name  <target> <label>                     # ペインにラベルを付ける
nmux-bridge wait  <target> [pattern] [timeout] [--then <cmd>]  # パターン待機・検出後コマンド実行
```

**環境変数:**

| 変数 | デフォルト | 説明 |
|-----|----------|------|
| `NMUX_READ_MARK_TTL` | 60 | Read Guard の有効期限（秒） |
| `NMUX_DEBUG` | 0 | `1` にするとデバッグログを出力 |

---

## nmux-converse（AI-to-AI リアルタイム会話）

tmux ペインで動く AI エージェント同士をリアルタイムで対話させます。
ラウンドロビン方式で各エージェントへメッセージを送り、応答を次の入力として渡します。

### 基本の使い方

```bash
# シンプル起動（2エージェント・10ターン）
nmux-converse agent-a agent-b "AIの未来について議論して"

# セッション名・ターン数を指定
nmux-converse start -n debate -t 20 agent-a agent-b -m "量子コンピュータの課題"

# バックグラウンドで実行
nmux-converse start --daemon -n bg agent-a agent-b -m "コードレビューして"
tail -f ~/.nmux/state/converse/bg.log
```

### リモートエージェントとの会話

```bash
# サブ機のエージェントを含む会話
nmux-converse agent-a sub1/agent-b "設計を議論して"

# ユーザー・ポート指定
nmux-converse agent-a user@sub1:2222/agent-b "議論して"
```

エージェントの書式: `[user@]host[:port]/label`

### エージェントの動的追加・削除

会話を止めずにエージェントを追加・削除できます。次のターンから即反映されます。

```bash
nmux-converse add    debate agent-c   # 追加（次ターンから参加）
nmux-converse remove debate agent-b   # 削除（最低2名必須）
```

### スキル自動判別（Feature A）

会話メッセージをリアルタイムに分析し、適切なスキルを自動検出・表示します。

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[Turn 3/10]  → agent-b
[skill: code-reviewer ✓]
▶ コードをレビューして
```

スキルが未インストールの場合はダイアログが表示されます：

```
"code-reviewer" スキルが見つかりません。どうしますか？

  1) 最小テンプレートを自動生成して使う（推奨）
  2) このセッションはスキルなしで続ける
  3) 今後このキーワードでは表示しない

選択 (1-3, デフォルト=1):
```

**スキルマッピングの確認と編集:**

```bash
# 現在のマッピング一覧を表示
nmux-converse skill-map
```

```
SKILL                KEYWORDS                               INSTALLED
--------------------------------------------------------------------
brainstorming        設計, アーキテクチャ, 提案...          ✓
writing-plans        実装計画, タスク分解, ステップ...       ✓
code-reviewer        レビュー, コード確認, 品質...           ✗
research             調査, 調べて, 比較...                  ✓
weekly-report        週次, 週報, サマリー...                 ✗
```

`~/.nmux/skill-map.json` を編集してキーワードを追加・変更できます：

```json
{
  "version": "1.0",
  "mappings": {
    "my-skill": {
      "keywords": ["カスタムキーワード", "custom keyword"],
      "skill_path": "my-skill"
    }
  },
  "skip": []
}
```

`skip` 配列にスキル名を追加すると、そのスキルの検出通知を無効化できます。

### エージェント自動増設（Feature B）

タイムアウト・失敗・応答負荷を監視し、スコアが閾値（5点）を超えると増設を提案します。

**スコアリングロジック:**

| 条件 | 加点 |
|------|------|
| タイムアウト発生 | +3 |
| 応答失敗 | +2 |
| 応答長の最大/最小比 > 3（負荷不均衡） | +1 |
| ターン節目（50% / 75%） | +1 |

スコア ≥ 5 で増設ダイアログを表示：

```
[自動増設の提案]
現在の会話負荷が高まっています。
AIの推奨追加数: 2名

何名追加しますか？ (0でキャンセル): 2
最大何名まで許可しますか？ (現在の上限: 未設定): 5
```

承認すると tmux ペインを自動作成してセッションに追加します。ラベルは `agent-c`, `agent-d`, `agent-e`... と自動採番されます。

### セッション管理

```bash
nmux-converse list              # 全セッション一覧（● = 稼働中）
nmux-converse stop  <name>      # セッションを停止
nmux-converse log   <name> 50   # ログの最新50行を表示
nmux-converse skill-map         # スキルマッピング一覧
```

### オプション一覧（start）

| オプション | デフォルト | 説明 |
|-----------|----------|------|
| `-n, --name <name>` | `sess-HHMMSS` | セッション名 |
| `-t, --turns <N>` | 10 | ターン数 |
| `--timeout <sec>` | 120 | 応答タイムアウト秒 |
| `--lines <N>` | 80 | 応答読み取り行数 |
| `--prompt <pattern>` | `[$%#>❯]` | プロンプト検出パターン |
| `--interval <sec>` | 1 | ターン間の待機秒 |
| `--ssh-port <port>` | 22 | デフォルト SSH ポート |
| `--daemon` | — | バックグラウンド実行 |
| `-m, --message <text>` | — | 初期トピック（必須） |

---

## nmux-dispatch（JSON タスク並列分散）

Python 3.6+ が必要。依存関係を自動解決しながら複数エージェントへタスクを並列分散します。

```bash
nmux-dispatch tasks.json            # 実行
nmux-dispatch tasks.json --dry-run  # 実行計画のみ確認（実行しない）
```

**タスク定義例（`tasks.json`）:**

```json
{
  "defaults": { "timeout": 120, "on_failure": "abort" },
  "tasks": [
    { "id": "plan",  "agent": "agent-a", "message": "設計してください" },
    { "id": "impl",  "agent": "agent-b", "message": "実装してください", "depends_on": ["plan"] },
    { "id": "test",  "agent": "agent-c", "message": "テストしてください", "depends_on": ["impl"] }
  ]
}
```

依存関係はトポロジカルソートで自動解決され、依存のないタスクは並列実行されます。

---

## nmux-api（HTTP REST API）

Python 3.6+ が必要。n8n・GitHub Actions・スクリプト等から nmux を HTTP で操作できます。

```bash
nmux api start    # バックグラウンドで起動
nmux api stop     # 停止
nmux api status   # 状態確認（URL・PID・トークン設定）
```

**エンドポイント一覧:**

| メソッド | パス | 説明 |
|---------|------|------|
| GET  | `/status` | nmux 全体の状態 |
| GET  | `/panes` | 全ペイン一覧（JSON） |
| GET  | `/panes/{target}/read?lines=N` | ペイン内容取得 |
| POST | `/panes/{target}/type` | テキスト入力 |
| POST | `/panes/{target}/message` | メッセージ送信 |
| POST | `/panes/{target}/wait` | パターン待機 |
| POST | `/dispatch` | タスク分散実行 |

**設定（`~/.nmux/nmux.conf`）:**

```bash
NMUX_API_HOST=127.0.0.1   # 外部公開時は 0.0.0.0（要トークン設定）
NMUX_API_PORT=8765
NMUX_API_TOKEN=            # Bearer トークン（空の場合は認証なし）
NMUX_API_MODE=integrated   # integrated（tmux連動）/ daemon（常駐）
```

---

## nmux-tui（TUI ダッシュボード）

Python 3.6+ が必要。tmux 内の全ペイン状態をリアルタイムで確認・操作できます。

```bash
nmux tui        # TUI 起動
# または tmux 内で prefix + T
```

**キーバインド:**

| キー | 動作 |
|-----|------|
| `q` | 終了 |
| `r` | 手動更新 |
| `↑` / `↓` | ペイン選択 |
| `Enter` | 選択ペインにフォーカス移動 |
| `d` | dispatch ファイルを指定して実行 |

更新間隔: ≤20 ペインで 1 秒、>20 ペインで 3 秒
`NMUX_TUI_INTERVAL=<秒>` で手動設定可。

---

## ハートビート（サブ機死活監視）

クロスマシンモードのみ。tmux 起動時に自動起動し、サブ機を 1 秒間隔で監視します。

```bash
nmux heartbeat start   # 手動起動
nmux heartbeat stop    # 停止
nmux heartbeat status  # 状態確認
```

**ステータスバー表示:**

```
# サブ機が正常
1:bash  2:claude     ● 192.168.1.100 | main

# サブ機ダウン
1:bash  2:claude     ✗ 192.168.1.100 OFFLINE | main
```

---

## 設定ファイルリファレンス（`~/.nmux/nmux.conf`）

| 変数 | デフォルト | 説明 |
|-----|----------|------|
| `REMOTE_HOST` | — | サブ機のホスト名または IP |
| `REMOTE_USER` | `$(whoami)` | SSH ユーザー名 |
| `REMOTE_PORT` | 22 | SSH ポート |
| `NMUX_API_HOST` | `127.0.0.1` | API サーバーのバインドアドレス |
| `NMUX_API_PORT` | 8765 | API サーバーのポート |
| `NMUX_API_TOKEN` | — | Bearer 認証トークン |
| `NMUX_API_MODE` | `integrated` | `integrated` / `daemon` |
| `NMUX_TUI_INTERVAL` | 自動 | TUI 更新間隔（秒） |
| `NMUX_READ_MARK_TTL` | 60 | Read Guard 有効期限（秒） |

---

## トラブルシューティング

**ログの確認:**

```bash
# nmux 全体のログ
ls ~/.nmux/logs/

# converse セッションのログ
ls ~/.nmux/state/converse/*.log

# デバッグモードで実行（SSH 通信エラーの詳細を表示）
NMUX_DEBUG=1 nmux-converse agent-a agent-b "テスト"
```

**よくある問題:**

| 症状 | 原因 | 対処 |
|------|------|------|
| `agent not found` | ラベル未登録 | `nmux-bridge name <pane-id> <label>` で登録 |
| SSH 接続失敗 | `~/.ssh/config` の設定不足 | `Host sub1` エントリと `IdentityFile` を確認 |
| タイムアウト多発 | AI の応答が遅い | `--timeout` を延長 or `--turns` を減らす |
| TUI が起動しない | Python 3.6+ 未インストール | `python3 --version` で確認し、インストール |
| `skill-map.json` が見つからない | インストールが古い | `nmux update` で最新版に更新 |

---

## ライセンス

MIT — Original smux by ShawnPana (https://github.com/ShawnPana/smux)
