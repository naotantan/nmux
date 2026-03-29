#!/usr/bin/env bash
# nmux i18n — 中文 (Chinese Simplified)
# 由 install.sh 加载

# ── 安装 ──────────────────────────────────────────────────────
L_INSTALLING_PKG="正在安装 %s (%s)..."
L_PKG_INSTALL_FAIL="安装 %s 失败，请手动安装。"
L_BREW_REQUIRED="macOS 需要 Homebrew，请从 https://brew.sh 安装。"
L_CLIPBOARD_INSTALLING="正在安装剪贴板工具..."
L_CLIPBOARD_FAIL="安装 %s 失败"
L_TMUX_UNSUPPORTED="tmux %s 不受支持，需要 tmux 3.2+。"
L_TMUX_OK="tmux %s — 正常"
L_SHA256_SKIP="未找到 sha256sum，跳过验证。"
L_VERIFY_FAIL="文件验证失败：%s"
L_DOWNLOAD_FAIL="下载失败：%s"
L_CURL_WGET_REQUIRED="需要 curl 或 wget，请安装其中一个。"
L_BACKUP="备份：%s"
L_PATH_APPENDING="正在将 PATH 添加到 %s..."
L_PATH_REMOVED="已从 %s 中删除 PATH 配置"

# ── 模式选择 ──────────────────────────────────────────────────
L_SELECT_MODE="请选择安装模式："
L_MODE_STANDALONE="  1) 单机模式    — 仅使用本机进行 AI 智能体通信"
L_MODE_CROSSMACHINE="  2) 跨机器模式  — 主机 + 子机（SSH 连接）"
L_MODE_PROMPT="请选择 [1/2]（默认：1）："
L_MODE_SELECTED="模式：%s"

# ── 子机连接配置 ──────────────────────────────────────────────
L_REMOTE_CONF_HEADER="请输入子机连接信息："
L_REMOTE_HOST_PROMPT="  主机名或 IP 地址："
L_REMOTE_HOST_REQUIRED="主机名不能为空。"
L_REMOTE_USER_PROMPT="  SSH 用户名 [%s]："
L_REMOTE_PORT_PROMPT="  SSH 端口 [22]："
L_REMOTE_CONF_INFO="连接信息：%s@%s:%s"
L_SSH_TESTING="正在测试 SSH 连接..."
L_SSH_OK="SSH 连接正常"
L_SSH_FAIL="SSH 连接失败，请检查设置。"
L_SSH_FAIL_HINT="  请确认 ~/.ssh/config 配置或使用 ssh-copy-id 部署密钥。"
L_SSH_CONTINUE="  是否继续？[y/N]："
L_INSTALL_ABORTED="安装已中止。"
L_INSTALL_SUB_PROMPT="  是否也在子机上安装 nmux？[Y/n]："
L_INSTALL_SUB_SKIP="已跳过子机安装。"
L_INSTALL_SUB_RUNNING="正在子机 (%s) 上安装 nmux..."
L_INSTALL_SUB_DONE="子机安装完成"
L_INSTALL_SUB_FAIL="子机安装失败，请手动安装。"

# ── 核心安装 ──────────────────────────────────────────────────
L_INSTALLING_TMUX="正在安装 tmux..."
L_DOWNLOADING="正在下载 %s..."
L_INSTALLING="正在安装 %s..."
L_SKILL_MAP_PLACED="skill-map.json 已放置至：%s"
L_PYTHON_SKIP="未找到 Python 3.6+，跳过 nmux-dispatch / nmux-api / nmux-tui。"
L_PYTHON_SKIP_HINT="如需后续手动添加：brew install python3（macOS）或 apt-get install python3（Linux）"
L_SELECT_API_MODE="? 请选择 nmux-api 运行模式："
L_API_MODE_INTEGRATED="  1) integrated  — 与 tmux 会话联动（推荐，默认）"
L_API_MODE_DAEMON="  2) daemon      — 作为独立后台进程运行"
L_API_MODE_PROMPT="模式 [1/2，默认：1]："

# ── 完成消息 ──────────────────────────────────────────────────
L_INSTALL_SUB_COMPLETE="nmux v%s（子机）安装完成！"
L_INSTALLER_HEADER="nmux v%s 安装程序（OS：%s）"
L_INSTALL_COMPLETE="nmux v%s 安装完成！"
L_INFO_MODE="  模式：         %s"
L_INFO_DIR="  配置目录：     %s"
L_INFO_LOG="  日志目录：     %s"
L_INFO_REMOTE="  子机：         %s@%s:%s"
L_INFO_USAGE="  使用方法：nmux help"
L_PATH_RELOAD="请重启 Shell 或执行："

# ── 更新 / 回滚 ───────────────────────────────────────────────
L_UPDATING="正在更新 nmux...（当前：v%s）"
L_ALREADY_LATEST="已是最新版本（v%s）。"
L_UPDATING_TO="正在从 v%s 更新至 v%s..."
L_VERSION_CHECK_FAIL="版本检查失败，强制更新..."
L_UPDATE_COMPLETE="nmux v%s 更新完成！"
L_ROLLBACK_HEADER="可用备份列表："
L_NO_BACKUP="未找到备份。"
L_ROLLBACK_PROMPT="请输入备份编号（1-%d）："
L_ROLLBACK_INVALID="无效选择：%s"
L_ROLLBACK_DONE="已恢复：%s"

# ── 卸载 ──────────────────────────────────────────────────────
L_UNINSTALLING="正在卸载 nmux..."
L_SYMLINK_REMOVED="符号链接已删除"
L_BACKUP_RESTORED="已恢复备份：%s"
L_DIR_REMOVED="已删除 %s"
L_UNINSTALL_COMPLETE="nmux 已卸载。"
L_RESTART_SHELL="  请重启 Shell。"

# ── 状态 ──────────────────────────────────────────────────────
L_STATUS_HEADER="nmux 状态"
L_STATUS_VERSION="  版本：         %s"
L_STATUS_OS="  OS：           %s"
L_STATUS_MODE="  模式：         %s"
L_STATUS_TMUX="  tmux：         %s"
L_STATUS_CLIPBOARD="  剪贴板：       %s"
L_STATUS_BRIDGE="  nmux-bridge：  "
L_STATUS_REMOTE="  nmux-remote：  "
L_STATUS_SUB="  子机：         %s@%s:%s"
L_STATUS_HEARTBEAT="  心跳检测：     %s"
L_STATUS_API="  nmux-api：     %s"
L_STATUS_LOG="  日志：         %s"
L_STATUS_RUNNING="运行中 (PID: %s)"
L_STATUS_STOPPED="已停止"
L_STATUS_NOT_INSTALLED="未安装"
L_STATUS_NOT_SET="未设置"

# ── 其他 ──────────────────────────────────────────────────────
L_HEARTBEAT_NOT_FOUND="未找到 nmux-heartbeat，请执行：nmux update"
L_FILE_NOT_FOUND="文件不存在：%s"
L_VERIFY_OK="验证成功：%s"
L_LOG_NOT_FOUND="日志文件不存在：%s"
L_UNKNOWN_CMD="未知命令：%s"
L_UNKNOWN_CMD_HINT="  请执行：nmux help"
L_TMUX_RELOAD_OK="tmux 配置已重新加载"
L_TMUX_RELOAD_FAIL="tmux 重载失败（手动执行：tmux source ~/.nmux/tmux.conf）"

# ── 帮助 ──────────────────────────────────────────────────────
L_HELP=$(cat <<'HELP'

nmux — 多智能体 tmux 编排工具（macOS / Ubuntu）

用法：nmux <命令> [选项]

命令：
  install              安装（含模式和语言选择）
  update               更新到最新版本
  rollback             恢复之前的 tmux 配置
  uninstall            完全卸载（自动清理 PATH）
  status               查看安装状态
  heartbeat <subcmd>   管理心跳检测（start/stop/status）
  api [start|stop|status]  管理 REST API 服务器（daemon 模式）
  tui                  启动 TUI 仪表盘
  converse [opts]      AI 与 AI 实时对话
  verify <file> <sha>  验证文件 sha256
  log [N]              显示最近 N 行日志
  version              显示版本
  help                 显示此帮助

环境变量：
  NMUX_DEBUG=1         启用调试日志

文件：
  ~/.nmux/nmux.conf        配置文件
  ~/.nmux/tmux.conf        tmux 配置
  ~/.nmux/bin/             CLI 工具
  ~/.nmux/backups/         配置备份
  ~/.nmux/logs/            日志（按天）
  ~/.nmux/state/           状态文件
  ~/.nmux/skill-map.json   技能映射

HELP
)
