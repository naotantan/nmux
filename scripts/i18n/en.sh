#!/usr/bin/env bash
# nmux i18n — English
# Sourced by install.sh

# ── Installation ─────────────────────────────────────────────
L_INSTALLING_PKG="Installing %s (%s)..."
L_PKG_INSTALL_FAIL="Failed to install %s. Please install it manually."
L_BREW_REQUIRED="Homebrew is required on macOS. Install it from https://brew.sh"
L_CLIPBOARD_INSTALLING="Installing clipboard tool..."
L_CLIPBOARD_FAIL="Failed to install %s"
L_TMUX_UNSUPPORTED="tmux %s is not supported. tmux 3.2+ is required."
L_TMUX_OK="tmux %s — OK"
L_SHA256_SKIP="sha256sum not found. Skipping verification."
L_VERIFY_FAIL="File verification failed: %s"
L_DOWNLOAD_FAIL="Download failed: %s"
L_CURL_WGET_REQUIRED="curl or wget is required. Please install one of them."
L_BACKUP="Backup: %s"
L_PATH_APPENDING="Adding PATH entry to %s..."
L_PATH_REMOVED="Removed PATH entry from %s"

# ── Mode selection ────────────────────────────────────────────
L_SELECT_MODE="Select installation mode:"
L_MODE_STANDALONE="  1) Standalone   — single machine, local AI agent communication"
L_MODE_CROSSMACHINE="  2) Cross-machine — main + sub machine (SSH connection)"
L_MODE_PROMPT="Choice [1/2] (default: 1): "
L_MODE_SELECTED="Mode: %s"

# ── Remote machine config ─────────────────────────────────────
L_REMOTE_CONF_HEADER="Enter sub machine connection details:"
L_REMOTE_HOST_PROMPT="  Hostname or IP address: "
L_REMOTE_HOST_REQUIRED="Hostname is required."
L_REMOTE_USER_PROMPT="  SSH username [%s]: "
L_REMOTE_PORT_PROMPT="  SSH port [22]: "
L_REMOTE_CONF_INFO="Connection: %s@%s:%s"
L_SSH_TESTING="Testing SSH connection..."
L_SSH_OK="SSH connection OK"
L_SSH_FAIL="SSH connection failed. Please check your settings."
L_SSH_FAIL_HINT="  Verify ~/.ssh/config or use ssh-copy-id to deploy your key."
L_SSH_CONTINUE="  Continue anyway? [y/N]: "
L_INSTALL_ABORTED="Installation aborted."
L_INSTALL_SUB_PROMPT="  Install nmux on sub machine too? [Y/n]: "
L_INSTALL_SUB_SKIP="Skipped installation on sub machine."
L_INSTALL_SUB_RUNNING="Installing nmux on sub machine (%s)..."
L_INSTALL_SUB_DONE="Sub machine installation complete"
L_INSTALL_SUB_FAIL="Sub machine installation failed. Please install manually."

# ── Core installation ─────────────────────────────────────────
L_INSTALLING_TMUX="Installing tmux..."
L_DOWNLOADING="Downloading %s..."
L_INSTALLING="Installing %s..."
L_SKILL_MAP_PLACED="skill-map.json placed at: %s"
L_PYTHON_SKIP="Python 3.6+ not found. Skipping nmux-dispatch / nmux-api / nmux-tui."
L_PYTHON_SKIP_HINT="To add them later: brew install python3 (macOS) or apt-get install python3 (Linux)"
L_SELECT_API_MODE="? Select nmux-api mode:"
L_API_MODE_INTEGRATED="  1) integrated  — linked to tmux session (recommended, default)"
L_API_MODE_DAEMON="  2) daemon      — runs as a standalone background process"
L_API_MODE_PROMPT="Mode [1/2, default: 1]: "

# ── Completion messages ───────────────────────────────────────
L_INSTALL_SUB_COMPLETE="nmux v%s (sub machine) installation complete!"
L_INSTALLER_HEADER="nmux v%s installer (OS: %s)"
L_INSTALL_COMPLETE="nmux v%s installation complete!"
L_INFO_MODE="  Mode:         %s"
L_INFO_DIR="  Config:       %s"
L_INFO_LOG="  Logs:         %s"
L_INFO_REMOTE="  Sub machine:  %s@%s:%s"
L_INFO_USAGE="  Usage: nmux help"
L_PATH_RELOAD="Restart your shell or run:"

# ── Update / Rollback ─────────────────────────────────────────
L_UPDATING="Updating nmux... (current: v%s)"
L_ALREADY_LATEST="Already on the latest version (v%s)."
L_UPDATING_TO="Updating v%s → v%s..."
L_VERSION_CHECK_FAIL="Version check failed. Forcing update..."
L_UPDATE_COMPLETE="nmux v%s update complete!"
L_ROLLBACK_HEADER="Available backups:"
L_NO_BACKUP="No backups found."
L_ROLLBACK_PROMPT="Enter backup number (1-%d): "
L_ROLLBACK_INVALID="Invalid selection: %s"
L_ROLLBACK_DONE="Restored: %s"

# ── Uninstall ─────────────────────────────────────────────────
L_UNINSTALLING="Uninstalling nmux..."
L_SYMLINK_REMOVED="Symlink removed"
L_BACKUP_RESTORED="Backup restored: %s"
L_DIR_REMOVED="Removed %s"
L_UNINSTALL_COMPLETE="nmux has been uninstalled."
L_RESTART_SHELL="  Please restart your shell."

# ── Status ────────────────────────────────────────────────────
L_STATUS_HEADER="nmux Status"
L_STATUS_VERSION="  Version:      %s"
L_STATUS_OS="  OS:           %s"
L_STATUS_MODE="  Mode:         %s"
L_STATUS_TMUX="  tmux:         %s"
L_STATUS_CLIPBOARD="  Clipboard:    %s"
L_STATUS_BRIDGE="  nmux-bridge:  "
L_STATUS_REMOTE="  nmux-remote:  "
L_STATUS_SUB="  Sub machine:  %s@%s:%s"
L_STATUS_HEARTBEAT="  Heartbeat:    %s"
L_STATUS_API="  nmux-api:     %s"
L_STATUS_LOG="  Logs:         %s"
L_STATUS_RUNNING="running (PID: %s)"
L_STATUS_STOPPED="stopped"
L_STATUS_NOT_INSTALLED="not installed"
L_STATUS_NOT_SET="not set"

# ── Misc ──────────────────────────────────────────────────────
L_HEARTBEAT_NOT_FOUND="nmux-heartbeat not found. Run: nmux update"
L_FILE_NOT_FOUND="File not found: %s"
L_VERIFY_OK="Verification OK: %s"
L_LOG_NOT_FOUND="Log file not found: %s"
L_UNKNOWN_CMD="Unknown command: %s"
L_UNKNOWN_CMD_HINT="  Run: nmux help"
L_TMUX_RELOAD_OK="tmux config reloaded"
L_TMUX_RELOAD_FAIL="tmux reload failed (manual: tmux source ~/.nmux/tmux.conf)"

# ── Help ──────────────────────────────────────────────────────
L_HELP=$(cat <<'HELP'

nmux — multi-agent tmux setup (macOS / Ubuntu)

Usage: nmux <command> [options]

Commands:
  install              Install (with mode and language selection)
  update               Update to latest version
  rollback             Restore previous tmux config
  uninstall            Completely remove (cleans up PATH automatically)
  status               Show installation status
  heartbeat <subcmd>   Manage heartbeat (start/stop/status)
  api [start|stop|status]  Manage REST API server (daemon mode)
  tui                  Launch TUI dashboard
  converse [opts]      AI-to-AI real-time conversation
  verify <file> <sha>  Verify sha256 of a file
  log [N]              Show last N log lines
  version              Show version
  help                 Show this help

Environment variables:
  NMUX_DEBUG=1         Enable debug logging

Files:
  ~/.nmux/nmux.conf        Configuration file
  ~/.nmux/tmux.conf        tmux config
  ~/.nmux/bin/             CLI tools
  ~/.nmux/backups/         Config backups
  ~/.nmux/logs/            Logs (daily)
  ~/.nmux/state/           State files
  ~/.nmux/skill-map.json   Skill mappings

HELP
)
