#!/usr/bin/env bash
# nmux i18n — 日本語 (Japanese)
# このファイルは install.sh から source されます

# ── インストール ──────────────────────────────────────────────
L_INSTALLING_PKG="%s をインストール中 (%s)..."
L_PKG_INSTALL_FAIL="%s のインストールに失敗しました。手動でインストールしてください。"
L_BREW_REQUIRED="macOS では Homebrew が必要です。https://brew.sh からインストールしてください。"
L_CLIPBOARD_INSTALLING="クリップボードツールをインストール中..."
L_CLIPBOARD_FAIL="%s のインストールに失敗しました"
L_TMUX_UNSUPPORTED="tmux %s は未対応です。tmux 3.2+ が必要です。"
L_TMUX_OK="tmux %s — OK"
L_SHA256_SKIP="sha256sum が見つかりません。検証をスキップします。"
L_VERIFY_FAIL="ファイル検証失敗: %s"
L_DOWNLOAD_FAIL="ダウンロード失敗: %s"
L_CURL_WGET_REQUIRED="curl / wget が必要です。どちらかをインストールしてください。"
L_BACKUP="バックアップ: %s"
L_PATH_APPENDING="PATH 設定を %s に追記..."
L_PATH_REMOVED="PATH 設定を %s から削除しました"

# ── モード選択 ────────────────────────────────────────────────
L_SELECT_MODE="インストールモードを選択してください:"
L_MODE_STANDALONE="  1) スタンドアロン  — このマシン単体で AI エージェント間通信"
L_MODE_CROSSMACHINE="  2) クロスマシン    — メイン機 ＋ サブ機（別マシン）で連携"
L_MODE_PROMPT="選択 [1/2] (デフォルト: 1): "
L_MODE_SELECTED="モード: %s"

# ── サブ機接続情報 ────────────────────────────────────────────
L_REMOTE_CONF_HEADER="サブ機の接続情報を入力してください:"
L_REMOTE_HOST_PROMPT="  ホスト名または IP アドレス: "
L_REMOTE_HOST_REQUIRED="ホスト名は必須です。"
L_REMOTE_USER_PROMPT="  SSH ユーザー名 [%s]: "
L_REMOTE_PORT_PROMPT="  SSH ポート [22]: "
L_REMOTE_CONF_INFO="接続情報: %s@%s:%s"
L_SSH_TESTING="SSH 接続テスト中..."
L_SSH_OK="SSH 接続 OK"
L_SSH_FAIL="SSH 接続に失敗しました。設定を確認してください。"
L_SSH_FAIL_HINT="  ~/.ssh/config または ssh-copy-id での鍵配布を確認してください。"
L_SSH_CONTINUE="  続行しますか？ [y/N]: "
L_INSTALL_ABORTED="インストールを中止しました。"
L_INSTALL_SUB_PROMPT="  サブ機にも nmux をインストールしますか？ [Y/n]: "
L_INSTALL_SUB_SKIP="サブ機へのインストールをスキップしました。"
L_INSTALL_SUB_RUNNING="サブ機 (%s) に nmux をインストール中..."
L_INSTALL_SUB_DONE="サブ機へのインストール完了"
L_INSTALL_SUB_FAIL="サブ機へのインストールに失敗しました。手動でインストールしてください。"

# ── コアインストール ──────────────────────────────────────────
L_INSTALLING_TMUX="tmux をインストール中..."
L_DOWNLOADING="%s をダウンロード中..."
L_INSTALLING="%s をインストール中..."
L_SKILL_MAP_PLACED="skill-map.json を配置しました: %s"
L_PYTHON_SKIP="Python 3.6+ が見つかりません。nmux-dispatch / nmux-api / nmux-tui をスキップします。"
L_PYTHON_SKIP_HINT="インストール後に手動で追加する場合: brew install python3 (macOS) または apt-get install python3 (Linux)"
L_SELECT_API_MODE="? nmux-api の動作モードを選択してください:"
L_API_MODE_INTEGRATED="  1) integrated  — tmux セッション連動（推奨・デフォルト）"
L_API_MODE_DAEMON="  2) daemon      — 常駐プロセスとして独立起動"
L_API_MODE_PROMPT="モード [1/2, デフォルト: 1]: "

# ── 完了メッセージ ────────────────────────────────────────────
L_INSTALL_SUB_COMPLETE="nmux v%s (サブ機) インストール完了！"
L_INSTALLER_HEADER="nmux v%s インストーラー (OS: %s)"
L_INSTALL_COMPLETE="nmux v%s インストール完了！"
L_INFO_MODE="  モード:       %s"
L_INFO_DIR="  設定:         %s"
L_INFO_LOG="  ログ:         %s"
L_INFO_REMOTE="  サブ機:       %s@%s:%s"
L_INFO_USAGE="  使い方: nmux help"
L_PATH_RELOAD="シェルを再起動するか以下を実行してください:"

# ── 更新・ロールバック ────────────────────────────────────────
L_UPDATING="nmux を更新中... (現在: v%s)"
L_ALREADY_LATEST="すでに最新バージョン (v%s) です。"
L_UPDATING_TO="v%s → v%s に更新します..."
L_VERSION_CHECK_FAIL="バージョン確認に失敗しました。強制更新します..."
L_UPDATE_COMPLETE="nmux v%s に更新しました！"
L_ROLLBACK_HEADER="利用可能なバックアップ:"
L_NO_BACKUP="バックアップが見つかりません。"
L_ROLLBACK_PROMPT="バックアップ番号を入力してください (1-%d): "
L_ROLLBACK_INVALID="無効な選択: %s"
L_ROLLBACK_DONE="復元完了: %s"

# ── アンインストール ──────────────────────────────────────────
L_UNINSTALLING="nmux をアンインストール中..."
L_SYMLINK_REMOVED="シンボリックリンクを削除"
L_BACKUP_RESTORED="バックアップを復元: %s"
L_DIR_REMOVED="%s を削除しました"
L_UNINSTALL_COMPLETE="nmux をアンインストールしました。"
L_RESTART_SHELL="  シェルを再起動してください。"

# ── ステータス ────────────────────────────────────────────────
L_STATUS_HEADER="nmux ステータス"
L_STATUS_VERSION="  バージョン:      %s"
L_STATUS_OS="  OS:              %s"
L_STATUS_MODE="  モード:          %s"
L_STATUS_TMUX="  tmux:            %s"
L_STATUS_CLIPBOARD="  クリップボード:  %s"
L_STATUS_BRIDGE="  nmux-bridge:     "
L_STATUS_REMOTE="  nmux-remote:     "
L_STATUS_SUB="  サブ機:          %s@%s:%s"
L_STATUS_HEARTBEAT="  ハートビート:    %s"
L_STATUS_API="  nmux-api:        %s"
L_STATUS_LOG="  ログ:            %s"
L_STATUS_RUNNING="稼働中 (PID: %s)"
L_STATUS_STOPPED="停止"
L_STATUS_NOT_INSTALLED="未インストール"
L_STATUS_NOT_SET="未設定"

# ── その他 ────────────────────────────────────────────────────
L_HEARTBEAT_NOT_FOUND="nmux-heartbeat が見つかりません。nmux update を実行してください。"
L_FILE_NOT_FOUND="ファイルが見つかりません: %s"
L_VERIFY_OK="検証成功: %s"
L_LOG_NOT_FOUND="ログファイルが見つかりません: %s"
L_UNKNOWN_CMD="不明なコマンド: %s"
L_UNKNOWN_CMD_HINT="  nmux help で使い方を確認してください。"
L_TMUX_RELOAD_OK="tmux 設定をリロードしました"
L_TMUX_RELOAD_FAIL="tmux リロードに失敗しました（手動: tmux source ~/.nmux/tmux.conf）"

# ── ヘルプ ────────────────────────────────────────────────────
L_HELP=$(cat <<'HELP'

nmux — マルチエージェント tmux セットアップ (macOS / Ubuntu)

使い方: nmux <コマンド> [オプション]

コマンド:
  install              インストール（モード・言語選択あり）
  update               最新バージョンに更新
  rollback             以前の tmux 設定を復元
  uninstall            完全削除（PATH も自動クリーンアップ）
  status               インストール状態を確認
  heartbeat <subcmd>   ハートビート管理 (start/stop/status)
  api [start|stop|status]  REST API サーバー管理（daemon モード用）
  tui                  TUI ダッシュボードを起動
  converse [opts]      AI-to-AI リアルタイム会話
  verify <file> <sha>  ファイルの sha256 を検証
  log [N]              直近 N 行のログを表示
  version              バージョン表示
  help                 このヘルプを表示

環境変数:
  NMUX_DEBUG=1         デバッグログを有効化

ファイル:
  ~/.nmux/nmux.conf        設定ファイル
  ~/.nmux/tmux.conf        tmux 設定
  ~/.nmux/bin/             CLI ツール群
  ~/.nmux/backups/         設定バックアップ
  ~/.nmux/logs/            操作ログ（日別）
  ~/.nmux/state/           状態ファイル
  ~/.nmux/skill-map.json   スキルマッピング

HELP
)
