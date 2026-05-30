#!/usr/bin/env bash

# Register monitor.sh in agent-admin's crontab.
# Duplicate entries are avoided by replacing the exact command if present.
# Run on the OrbStack Ubuntu 24.04 VM codyssey-b1-1-ubuntu24.

set -u

CRON_USER="${CRON_USER:-agent-admin}"
AGENT_HOME="${AGENT_HOME:-/home/agent-admin/agent-app}"
MONITOR_SCRIPT="$AGENT_HOME/bin/monitor.sh"
CRON_LOG="${AGENT_LOG_DIR:-/var/log/agent-app}/cron.log"
CRON_ENTRY="* * * * * $MONITOR_SCRIPT >> $CRON_LOG 2>&1"

info() {
  printf '[INFO] %s\n' "$*"
}

error() {
  printf '[ERROR] %s\n' "$*" >&2
}

require_root() {
  if [ "$(id -u)" -ne 0 ]; then
    error "This script must be run with sudo or as root on codyssey-b1-1-ubuntu24."
    exit 1
  fi
}

main() {
  require_root

  if ! id "$CRON_USER" >/dev/null 2>&1; then
    error "Missing user: $CRON_USER"
    exit 1
  fi

  if [ ! -x "$MONITOR_SCRIPT" ]; then
    error "Monitor script is not executable: $MONITOR_SCRIPT"
    error "Copy bin/monitor.sh there and set owner/group/mode first."
    exit 1
  fi

  if crontab -u "$CRON_USER" -l 2>/dev/null | grep -Fqx "$CRON_ENTRY"; then
    info "Cron entry already exists for $CRON_USER"
  else
    {
      crontab -u "$CRON_USER" -l 2>/dev/null | grep -Fv "$MONITOR_SCRIPT" || true
      printf '%s\n' "$CRON_ENTRY"
    } | crontab -u "$CRON_USER" -
    info "Registered cron entry for $CRON_USER"
  fi

  info "Current crontab for $CRON_USER:"
  crontab -u "$CRON_USER" -l
}

main "$@"
