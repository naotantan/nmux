# nmux v2.0.0

**smux 的增强版分支** — 在 tmux 上协调、对话和并行运行多个 AI 智能体的编排工具

[日本語](README.md) | [English](README.en.md)

---

## 概述

nmux 用于控制在 tmux 窗格中运行的 AI 智能体（如 Claude Code）。
您可以在单台机器上并行运行多个智能体，通过 SSH 操作远程机器上的智能体，或让智能体之间进行实时对话。

```
┌─────────────────────────────────────────────────────┐
│  nmux 生态系统                                       │
│                                                     │
│  nmux-bridge   ←→  本地窗格通信（核心基础）          │
│  nmux-remote   ←→  SSH 跨机器通信                   │
│  nmux-converse  ─→  AI 与 AI 实时对话               │
│  nmux-dispatch  ─→  JSON 任务并行分发执行            │
│  nmux-api      ←→  HTTP REST API（外部工具集成）     │
│  nmux-tui       ─→  TUI 仪表盘（监控）              │
│  nmux-heartbeat ─→  子机存活检测                    │
└─────────────────────────────────────────────────────┘
```

### 支持环境

| 主机 | 子机 |
|-----|------|
| macOS   | macOS  |
| macOS   | Ubuntu |
| Ubuntu  | macOS  |
| Ubuntu  | Ubuntu |

---

## 安装

```bash
curl -fsSL https://raw.githubusercontent.com/naotantan/nmux/main/install.sh | bash
```

安装时选择**语言**和**运行模式**：

```
请选择语言:
  1) 日本語
  2) English
  3) 中文（简体）

请选择安装模式:
  1) 单机模式    — 仅使用本机
  2) 跨机器模式  — 主机 + 子机（SSH 连接）
```

如果系统安装了 Python 3.6+，将自动安装 nmux-dispatch / nmux-api / nmux-tui / nmux-converse。

---

## 快速开始（5分钟）

### 第 1 步：在 tmux 中打开窗格并分配标签

```bash
nmux-bridge name nmux:1.1 agent-a
nmux-bridge name nmux:1.2 agent-b

nmux-bridge list   # 确认标签
```

### 第 2 步：向 agent-b 发送消息

```bash
nmux-bridge type agent-b "你好，这是一条测试消息"
nmux-bridge keys agent-b Enter
nmux-bridge read agent-b 20
```

### 第 3 步：让两个智能体进行对话

```bash
nmux-converse agent-a agent-b "讨论 AI 的未来"
```

---

## 主要功能

| 功能 | 命令 | 说明 |
|------|------|------|
| 本地窗格通信 | `nmux-bridge` | tmux 窗格的输入/输出控制（所有功能的核心基础） |
| 跨机器通信 | `nmux-remote` | 通过 SSH 远程控制子机窗格 |
| AI 对话 | `nmux-converse` | 智能体之间的实时对话，支持技能自动识别 |
| 任务并行分发 | `nmux-dispatch` | 基于 JSON 定义自动解析依赖关系并并行执行 |
| REST API | `nmux api` | 通过 HTTP 与外部工具（n8n/GitHub Actions 等）集成 |
| TUI 监控 | `nmux tui` | 所有窗格状态的实时仪表盘 |
| 存活检测 | `nmux heartbeat` | 子机监控（1秒间隔，状态栏显示） |
| 版本管理 | `nmux update / rollback` | 更新到最新版本 / 恢复上一版本 |

---

## nmux CLI

```
nmux install                     # 安装（含模式选择）
nmux update                      # 更新到最新版本
nmux rollback                    # 恢复上一版本
nmux uninstall                   # 完全卸载
nmux status                      # 查看当前状态
nmux heartbeat start/stop/status # 管理存活检测
nmux api start/stop/status       # 管理 REST API 服务器
nmux tui                         # 启动 TUI 仪表盘
nmux converse [opts]             # 启动 AI 对话
nmux log [N]                     # 查看日志（默认：最近 100 行）
nmux version                     # 查看版本
```

---

## 智能体配置

### 单机（无数量限制）

```bash
nmux-bridge name nmux:1.1 agent-a
nmux-bridge name nmux:1.2 agent-b
nmux-bridge name nmux:1.3 agent-c

nmux-bridge list   # 列出已注册的智能体
```

### 多机器（通过 SSH）

```bash
# 建议在 ~/.ssh/config 中添加主机别名
# Host sub1  HostName 192.168.1.101

# 查看子机上的智能体列表
ssh sub1 "~/.nmux/bin/nmux-bridge list"

# 向远程智能体发送消息
ssh sub1 "~/.nmux/bin/nmux-bridge type agent-c '请执行任务'"
ssh sub1 "~/.nmux/bin/nmux-bridge keys agent-c Enter"
```

### AI-A 向 AI-B 发出指令（基本模式）

```bash
# 1. 获取 Read Guard（标记新输出的起始位置）
nmux-bridge read agent-b 20

# 2. 发送指令
nmux-bridge type agent-b "请执行以下任务：..."
nmux-bridge keys agent-b Enter

# 3. 等待完成（最多等待 60 秒，直到出现 $ 提示符）
nmux-bridge wait agent-b '\$' 60

# 4. 读取结果
nmux-bridge read agent-b 50
```

---

## nmux-bridge（本地窗格通信）

所有 nmux 功能的核心基础。

```
nmux-bridge list [--json]                              # 列出窗格（--json 输出 JSON 格式）
nmux-bridge read  <target> [lines]                     # 读取窗格内容
nmux-bridge type  <target> <text>                      # 输入文本（不含 Enter）
nmux-bridge keys  <target> <key>...                    # 发送特殊键（Enter、Tab、Escape 等）
nmux-bridge message <target> <text>                    # 发送带发送方信息的消息
nmux-bridge name  <target> <label>                     # 为窗格分配标签
nmux-bridge wait  <target> [pattern] [timeout] [--then <cmd>]  # 等待模式匹配，匹配后执行命令
```

**环境变量：**

| 变量 | 默认值 | 说明 |
|-----|-------|------|
| `NMUX_READ_MARK_TTL` | 60 | Read Guard 有效期（秒） |
| `NMUX_DEBUG` | 0 | 设置为 `1` 启用调试日志 |

---

## nmux-converse（AI 与 AI 实时对话）

让 tmux 窗格中的 AI 智能体进行实时对话。
采用轮询方式，将每个智能体的响应作为下一个智能体的输入。

### 基本用法

```bash
# 简单启动（2个智能体，10轮对话）
nmux-converse agent-a agent-b "讨论 AI 的未来"

# 指定会话名称和轮次数量
nmux-converse start -n debate -t 20 agent-a agent-b -m "量子计算的挑战"

# 在后台运行
nmux-converse start --daemon -n bg agent-a agent-b -m "代码审查"
tail -f ~/.nmux/state/converse/bg.log
```

### 包含远程智能体

```bash
# 与子机上的智能体进行对话
nmux-converse agent-a sub1/agent-b "讨论设计方案"

# 指定用户名和端口
nmux-converse agent-a user@sub1:2222/agent-b "讨论"
```

智能体格式：`[user@]host[:port]/label`

### 动态添加/删除智能体

无需停止对话即可添加或删除智能体，下一轮立即生效。

```bash
nmux-converse add    debate agent-c   # 添加（下一轮参与）
nmux-converse remove debate agent-b   # 删除（最少需要 2 个）
```

### 技能自动识别（功能 A）

实时分析每条消息，自动检测并建议合适的 Claude Code 技能（斜杠命令）。请求代码审查时自动识别 `code-reviewer`，请求调查时自动识别 `research`。

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[Turn 3/10]  → agent-b
[skill: code-reviewer ✓]
▶ 请审查代码
```

如果检测到的技能未安装，将显示对话框：

```
未找到 "code-reviewer" 技能。您想怎么做？

  1) 自动生成最小模板（推荐）
  2) 本次会话不使用技能继续
  3) 以后不再显示此通知

请选择 (1-3, 默认=1):
```

**查看和编辑技能映射：**

```bash
nmux-converse skill-map
```

```
SKILL                KEYWORDS                               INSTALLED
--------------------------------------------------------------------
brainstorming        设计, 架构, 提案...                    ✓
code-reviewer        审查, 代码检查, 质量...                 ✗
research             调查, 比较, 研究...                    ✓
```

编辑 `~/.nmux/skill-map.json` 可添加自定义关键词：

```json
{
  "version": "1.0",
  "mappings": {
    "my-skill": {
      "keywords": ["自定义关键词", "custom keyword"],
      "skill_path": "my-skill"
    }
  },
  "skip": []
}
```

将技能名称添加到 `skip` 数组可禁用该技能的通知。

### 智能体自动扩容（功能 B）

自动监控对话中的超时、失败和响应不均衡情况。当负载升高时，显示对话框："是否添加更多智能体？"——确认后自动创建 tmux 窗格并立即加入会话。

**评分逻辑：**

| 条件 | 加分 |
|------|------|
| 发生超时 | +3 |
| 响应失败 | +2 |
| 负载不均衡（最大/最小比 > 3） | +1 |
| 轮次节点（50% / 75%） | +1 |

评分 ≥ 5 时显示扩容对话框：

```
[自动扩容建议]
当前对话负载较高。
AI 推荐新增数量：2个

要添加几个智能体？(0 取消): 2
最多允许几个智能体？(当前上限：未设置): 5
```

标签自动按 `agent-c`、`agent-d`、`agent-e`... 顺序分配。

### 会话管理

```bash
nmux-converse list              # 列出所有会话（● = 运行中）
nmux-converse stop  <name>      # 停止会话
nmux-converse log   <name> 50   # 显示日志最近 50 行
nmux-converse skill-map         # 显示技能映射
```

### 选项列表（start）

| 选项 | 默认值 | 说明 |
|-----|-------|------|
| `-n, --name <name>` | `sess-HHMMSS` | 会话名称 |
| `-t, --turns <N>` | 10 | 对话轮次数 |
| `--timeout <sec>` | 120 | 响应超时秒数 |
| `--lines <N>` | 80 | 每次响应读取的行数 |
| `--prompt <pattern>` | `[$%#>❯]` | 提示符检测模式 |
| `--interval <sec>` | 1 | 轮次间等待秒数 |
| `--ssh-port <port>` | 22 | 默认 SSH 端口 |
| `--daemon` | — | 后台运行 |
| `-m, --message <text>` | — | 初始话题（必填） |

---

## nmux-dispatch（JSON 任务并行分发）

需要 Python 3.6+。自动解析依赖关系并将任务并行分发给多个智能体。

```bash
nmux-dispatch tasks.json            # 执行
nmux-dispatch tasks.json --dry-run  # 仅预览执行计划
```

**任务定义示例（`tasks.json`）：**

```json
{
  "defaults": { "timeout": 120, "on_failure": "abort" },
  "tasks": [
    { "id": "plan",  "agent": "agent-a", "message": "制定设计方案" },
    { "id": "impl",  "agent": "agent-b", "message": "实现方案", "depends_on": ["plan"] },
    { "id": "test",  "agent": "agent-c", "message": "运行测试", "depends_on": ["impl"] }
  ]
}
```

无依赖关系的任务并行执行，依赖关系通过拓扑排序自动解析。

---

## nmux-api（HTTP REST API）

需要 Python 3.6+。可从 n8n、GitHub Actions 或自定义脚本通过 HTTP 控制 nmux。

```bash
nmux api start    # 在后台启动
nmux api stop     # 停止
nmux api status   # 查看状态（URL、PID、令牌配置）
```

**接口列表：**

| 方法 | 路径 | 说明 |
|-----|------|------|
| GET  | `/status` | nmux 整体状态 |
| GET  | `/panes` | 所有窗格（JSON） |
| GET  | `/panes/{target}/read?lines=N` | 读取窗格内容 |
| POST | `/panes/{target}/type` | 向窗格输入文本 |
| POST | `/panes/{target}/message` | 向窗格发送消息 |
| POST | `/panes/{target}/wait` | 等待模式匹配 |
| POST | `/dispatch` | 分发任务集 |

**配置（`~/.nmux/nmux.conf`）：**

```bash
NMUX_API_HOST=127.0.0.1   # 外部访问时使用 0.0.0.0（需设置令牌）
NMUX_API_PORT=8765
NMUX_API_TOKEN=            # Bearer 令牌（空值=无认证）
NMUX_API_MODE=integrated   # integrated（与 tmux 联动）/ daemon（常驻）
```

---

## nmux-tui（TUI 仪表盘）

需要 Python 3.6+。实时可视化所有 tmux 窗格状态。

```bash
nmux tui        # 启动 TUI
# 或在 tmux 内按：prefix + T
```

**快捷键：**

| 按键 | 操作 |
|-----|------|
| `q` | 退出 |
| `r` | 手动刷新 |
| `↑` / `↓` | 选择窗格 |
| `Enter` | 聚焦选中窗格 |
| `d` | 指定并运行分发文件 |

刷新频率：≤20 个窗格每 1 秒，>20 个窗格每 3 秒。
可通过 `NMUX_TUI_INTERVAL=<秒>` 手动设置。

---

## 心跳检测（子机存活监控）

仅限跨机器模式。随 tmux 自动启动，每秒检测一次子机状态。

```bash
nmux heartbeat start   # 手动启动
nmux heartbeat stop    # 停止
nmux heartbeat status  # 查看状态
```

**状态栏显示：**

```
# 子机正常
1:bash  2:claude     ● 192.168.1.100 | main

# 子机宕机
1:bash  2:claude     ✗ 192.168.1.100 OFFLINE | main
```

---

## 配置文件参考（`~/.nmux/nmux.conf`）

| 变量 | 默认值 | 说明 |
|-----|-------|------|
| `REMOTE_HOST` | — | 子机主机名或 IP |
| `REMOTE_USER` | `$(whoami)` | SSH 用户名 |
| `REMOTE_PORT` | 22 | SSH 端口 |
| `NMUX_API_HOST` | `127.0.0.1` | API 服务器绑定地址 |
| `NMUX_API_PORT` | 8765 | API 服务器端口 |
| `NMUX_API_TOKEN` | — | Bearer 认证令牌 |
| `NMUX_API_MODE` | `integrated` | `integrated` / `daemon` |
| `NMUX_TUI_INTERVAL` | 自动 | TUI 刷新间隔（秒） |
| `NMUX_READ_MARK_TTL` | 60 | Read Guard 有效期（秒） |

---

## 故障排除

**查看日志：**

```bash
# nmux 通用日志
ls ~/.nmux/logs/

# converse 会话日志
ls ~/.nmux/state/converse/*.log

# 启用调试模式（显示 SSH 通信错误详情）
NMUX_DEBUG=1 nmux-converse agent-a agent-b "测试"
```

**常见问题：**

| 症状 | 原因 | 解决方法 |
|------|------|---------|
| `agent not found` | 标签未注册 | 运行 `nmux-bridge name <pane-id> <label>` |
| SSH 连接失败 | `~/.ssh/config` 配置缺失 | 添加 `Host sub1` 条目并设置 `IdentityFile` |
| 频繁超时 | AI 响应速度慢 | 增大 `--timeout` 或减少 `--turns` |
| TUI 无法启动 | 未安装 Python 3.6+ | 运行 `python3 --version` 确认并安装 |
| 找不到 `skill-map.json` | 安装版本较旧 | 运行 `nmux update` 更新 |

---

## 许可证

MIT — 原始 smux 由 ShawnPana 开发 (https://github.com/ShawnPana/smux)
