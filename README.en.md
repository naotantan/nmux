# nmux v2.0.0

**Enhanced fork of smux** — Orchestration tool for connecting, conversing, and parallelizing multiple AI agents on tmux

[日本語](README.md) | [中文](README.zh.md)

---

## Overview

nmux controls AI agents (e.g. Claude Code) running in tmux panes.
You can run multiple agents on a single machine, operate remote agents via SSH, or have agents hold real-time conversations with each other.

```
┌─────────────────────────────────────────────────────┐
│  nmux Ecosystem                                     │
│                                                     │
│  nmux-bridge   ←→  Local pane I/O (core)           │
│  nmux-remote   ←→  SSH cross-machine comm          │
│  nmux-converse  ─→  AI-to-AI real-time chat        │
│  nmux-dispatch  ─→  Parallel JSON task dispatch    │
│  nmux-api      ←→  HTTP REST API (integrations)    │
│  nmux-tui       ─→  TUI dashboard (monitoring)     │
│  nmux-heartbeat ─→  Remote host liveness check     │
└─────────────────────────────────────────────────────┘
```

### Supported Platforms

| Main machine | Sub machine |
|-------------|-------------|
| macOS       | macOS       |
| macOS       | Ubuntu      |
| Ubuntu      | macOS       |
| Ubuntu      | Ubuntu      |

---

## Installation

```bash
curl -fsSL https://raw.githubusercontent.com/naotantan/nmux/main/install.sh | bash
```

Choose a **language** and **mode** during installation:

```
Select language:
  1) 日本語
  2) English
  3) 中文（简体）

Select installation mode:
  1) Standalone     — single machine only
  2) Cross-machine  — main + sub machine (SSH)
```

If Python 3.6+ is available, nmux-dispatch / nmux-api / nmux-tui / nmux-converse are also installed automatically.

---

## Quick Start (5 min)

### Step 1: Open panes in tmux and assign labels

```bash
nmux-bridge name nmux:1.1 agent-a
nmux-bridge name nmux:1.2 agent-b

nmux-bridge list   # verify labels
```

### Step 2: Send a message to agent-b

```bash
nmux-bridge type agent-b "hello, this is a test message"
nmux-bridge keys agent-b Enter
nmux-bridge read agent-b 20
```

### Step 3: Start a conversation between two agents

```bash
nmux-converse agent-a agent-b "Discuss the future of AI"
```

---

## Features

| Feature | Command | Description |
|---------|---------|-------------|
| Local pane I/O | `nmux-bridge` | Input/output control for tmux panes (core foundation) |
| Cross-machine comm | `nmux-remote` | Remote pane control via SSH |
| AI-to-AI chat | `nmux-converse` | Real-time agent conversations with skill detection |
| Task dispatch | `nmux-dispatch` | Parallel JSON task execution with dependency resolution |
| REST API | `nmux api` | HTTP control for external tools (n8n, GitHub Actions, etc.) |
| TUI monitor | `nmux tui` | Real-time dashboard for all pane states |
| Liveness check | `nmux heartbeat` | Sub-machine monitoring (1-second interval, status bar) |
| Version management | `nmux update / rollback` | Update to latest / restore previous version |

---

## nmux CLI

```
nmux install                     # Install (with mode selection)
nmux update                      # Update to latest version
nmux rollback                    # Restore previous version
nmux uninstall                   # Completely remove nmux
nmux status                      # Show current state
nmux heartbeat start/stop/status # Manage liveness monitoring
nmux api start/stop/status       # Manage REST API server
nmux tui                         # Launch TUI dashboard
nmux converse [opts]             # Start AI-to-AI conversation
nmux log [N]                     # Show logs (default: last 100 lines)
nmux version                     # Show version
```

---

## Agent Setup

### Single machine (no limit)

```bash
nmux-bridge name nmux:1.1 agent-a
nmux-bridge name nmux:1.2 agent-b
nmux-bridge name nmux:1.3 agent-c

nmux-bridge list   # list registered agents
```

### Multiple machines (via SSH)

```bash
# Add Host aliases to ~/.ssh/config for convenience
# Host sub1  HostName 192.168.1.101

# Check agents on sub machine
ssh sub1 "~/.nmux/bin/nmux-bridge list"

# Send message to remote agent
ssh sub1 "~/.nmux/bin/nmux-bridge type agent-c 'please run the task'"
ssh sub1 "~/.nmux/bin/nmux-bridge keys agent-c Enter"
```

### AI-A instructs AI-B (basic pattern)

```bash
# 1. Get Read Guard (marks start of new output)
nmux-bridge read agent-b 20

# 2. Send instruction
nmux-bridge type agent-b "please execute the following task: ..."
nmux-bridge keys agent-b Enter

# 3. Wait for completion (up to 60 sec for $ prompt)
nmux-bridge wait agent-b '\$' 60

# 4. Read result
nmux-bridge read agent-b 50
```

---

## nmux-bridge (Local Pane Communication)

Core foundation for all nmux features.

```
nmux-bridge list [--json]                              # List panes (--json for JSON output)
nmux-bridge read  <target> [lines]                     # Read pane content
nmux-bridge type  <target> <text>                      # Type text (no Enter)
nmux-bridge keys  <target> <key>...                    # Send special keys (Enter, Tab, Escape, etc.)
nmux-bridge message <target> <text>                    # Send message with sender info
nmux-bridge name  <target> <label>                     # Assign label to pane
nmux-bridge wait  <target> [pattern] [timeout] [--then <cmd>]  # Wait for pattern, then run command
```

**Environment variables:**

| Variable | Default | Description |
|---------|---------|-------------|
| `NMUX_READ_MARK_TTL` | 60 | Read Guard expiry in seconds |
| `NMUX_DEBUG` | 0 | Set to `1` to enable debug logging |

---

## nmux-converse (AI-to-AI Real-Time Conversation)

Connects AI agents in tmux panes in real-time conversation.
Uses round-robin routing — each agent's response becomes the next agent's input.

### Basic Usage

```bash
# Simple start (2 agents, 10 turns)
nmux-converse agent-a agent-b "Discuss the future of AI"

# Specify session name and turn count
nmux-converse start -n debate -t 20 agent-a agent-b -m "Quantum computing challenges"

# Run in background
nmux-converse start --daemon -n bg agent-a agent-b -m "Code review"
tail -f ~/.nmux/state/converse/bg.log
```

### Including Remote Agents

```bash
# Include agent on sub machine
nmux-converse agent-a sub1/agent-b "Discuss the design"

# With user and port
nmux-converse agent-a user@sub1:2222/agent-b "Discussion"
```

Agent format: `[user@]host[:port]/label`

### Dynamic Add / Remove

Add or remove agents without stopping the conversation. Changes apply from the next turn.

```bash
nmux-converse add    debate agent-c   # add (joins next turn)
nmux-converse remove debate agent-b   # remove (minimum 2 required)
```

### Skill Auto-Detection (Feature A)

Analyzes each message in real-time and automatically suggests the appropriate Claude Code skill (slash command). Ask for a code review and it detects `code-reviewer`; ask for research and it detects `research`.

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[Turn 3/10]  → agent-b
[skill: code-reviewer ✓]
▶ please review the code
```

If the detected skill is not installed, a dialog appears:

```
"code-reviewer" skill not found. What would you like to do?

  1) Auto-generate a minimal template (recommended)
  2) Continue this session without a skill
  3) Never show this notification again

Choice (1-3, default=1):
```

**Viewing and editing skill mappings:**

```bash
nmux-converse skill-map
```

```
SKILL                KEYWORDS                               INSTALLED
--------------------------------------------------------------------
brainstorming        design, architecture, proposal...      ✓
code-reviewer        review, code check, quality...         ✗
research             investigate, compare, research...      ✓
```

Edit `~/.nmux/skill-map.json` to add custom keywords:

```json
{
  "version": "1.0",
  "mappings": {
    "my-skill": {
      "keywords": ["custom keyword", "カスタムキーワード"],
      "skill_path": "my-skill"
    }
  },
  "skip": []
}
```

Add a skill name to the `skip` array to disable notifications for it.

### Agent Auto-Scale (Feature B)

Automatically monitors timeouts, failures, and response imbalance during conversation. When load increases, it shows a dialog: "Add more agents?" — approve and tmux panes are created and joined to the session on the spot.

**Scoring logic:**

| Condition | Points |
|-----------|--------|
| Timeout occurred | +3 |
| Response failure | +2 |
| Load imbalance (max/min ratio > 3) | +1 |
| Turn milestone (50% / 75%) | +1 |

When score ≥ 5, a dialog appears:

```
[Auto-Scale Proposal]
Conversation load is increasing.
AI recommended additions: 2

How many agents to add? (0 to cancel): 2
Maximum agents allowed? (current limit: unset): 5
```

Labels are auto-assigned as `agent-c`, `agent-d`, `agent-e`...

### Session Management

```bash
nmux-converse list              # List all sessions (● = running)
nmux-converse stop  <name>      # Stop a session
nmux-converse log   <name> 50   # Show last 50 lines of log
nmux-converse skill-map         # Show skill mappings
```

### Options (start)

| Option | Default | Description |
|--------|---------|-------------|
| `-n, --name <name>` | `sess-HHMMSS` | Session name |
| `-t, --turns <N>` | 10 | Number of turns |
| `--timeout <sec>` | 120 | Response timeout in seconds |
| `--lines <N>` | 80 | Lines to read per response |
| `--prompt <pattern>` | `[$%#>❯]` | Prompt detection pattern |
| `--interval <sec>` | 1 | Wait between turns (seconds) |
| `--ssh-port <port>` | 22 | Default SSH port |
| `--daemon` | — | Run in background |
| `-m, --message <text>` | — | Initial topic (required) |

---

## nmux-dispatch (Parallel JSON Task Dispatch)

Requires Python 3.6+. Dispatches tasks to multiple agents with automatic dependency resolution.

```bash
nmux-dispatch tasks.json            # Execute
nmux-dispatch tasks.json --dry-run  # Preview execution plan
```

**Task definition example (`tasks.json`):**

```json
{
  "defaults": { "timeout": 120, "on_failure": "abort" },
  "tasks": [
    { "id": "plan",  "agent": "agent-a", "message": "Create a design plan" },
    { "id": "impl",  "agent": "agent-b", "message": "Implement the plan", "depends_on": ["plan"] },
    { "id": "test",  "agent": "agent-c", "message": "Run tests",          "depends_on": ["impl"] }
  ]
}
```

Tasks without dependencies run in parallel. Dependency order is resolved automatically via topological sort.

---

## nmux-api (HTTP REST API)

Requires Python 3.6+. Control nmux via HTTP from n8n, GitHub Actions, or custom scripts.

```bash
nmux api start    # Start in background
nmux api stop     # Stop
nmux api status   # Show status (URL, PID, token config)
```

**Endpoints:**

| Method | Path | Description |
|--------|------|-------------|
| GET  | `/status` | Overall nmux state |
| GET  | `/panes` | All panes (JSON) |
| GET  | `/panes/{target}/read?lines=N` | Read pane content |
| POST | `/panes/{target}/type` | Type text into pane |
| POST | `/panes/{target}/message` | Send message to pane |
| POST | `/panes/{target}/wait` | Wait for pattern |
| POST | `/dispatch` | Dispatch task set |

**Configuration (`~/.nmux/nmux.conf`):**

```bash
NMUX_API_HOST=127.0.0.1   # Use 0.0.0.0 for external access (set a token)
NMUX_API_PORT=8765
NMUX_API_TOKEN=            # Bearer token (empty = no auth)
NMUX_API_MODE=integrated   # integrated (tmux-aware) / daemon (always-on)
```

---

## nmux-tui (TUI Dashboard)

Requires Python 3.6+. Real-time visual dashboard of all tmux pane states.

```bash
nmux tui        # Launch TUI
# or inside tmux: prefix + T
```

**Key bindings:**

| Key | Action |
|-----|--------|
| `q` | Quit |
| `r` | Manual refresh |
| `↑` / `↓` | Select pane |
| `Enter` | Focus selected pane |
| `d` | Specify and run dispatch file |

Refresh rate: 1 second for ≤20 panes, 3 seconds for >20 panes.
Override with `NMUX_TUI_INTERVAL=<seconds>`.

---

## Heartbeat (Sub-Machine Liveness)

Cross-machine mode only. Auto-starts with tmux and monitors sub machines every second.

```bash
nmux heartbeat start   # Manual start
nmux heartbeat stop    # Stop
nmux heartbeat status  # Show status
```

**Status bar display:**

```
# Sub machine online
1:bash  2:claude     ● 192.168.1.100 | main

# Sub machine offline
1:bash  2:claude     ✗ 192.168.1.100 OFFLINE | main
```

---

## Configuration Reference (`~/.nmux/nmux.conf`)

| Variable | Default | Description |
|---------|---------|-------------|
| `REMOTE_HOST` | — | Sub machine hostname or IP |
| `REMOTE_USER` | `$(whoami)` | SSH username |
| `REMOTE_PORT` | 22 | SSH port |
| `NMUX_API_HOST` | `127.0.0.1` | API server bind address |
| `NMUX_API_PORT` | 8765 | API server port |
| `NMUX_API_TOKEN` | — | Bearer auth token |
| `NMUX_API_MODE` | `integrated` | `integrated` / `daemon` |
| `NMUX_TUI_INTERVAL` | auto | TUI refresh interval (seconds) |
| `NMUX_READ_MARK_TTL` | 60 | Read Guard expiry (seconds) |

---

## Troubleshooting

**Check logs:**

```bash
# nmux general logs
ls ~/.nmux/logs/

# converse session logs
ls ~/.nmux/state/converse/*.log

# Enable debug mode (shows SSH errors in detail)
NMUX_DEBUG=1 nmux-converse agent-a agent-b "test"
```

**Common issues:**

| Symptom | Cause | Fix |
|---------|-------|-----|
| `agent not found` | Label not registered | Run `nmux-bridge name <pane-id> <label>` |
| SSH connection failure | Missing `~/.ssh/config` entry | Add `Host sub1` with `IdentityFile` |
| Frequent timeouts | AI response is slow | Increase `--timeout` or reduce `--turns` |
| TUI won't start | Python 3.6+ not installed | Check `python3 --version` and install |
| `skill-map.json` not found | Older installation | Run `nmux update` |

---

## License

MIT — Original smux by ShawnPana (https://github.com/ShawnPana/smux)
