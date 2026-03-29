#!/usr/bin/env bash
# nmux — next-generation multi-agent tmux setup
# Supports: macOS / Ubuntu (main & sub machine)
# https://github.com/naotantan/nmux
set -euo pipefail

NMUX_VERSION="2.1.0"
REPO_OWNER="naotantan"
REPO_NAME="nmux"
BRANCH="main"
BASE_URL="https://raw.githubusercontent.com/${REPO_OWNER}/${REPO_NAME}/${BRANCH}"
NMUX_DIR="${HOME}/.nmux"
BIN_DIR="${NMUX_DIR}/bin"
BACKUP_DIR="${NMUX_DIR}/backups"
LOG_DIR="${NMUX_DIR}/logs"
STATE_DIR="${NMUX_DIR}/state"
CONF_FILE="${NMUX_DIR}/nmux.conf"
TMUX_XDG_DIR="${HOME}/.config/tmux"
NMUX_I18N_DIR="${NMUX_DIR}/i18n"

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

# ============================================================
# i18n — Japanese built-in defaults (overridden by language files)
# ============================================================
NMUX_LANG="${NMUX_LANG:-ja}"

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
L_SELECT_MODE="インストールモードを選択してください:"
L_MODE_STANDALONE="  1) スタンドアロン  — このマシン単体で AI エージェント間通信"
L_MODE_CROSSMACHINE="  2) クロスマシン    — メイン機 ＋ サブ機（別マシン）で連携"
L_MODE_PROMPT="選択 [1/2] (デフォルト: 1): "
L_MODE_SELECTED="モード: %s"
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
L_INSTALL_SUB_COMPLETE="nmux v%s (サブ機) インストール完了！"
L_INSTALLER_HEADER="nmux v%s インストーラー (OS: %s)"
L_INSTALL_COMPLETE="nmux v%s インストール完了！"
L_INFO_MODE="  モード:       %s"
L_INFO_DIR="  設定:         %s"
L_INFO_LOG="  ログ:         %s"
L_INFO_REMOTE="  サブ機:       %s@%s:%s"
L_INFO_USAGE="  使い方: nmux help"
L_PATH_RELOAD="シェルを再起動するか以下を実行してください:"
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
L_UNINSTALLING="nmux をアンインストール中..."
L_SYMLINK_REMOVED="シンボリックリンクを削除"
L_BACKUP_RESTORED="バックアップを復元: %s"
L_DIR_REMOVED="%s を削除しました"
L_UNINSTALL_COMPLETE="nmux をアンインストールしました。"
L_RESTART_SHELL="  シェルを再起動してください。"
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
L_HEARTBEAT_NOT_FOUND="nmux-heartbeat が見つかりません。nmux update を実行してください。"
L_FILE_NOT_FOUND="ファイルが見つかりません: %s"
L_VERIFY_OK="検証成功: %s"
L_LOG_NOT_FOUND="ログファイルが見つかりません: %s"
L_UNKNOWN_CMD="不明なコマンド: %s"
L_UNKNOWN_CMD_HINT="  nmux help で使い方を確認してください。"
L_TMUX_RELOAD_OK="tmux 設定をリロードしました"
L_TMUX_RELOAD_FAIL="tmux リロードに失敗しました（手動: tmux source ~/.nmux/tmux.conf）"
L_LOG_LABEL="ログ"
L_HELP=$(cat <<'HELP'

nmux — マルチエージェント tmux セットアップ (macOS / Ubuntu)

使い方: nmux <コマンド> [オプション]

コマンド:
  install              インストール（モード・言語選択あり）
  init                 初回セットアップウィザード（インストール後に実行）
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

# ============================================================
# i18n — 言語ファイルのロード
# ============================================================

# 言語ファイルをキャッシュから、またはGitHubからダウンロードして読み込む
load_language() {
  local lang="${1:-ja}"
  case "${lang}" in ja|en|zh) ;; *) lang="ja" ;; esac

  # キャッシュ済みならそこから読み込む
  local cached="${NMUX_I18N_DIR}/${lang}.sh"
  if [ -f "${cached}" ]; then
    # shellcheck source=/dev/null
    . "${cached}"
    NMUX_LANG="${lang}"
    return 0
  fi

  # GitHubからダウンロード
  local tmp_f
  tmp_f=$(mktemp)
  local dl_ok=0
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "${BASE_URL}/scripts/i18n/${lang}.sh" -o "${tmp_f}" 2>/dev/null && dl_ok=1
  elif command -v wget >/dev/null 2>&1; then
    wget -qO "${tmp_f}" "${BASE_URL}/scripts/i18n/${lang}.sh" 2>/dev/null && dl_ok=1
  fi

  if [ "${dl_ok}" = "1" ] && [ -s "${tmp_f}" ]; then
    mkdir -p "${NMUX_I18N_DIR}"
    cp "${tmp_f}" "${cached}"
    # shellcheck source=/dev/null
    . "${tmp_f}"
    NMUX_LANG="${lang}"
    rm -f "${tmp_f}"
    return 0
  fi

  rm -f "${tmp_f}"
  # ダウンロード失敗時は日本語デフォルトのまま継続
  NMUX_LANG="ja"
  return 1
}

# インストール時の言語選択ダイアログ（常に3言語で表示）
select_language() {
  # nmux.conf に保存済みならスキップ
  if [ -n "${NMUX_LANG:-}" ] && [ "${NMUX_LANG}" != "ja" ]; then
    load_language "${NMUX_LANG}" 2>/dev/null || true
    return 0
  fi

  echo ""
  printf '%b%bSelect language / 言語を選択 / 选择语言:%b\n' "${BOLD}" "" "${NC}"
  printf '  1) 日本語\n'
  printf '  2) English\n'
  printf '  3) 中文\n'
  echo ""
  printf 'Choice / 選択 / 请选择 [1/2/3] (default / デフォルト / 默认: 1): '
  read -r lang_input

  case "${lang_input}" in
    2) load_language "en" ;;
    3) load_language "zh" ;;
    *) load_language "ja" ;;
  esac
}

# ============================================================
# Logging
# ============================================================
_ts() { date '+%Y-%m-%dT%H:%M:%S'; }

_log() {
  local level="$1"; shift
  mkdir -p "${LOG_DIR}"
  printf '%s [%s] %s\n' "$(_ts)" "${level}" "$*" \
    >> "${LOG_DIR}/nmux-$(date +%Y%m%d).log"
}

info()  { printf "${GREEN}[nmux]${NC} %s\n" "$*";  _log INFO  "$*"; }
warn()  { printf "${YELLOW}[nmux]${NC} %s\n" "$*"; _log WARN  "$*"; }
debug() {
  if [ "${NMUX_DEBUG:-0}" = "1" ]; then
    printf "${BLUE}[nmux:dbg]${NC} %s\n" "$*"
  fi
  _log DEBUG "$*"
}
error() {
  printf "${RED}[nmux]${NC} %s\n" "$*" >&2
  _log ERROR "$*"
  printf '\n  %s: %s/nmux-%s.log\n' "${L_LOG_LABEL}" "${LOG_DIR}" "$(date +%Y%m%d)" >&2
  exit 1
}

# ============================================================
# OS 検出
# ============================================================
detect_os() {
  case "$(uname -s)" in
    Darwin) echo "macos" ;;
    Linux)
      if grep -qi microsoft /proc/version 2>/dev/null; then
        echo "wsl"
      else
        echo "linux"
      fi
      ;;
    *) error "Unsupported OS: $(uname -s)" ;;
  esac
}

OS=$(detect_os)
debug "OS: ${OS}"

# ============================================================
# パッケージマネージャ
# ============================================================
detect_pkg_manager() {
  if [ "${OS}" = "macos" ]; then
    command -v brew >/dev/null 2>&1 && echo "brew" || echo "unknown"
    return
  fi
  if command -v apt-get >/dev/null 2>&1; then echo "apt"
  elif command -v dnf    >/dev/null 2>&1; then echo "dnf"
  elif command -v pacman >/dev/null 2>&1; then echo "pacman"
  elif command -v apk    >/dev/null 2>&1; then echo "apk"
  elif command -v brew   >/dev/null 2>&1; then echo "brew"
  else echo "unknown"
  fi
}

pkg_install() {
  local pkg="$1"
  local mgr
  mgr=$(detect_pkg_manager)
  info "$(printf "${L_INSTALLING_PKG}" "${pkg}" "${mgr}")"
  case "${mgr}" in
    brew)   brew install "${pkg}" ;;
    apt)    sudo apt-get update -qq && sudo apt-get install -y -qq "${pkg}" ;;
    dnf)    sudo dnf install -y -q "${pkg}" ;;
    pacman) sudo pacman -S --noconfirm "${pkg}" ;;
    apk)    sudo apk add "${pkg}" ;;
    *)      error "$(printf "${L_PKG_INSTALL_FAIL}" "${pkg}")" ;;
  esac
}

require_brew() {
  if [ "${OS}" = "macos" ] && ! command -v brew >/dev/null 2>&1; then
    error "${L_BREW_REQUIRED}"
  fi
}

# Python 3.6+ の存在確認
check_python3() {
  local py
  for py in python3 python; do
    if command -v "${py}" >/dev/null 2>&1; then
      local ver
      ver=$("${py}" -c "import sys; print(sys.version_info >= (3,6))" 2>/dev/null || true)
      if [ "${ver}" = "True" ]; then
        debug "Python 3.6+: $(${py} --version 2>&1)"
        return 0
      fi
    fi
  done
  return 1
}

# ============================================================
# クリップボード検出
# ============================================================
detect_clipboard() {
  if command -v pbcopy  >/dev/null 2>&1; then echo "pbcopy"
  elif command -v wl-copy >/dev/null 2>&1; then echo "wl-copy"
  elif command -v xclip   >/dev/null 2>&1; then echo "xclip"
  elif command -v xsel    >/dev/null 2>&1; then echo "xsel"
  else echo "none"
  fi
}

install_clipboard() {
  local clip
  clip=$(detect_clipboard)
  if [ "${clip}" = "none" ]; then
    info "${L_CLIPBOARD_INSTALLING}"
    if [ "${OS}" = "macos" ]; then
      :
    elif [ -n "${WAYLAND_DISPLAY:-}" ] || [ "${XDG_SESSION_TYPE:-}" = "wayland" ]; then
      pkg_install wl-clipboard || warn "$(printf "${L_CLIPBOARD_FAIL}" "wl-clipboard")"
    else
      pkg_install xclip || warn "$(printf "${L_CLIPBOARD_FAIL}" "xclip")"
    fi
  fi
  debug "clipboard: $(detect_clipboard)"
}

# ============================================================
# tmux バージョンチェック
# ============================================================
check_tmux_version() {
  local ver major minor
  ver=$(tmux -V 2>/dev/null | grep -oE '[0-9]+\.[0-9]+' || echo "0.0")
  major=$(printf '%s' "${ver}" | cut -d. -f1)
  minor=$(printf '%s' "${ver}" | cut -d. -f2)
  if [ "${major}" -lt 3 ] || { [ "${major}" -eq 3 ] && [ "${minor}" -lt 2 ]; }; then
    error "$(printf "${L_TMUX_UNSUPPORTED}" "${ver}")"
  fi
  info "$(printf "${L_TMUX_OK}" "${ver}")"
}

# ============================================================
# セキュリティ: shasum 検証
# ============================================================
verify_file() {
  local file="$1"
  local expected="$2"
  local actual

  [ -z "${expected}" ] && return 0

  if command -v sha256sum >/dev/null 2>&1; then
    actual=$(sha256sum "${file}" | awk '{print $1}')
  elif command -v shasum >/dev/null 2>&1; then
    actual=$(shasum -a 256 "${file}" | awk '{print $1}')
  else
    warn "${L_SHA256_SKIP}"
    return 0
  fi

  if [ "${actual}" != "${expected}" ]; then
    rm -f "${file}"
    error "$(printf "${L_VERIFY_FAIL}" "$(basename "${file}")")"
  fi
  debug "verify OK: $(basename "${file}")"
}

# ============================================================
# ダウンロード
# ============================================================
download() {
  local url="$1"
  local dest="$2"
  debug "DL: ${url}"
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "${url}" -o "${dest}" || error "$(printf "${L_DOWNLOAD_FAIL}" "${url}")"
  elif command -v wget >/dev/null 2>&1; then
    wget -qO "${dest}" "${url}" || error "$(printf "${L_DOWNLOAD_FAIL}" "${url}")"
  else
    error "${L_CURL_WGET_REQUIRED}"
  fi
}

# ============================================================
# バックアップ
# ============================================================
backup_existing() {
  local ts
  ts=$(date +%Y%m%d-%H%M%S)
  mkdir -p "${BACKUP_DIR}"

  if [ -f "${TMUX_XDG_DIR}/tmux.conf" ] && [ ! -L "${TMUX_XDG_DIR}/tmux.conf" ]; then
    cp "${TMUX_XDG_DIR}/tmux.conf" "${BACKUP_DIR}/tmux.conf.${ts}"
    info "$(printf "${L_BACKUP}" "~/.config/tmux/tmux.conf")"
  fi
  if [ -f "${HOME}/.tmux.conf" ]; then
    cp "${HOME}/.tmux.conf" "${BACKUP_DIR}/tmux.conf.legacy.${ts}"
    info "$(printf "${L_BACKUP}" "~/.tmux.conf")"
  fi
}

# ============================================================
# PATH 管理
# ============================================================
ensure_path() {
  case ":${PATH}:" in
    *":${BIN_DIR}:"*) debug "PATH already set"; return 0 ;;
  esac

  local rc_file
  case "${SHELL:-/bin/bash}" in
    */zsh)  rc_file="${HOME}/.zshrc" ;;
    */bash) rc_file="${HOME}/.bashrc" ;;
    *)      rc_file="${HOME}/.profile" ;;
  esac

  if [ -f "${rc_file}" ] && grep -q '# nmux-path-begin' "${rc_file}"; then
    debug "PATH block exists"
    export PATH="${BIN_DIR}:${PATH}"
    return 0
  fi

  info "$(printf "${L_PATH_APPENDING}" "${rc_file}")"
  # shellcheck disable=SC2016
  { printf '\n# nmux-path-begin\n';
    printf 'export PATH="%s:${PATH}"\n' "${BIN_DIR}";
    printf '# nmux-path-end\n'; } >> "${rc_file}"
  export PATH="${BIN_DIR}:${PATH}"
}

remove_path() {
  local rc_file
  case "${SHELL:-/bin/bash}" in
    */zsh)  rc_file="${HOME}/.zshrc" ;;
    */bash) rc_file="${HOME}/.bashrc" ;;
    *)      rc_file="${HOME}/.profile" ;;
  esac

  if [ -f "${rc_file}" ] && grep -q '# nmux-path-begin' "${rc_file}"; then
    if sed --version 2>/dev/null | grep -q GNU; then
      sed -i '/# nmux-path-begin/,/# nmux-path-end/d' "${rc_file}"
    else
      sed -i '' '/# nmux-path-begin/,/# nmux-path-end/d' "${rc_file}"
    fi
    info "$(printf "${L_PATH_REMOVED}" "${rc_file}")"
  fi
}

# ============================================================
# 設定ファイル読み書き
# ============================================================
load_conf() {
  if [ -f "${CONF_FILE}" ]; then
    # shellcheck source=/dev/null
    . "${CONF_FILE}"
  fi
}

save_conf() {
  mkdir -p "${NMUX_DIR}"
  cat > "${CONF_FILE}" <<CONF
# nmux configuration file
# Auto-generated: $(_ts)

NMUX_MODE="${NMUX_MODE:-standalone}"
NMUX_LANG="${NMUX_LANG:-ja}"
NMUX_HEARTBEAT_INTERVAL="${NMUX_HEARTBEAT_INTERVAL:-1}"

# API server settings (nmux-api)
NMUX_API_MODE="${NMUX_API_MODE:-integrated}"
NMUX_API_HOST="${NMUX_API_HOST:-127.0.0.1}"
NMUX_API_PORT="${NMUX_API_PORT:-8765}"
NMUX_API_TOKEN="${NMUX_API_TOKEN:-}"

# Cross-machine settings (crossmachine mode only)
REMOTE_HOST="${REMOTE_HOST:-}"
REMOTE_USER="${REMOTE_USER:-}"
REMOTE_PORT="${REMOTE_PORT:-22}"
REMOTE_BRIDGE="${REMOTE_BRIDGE:-\$HOME/.nmux/bin/nmux-bridge}"
CONF
  debug "config saved: ${CONF_FILE}"
}

# ============================================================
# インストールモード選択
# ============================================================
select_mode() {
  echo ""
  printf "%b%b%s%b\n" "${BOLD}" "" "${L_SELECT_MODE}" "${NC}"
  printf "%s\n" "${L_MODE_STANDALONE}"
  printf "%s\n" "${L_MODE_CROSSMACHINE}"
  echo ""
  printf "%s" "${L_MODE_PROMPT}"
  read -r mode_input

  case "${mode_input}" in
    2) NMUX_MODE="crossmachine" ;;
    *) NMUX_MODE="standalone" ;;
  esac

  info "$(printf "${L_MODE_SELECTED}" "${NMUX_MODE}")"
}

# ============================================================
# サブ機接続情報の入力
# ============================================================
input_remote_conf() {
  echo ""
  printf "%b%b%s%b\n" "${BOLD}" "" "${L_REMOTE_CONF_HEADER}" "${NC}"
  echo ""

  printf "%s" "${L_REMOTE_HOST_PROMPT}"
  read -r REMOTE_HOST
  [ -z "${REMOTE_HOST}" ] && error "${L_REMOTE_HOST_REQUIRED}"

  printf "${L_REMOTE_USER_PROMPT}" "$(whoami)"
  read -r input_user
  REMOTE_USER="${input_user:-$(whoami)}"

  printf "%s" "${L_REMOTE_PORT_PROMPT}"
  read -r input_port
  REMOTE_PORT="${input_port:-22}"

  REMOTE_BRIDGE="\$HOME/.nmux/bin/nmux-bridge"

  echo ""
  info "$(printf "${L_REMOTE_CONF_INFO}" "${REMOTE_USER}" "${REMOTE_HOST}" "${REMOTE_PORT}")"

  info "${L_SSH_TESTING}"
  if ssh -q \
       -o ConnectTimeout=10 \
       -o StrictHostKeyChecking=accept-new \
       -p "${REMOTE_PORT}" \
       "${REMOTE_USER}@${REMOTE_HOST}" \
       'true' 2>/dev/null; then
    info "${L_SSH_OK}"
  else
    warn "${L_SSH_FAIL}"
    warn "${L_SSH_FAIL_HINT}"
    printf "%s" "${L_SSH_CONTINUE}"
    read -r cont
    case "${cont}" in
      y|Y) : ;;
      *)   error "${L_INSTALL_ABORTED}" ;;
    esac
  fi

  echo ""
  printf "%s" "${L_INSTALL_SUB_PROMPT}"
  read -r install_sub
  case "${install_sub}" in
    n|N) info "${L_INSTALL_SUB_SKIP}" ;;
    *)
      info "$(printf "${L_INSTALL_SUB_RUNNING}" "${REMOTE_HOST}")"
      if ssh -q \
         -o ConnectTimeout=10 \
         -p "${REMOTE_PORT}" \
         "${REMOTE_USER}@${REMOTE_HOST}" \
         "curl -fsSL ${BASE_URL}/install.sh | bash -s -- --sub"; then
        info "${L_INSTALL_SUB_DONE}"
      else
        warn "${L_INSTALL_SUB_FAIL}"
      fi
      ;;
  esac
}

# ============================================================
# コアファイルのインストール
# ============================================================
install_core() {
  mkdir -p "${NMUX_DIR}" "${BIN_DIR}" "${BACKUP_DIR}" "${LOG_DIR}" "${STATE_DIR}"

  # tmux
  if ! command -v tmux >/dev/null 2>&1; then
    info "${L_INSTALLING_TMUX}"
    require_brew
    pkg_install tmux
  fi
  check_tmux_version

  # クリップボード
  install_clipboard

  # バックアップ
  backup_existing

  # tmux.conf
  info "$(printf "${L_DOWNLOADING}" "tmux.conf")"
  download "${BASE_URL}/.tmux.conf" "${NMUX_DIR}/tmux.conf"
  mkdir -p "${TMUX_XDG_DIR}"
  ln -sf "${NMUX_DIR}/tmux.conf" "${TMUX_XDG_DIR}/tmux.conf"

  # nmux-bridge
  info "$(printf "${L_DOWNLOADING}" "nmux-bridge")"
  download "${BASE_URL}/scripts/nmux-bridge" "${BIN_DIR}/nmux-bridge"
  chmod +x "${BIN_DIR}/nmux-bridge"

  # nmux-heartbeat
  info "$(printf "${L_DOWNLOADING}" "nmux-heartbeat")"
  download "${BASE_URL}/scripts/nmux-heartbeat" "${BIN_DIR}/nmux-heartbeat"
  chmod +x "${BIN_DIR}/nmux-heartbeat"

  # クロスマシンモードのみ nmux-remote もインストール
  if [ "${NMUX_MODE:-standalone}" = "crossmachine" ]; then
    info "$(printf "${L_DOWNLOADING}" "nmux-remote")"
    download "${BASE_URL}/scripts/nmux-remote" "${BIN_DIR}/nmux-remote"
    chmod +x "${BIN_DIR}/nmux-remote"
  fi

  # Python スクリプト群
  if check_python3; then
    info "$(printf "${L_DOWNLOADING}" "nmux-dispatch")"
    download "${BASE_URL}/scripts/nmux-dispatch" "${BIN_DIR}/nmux-dispatch"
    chmod +x "${BIN_DIR}/nmux-dispatch"

    info "$(printf "${L_DOWNLOADING}" "nmux-api")"
    download "${BASE_URL}/scripts/nmux-api" "${BIN_DIR}/nmux-api"
    chmod +x "${BIN_DIR}/nmux-api"

    info "$(printf "${L_DOWNLOADING}" "nmux-tui")"
    download "${BASE_URL}/scripts/nmux-tui" "${BIN_DIR}/nmux-tui"
    chmod +x "${BIN_DIR}/nmux-tui"

    if [ "${1:-}" != "--sub" ] && [ -t 0 ]; then
      printf '\n%b%s%b\n' "${YELLOW}" "${L_SELECT_API_MODE}" "${NC}"
      printf '%s\n' "${L_API_MODE_INTEGRATED}"
      printf '%s\n' "${L_API_MODE_DAEMON}"
      printf '%s' "${L_API_MODE_PROMPT}"
      read -r api_mode_input
      case "${api_mode_input}" in
        2) NMUX_API_MODE="daemon" ;;
        *) NMUX_API_MODE="integrated" ;;
      esac
      export NMUX_API_MODE
    fi
  else
    warn "${L_PYTHON_SKIP}"
    warn "${L_PYTHON_SKIP_HINT}"
  fi

  # nmux-converse
  info "$(printf "${L_INSTALLING}" "nmux-converse")"
  download "${BASE_URL}/scripts/nmux-converse" "${BIN_DIR}/nmux-converse"
  chmod +x "${BIN_DIR}/nmux-converse"

  # nmux-init（セットアップウィザード）
  info "$(printf "${L_INSTALLING}" "nmux-init")"
  download "${BASE_URL}/scripts/nmux-init" "${BIN_DIR}/nmux-init"
  chmod +x "${BIN_DIR}/nmux-init"

  # skill-map.json（既存は上書きしない）
  if [ ! -f "${NMUX_DIR}/skill-map.json" ]; then
    download "${BASE_URL}/scripts/skill-map.json" "${NMUX_DIR}/skill-map.json"
    info "$(printf "${L_SKILL_MAP_PLACED}" "${NMUX_DIR}/skill-map.json")"
  fi

  # i18n キャッシュ更新（現在の言語を最新に保つ）
  mkdir -p "${NMUX_I18N_DIR}"
  local lang_file="${NMUX_I18N_DIR}/${NMUX_LANG:-ja}.sh"
  download "${BASE_URL}/scripts/i18n/${NMUX_LANG:-ja}.sh" "${lang_file}" 2>/dev/null || true

  # nmux CLI 本体
  info "$(printf "${L_INSTALLING}" "nmux CLI")"
  download "${BASE_URL}/install.sh" "${BIN_DIR}/nmux"
  chmod +x "${BIN_DIR}/nmux"

  # VERSION
  printf '%s\n' "${NMUX_VERSION}" > "${NMUX_DIR}/VERSION"

  # PATH
  ensure_path
}

# ============================================================
# コマンド実装
# ============================================================

cmd_install() {
  # サブ機側インストール（--sub フラグ時はモード・言語選択をスキップ）
  if [ "${1:-}" = "--sub" ]; then
    NMUX_MODE="standalone"
    info "$(printf "${L_INSTALL_SUB_COMPLETE}" "")"
    install_core "--sub"
    save_conf
    _reload_tmux
    printf '\n%b%b'"$(printf "${L_INSTALL_SUB_COMPLETE}" "${NMUX_VERSION}")"'%b\n\n' \
      "${GREEN}" "${BOLD}" "${NC}"
    return 0
  fi

  # 言語選択（初回のみ）
  select_language

  info "$(printf "${L_INSTALLER_HEADER}" "${NMUX_VERSION}" "${OS}")"
  echo ""

  # モード選択
  select_mode

  # クロスマシンの場合はサブ機情報を入力
  if [ "${NMUX_MODE}" = "crossmachine" ]; then
    input_remote_conf
  fi

  # コアインストール
  install_core

  # 設定ファイル保存
  save_conf

  # tmux リロード
  _reload_tmux

  echo ""
  printf '%b%b'"$(printf "${L_INSTALL_COMPLETE}" "${NMUX_VERSION}")"'%b\n\n' \
    "${GREEN}" "${BOLD}" "${NC}"
  printf '%s\n' "$(printf "${L_INFO_MODE}" "${NMUX_MODE}")"
  printf '%s\n' "$(printf "${L_INFO_DIR}" "${NMUX_DIR}")"
  printf '%s\n' "$(printf "${L_INFO_LOG}" "${LOG_DIR}")"
  if [ "${NMUX_MODE}" = "crossmachine" ]; then
    printf '%s\n' "$(printf "${L_INFO_REMOTE}" "${REMOTE_USER}" "${REMOTE_HOST}" "${REMOTE_PORT}")"
  fi
  echo ""
  printf '%s\n\n' "${L_INFO_USAGE}"

  case ":${PATH}:" in
    *":${BIN_DIR}:"*) : ;;
    *)
      warn "${L_PATH_RELOAD}"
      warn "  export PATH=\"\${HOME}/.nmux/bin:\${PATH}\""
      ;;
  esac
}

_reload_tmux() {
  if tmux list-sessions >/dev/null 2>&1; then
    if tmux source-file "${NMUX_DIR}/tmux.conf" 2>/dev/null; then
      info "${L_TMUX_RELOAD_OK}"
    else
      warn "${L_TMUX_RELOAD_FAIL}"
    fi
  fi
}

cmd_update() {
  load_conf
  local current_ver="?"
  if [ -f "${NMUX_DIR}/VERSION" ]; then
    current_ver=$(cat "${NMUX_DIR}/VERSION")
  fi

  # 言語を自動ロード
  load_language "${NMUX_LANG:-ja}" 2>/dev/null || true

  info "$(printf "${L_UPDATING}" "${current_ver}")"
  mkdir -p "${NMUX_DIR}" "${BIN_DIR}" "${BACKUP_DIR}" "${LOG_DIR}" "${STATE_DIR}"

  local tmp_ver remote_ver
  tmp_ver=$(mktemp)
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "${BASE_URL}/VERSION" -o "${tmp_ver}" 2>/dev/null
  else
    wget -qO "${tmp_ver}" "${BASE_URL}/VERSION" 2>/dev/null || true
  fi
  remote_ver=$(cat "${tmp_ver}" 2>/dev/null | tr -d '[:space:]' || true)
  rm -f "${tmp_ver}"

  if [ -n "${remote_ver}" ]; then
    if [ "${current_ver}" = "${remote_ver}" ]; then
      info "$(printf "${L_ALREADY_LATEST}" "${current_ver}")"
      return 0
    fi
    info "$(printf "${L_UPDATING_TO}" "${current_ver}" "${remote_ver}")"
  else
    warn "${L_VERSION_CHECK_FAIL}"
  fi

  backup_existing
  download "${BASE_URL}/.tmux.conf"           "${NMUX_DIR}/tmux.conf"
  download "${BASE_URL}/scripts/nmux-bridge"  "${BIN_DIR}/nmux-bridge"
  chmod +x "${BIN_DIR}/nmux-bridge"
  download "${BASE_URL}/scripts/nmux-heartbeat" "${BIN_DIR}/nmux-heartbeat"
  chmod +x "${BIN_DIR}/nmux-heartbeat"

  if [ "${NMUX_MODE:-standalone}" = "crossmachine" ]; then
    download "${BASE_URL}/scripts/nmux-remote" "${BIN_DIR}/nmux-remote"
    chmod +x "${BIN_DIR}/nmux-remote"
  fi

  if check_python3; then
    download "${BASE_URL}/scripts/nmux-dispatch" "${BIN_DIR}/nmux-dispatch"
    chmod +x "${BIN_DIR}/nmux-dispatch"
    download "${BASE_URL}/scripts/nmux-api"      "${BIN_DIR}/nmux-api"
    chmod +x "${BIN_DIR}/nmux-api"
    download "${BASE_URL}/scripts/nmux-tui"      "${BIN_DIR}/nmux-tui"
    chmod +x "${BIN_DIR}/nmux-tui"
  fi

  download "${BASE_URL}/scripts/nmux-converse" "${BIN_DIR}/nmux-converse"
  chmod +x "${BIN_DIR}/nmux-converse"

  if [ ! -f "${NMUX_DIR}/skill-map.json" ]; then
    download "${BASE_URL}/scripts/skill-map.json" "${NMUX_DIR}/skill-map.json"
  fi

  # i18n キャッシュ更新
  mkdir -p "${NMUX_I18N_DIR}"
  download "${BASE_URL}/scripts/i18n/${NMUX_LANG:-ja}.sh" \
    "${NMUX_I18N_DIR}/${NMUX_LANG:-ja}.sh" 2>/dev/null || true

  download "${BASE_URL}/install.sh" "${BIN_DIR}/nmux"
  chmod +x "${BIN_DIR}/nmux"

  local new_ver
  new_ver=$(curl -fsSL "${BASE_URL}/VERSION" 2>/dev/null || printf '%s' "${NMUX_VERSION}")
  printf '%s\n' "${new_ver}" > "${NMUX_DIR}/VERSION"
  _reload_tmux
  printf '%b%b'"$(printf "${L_UPDATE_COMPLETE}" "${new_ver}")"'%b\n' \
    "${GREEN}" "${BOLD}" "${NC}"
}

cmd_rollback() {
  load_language "${NMUX_LANG:-ja}" 2>/dev/null || true
  info "${L_ROLLBACK_HEADER}"
  echo ""

  local backups i=1
  backups=$(find "${BACKUP_DIR}" -name 'tmux.conf.*' -not -name '*.legacy.*' 2>/dev/null \
    | sort -r | head -10 || true)

  if [ -z "${backups}" ]; then
    warn "${L_NO_BACKUP}"
    return 1
  fi

  while IFS= read -r bk; do
    printf '  %d) %s\n' "${i}" "${bk}"
    i=$((i + 1))
  done <<EOF
${backups}
EOF

  echo ""
  printf "$(printf "${L_ROLLBACK_PROMPT}" "$((i - 1))")"
  read -r num

  local target
  target=$(printf '%s\n' "${backups}" | sed -n "${num}p")
  if [ -z "${target}" ] || [ ! -f "${target}" ]; then
    error "$(printf "${L_ROLLBACK_INVALID}" "${num}")"
  fi

  cp "${target}" "${NMUX_DIR}/tmux.conf"
  _reload_tmux
  info "$(printf "${L_ROLLBACK_DONE}" "${target}")"
}

cmd_uninstall() {
  load_language "${NMUX_LANG:-ja}" 2>/dev/null || true
  info "${L_UNINSTALLING}"

  if [ -x "${BIN_DIR}/nmux-api" ]; then
    "${BIN_DIR}/nmux-api" stop 2>/dev/null || true
  fi

  if [ -x "${BIN_DIR}/nmux-heartbeat" ]; then
    "${BIN_DIR}/nmux-heartbeat" stop 2>/dev/null || true
  fi

  if [ -L "${TMUX_XDG_DIR}/tmux.conf" ]; then
    rm "${TMUX_XDG_DIR}/tmux.conf"
    info "${L_SYMLINK_REMOVED}"
  fi

  local latest_backup
  latest_backup=$(find "${BACKUP_DIR}" -name 'tmux.conf.*' 2>/dev/null \
    | sort -r | head -1 || true)
  if [ -n "${latest_backup}" ] && [ -f "${latest_backup}" ]; then
    info "$(printf "${L_BACKUP_RESTORED}" "${latest_backup}")"
    mkdir -p "${TMUX_XDG_DIR}"
    cp "${latest_backup}" "${TMUX_XDG_DIR}/tmux.conf"
  fi

  remove_path
  rm -rf "${NMUX_DIR}"
  printf '%b[nmux]%b '"$(printf "${L_DIR_REMOVED}" "${NMUX_DIR}")"'\n' "${GREEN}" "${NC}"

  printf '\n%b%b%s%b\n' "${GREEN}" "${BOLD}" "${L_UNINSTALL_COMPLETE}" "${NC}"
  printf '%s\n\n' "${L_RESTART_SHELL}"
}

cmd_status() {
  load_conf
  load_language "${NMUX_LANG:-ja}" 2>/dev/null || true

  local ver
  ver="$(printf "${L_STATUS_NOT_INSTALLED}")"
  if [ -f "${NMUX_DIR}/VERSION" ]; then
    ver=$(cat "${NMUX_DIR}/VERSION")
  fi

  local hb_status
  hb_status="$(printf "${L_STATUS_STOPPED}")"
  if [ -f "${STATE_DIR}/heartbeat.pid" ]; then
    local hb_pid
    hb_pid=$(cat "${STATE_DIR}/heartbeat.pid")
    if kill -0 "${hb_pid}" 2>/dev/null; then
      hb_status="$(printf "${L_STATUS_RUNNING}" "${hb_pid}")"
    fi
  fi

  printf '\n%b%b%s%b\n' "${BOLD}" "${GREEN}" "${L_STATUS_HEADER}" "${NC}"
  printf '────────────────────────────────────────\n'
  printf '%s\n' "$(printf "${L_STATUS_VERSION}" "${ver}")"
  printf '%s\n' "$(printf "${L_STATUS_OS}" "${OS}")"
  printf '%s\n' "$(printf "${L_STATUS_MODE}" "${NMUX_MODE:-standalone}")"
  printf '%s\n' "$(printf "${L_STATUS_TMUX}" "$(tmux -V 2>/dev/null || printf '%s' "${L_STATUS_NOT_INSTALLED}")")"
  printf '%s\n' "$(printf "${L_STATUS_CLIPBOARD}" "$(detect_clipboard)")"
  printf '%s' "${L_STATUS_BRIDGE}"
  if [ -x "${BIN_DIR}/nmux-bridge" ]; then
    printf '%b✓%b\n' "${GREEN}" "${NC}"
  else
    printf '%b✗%b\n' "${RED}" "${NC}"
  fi

  if [ "${NMUX_MODE:-standalone}" = "crossmachine" ]; then
    printf '%s' "${L_STATUS_REMOTE}"
    if [ -x "${BIN_DIR}/nmux-remote" ]; then
      printf '%b✓%b\n' "${GREEN}" "${NC}"
    else
      printf '%b✗%b\n' "${RED}" "${NC}"
    fi
    printf '%s\n' "$(printf "${L_STATUS_SUB}" \
      "${REMOTE_USER:-${L_STATUS_NOT_SET}}" \
      "${REMOTE_HOST:-${L_STATUS_NOT_SET}}" \
      "${REMOTE_PORT:-22}")"
  fi

  printf '%s\n' "$(printf "${L_STATUS_HEARTBEAT}" "${hb_status}")"

  local api_status
  api_status="$(printf "${L_STATUS_STOPPED}")"
  if [ -f "${STATE_DIR}/api.pid" ]; then
    local api_pid
    api_pid=$(cat "${STATE_DIR}/api.pid")
    if kill -0 "${api_pid}" 2>/dev/null; then
      api_status="$(printf "${L_STATUS_RUNNING}" "${api_pid}")"
    fi
  fi
  printf '%s\n' "$(printf "${L_STATUS_API}" "${api_status}")"
  printf '%s\n' "$(printf "${L_STATUS_LOG}" "${LOG_DIR}")"
  printf '\n'
}

cmd_heartbeat() {
  local subcmd="${1:-status}"
  shift || true
  if [ -x "${BIN_DIR}/nmux-heartbeat" ]; then
    "${BIN_DIR}/nmux-heartbeat" "${subcmd}" "$@"
  else
    error "${L_HEARTBEAT_NOT_FOUND}"
  fi
}

cmd_verify() {
  local file="${1:-}"
  local sha="${2:-}"
  if [ ! -f "${file}" ]; then
    error "$(printf "${L_FILE_NOT_FOUND}" "${file}")"
  fi
  verify_file "${file}" "${sha}"
  info "$(printf "${L_VERIFY_OK}" "${file}")"
}

cmd_log() {
  local n="${1:-50}"
  local log_file
  log_file="${LOG_DIR}/nmux-$(date +%Y%m%d).log"
  if [ -f "${log_file}" ]; then
    tail -n "${n}" "${log_file}"
  else
    warn "$(printf "${L_LOG_NOT_FOUND}" "${log_file}")"
  fi
}

cmd_version() {
  local ver="?"
  if [ -f "${NMUX_DIR}/VERSION" ]; then
    ver=$(cat "${NMUX_DIR}/VERSION")
  fi
  printf 'nmux %s\n' "${ver}"
}

cmd_help() {
  printf '%s\n' "${L_HELP}"
}

# ============================================================
# メイン
# ============================================================
load_conf 2>/dev/null || true

# nmux.conf に NMUX_LANG が保存されていれば自動ロード（ja も含め常にロード）
if [ -n "${NMUX_LANG:-}" ]; then
  load_language "${NMUX_LANG}" 2>/dev/null || true
fi

case "${1:-install}" in
  install)            cmd_install "${2:-}" ;;
  update)             cmd_update ;;
  rollback)           cmd_rollback ;;
  uninstall|remove)   cmd_uninstall ;;
  status)             cmd_status ;;
  heartbeat)          shift; cmd_heartbeat "$@" ;;
  api)                shift; "${BIN_DIR}/nmux-api" "${1:-status}" ;;
  init)               "${BIN_DIR}/nmux-init" ;;
  tui)                "${BIN_DIR}/nmux-tui" ;;
  converse)           shift; "${BIN_DIR}/nmux-converse" "$@" ;;
  verify)             cmd_verify "${2:-}" "${3:-}" ;;
  log)                cmd_log "${2:-50}" ;;
  version|--version|-v|-V) cmd_version ;;
  help|--help|-h)     cmd_help ;;
  *)
    printf '%b[nmux]%b '"$(printf "${L_UNKNOWN_CMD}" "$1")"'\n' "${RED}" "${NC}" >&2
    _log ERROR "unknown command: $1"
    printf '%s\n' "${L_UNKNOWN_CMD_HINT}" >&2
    exit 1
    ;;
esac
