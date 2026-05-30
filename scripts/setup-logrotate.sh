#!/usr/bin/env bash

# Install logrotate policy for /var/log/agent-app/monitor.log.
# Run on the OrbStack Ubuntu 24.04 VM codyssey-b1-1-ubuntu24.

set -u

CONFIG_PATH="${CONFIG_PATH:-/etc/logrotate.d/agent-app-monitor}"
MONITOR_LOG="${MONITOR_LOG:-/var/log/agent-app/monitor.log}"

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

  if ! command -v logrotate >/dev/null 2>&1; then
    error "logrotate is not installed. Install it first: sudo apt update && sudo apt install -y logrotate"
    exit 1
  fi

  cat >"$CONFIG_PATH" <<EOF
$MONITOR_LOG {
    size 10M
    rotate 10
    missingok
    notifempty
    copytruncate
    compress
    delaycompress
    create 0640 agent-admin agent-core
}
EOF

  chmod 0644 "$CONFIG_PATH"
  info "Installed logrotate config: $CONFIG_PATH"
  info "Syntax check command: sudo logrotate -d $CONFIG_PATH"
}

main "$@"
