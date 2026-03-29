#!/usr/bin/env bash
# nmux — next-generation multi-agent tmux setup
# Supports: macOS / Ubuntu (main & sub machine)
# https://github.com/naotantan/nmux
set -euo pipefail

NMUX_VERSION="2.0.0"
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

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

# --- Logging ---
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
  printf '\n  ログ: %s/nmux-%s.log\n' "${LOG_DIR}" "$(date +%Y%m%d)" >&2
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
    *) error "未対応 OS: $(uname -s)" ;;
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
  # Linux: システムパッケージマネージャを優先（Linuxbrew より先に検出）
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
  info "${pkg} をインストール中 (${mgr})..."
  case "${mgr}" in
    brew)   brew install "${pkg}" ;;
    apt)    sudo apt-get update -qq && sudo apt-get install -y -qq "${pkg}" ;;
    dnf)    sudo dnf install -y -q "${pkg}" ;;
    pacman) sudo pacman -S --noconfirm "${pkg}" ;;
    apk)    sudo apk add "${pkg}" ;;
    *)      error "${pkg} のインストールに失敗しました。手動でインストールしてください。" ;;
  esac
}

require_brew() {
  if [ "${OS}" = "macos" ] && ! command -v brew >/dev/null 2>&1; then
    error "macOS では Homebrew が必要です。https://brew.sh からインストールしてください。"
  fi
}

# Python 3.6+ の存在確認（nmux-dispatch に必要）
# 存在すれば 0、なければ 1 を返す
check_python3() {
  local py
  for py in python3 python; do
    if command -v "${py}" >/dev/null 2>&1; then
      local ver
      ver=$("${py}" -c "import sys; print(sys.version_info >= (3,6))" 2>/dev/null || true)
      if [ "${ver}" = "True" ]; then
        debug "Python 3.6+ 確認済み: $(${py} --version 2>&1)"
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
    info "クリップボードツールをインストール中..."
    if [ "${OS}" = "macos" ]; then
      : # pbcopy は標準搭載のため不要
    elif [ -n "${WAYLAND_DISPLAY:-}" ] || [ "${XDG_SESSION_TYPE:-}" = "wayland" ]; then
      pkg_install wl-clipboard || warn "wl-clipboard のインストールに失敗しました"
    else
      pkg_install xclip || warn "xclip のインストールに失敗しました"
    fi
  fi
  debug "クリップボード: $(detect_clipboard)"
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
    error "tmux ${ver} は未対応です。tmux 3.2+ が必要です。"
  fi
  info "tmux ${ver} — OK"
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
    warn "sha256sum が見つかりません。検証をスキップします。"
    return 0
  fi

  if [ "${actual}" != "${expected}" ]; then
    rm -f "${file}"
    error "ファイル検証失敗: $(basename "${file}")"
  fi
  debug "検証 OK: $(basename "${file}")"
}

# ============================================================
# ダウンロード
# ============================================================
download() {
  local url="$1"
  local dest="$2"
  debug "DL: ${url}"
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "${url}" -o "${dest}" || error "ダウンロード失敗: ${url}"
  elif command -v wget >/dev/null 2>&1; then
    wget -qO "${dest}" "${url}" || error "ダウンロード失敗: ${url}"
  else
    error "curl / wget が必要です。どちらかをインストールしてください。"
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
    info "バックアップ: ~/.config/tmux/tmux.conf"
  fi
  if [ -f "${HOME}/.tmux.conf" ]; then
    cp "${HOME}/.tmux.conf" "${BACKUP_DIR}/tmux.conf.legacy.${ts}"
    info "バックアップ: ~/.tmux.conf"
  fi
}

# ============================================================
# PATH 管理（重複防止・ブロック形式）
# ============================================================
ensure_path() {
  case ":${PATH}:" in
    *":${BIN_DIR}:"*) debug "PATH 設定済み"; return 0 ;;
  esac

  local rc_file
  case "${SHELL:-/bin/bash}" in
    */zsh)  rc_file="${HOME}/.zshrc" ;;
    */bash) rc_file="${HOME}/.bashrc" ;;
    *)      rc_file="${HOME}/.profile" ;;
  esac

  if [ -f "${rc_file}" ] && grep -q '# nmux-path-begin' "${rc_file}"; then
    debug "PATH ブロック既存"
    export PATH="${BIN_DIR}:${PATH}"
    return 0
  fi

  info "PATH 設定を ${rc_file} に追記..."
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
    info "PATH 設定を ${rc_file} から削除しました"
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
# nmux 設定ファイル
# 自動生成: $(_ts)

NMUX_MODE="${NMUX_MODE:-standalone}"
NMUX_HEARTBEAT_INTERVAL="${NMUX_HEARTBEAT_INTERVAL:-1}"

# API サーバー設定（nmux-api）
NMUX_API_MODE="${NMUX_API_MODE:-integrated}"
NMUX_API_HOST="${NMUX_API_HOST:-127.0.0.1}"
NMUX_API_PORT="${NMUX_API_PORT:-8765}"
NMUX_API_TOKEN="${NMUX_API_TOKEN:-}"

# クロスマシン設定（モード: crossmachine のみ使用）
REMOTE_HOST="${REMOTE_HOST:-}"
REMOTE_USER="${REMOTE_USER:-}"
REMOTE_PORT="${REMOTE_PORT:-22}"
REMOTE_BRIDGE="${REMOTE_BRIDGE:-\$HOME/.nmux/bin/nmux-bridge}"
CONF
  debug "設定ファイル保存: ${CONF_FILE}"
}

# ============================================================
# インストールモード選択
# ============================================================
select_mode() {
  echo ""
  printf "%b%bインストールモードを選択してください:%b\n" "${BOLD}" "" "${NC}"
  printf "  1) スタンドアロン  — このマシン単体で AI エージェント間通信\n"
  printf "  2) クロスマシン    — メイン機 ＋ サブ機（別マシン）で連携\n"
  echo ""
  printf "選択 [1/2] (デフォルト: 1): "
  read -r mode_input

  case "${mode_input}" in
    2) NMUX_MODE="crossmachine" ;;
    *) NMUX_MODE="standalone" ;;
  esac

  info "モード: ${NMUX_MODE}"
}

# ============================================================
# サブ機接続情報の入力
# ============================================================
input_remote_conf() {
  echo ""
  printf "%b%bサブ機の接続情報を入力してください:%b\n" "${BOLD}" "" "${NC}"
  echo ""

  printf "  ホスト名または IP アドレス: "
  read -r REMOTE_HOST
  [ -z "${REMOTE_HOST}" ] && error "ホスト名は必須です。"

  printf "  SSH ユーザー名 [%s]: " "$(whoami)"
  read -r input_user
  REMOTE_USER="${input_user:-$(whoami)}"

  printf "  SSH ポート [22]: "
  read -r input_port
  REMOTE_PORT="${input_port:-22}"

  REMOTE_BRIDGE="\$HOME/.nmux/bin/nmux-bridge"

  echo ""
  info "接続情報: ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_PORT}"

  # SSH 接続テスト
  info "SSH 接続テスト中..."
  if ssh -q \
       -o ConnectTimeout=10 \
       -o StrictHostKeyChecking=accept-new \
       -p "${REMOTE_PORT}" \
       "${REMOTE_USER}@${REMOTE_HOST}" \
       'true' 2>/dev/null; then
    info "SSH 接続 OK"
  else
    warn "SSH 接続に失敗しました。設定を確認してください。"
    warn "  ~/.ssh/config または ssh-copy-id での鍵配布を確認してください。"
    printf "  続行しますか？ [y/N]: "
    read -r cont
    case "${cont}" in
      y|Y) : ;;
      *)   error "インストールを中止しました。" ;;
    esac
  fi

  # サブ機への nmux インストール
  echo ""
  printf "  サブ機にも nmux をインストールしますか？ [Y/n]: "
  read -r install_sub
  case "${install_sub}" in
    n|N) info "サブ機へのインストールをスキップしました。" ;;
    *)
      info "サブ機 (${REMOTE_HOST}) に nmux をインストール中..."
      if ssh -q \
         -o ConnectTimeout=10 \
         -p "${REMOTE_PORT}" \
         "${REMOTE_USER}@${REMOTE_HOST}" \
         "curl -fsSL ${BASE_URL}/install.sh | bash -s -- --sub"; then
      info "サブ機へのインストール完了"
    else
      warn "サブ機へのインストールに失敗しました。手動でインストールしてください。"
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
    info "tmux をインストール中..."
    require_brew
    pkg_install tmux
  fi
  check_tmux_version

  # クリップボード
  install_clipboard

  # バックアップ
  backup_existing

  # tmux.conf
  info "tmux.conf をダウンロード中..."
  download "${BASE_URL}/.tmux.conf" "${NMUX_DIR}/tmux.conf"
  mkdir -p "${TMUX_XDG_DIR}"
  ln -sf "${NMUX_DIR}/tmux.conf" "${TMUX_XDG_DIR}/tmux.conf"

  # nmux-bridge
  info "nmux-bridge をダウンロード中..."
  download "${BASE_URL}/scripts/nmux-bridge" "${BIN_DIR}/nmux-bridge"
  chmod +x "${BIN_DIR}/nmux-bridge"

  # nmux-heartbeat
  info "nmux-heartbeat をダウンロード中..."
  download "${BASE_URL}/scripts/nmux-heartbeat" "${BIN_DIR}/nmux-heartbeat"
  chmod +x "${BIN_DIR}/nmux-heartbeat"

  # クロスマシンモードのみ nmux-remote もインストール
  if [ "${NMUX_MODE:-standalone}" = "crossmachine" ]; then
    info "nmux-remote をダウンロード中..."
    download "${BASE_URL}/scripts/nmux-remote" "${BIN_DIR}/nmux-remote"
    chmod +x "${BIN_DIR}/nmux-remote"
  fi

  # Python スクリプト群（nmux-dispatch / nmux-api / nmux-tui）
  # Python 3.6+ がなければ全スクリプトをスキップし警告を表示
  if check_python3; then
    info "nmux-dispatch をダウンロード中..."
    download "${BASE_URL}/scripts/nmux-dispatch" "${BIN_DIR}/nmux-dispatch"
    chmod +x "${BIN_DIR}/nmux-dispatch"

    info "nmux-api をダウンロード中..."
    download "${BASE_URL}/scripts/nmux-api" "${BIN_DIR}/nmux-api"
    chmod +x "${BIN_DIR}/nmux-api"

    info "nmux-tui をダウンロード中..."
    download "${BASE_URL}/scripts/nmux-tui" "${BIN_DIR}/nmux-tui"
    chmod +x "${BIN_DIR}/nmux-tui"

    # API モード選択（インタラクティブインストール時のみ）
    if [ "${1:-}" != "--sub" ] && [ -t 0 ]; then
      printf '\n%b? nmux-api の動作モードを選択してください:%b\n' "${YELLOW}" "${NC}"
      printf '  1) integrated  — tmux セッション連動（推奨・デフォルト）\n'
      printf '  2) daemon      — 常駐プロセスとして独立起動\n'
      printf 'モード [1/2, デフォルト: 1]: '
      read -r api_mode_input
      case "${api_mode_input}" in
        2) NMUX_API_MODE="daemon" ;;
        *) NMUX_API_MODE="integrated" ;;
      esac
      # nmux.conf に書き出す（save_conf で反映される）
      export NMUX_API_MODE
    fi
  else
    warn "Python 3.6+ が見つかりません。nmux-dispatch / nmux-api / nmux-tui をスキップします。"
    warn "インストール後に手動で追加する場合: brew install python3 (macOS) または apt-get install python3 (Linux)"
  fi

  # nmux CLI 本体
  info "nmux CLI をインストール中..."
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
  # サブ機側インストール（--sub フラグ時はモード選択をスキップ）
  if [ "${1:-}" = "--sub" ]; then
    NMUX_MODE="standalone"
    info "サブ機モードでインストール中..."
    install_core
    save_conf
    _reload_tmux
    printf '\n%b%bnmux v%s (サブ機) インストール完了！%b\n\n' \
      "${GREEN}" "${BOLD}" "${NMUX_VERSION}" "${NC}"
    return 0
  fi

  info "nmux v${NMUX_VERSION} インストーラー (OS: ${OS})"
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
  printf '%b%bnmux v%s インストール完了！%b\n\n' \
    "${GREEN}" "${BOLD}" "${NMUX_VERSION}" "${NC}"
  printf '  モード:       %s\n' "${NMUX_MODE}"
  printf '  設定:         %s\n' "${NMUX_DIR}"
  printf '  ログ:         %s\n' "${LOG_DIR}"
  if [ "${NMUX_MODE}" = "crossmachine" ]; then
    printf '  サブ機:       %s@%s:%s\n' "${REMOTE_USER}" "${REMOTE_HOST}" "${REMOTE_PORT}"
  fi
  echo ""
  printf '  使い方: nmux help\n\n'

  case ":${PATH}:" in
    *":${BIN_DIR}:"*) : ;;
    *)
      warn "シェルを再起動するか以下を実行してください:"
      warn "  export PATH=\"\${HOME}/.nmux/bin:\${PATH}\""
      ;;
  esac
}

_reload_tmux() {
  if tmux list-sessions >/dev/null 2>&1; then
    if tmux source-file "${NMUX_DIR}/tmux.conf" 2>/dev/null; then
      info "tmux 設定をリロードしました"
    else
      warn "tmux リロードに失敗しました（手動: tmux source ~/.nmux/tmux.conf）"
    fi
  fi
}

cmd_update() {
  load_conf
  local current_ver="不明"
  if [ -f "${NMUX_DIR}/VERSION" ]; then
    current_ver=$(cat "${NMUX_DIR}/VERSION")
  fi

  info "nmux を更新中... (現在: v${current_ver})"
  mkdir -p "${NMUX_DIR}" "${BIN_DIR}" "${BACKUP_DIR}" "${LOG_DIR}" "${STATE_DIR}"

  # VERSION ファイルを soft-download（失敗時は exit せず強制更新へ）
  # download() は失敗時に error() → exit 1 するため直接 curl/wget を使う
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
      info "すでに最新バージョン (v${current_ver}) です。"
      return 0
    fi
    info "v${current_ver} → v${remote_ver} に更新します..."
  else
    warn "バージョン確認に失敗しました。強制更新します..."
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

  # Python スクリプト群（Python 3.6+ がある場合のみ更新）
  if check_python3; then
    download "${BASE_URL}/scripts/nmux-dispatch" "${BIN_DIR}/nmux-dispatch"
    chmod +x "${BIN_DIR}/nmux-dispatch"
    download "${BASE_URL}/scripts/nmux-api"      "${BIN_DIR}/nmux-api"
    chmod +x "${BIN_DIR}/nmux-api"
    download "${BASE_URL}/scripts/nmux-tui"      "${BIN_DIR}/nmux-tui"
    chmod +x "${BIN_DIR}/nmux-tui"
  fi

  download "${BASE_URL}/install.sh" "${BIN_DIR}/nmux"
  chmod +x "${BIN_DIR}/nmux"

  local new_ver
  new_ver=$(curl -fsSL "${BASE_URL}/VERSION" 2>/dev/null || printf '%s' "${NMUX_VERSION}")
  printf '%s\n' "${new_ver}" > "${NMUX_DIR}/VERSION"
  _reload_tmux
  printf '%b%bnmux v%s に更新しました！%b\n' "${GREEN}" "${BOLD}" "${new_ver}" "${NC}"
}

cmd_rollback() {
  info "利用可能なバックアップ:"
  echo ""

  local backups i=1
  backups=$(find "${BACKUP_DIR}" -name 'tmux.conf.*' -not -name '*.legacy.*' 2>/dev/null \
    | sort -r | head -10 || true)

  if [ -z "${backups}" ]; then
    warn "バックアップが見つかりません。"
    return 1
  fi

  while IFS= read -r bk; do
    printf '  %d) %s\n' "${i}" "${bk}"
    i=$((i + 1))
  done <<EOF
${backups}
EOF

  echo ""
  printf 'バックアップ番号を入力してください (1-%d): ' "$((i - 1))"
  read -r num

  local target
  target=$(printf '%s\n' "${backups}" | sed -n "${num}p")
  if [ -z "${target}" ] || [ ! -f "${target}" ]; then
    error "無効な選択: ${num}"
  fi

  cp "${target}" "${NMUX_DIR}/tmux.conf"
  _reload_tmux
  info "復元完了: ${target}"
}

cmd_uninstall() {
  info "nmux をアンインストール中..."

  # nmux-api 停止（daemon / integrated どちらでも）
  if [ -x "${BIN_DIR}/nmux-api" ]; then
    "${BIN_DIR}/nmux-api" stop 2>/dev/null || true
  fi

  # ハートビート停止
  if [ -x "${BIN_DIR}/nmux-heartbeat" ]; then
    "${BIN_DIR}/nmux-heartbeat" stop 2>/dev/null || true
  fi

  if [ -L "${TMUX_XDG_DIR}/tmux.conf" ]; then
    rm "${TMUX_XDG_DIR}/tmux.conf"
    info "シンボリックリンクを削除"
  fi

  local latest_backup
  latest_backup=$(find "${BACKUP_DIR}" -name 'tmux.conf.*' 2>/dev/null \
    | sort -r | head -1 || true)
  if [ -n "${latest_backup}" ] && [ -f "${latest_backup}" ]; then
    info "バックアップを復元: ${latest_backup}"
    mkdir -p "${TMUX_XDG_DIR}"
    cp "${latest_backup}" "${TMUX_XDG_DIR}/tmux.conf"
  fi

  remove_path
  # rm -rf の後は _log() を呼ぶ info/warn/error を使わない。
  # _log() が mkdir -p "${LOG_DIR}" するため、rm -rf 後に呼ぶと
  # ~/.nmux/logs/ が再生成される。
  rm -rf "${NMUX_DIR}"
  printf '%b[nmux]%b %s を削除しました\n' "${GREEN}" "${NC}" "${NMUX_DIR}"

  printf '\n%b%bnmux をアンインストールしました。%b\n' "${GREEN}" "${BOLD}" "${NC}"
  printf '  シェルを再起動してください。\n\n'
}

cmd_status() {
  load_conf
  local ver="未インストール"
  if [ -f "${NMUX_DIR}/VERSION" ]; then
    ver=$(cat "${NMUX_DIR}/VERSION")
  fi

  local hb_status="停止"
  if [ -f "${STATE_DIR}/heartbeat.pid" ]; then
    local hb_pid
    hb_pid=$(cat "${STATE_DIR}/heartbeat.pid")
    if kill -0 "${hb_pid}" 2>/dev/null; then
      hb_status="稼働中 (PID: ${hb_pid})"
    fi
  fi

  printf '\n%b%bnmux ステータス%b\n' "${BOLD}" "${GREEN}" "${NC}"
  printf '────────────────────────────────────────\n'
  printf '  バージョン:      %s\n' "${ver}"
  printf '  OS:              %s\n' "${OS}"
  printf '  モード:          %s\n' "${NMUX_MODE:-standalone}"
  printf '  tmux:            %s\n' "$(tmux -V 2>/dev/null || echo '未インストール')"
  printf '  クリップボード:  %s\n' "$(detect_clipboard)"
  printf '  nmux-bridge:     '
  if [ -x "${BIN_DIR}/nmux-bridge" ]; then
    printf '%b✓%b\n' "${GREEN}" "${NC}"
  else
    printf '%b✗%b\n' "${RED}" "${NC}"
  fi

  if [ "${NMUX_MODE:-standalone}" = "crossmachine" ]; then
    printf '  nmux-remote:     '
    if [ -x "${BIN_DIR}/nmux-remote" ]; then
      printf '%b✓%b\n' "${GREEN}" "${NC}"
    else
      printf '%b✗%b\n' "${RED}" "${NC}"
    fi
    printf '  サブ機:          %s@%s:%s\n' \
      "${REMOTE_USER:-未設定}" "${REMOTE_HOST:-未設定}" "${REMOTE_PORT:-22}"
  fi

  printf '  ハートビート:    %s\n' "${hb_status}"

  # nmux-api 稼働状況
  local api_status="停止"
  if [ -f "${STATE_DIR}/api.pid" ]; then
    local api_pid
    api_pid=$(cat "${STATE_DIR}/api.pid")
    if kill -0 "${api_pid}" 2>/dev/null; then
      api_status="稼働中 (PID: ${api_pid})"
    fi
  fi
  printf '  nmux-api:        %s\n' "${api_status}"

  printf '  ログ:            %s\n' "${LOG_DIR}"
  printf '\n'
}

cmd_heartbeat() {
  local subcmd="${1:-status}"
  shift || true
  if [ -x "${BIN_DIR}/nmux-heartbeat" ]; then
    "${BIN_DIR}/nmux-heartbeat" "${subcmd}" "$@"
  else
    error "nmux-heartbeat が見つかりません。nmux update を実行してください。"
  fi
}

cmd_verify() {
  local file="${1:-}"
  local sha="${2:-}"
  if [ ! -f "${file}" ]; then
    error "ファイルが見つかりません: ${file}"
  fi
  verify_file "${file}" "${sha}"
  info "検証成功: ${file}"
}

cmd_log() {
  local n="${1:-50}"
  local log_file
  log_file="${LOG_DIR}/nmux-$(date +%Y%m%d).log"
  if [ -f "${log_file}" ]; then
    tail -n "${n}" "${log_file}"
  else
    warn "ログファイルが見つかりません: ${log_file}"
  fi
}

cmd_version() {
  local ver="不明"
  if [ -f "${NMUX_DIR}/VERSION" ]; then
    ver=$(cat "${NMUX_DIR}/VERSION")
  fi
  printf 'nmux %s\n' "${ver}"
}

cmd_help() {
  cat <<'HELP'

nmux — multi-agent tmux setup (macOS / Ubuntu)

使い方: nmux <コマンド> [オプション]

コマンド:
  install              インストール（モード選択あり）
  update               最新バージョンに更新
  rollback             以前の tmux 設定を復元
  uninstall            完全削除（PATH も自動クリーンアップ）
  status               インストール状態を確認
  heartbeat <subcmd>   ハートビート管理 (start/stop/status)
  api [start|stop|status]  REST API サーバー管理（daemon モード用）
  tui                  TUI ダッシュボードを起動
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
  ~/.nmux/VERSION          バージョン

HELP
}

# ============================================================
# メイン
# ============================================================
load_conf 2>/dev/null || true

case "${1:-install}" in
  install)            cmd_install "${2:-}" ;;
  update)             cmd_update ;;
  rollback)           cmd_rollback ;;
  uninstall|remove)   cmd_uninstall ;;
  status)             cmd_status ;;
  heartbeat)          shift; cmd_heartbeat "$@" ;;
  api)                shift; "${BIN_DIR}/nmux-api" "${1:-status}" ;;
  tui)                "${BIN_DIR}/nmux-tui" ;;
  verify)             cmd_verify "${2:-}" "${3:-}" ;;
  log)                cmd_log "${2:-50}" ;;
  version|--version|-v|-V) cmd_version ;;
  help|--help|-h)     cmd_help ;;
  *)
    printf '%b[nmux]%b 不明なコマンド: %s\n' "${RED}" "${NC}" "$1" >&2
    _log ERROR "不明なコマンド: $1"
    printf '  nmux help で使い方を確認してください。\n' >&2
    exit 1
    ;;
esac
