# nmux v2.0.0

**smux の強化フォーク** — macOS / Ubuntu 対応・マルチ AI エージェント tmux セットアップ

## 対応構成

| メイン機 | サブ機 |
|---|---|
| macOS | macOS |
| macOS | Ubuntu |
| Ubuntu | macOS |
| Ubuntu | Ubuntu |

## インストール
```bash
curl -fsSL https://raw.githubusercontent.com/naotantan/nmux/main/install.sh | bash
```

インストール時にモードを選択できます：
```
1) スタンドアロン  — このマシン単体
2) クロスマシン    — メイン機 ＋ サブ機（SSH接続）
```

Python 3.6+ がある場合、nmux-dispatch / nmux-api / nmux-tui も自動インストールされます。

## 主な機能

| 機能 | コマンド |
|---|---|
| ローカルペイン通信 | `nmux-bridge` |
| クロスマシン通信（SSH） | `nmux-remote` |
| AI-to-AI リアルタイム会話 | `nmux-converse` |
| JSON タスク分散実行 | `nmux-dispatch` |
| HTTP REST API サーバー | `nmux api start/stop/status` |
| TUI ダッシュボード | `nmux tui` / prefix+T |
| サブ機死活監視（1秒間隔） | `nmux heartbeat start/stop/status` |
| ステータスバーに死活表示 | 自動（tmux起動時） |
| バージョン管理・ロールバック | `nmux update` / `nmux rollback` |
| 完全アンインストール | `nmux uninstall` |

## nmux CLI

```
nmux install                    # インストール（モード選択あり）
nmux update                     # 最新版に更新
nmux rollback                   # 前の設定に戻す
nmux uninstall                  # 完全削除
nmux status                     # 状態確認
nmux heartbeat start/stop/status
nmux api start/stop/status      # REST API サーバー管理
nmux tui                        # TUI ダッシュボード起動
nmux converse [opts]            # AI-to-AI リアルタイム会話
nmux log [N]                    # ログ表示
nmux version
```

## エージェント構成

### 同一マシン（台数制限なし）

tmux ペインを開いた数だけ AI エージェントを並べられます。

```bash
# 各ペインにラベルを付ける
nmux-bridge name nmux:1.1 agent-a
nmux-bridge name nmux:1.2 agent-b
nmux-bridge name nmux:1.3 agent-c

# 全エージェントを一覧表示
nmux-bridge list
```

### 複数マシン（台数制限なし）

`nmux-remote` は `~/.nmux/nmux.conf` の `REMOTE_HOST` で1台のみ管理します。
2台目以降は SSH 直呼びで操作できます（追加設定不要）。

```bash
# ~/.ssh/config に登録しておくと便利
# Host sub1 → 192.168.1.101
# Host sub2 → 192.168.1.102

ssh sub1 "~/.nmux/bin/nmux-bridge list"
ssh sub2 "~/.nmux/bin/nmux-bridge list"
```

### AI-A が AI-B に指示を出す（基本パターン）

```bash
# 1. AI-B のペイン出力を読む（Read Guard を取得）
nmux-bridge read agent-b 20

# 2. AI-B にテキストを送信
nmux-bridge type agent-b "次のタスクを実行してください: ..."

# 3. Enter を送って実行
nmux-bridge keys agent-b Enter

# 4. AI-B の完了を待つ（プロンプト $ が出るまで最大60秒）
nmux-bridge wait agent-b '\$' 60

# 5. 結果を読む
nmux-bridge read agent-b 50
```

別マシンの AI-C への指示も同じ流れで SSH 経由で実行できます。

```bash
ssh sub1 "~/.nmux/bin/nmux-bridge read agent-c 20"
ssh sub1 "~/.nmux/bin/nmux-bridge type agent-c 'タスクを実行してください'"
ssh sub1 "~/.nmux/bin/nmux-bridge keys agent-c Enter"
```

### nmux-dispatch で複数エージェントに並列分散

依存関係を定義すると、自動で順序を解決して並列実行します。

```json
{
  "tasks": [
    { "id": "plan",  "agent": "agent-a", "message": "設計してください" },
    { "id": "impl",  "agent": "agent-b", "message": "実装してください", "depends_on": ["plan"] },
    { "id": "test",  "agent": "agent-c", "message": "テストしてください", "depends_on": ["impl"] }
  ]
}
```

```bash
nmux-dispatch tasks.json
```

---

## nmux-converse（AI-to-AI リアルタイム会話）

tmux ペインで動く AI エージェント同士をリアルタイムで対話させます。
ラウンドロビン方式で各エージェントへメッセージを送り、応答を次の入力として渡します。

### 基本の使い方

```bash
# ローカル 2 エージェントで会話開始（最もシンプル）
nmux-converse agent-a agent-b "AIの未来について議論して"

# セッション名・ターン数を指定
nmux-converse start -n debate -t 20 agent-a agent-b -m "量子コンピュータの課題"

# バックグラウンドで実行してログを監視
nmux-converse start --daemon -n bg agent-a agent-b -m "コードレビューして"
tail -f ~/.nmux/state/converse/bg.log
```

### リモートエージェントの追加

```bash
# サブ機のエージェントを含む会話
nmux-converse agent-a sub1/agent-b "設計を議論して"

# ユーザー・ポート指定あり
nmux-converse agent-a user@sub1:2222/agent-b "議論して"
```

SSH ポートはエージェント書式 `host:port/label` で個別指定、または `--ssh-port` でセッション全体に適用します。

### エージェントの動的追加・削除

会話を止めずにエージェントを追加・削除できます。次のターンから即座に反映されます。

```bash
# 実行中セッションにエージェントを追加
nmux-converse add debate agent-c

# エージェントを削除（最低2名必須）
nmux-converse remove debate agent-b
```

### スキル自動判別（Feature A）

会話メッセージをリアルタイムに分析し、適切なスキルを自動検出・表示します。

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[Turn 3/10]  → agent-b
[skill: code-reviewer ✓]       ← 検出されたスキルを表示
▶ コードをレビューして
```

スキルが未インストールの場合はダイアログが表示され、テンプレートを自動生成できます。

```bash
# スキルマッピング一覧を確認
nmux-converse skill-map
```

```
SKILL                KEYWORDS                               INSTALLED
--------------------------------------------------------------------
brainstorming        設計, アーキテクチャ, 提案...          ✓
code-reviewer        レビュー, コード確認, 品質...           ✗
research             調査, 調べて, 比較...                  ✓
```

マッピングは `~/.nmux/skill-map.json` で自由に編集できます。

### エージェント自動増設（Feature B）

タイムアウトや応答負荷を監視し、増設が必要と判断した場合に提案ダイアログを表示します。

```
[自動増設の提案]
現在の会話負荷が高まっています。
AIの推奨追加数: 2名

何名追加しますか？ (0でキャンセル):
```

承認すると tmux ペインを自動作成してセッションに追加します。

### セッション管理

```bash
nmux-converse list              # 全セッション一覧（● = 稼働中）
nmux-converse stop debate       # セッションを停止
nmux-converse log debate 50     # ログの最新50行を表示
nmux-converse skill-map         # スキルマッピング一覧
```

### コマンドリファレンス

```
nmux-converse <agent1> <agent2> "<topic>"                    # シンプル起動
nmux-converse start [opts] <agent1> <agent2> -m "<topic>"   # 詳細起動

オプション（start）:
  -n, --name <name>      セッション名（デフォルト: sess-HHMMSS）
  -t, --turns <N>        ターン数（デフォルト: 10）
  --timeout <sec>        応答タイムアウト秒（デフォルト: 120）
  --lines <N>            応答読み取り行数（デフォルト: 80）
  --prompt <pattern>     プロンプト検出パターン（デフォルト: [$%#>❯]）
  --interval <sec>       ターン間の待機秒（デフォルト: 1）
  --ssh-port <port>      デフォルト SSH ポート（デフォルト: 22）
  --daemon               バックグラウンドで実行
  -m, --message <text>   初期トピック
```

エージェントを事前に `nmux-bridge name` でラベル登録しておく必要があります。

```bash
nmux-bridge name nmux:1.1 agent-a
nmux-bridge name nmux:1.2 agent-b
```

---

## nmux-bridge（ローカルペイン通信）

```
nmux-bridge list [--json]                          # ペイン一覧（--json で JSON 出力）
nmux-bridge read <target> [lines]                  # ペイン内容を読む
nmux-bridge type <target> <text>                   # テキスト入力（Enter なし）
nmux-bridge keys <target> <key>...                 # 特殊キー送信
nmux-bridge message <target> <text>                # 送信元情報付きメッセージ
nmux-bridge name <target> <label>                  # ラベルを付ける
nmux-bridge wait <target> [pattern] [timeout] [--then <cmd>]  # パターン待機・検出後コマンド実行
```

環境変数:
- `NMUX_READ_MARK_TTL=<秒>` — Read Guard の有効期限（デフォルト: 60）

## nmux-remote（クロスマシン・SSH）

```
nmux-remote setup
nmux-remote ping
nmux-remote list
nmux-remote read <target> [lines]
nmux-remote type <target> <text>
nmux-remote keys <target> <key>...
nmux-remote message <target> <text>
nmux-remote wait <target> [pattern] [timeout]
```

## nmux-dispatch（JSON タスク分散実行）

Python 3.6+ が必要。依存関係を解決しながら複数エージェントへタスクを並列分散します。

```bash
nmux-dispatch tasks.json
nmux-dispatch tasks.json --dry-run   # 実行計画のみ確認
```

タスク定義例（`tasks.json`）:
```json
{
  "defaults": { "timeout": 120, "on_failure": "abort" },
  "tasks": [
    { "id": "setup", "agent": "claude",  "message": "環境を準備して" },
    { "id": "impl",  "agent": "claude",  "message": "実装して", "depends_on": ["setup"] },
    { "id": "test",  "agent": "tester",  "message": "テストして", "depends_on": ["impl"] }
  ]
}
```

## nmux-api（HTTP REST API）

Python 3.6+ が必要。外部ツール（n8n / GitHub Actions 等）から nmux を HTTP で操作できます。

```bash
nmux api start    # バックグラウンドで起動（daemon モード）
nmux api stop     # 停止
nmux api status   # 状態確認
```

エンドポイント:

| メソッド | パス | 説明 |
|---------|------|------|
| GET | `/status` | nmux 全体状態 |
| GET | `/panes` | ペイン一覧（JSON） |
| GET | `/panes/{target}/read?lines=N` | ペイン内容取得 |
| POST | `/panes/{target}/type` | テキスト入力 |
| POST | `/panes/{target}/message` | メッセージ送信 |
| POST | `/panes/{target}/wait` | パターン待機 |
| POST | `/dispatch` | タスク分散実行 |

設定（`~/.nmux/nmux.conf`）:
```bash
NMUX_API_HOST=127.0.0.1   # 外部公開時は 0.0.0.0（要トークン設定）
NMUX_API_PORT=8765
NMUX_API_TOKEN=            # Bearer トークン（空の場合は認証なし）
NMUX_API_MODE=integrated   # integrated（tmux連動）/ daemon（常駐）
```

## nmux-tui（TUI ダッシュボード）

Python 3.6+ が必要。tmux の全ペイン状態をリアルタイムで確認できます。

```bash
nmux tui          # TUI 起動
# または tmux 内で: prefix + T
```

キーバインド:

| キー | 動作 |
|-----|------|
| `q` | 終了 |
| `r` | 手動更新 |
| `↑` / `↓` | ペイン選択 |
| `Enter` | 選択ペインにフォーカス移動 |
| `d` | dispatch ファイルを指定して実行 |

更新間隔: ≤20 ペインで 1 秒、>20 ペインで 3 秒（`NMUX_TUI_INTERVAL` で手動設定可）。

## ハートビート

tmux 起動時に自動起動（クロスマシンモードのみ）。

サブ機が正常な場合：

    1:bash  2:claude     ● 192.168.1.100 | main

サブ機ダウン時：

    1:bash  2:claude     ✗ 192.168.1.100 OFFLINE | main

## ライセンス

MIT — Original smux by ShawnPana (https://github.com/ShawnPana/smux)
