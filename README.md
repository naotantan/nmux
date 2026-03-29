# nmux v1.1.0

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

## 主な機能

| 機能 | コマンド |
|---|---|
| ローカルペイン通信 | nmux-bridge |
| クロスマシン通信（SSH） | nmux-remote |
| サブ機死活監視（1秒間隔） | nmux heartbeat start/stop/status |
| ステータスバーに死活表示 | 自動（tmux起動時） |
| バージョン管理・ロールバック | nmux update / nmux rollback |
| 完全アンインストール | nmux uninstall |

## nmux CLI

    nmux install      # インストール（モード選択あり）
    nmux update       # 最新版に更新
    nmux rollback     # 前の設定に戻す
    nmux uninstall    # 完全削除
    nmux status       # 状態確認
    nmux heartbeat start/stop/status
    nmux log [N]      # ログ表示
    nmux version

## nmux-bridge（ローカル）

    nmux-bridge list
    nmux-bridge read <target> [lines]
    nmux-bridge type <target> <text>
    nmux-bridge keys <target> <key>...
    nmux-bridge message <target> <text>
    nmux-bridge name <target> <label>
    nmux-bridge wait <target> [pattern] [timeout]

## nmux-remote（クロスマシン）

    nmux-remote setup
    nmux-remote ping
    nmux-remote list
    nmux-remote read <target> [lines]
    nmux-remote type <target> <text>
    nmux-remote keys <target> <key>...
    nmux-remote message <target> <text>
    nmux-remote wait <target> [pattern] [timeout]

## ハートビート

tmux 起動時に自動起動（クロスマシンモードのみ）。

サブ機が正常な場合：

    1:bash  2:claude     ● 192.168.1.100 | main

サブ機ダウン時：

    1:bash  2:claude     ✗ 192.168.1.100 OFFLINE | main

## ライセンス

MIT — Original smux by ShawnPana (https://github.com/ShawnPana/smux)
