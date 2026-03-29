# nmux-converse Feature A & B Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** nmux-converse に「スキル自動判別・学習機能（Feature A）」と「エージェント自動増設機能（Feature B）」を追加する。

**Architecture:** Feature A は各ターン前にメッセージをキーワード分析し、対応スキルをリアルタイム表示する。Feature B は各ターン後にスコアリングして増設必要性を判断、ユーザ承認を経てエージェントを追加する。両機能とも `_run_loop` に統合し、既存の会話フローを壊さない。

**Tech Stack:** bash 5.x, Python 3.6+（JSON操作・キーワードマッチ用）, tmux, nmux-bridge

---

## ファイル構成

| ファイル | 操作 | 責務 |
|---|---|---|
| `scripts/nmux-converse` | 変更 | Feature A/B 関数追加、`_run_loop` 拡張、`cmd_skill_map` 追加 |
| `scripts/skill-map.json` | 新規作成 | デフォルトキーワードマッピング（インストール時に配布） |
| `install.sh` | 変更 | skill-map.json を `~/.nmux/skill-map.json` に配置する処理を追加 |

---

## Task 1: skill-map.json デフォルトファイル作成

**Files:**
- Create: `scripts/skill-map.json`

- [ ] **Step 1: ファイルを作成する**

```bash
cat > /Users/naoto/Downloads/nmux/scripts/skill-map.json <<'EOF'
{
  "version": "1.0",
  "mappings": {
    "brainstorming": {
      "keywords": ["設計", "アーキテクチャ", "提案", "アイデア", "ブレスト", "どう思う", "design", "brainstorm"],
      "skill_path": "brainstorming"
    },
    "writing-plans": {
      "keywords": ["実装計画", "タスク分解", "ステップ", "手順", "計画", "plan", "roadmap"],
      "skill_path": "writing-plans"
    },
    "code-reviewer": {
      "keywords": ["レビュー", "コード確認", "品質", "バグ", "チェック", "review", "lint"],
      "skill_path": "code-reviewer"
    },
    "research": {
      "keywords": ["調査", "調べて", "比較", "リサーチ", "市場", "research", "investigate"],
      "skill_path": "research"
    },
    "weekly-report": {
      "keywords": ["週次", "週報", "サマリー", "振り返り", "週まとめ", "weekly", "summary"],
      "skill_path": "weekly-report"
    }
  },
  "skip": []
}
EOF
```

- [ ] **Step 2: JSON の構文確認**

```bash
python3 -c "import json; json.load(open('/Users/naoto/Downloads/nmux/scripts/skill-map.json')); print('OK')"
```

期待出力: `OK`

- [ ] **Step 3: コミット**

```bash
cd /Users/naoto/Downloads/nmux
git add scripts/skill-map.json
git commit -m "feat: add default skill-map.json for skill auto-detection"
```

---

## Task 2: Feature A — スキル検出・表示関数の追加

**Files:**
- Modify: `scripts/nmux-converse`（`_skill_map_load` / `_skill_detect` / `_skill_installed` / `_skill_show` 追加）

スクリプト末尾の `# ──` 区切り行群の直後、`_run_loop` の前に追加する。

- [ ] **Step 1: スキル検出関数ブロックを `_agent_exists` の直後（行97付近）に挿入する**

`scripts/nmux-converse` の以下の箇所を探す：
```bash
# ── 応答抽出: 送信メッセージ以降、最後のプロンプト行を除く ──
```

その直前に以下を挿入する：

```bash
# ── Feature A: スキル自動判別 ─────────────────────────────
# skill-map.json をセッション開始時に変数にキャッシュする
_skill_map_load() {
  local map_f="${NMUX_DIR}/skill-map.json"
  if [ ! -f "${map_f}" ]; then
    _SKILL_MAP_LOADED=0
    return
  fi
  _SKILL_MAP_FILE="${map_f}"
  _SKILL_MAP_LOADED=1
}

# メッセージをキーワード分析してスキル名を返す（未検出なら空文字）
_skill_detect() {
  local message="$1"
  [ "${_SKILL_MAP_LOADED:-0}" = "0" ] && return
  # skip リストのスキルは除外してマッチング
  python3 - "${message}" "${_SKILL_MAP_FILE}" <<'PYEOF' 2>/dev/null || true
import sys, json
message, map_file = sys.argv[1], sys.argv[2]
try:
    data = json.load(open(map_file))
except Exception:
    sys.exit(0)
skip = data.get('skip', [])
for skill_name, info in data.get('mappings', {}).items():
    if skill_name in skip:
        continue
    for kw in info.get('keywords', []):
        if kw in message:
            print(skill_name)
            sys.exit(0)
PYEOF
}

# スキルディレクトリまたはスキルファイルが存在するか確認
_skill_installed() {
  local skill_name="$1"
  local sd="${HOME}/.claude/skills"
  [ -d "${sd}/${skill_name}" ] || [ -f "${sd}/${skill_name}.md" ]
}

# ターンヘッダーにスキル状態を1行表示する
_skill_show() {
  local skill_name="$1"
  if [ -z "${skill_name}" ]; then
    printf "${YELLOW}[skill: ? 汎用モード]${NC}\n"
    return
  fi
  if _skill_installed "${skill_name}"; then
    printf "${GREEN}[skill: %s ✓]${NC}\n" "${skill_name}"
  else
    printf "${RED}[skill: %s ✗]${NC}\n" "${skill_name}"
  fi
}

# skill-map.json の skip 配列にスキル名を追記する
_skill_map_skip() {
  local skill_name="$1"
  local map_f="${_SKILL_MAP_FILE:-${NMUX_DIR}/skill-map.json}"
  [ -f "${map_f}" ] || return
  python3 - "${map_f}" "${skill_name}" <<'PYEOF' 2>/dev/null || true
import sys, json
map_file, skill_name = sys.argv[1], sys.argv[2]
try:
    data = json.load(open(map_file))
except Exception:
    sys.exit(0)
if skill_name not in data.get('skip', []):
    data.setdefault('skip', []).append(skill_name)
    json.dump(data, open(map_file, 'w'), ensure_ascii=False, indent=2)
PYEOF
  _info "'${skill_name}' の通知を無効化しました"
}

# スキルテンプレートを ~/.claude/skills/<name>/<name>.md に生成する
_generate_skill_template() {
  local skill_name="$1" tpl_choice="$2"
  local skills_dir="${HOME}/.claude/skills/${skill_name}"
  mkdir -p "${skills_dir}"
  local content
  case "${tpl_choice}" in
    2) content="# ${skill_name}

あなたはコードレビューの専門家です。可読性・セキュリティ・パフォーマンス・テスト・保守性の5軸で指摘します。" ;;
    3) content="# ${skill_name}

あなたは設計・ブレストの専門家です。アーキテクチャ提案・議論のファシリテーションを行います。" ;;
    *) content="# ${skill_name}

あなたは汎用アシスタントです。コーディング・相談・分析に幅広く対応します。" ;;
  esac
  printf '%s\n' "${content}" > "${skills_dir}/${skill_name}.md"
  _info "スキル '${skill_name}' を作成しました: ${skills_dir}/${skill_name}.md"
}

# スキル未存在時の選択ダイアログ（同セッション中は1度だけ表示）
_prompt_create_skill() {
  local skill_name="$1"
  # セッション内フラグで重複表示防止（変数名に記号が含まれないようエスケープ）
  local flag_var="_SKILL_SKIP_$(printf '%s' "${skill_name}" | tr '-' '_')"
  eval "local flag_val=\${${flag_var}:-0}"
  [ "${flag_val}" = "1" ] && return

  printf "\n${RED}[skill: %s ✗]${NC}\n" "${skill_name}"
  printf '"%s" スキルが見つかりません。どうしますか？\n\n' "${skill_name}"
  printf '  1) 最小テンプレートを自動生成して使う（推奨）\n'
  printf '  2) このセッションはスキルなしで続ける\n'
  printf '  3) 今後このキーワードでは表示しない\n\n'
  printf '選択 (1-3, デフォルト=1): '

  local choice
  read -r choice </dev/tty 2>/dev/null || choice="1"
  [ -z "${choice}" ] && choice="1"

  case "${choice}" in
    1)
      printf '\nスキルのベースを選んでください:\n\n'
      printf '  1) 汎用アシスタント（コーディング・相談・分析に適用）\n'
      printf '  2) コードレビュー特化（品質・セキュリティ・テスト重視）\n'
      printf '  3) 設計・ブレスト特化（アーキテクチャ・提案・議論重視）\n\n'
      printf '選択 (1-3): '
      local tpl_choice
      read -r tpl_choice </dev/tty 2>/dev/null || tpl_choice="1"
      [ -z "${tpl_choice}" ] && tpl_choice="1"
      _generate_skill_template "${skill_name}" "${tpl_choice}"
      ;;
    2)
      eval "${flag_var}=1"
      ;;
    3)
      _skill_map_skip "${skill_name}"
      eval "${flag_var}=1"
      ;;
  esac
}

# cmd_skill_map — マッピング一覧表示
cmd_skill_map() {
  local map_f="${NMUX_DIR}/skill-map.json"
  if [ ! -f "${map_f}" ]; then
    _warn "skill-map.json が見つかりません: ${map_f}"
    _warn "インストール後は ~/.nmux/skill-map.json に自動配置されます"
    return 1
  fi
  python3 - "${map_f}" "${HOME}/.claude/skills" <<'PYEOF' 2>/dev/null || true
import sys, json, os
map_file, skills_dir = sys.argv[1], sys.argv[2]
try:
    data = json.load(open(map_file))
except Exception:
    print("skill-map.json の読み込みに失敗しました")
    sys.exit(1)
skip = data.get('skip', [])
print(f"{'SKILL':<20} {'KEYWORDS':<38} INSTALLED")
print("-" * 68)
for name, info in data.get('mappings', {}).items():
    kws = ", ".join(info.get('keywords', [])[:3]) + "..."
    inst = "✓" if (os.path.isdir(f"{skills_dir}/{name}") or
                   os.path.isfile(f"{skills_dir}/{name}.md")) else "✗"
    sk = " (skip)" if name in skip else ""
    print(f"{name:<20} {kws:<38} {inst}{sk}")
PYEOF
}
```

- [ ] **Step 2: スクリプトの構文チェック**

```bash
bash -n /Users/naoto/Downloads/nmux/scripts/nmux-converse && echo "OK"
```

期待出力: `OK`

- [ ] **Step 3: コミット**

```bash
cd /Users/naoto/Downloads/nmux
git add scripts/nmux-converse
git commit -m "feat(converse): add skill auto-detection functions (Feature A)"
```

---

## Task 3: Feature A — `_run_loop` にスキル表示を統合

**Files:**
- Modify: `scripts/nmux-converse`（`_run_loop` の先頭と各ターン前を編集）

- [ ] **Step 1: `_run_loop` の先頭（`printf '%d\n' "$$" > "${pid_f}"` の直後）に初期化を追加する**

```bash
  # Feature A: skill-map をロード
  _SKILL_MAP_LOADED=0
  _SKILL_MAP_FILE=""
  _skill_map_load
```

- [ ] **Step 2: ターン処理の `_sep` / `printf Turn` ブロックを以下に差し替える**

現在のコード（`scripts/nmux-converse` 181行目付近）:
```bash
    _sep
    printf "${CYAN}${BOLD}[Turn %d/%d]${NC}  → ${BOLD}%s${NC}\n" \
      "${turn}" "${max_turns}" "${current_agent}"
    printf "${YELLOW}▶${NC} %s\n\n" "${current_msg}"
```

差し替え後:
```bash
    _sep
    printf "${CYAN}${BOLD}[Turn %d/%d]${NC}  → ${BOLD}%s${NC}\n" \
      "${turn}" "${max_turns}" "${current_agent}"
    # Feature A: スキル検出・表示
    local _detected_skill
    _detected_skill=$(_skill_detect "${current_msg}" || true)
    _skill_show "${_detected_skill}"
    # スキル未インストールかつ検出済みならダイアログ表示
    if [ -n "${_detected_skill}" ] && ! _skill_installed "${_detected_skill}"; then
      _prompt_create_skill "${_detected_skill}"
    fi
    printf "${YELLOW}▶${NC} %s\n\n" "${current_msg}"
```

- [ ] **Step 3: 構文チェック**

```bash
bash -n /Users/naoto/Downloads/nmux/scripts/nmux-converse && echo "OK"
```

- [ ] **Step 4: コミット**

```bash
cd /Users/naoto/Downloads/nmux
git add scripts/nmux-converse
git commit -m "feat(converse): integrate skill display into _run_loop (Feature A)"
```

---

## Task 4: Feature B — スコアリング・増設関数の追加

**Files:**
- Modify: `scripts/nmux-converse`（`_score_scale_up` / `_calc_recommended_count` / `_next_agent_label` / `_create_pane_for_agent` / `_add_agents` / `_recommend_scale_up` 追加）

Feature A 関数ブロックの直後に追加する。

- [ ] **Step 1: Feature B 関数ブロックを挿入する**

`cmd_skill_map` 関数の直後に以下を挿入：

```bash
# ── Feature B: エージェント自動増設 ──────────────────────
# 複数条件のスコアを計算して増設必要性を返す
# 引数: 直近タイムアウト数 直近失敗数 最大応答長 最小応答長 現在ターン 最大ターン
_score_scale_up() {
  local timeouts="$1" failures="$2" resp_max="$3" resp_min="$4"
  local current_turn="$5" max_turns="$6"
  local score=0
  [ "${timeouts}" -gt 0 ] && score=$(( score + 3 ))  # タイムアウト: +3
  [ "${failures}" -gt 0 ] && score=$(( score + 2 ))  # 失敗: +2
  # 負荷不均衡: 最大/最小比 > 3 なら +1
  if [ "${resp_min}" -gt 0 ]; then
    local ratio=$(( resp_max / resp_min ))
    [ "${ratio}" -gt 3 ] && score=$(( score + 1 ))
  fi
  # ターン節目 (50% or 75%): +1
  local half=$(( max_turns / 2 ))
  local three_q=$(( max_turns * 3 / 4 ))
  if [ "${current_turn}" -eq "${half}" ] || [ "${current_turn}" -eq "${three_q}" ]; then
    score=$(( score + 1 ))
  fi
  printf '%d' "${score}"
}

# スコアからAI推奨追加数を計算する（最大3）
_calc_recommended_count() {
  local timeouts="$1" failures="$2"
  local count=1
  [ "${timeouts}" -gt 1 ] && count=$(( count + 1 ))
  [ "${failures}" -gt 1 ] && count=$(( count + 1 ))
  [ "${count}" -gt 3 ] && count=3
  printf '%d' "${count}"
}

# 既存ラベルと重複しない次の連番ラベルを返す（agent-c, agent-d...）
_next_agent_label() {
  local existing="$*"
  local suffix
  for suffix in c d e f g h i j k l m n o p q r s t u v w x y z aa ab ac ad ae; do
    local label="agent-${suffix}"
    local found=0
    for a in ${existing}; do [ "${a}" = "${label}" ] && found=1 && break; done
    [ "${found}" = "0" ] && printf '%s' "${label}" && return
  done
  printf ''
}

# tmuxペインを新規作成してラベルを登録する
_create_pane_for_agent() {
  local label="$1"
  if [ -z "${TMUX:-}" ]; then
    _warn "tmux セッション外のためペイン自動作成をスキップしました"
    _warn "手動で tmux ペインを開き、nmux-bridge name <pane-id> ${label} を実行してください"
    return 1
  fi
  local pane_id
  pane_id=$(tmux split-window -P -F '#{pane_id}' 2>/dev/null) || {
    _warn "tmux split-window に失敗しました: ${label}"
    return 1
  }
  "${BRIDGE}" name "${pane_id}" "${label}" 2>/dev/null || {
    _warn "nmux-bridge name 登録に失敗しました: ${label} (${pane_id})"
    return 1
  }
  _info "ペイン '${label}' を作成しました (${pane_id})"
}

# count 個のエージェントを自動採番して追加する
_add_agents() {
  local name="$1" count="$2"
  shift 2
  local current_agents="$*"
  local added=0
  local i
  for i in $(seq 1 "${count}"); do
    local label
    label=$(_next_agent_label ${current_agents})
    if [ -z "${label}" ]; then
      _warn "ラベルの採番上限（agent-ae）に達しました"
      break
    fi
    # ラベルが未登録ならペイン作成
    if ! _agent_exists "${label}" 2>/dev/null; then
      _create_pane_for_agent "${label}" || continue
    fi
    # セッションに追加
    local cur
    cur=$(_get_agents "${name}")
    _conf_set "$(_sf "${name}")" AGENTS "${cur} ${label}" && \
      _info "'${label}' を追加しました" || continue
    current_agents="${current_agents} ${label}"
    added=$(( added + 1 ))
  done
  [ "${added}" -gt 0 ] && _info "計 ${added} 名のエージェントを追加しました"
}

# 増設提案ダイアログ: ユーザに数・上限を聞いて _add_agents を呼ぶ
_recommend_scale_up() {
  local name="$1" recommended="$2"
  shift 2
  local current_agents="$*"

  # 現在のエージェント数
  local current_count=0
  for a in ${current_agents}; do current_count=$(( current_count + 1 )); done

  _sep
  printf "${YELLOW}[自動増設の提案]${NC}\n"
  printf "現在の会話負荷が高まっています。\n"
  printf "エージェントを追加すると効率が上がる可能性があります。\n\n"
  printf "AIの推奨追加数: %d名\n\n" "${recommended}"
  printf "何名追加しますか？ (0でキャンセル): "

  local count
  read -r count </dev/tty 2>/dev/null || count="0"
  [ -z "${count}" ] && count="0"
  printf '%s' "${count}" | grep -qE '^[0-9]+$' || { _info "入力が無効です。キャンセルします"; return; }
  [ "${count}" = "0" ] && { _info "増設をキャンセルしました"; return; }

  local max_disp="${_SCALE_MAX:-未設定}"
  printf "最大何名まで許可しますか？ (現在の上限: %s): " "${max_disp}"
  local max_input
  read -r max_input </dev/tty 2>/dev/null || max_input="${_SCALE_MAX:-99}"
  [ -z "${max_input}" ] && max_input="${_SCALE_MAX:-99}"
  printf '%s' "${max_input}" | grep -qE '^[0-9]+$' || max_input="${_SCALE_MAX:-99}"
  _SCALE_MAX="${max_input}"

  # 上限チェック
  local after=$(( current_count + count ))
  if [ "${after}" -gt "${_SCALE_MAX}" ]; then
    local allowed=$(( _SCALE_MAX - current_count ))
    if [ "${allowed}" -le 0 ]; then
      _info "上限 (${_SCALE_MAX}名) に達しています。増設できません"
      return
    fi
    _info "上限に合わせて ${allowed} 名のみ追加します"
    count="${allowed}"
  fi

  _add_agents "${name}" "${count}" ${current_agents}
}
```

- [ ] **Step 2: 構文チェック**

```bash
bash -n /Users/naoto/Downloads/nmux/scripts/nmux-converse && echo "OK"
```

- [ ] **Step 3: コミット**

```bash
cd /Users/naoto/Downloads/nmux
git add scripts/nmux-converse
git commit -m "feat(converse): add agent auto-scale functions (Feature B)"
```

---

## Task 5: Feature B — `_run_loop` にスコアリング統合

**Files:**
- Modify: `scripts/nmux-converse`（`_run_loop` の変数初期化・ターン後処理を追加）

- [ ] **Step 1: `_run_loop` 先頭の初期化ブロックに Feature B 変数を追加する**

既存の Feature A 初期化コードの直後に以下を追加：

```bash
  # Feature B: スコアリング用状態変数
  local _recent_timeouts=0 _recent_failures=0
  local _resp_max=0 _resp_min=999999
  local _SCALE_MAX=""
```

- [ ] **Step 2: タイムアウト分岐の `continue` 前に失敗カウント更新を追加する**

現在のコード（`scripts/nmux-converse` の `# 応答待機` ブロック内）:
```bash
    if ! _bridge "${current_agent}" wait "${prompt}" "${timeout}" 2>/dev/null; then
      _warn "${current_agent} タイムアウト (${timeout}s)"
      current_msg="[タイムアウト: ${current_agent} 応答なし]"
      printf '[Turn %d] TIMEOUT: %s\n\n' "${turn}" "${current_agent}" >> "${log_f}"
      continue
    fi
```

差し替え後:
```bash
    if ! _bridge "${current_agent}" wait "${prompt}" "${timeout}" 2>/dev/null; then
      _warn "${current_agent} タイムアウト (${timeout}s)"
      current_msg="[タイムアウト: ${current_agent} 応答なし]"
      printf '[Turn %d] TIMEOUT: %s\n\n' "${turn}" "${current_agent}" >> "${log_f}"
      _recent_timeouts=$(( _recent_timeouts + 1 ))  # Feature B
      continue
    fi
```

- [ ] **Step 3: 応答表示後 `current_msg="${response}"` の直後に応答長記録とスコア評価を追加する**

現在のコード（`sleep "${interval}"` の直前）:
```bash
    current_msg="${response}"
    sleep "${interval}"
  done
```

差し替え後:
```bash
    current_msg="${response}"

    # Feature B: 応答長を記録してスコアリング
    local resp_len
    resp_len=$(printf '%s' "${response}" | wc -c | tr -d ' ')
    [ "${resp_len}" -gt "${_resp_max}" ] && _resp_max="${resp_len}"
    [ "${resp_len}" -lt "${_resp_min}" ] && _resp_min="${resp_len}"

    local scale_score
    scale_score=$(_score_scale_up \
      "${_recent_timeouts}" "${_recent_failures}" \
      "${_resp_max}" "${_resp_min}" \
      "${turn}" "${max_turns}")

    if [ "${scale_score}" -ge 5 ]; then
      local recommended
      recommended=$(_calc_recommended_count "${_recent_timeouts}" "${_recent_failures}")
      local cur_agents
      cur_agents=$(_get_agents "${name}")
      _recommend_scale_up "${name}" "${recommended}" ${cur_agents}
      # カウンタリセット（推奨後は次の蓄積サイクルへ）
      _recent_timeouts=0; _recent_failures=0
      _resp_max=0; _resp_min=999999
    fi

    sleep "${interval}"
  done
```

- [ ] **Step 4: 構文チェック**

```bash
bash -n /Users/naoto/Downloads/nmux/scripts/nmux-converse && echo "OK"
```

- [ ] **Step 5: コミット**

```bash
cd /Users/naoto/Downloads/nmux
git add scripts/nmux-converse
git commit -m "feat(converse): integrate auto-scale scoring into _run_loop (Feature B)"
```

---

## Task 6: メインディスパッチャと help へ skill-map コマンド追加

**Files:**
- Modify: `scripts/nmux-converse`（`case "$1"` と `cmd_help` を編集）

- [ ] **Step 1: `case "$1"` に `skill-map` を追加する**

現在:
```bash
case "$1" in
  start)          shift; cmd_start "$@" ;;
  stop)           shift; cmd_stop "$@" ;;
  add)            shift; cmd_add "$@" ;;
  remove)         shift; cmd_remove "$@" ;;
  list)                  cmd_list ;;
  log)            shift; cmd_log "$@" ;;
  help|--help|-h)        cmd_help ;;
  *)                     cmd_start "$@" ;;
esac
```

差し替え後:
```bash
case "$1" in
  start)          shift; cmd_start "$@" ;;
  stop)           shift; cmd_stop "$@" ;;
  add)            shift; cmd_add "$@" ;;
  remove)         shift; cmd_remove "$@" ;;
  list)                  cmd_list ;;
  log)            shift; cmd_log "$@" ;;
  skill-map)             cmd_skill_map ;;
  help|--help|-h)        cmd_help ;;
  *)                     cmd_start "$@" ;;
esac
```

- [ ] **Step 2: `cmd_help` の「コマンド:」セクションに `skill-map` を追記する**

現在:
```
  log       会話ログを表示する
```

差し替え後:
```
  log       会話ログを表示する
  skill-map スキルマッピング一覧を表示する
```

- [ ] **Step 3: 構文チェック**

```bash
bash -n /Users/naoto/Downloads/nmux/scripts/nmux-converse && echo "OK"
```

- [ ] **Step 4: コミット**

```bash
cd /Users/naoto/Downloads/nmux
git add scripts/nmux-converse
git commit -m "feat(converse): add skill-map subcommand to dispatcher and help"
```

---

## Task 7: install.sh に skill-map.json 配置処理を追加

**Files:**
- Modify: `install.sh`（`install_core` 関数と `cmd_update` 関数）

- [ ] **Step 1: install.sh の `install_core` 関数内、nmux-converse インストール行の直後に以下を追加する**

現在（`install_core` 内）:
```bash
  info "nmux-converse をインストール中..."
  download "${BASE_URL}/scripts/nmux-converse" "${BIN_DIR}/nmux-converse"
  chmod +x "${BIN_DIR}/nmux-converse"
```

直後に追加:
```bash
  # skill-map.json を配置（既存ファイルは上書きしない）
  if [ ! -f "${NMUX_DIR}/skill-map.json" ]; then
    download "${BASE_URL}/scripts/skill-map.json" "${NMUX_DIR}/skill-map.json"
    info "skill-map.json を配置しました: ${NMUX_DIR}/skill-map.json"
  fi
```

- [ ] **Step 2: `cmd_update` 関数内、nmux-converse ダウンロード行の直後にも同様に追加する**

`cmd_update` 内で nmux-converse をダウンロードしている箇所の直後に追加:
```bash
  # skill-map.json（存在しない場合のみ配置）
  if [ ! -f "${NMUX_DIR}/skill-map.json" ]; then
    download "${BASE_URL}/scripts/skill-map.json" "${NMUX_DIR}/skill-map.json"
  fi
```

- [ ] **Step 3: install.sh の構文チェック**

```bash
bash -n /Users/naoto/Downloads/nmux/install.sh && echo "OK"
```

- [ ] **Step 4: コミット**

```bash
cd /Users/naoto/Downloads/nmux
git add install.sh
git commit -m "feat(install): deploy skill-map.json during install and update"
```

---

## Task 8: ローカルインストール・動作確認

- [ ] **Step 1: スクリプトをローカルの nmux bin にコピーする**

```bash
cp /Users/naoto/Downloads/nmux/scripts/nmux-converse ~/.nmux/bin/nmux-converse
cp /Users/naoto/Downloads/nmux/scripts/skill-map.json ~/.nmux/skill-map.json
```

- [ ] **Step 2: 構文チェック（インストール先）**

```bash
bash -n ~/.nmux/bin/nmux-converse && echo "OK"
```

- [ ] **Step 3: skill-map コマンドの動作確認**

```bash
nmux-converse skill-map
```

期待出力（例）:
```
SKILL                KEYWORDS                               INSTALLED
--------------------------------------------------------------------
brainstorming        設計, アーキテクチャ, 提案...          ✓ or ✗
writing-plans        実装計画, タスク分解, ステップ...       ✓ or ✗
code-reviewer        レビュー, コード確認, 品質...           ✓ or ✗
research             調査, 調べて, 比較...                   ✓ or ✗
weekly-report        週次, 週報, サマリー...                 ✓ or ✗
```

- [ ] **Step 4: skill-detect 単体テスト（python3 インライン）**

```bash
python3 - "コードをレビューして" ~/.nmux/skill-map.json <<'PYEOF'
import sys, json
message, map_file = sys.argv[1], sys.argv[2]
data = json.load(open(map_file))
skip = data.get('skip', [])
for name, info in data.get('mappings', {}).items():
    if name in skip: continue
    for kw in info.get('keywords', []):
        if kw in message:
            print(f"Detected: {name}")
            sys.exit(0)
print("No match")
PYEOF
```

期待出力: `Detected: code-reviewer`

- [ ] **Step 5: _score_scale_up 単体テスト（bash inline）**

```bash
# タイムアウト2回 + 失敗1回 = スコア5以上になることを確認
bash -c '
source ~/.nmux/bin/nmux-converse 2>/dev/null || true
score=$(_score_scale_up 2 1 1000 100 5 10)
echo "score=${score}"
[ "${score}" -ge 5 ] && echo "PASS: score >= 5" || echo "FAIL: score=${score}"
' 2>/dev/null || echo "(source不可のため個別テストは手動で)"
```

---

## Task 9: 25/25 評価ループ

評価は実装完了後、以下の5軸×5段階（25点満点）で行う。**25点未満は修正して再評価。**

| 軸 | 評価基準 |
|---|---|
| 機能完全性 | Feature A/B の全成功基準が満たされているか |
| コード品質 | bash best practices、set -euo pipefail との整合性 |
| UX | ダイアログのデフォルト値・キャンセル・エラー時の案内 |
| 安全性 | eval インジェクション・ファイル競合・tmux外での安全な動作 |
| 保守性 | 既存コードへの影響最小化・関数の単一責任 |

- [ ] 評価を実施して25/25を確認する
- [ ] 不足があれば修正してから再評価する

---

## Task 10: GitHub push

- [ ] **Step 1: 全コミットを確認する**

```bash
cd /Users/naoto/Downloads/nmux
git log --oneline -10
```

- [ ] **Step 2: リモートに push する**

```bash
git push origin main
```
