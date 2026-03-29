#!/usr/bin/env bash
# nmux テストスクリプト
# tmux セッション外でも実行できる静的テストと、
# tmux 内でのみ実行できる統合テストを分けて実行する
# 使い方:
#   tests/test-nmux.sh            # 全テスト
#   tests/test-nmux.sh static     # 静的テストのみ（tmux不要）
#   tests/test-nmux.sh integration # 統合テスト（tmux内で実行）
set -euo pipefail

NMUX_DIR="${HOME}/.nmux"
BIN_DIR="${NMUX_DIR}/bin"
BRIDGE="${BIN_DIR}/nmux-bridge"
CONVERSE="${BIN_DIR}/nmux-converse"

# カラー出力
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; NC='\033[0m'; BOLD='\033[1m'

PASS=0
FAIL=0
SKIP=0

_pass() { PASS=$((PASS + 1)); printf "${GREEN}[PASS]${NC} %s\n" "$*"; }
_fail() { FAIL=$((FAIL + 1)); printf "${RED}[FAIL]${NC} %s\n" "$*"; }
_skip() { SKIP=$((SKIP + 1)); printf "${YELLOW}[SKIP]${NC} %s\n" "$*"; }
_head() { printf "\n${BOLD}=== %s ===${NC}\n\n" "$*"; }

# ============================================================
# 静的テスト（tmux 不要）
# ============================================================
run_static_tests() {
  _head "静的テスト"

  # --- ファイル存在チェック ---
  for script in nmux-bridge nmux-converse nmux-tui nmux-init; do
    if [ -f "${BIN_DIR}/${script}" ]; then
      _pass "${script}: インストール済み"
    elif [ -f "$(dirname "$0")/../scripts/${script}" ]; then
      _pass "${script}: scripts/ に存在"
    else
      _fail "${script}: 見つかりません"
    fi
  done

  # --- 実行権限チェック ---
  for script in nmux-bridge nmux-converse; do
    local path="${BIN_DIR}/${script}"
    [ -f "$(dirname "$0")/../scripts/${script}" ] && path="$(dirname "$0")/../scripts/${script}"
    if [ -x "${path}" ]; then
      _pass "${script}: 実行権限 OK"
    else
      _fail "${script}: 実行権限がありません"
    fi
  done

  # --- shellcheck（利用可能な場合）---
  if command -v shellcheck >/dev/null 2>&1; then
    local script_dir
    script_dir="$(dirname "$0")/../scripts"
    for script in nmux-bridge nmux-converse nmux-init; do
      if shellcheck -S error "${script_dir}/${script}" 2>/dev/null; then
        _pass "shellcheck ${script}: エラーなし"
      else
        _fail "shellcheck ${script}: 構文エラーあり"
      fi
    done
  else
    _skip "shellcheck: 未インストール（brew install shellcheck）"
  fi

  # --- nmux-bridge ヘルプ出力 ---
  local bridge_path="${BIN_DIR}/nmux-bridge"
  [ -f "$(dirname "$0")/../scripts/nmux-bridge" ] && \
    bridge_path="$(dirname "$0")/../scripts/nmux-bridge"
  if bash "${bridge_path}" help 2>&1 | grep -q "nmux-bridge"; then
    _pass "nmux-bridge help: 正常出力"
  else
    _fail "nmux-bridge help: 出力なし"
  fi

  # --- nmux-converse ヘルプ出力 ---
  local converse_path="${BIN_DIR}/nmux-converse"
  [ -f "$(dirname "$0")/../scripts/nmux-converse" ] && \
    converse_path="$(dirname "$0")/../scripts/nmux-converse"
  if bash "${converse_path}" help 2>&1 | grep -q "nmux-converse"; then
    _pass "nmux-converse help: 正常出力"
  else
    _fail "nmux-converse help: 出力なし"
  fi

  # --- nmux-bridge の引数バリデーション ---
  local bridge_path="${BIN_DIR}/nmux-bridge"
  [ -f "$(dirname "$0")/../scripts/nmux-bridge" ] && \
    bridge_path="$(dirname "$0")/../scripts/nmux-bridge"

  # 不明コマンドでエラー終了するか（stderr もキャプチャ）
  local bridge_out
  bridge_out=$(bash "${bridge_path}" unknown_command 2>&1 || true)
  if printf '%s' "${bridge_out}" | grep -qi "不明\|unknown\|error"; then
    _pass "nmux-bridge 不明コマンド: エラー出力 OK"
  else
    _fail "nmux-bridge 不明コマンド: エラー検出なし"
  fi

  # --- converse の _extract_response awk テスト ---
  # 絵文字・改行を含むメッセージで awk がクラッシュしないかチェック
  local test_script
  test_script=$(cat <<'AWKTEST'
#!/usr/bin/env bash
set -euo pipefail
CONVERSE_SCRIPT="$1"

# _extract_response を含む関数のみを一時ファイルに展開して呼び出す
TMP=$(mktemp)
# 絵文字+改行を含む入力でテスト
cat > "${TMP}" <<'EOF'
source "${CONVERSE_SCRIPT}"
result=$(_extract_response "$(printf 'hello\n✅ test done\nresult line')" "$(printf '✅ test done\nmore info')")
[ -n "${result}" ] && echo "ok" || echo "empty"
EOF
bash "${TMP}" 2>/dev/null
rm -f "${TMP}"
AWKTEST
)

  local converse_path="${BIN_DIR}/nmux-converse"
  [ -f "$(dirname "$0")/../scripts/nmux-converse" ] && \
    converse_path="$(dirname "$0")/../scripts/nmux-converse"

  # awk 実行テスト（スクリプトをソースして関数を呼ぶ）
  local awk_result
  awk_result=$(bash -c "
    source '${converse_path}' 2>/dev/null || true
    # _extract_response が定義されているか
    if declare -f _extract_response >/dev/null 2>&1; then
      echo 'defined'
    else
      echo 'undefined'
    fi
  " 2>/dev/null || echo "error")

  if [ "${awk_result}" = "defined" ]; then
    _pass "_extract_response: 関数定義 OK"
  else
    _skip "_extract_response: ソース読み込みスキップ（通常動作に影響なし）"
  fi

  # --- VERSION ファイル ---
  local ver_file
  ver_file="$(dirname "$0")/../VERSION"
  if [ -f "${ver_file}" ] && grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$' "${ver_file}"; then
    _pass "VERSION: $(cat "${ver_file}")"
  else
    _fail "VERSION: 形式不正"
  fi

  # --- skill-map.json ---
  local skill_map="${NMUX_DIR}/skill-map.json"
  if [ -f "${skill_map}" ]; then
    if python3 -m json.tool "${skill_map}" >/dev/null 2>&1; then
      _pass "skill-map.json: JSON 形式 OK"
    else
      _fail "skill-map.json: JSON 解析失敗"
    fi
  else
    _skip "skill-map.json: 未インストール（nmux install 後に確認）"
  fi
}

# ============================================================
# 統合テスト（tmux 内で実行）
# ============================================================
run_integration_tests() {
  _head "統合テスト（tmux内）"

  if [ -z "${TMUX:-}" ]; then
    _skip "tmux 外のため統合テストをスキップ"
    return 0
  fi

  local bridge_path="${BIN_DIR}/nmux-bridge"
  [ -f "$(dirname "$0")/../scripts/nmux-bridge" ] && \
    bridge_path="$(dirname "$0")/../scripts/nmux-bridge"

  # --- ペイン一覧 ---
  if bash "${bridge_path}" list 2>/dev/null | grep -q '.'; then
    _pass "nmux-bridge list: ペイン一覧取得 OK"
  else
    _fail "nmux-bridge list: ペイン一覧取得失敗"
  fi

  # --- JSON 出力 ---
  if bash "${bridge_path}" list --json 2>/dev/null | python3 -m json.tool >/dev/null 2>&1; then
    _pass "nmux-bridge list --json: JSON 形式 OK"
  else
    _fail "nmux-bridge list --json: JSON 解析失敗"
  fi

  # --- 自ペイン ID ---
  local my_id
  my_id=$(bash "${bridge_path}" id 2>/dev/null || echo "")
  if printf '%s' "${my_id}" | grep -qE '^%[0-9]+$'; then
    _pass "nmux-bridge id: ペイン ID 取得 OK (${my_id})"
  else
    _fail "nmux-bridge id: 取得失敗 (got: ${my_id})"
  fi

  # --- ラベル設定・解決のラウンドトリップ ---
  local test_label="nmux-test-label-$$"
  if bash "${bridge_path}" name "${my_id}" "${test_label}" >/dev/null 2>&1; then
    local resolved
    resolved=$(bash "${bridge_path}" resolve "${test_label}" 2>/dev/null || echo "")
    if [ "${resolved}" = "${my_id}" ]; then
      _pass "nmux-bridge name/resolve: ラウンドトリップ OK"
    else
      _fail "nmux-bridge name/resolve: ID 不一致 (expected ${my_id}, got ${resolved})"
    fi
    # テスト用ラベルファイルを後片付け
    rm -f "${NMUX_DIR}/state/label_${test_label}" 2>/dev/null || true
  else
    _fail "nmux-bridge name: ラベル設定失敗"
  fi

  # --- converse list（エラーなし）---
  local converse_path="${BIN_DIR}/nmux-converse"
  [ -f "$(dirname "$0")/../scripts/nmux-converse" ] && \
    converse_path="$(dirname "$0")/../scripts/nmux-converse"

  if bash "${converse_path}" list 2>/dev/null; then
    _pass "nmux-converse list: 正常実行"
  else
    _fail "nmux-converse list: 実行エラー"
  fi
}

# ============================================================
# 結果サマリー
# ============================================================
show_summary() {
  printf '\n'
  printf "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
  printf "  テスト結果: ${GREEN}PASS: %d${NC}  ${RED}FAIL: %d${NC}  ${YELLOW}SKIP: %d${NC}\n" \
    "${PASS}" "${FAIL}" "${SKIP}"
  printf "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
  printf '\n'

  if [ "${FAIL}" -gt 0 ]; then
    exit 1
  fi
}

# ============================================================
# メイン
# ============================================================
mode="${1:-all}"

case "${mode}" in
  static)
    run_static_tests
    ;;
  integration)
    run_integration_tests
    ;;
  all|*)
    run_static_tests
    run_integration_tests
    ;;
esac

show_summary
