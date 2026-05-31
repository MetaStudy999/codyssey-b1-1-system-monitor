#!/usr/bin/env bash

# B1-1 system monitor.
# Health check failures exit with 1. Resource threshold problems are warnings.

set -u

AGENT_HOME="${AGENT_HOME:-/home/agent-admin/agent-app}"
AGENT_PORT="${AGENT_PORT:-15034}"
AGENT_LOG_DIR="${AGENT_LOG_DIR:-/var/log/agent-app}"
MONITOR_LOG="$AGENT_LOG_DIR/monitor.log"
AGENT_BINARY="${AGENT_BINARY:-$AGENT_HOME/agent-app}"
PROCESS_PATTERNS=("$AGENT_BINARY" "./agent-app" "agent-app-linux-x86" "agent-app-linux-arm64" "agent_app.py")
CPU_THRESHOLD="${CPU_THRESHOLD:-20}"
MEM_THRESHOLD="${MEM_THRESHOLD:-10}"
DISK_THRESHOLD="${DISK_THRESHOLD:-80}"

info() {
  printf '[INFO] %s\n' "$*"
}

warning() {
  printf '[WARNING] %s\n' "$*"
}

error() {
  printf '[ERROR] %s\n' "$*" >&2
}

find_agent_pid() {
  local pattern

  for pattern in "${PROCESS_PATTERNS[@]}"; do
    if ps -eo pid=,comm=,args= | awk -v pattern="$pattern" -v self="$$" '
      $1 == self { next }
      $2 ~ /^(awk|ps|sudo|bash|sh|zsh)$/ { next }
      $0 ~ /monitor[.]sh/ { next }
      index($0, pattern) > 0 {
        print $1
        found=1
        exit
      }
      END { exit found ? 0 : 1 }
    '; then
      return 0
    fi
  done

  return 1
}

check_port_listen() {
  if ss -tuln 2>/dev/null | awk -v port=":$AGENT_PORT" '$0 ~ port { found=1 } END { exit found ? 0 : 1 }'; then
    return 0
  fi

  return 1
}

check_firewall() {
  if command -v ufw >/dev/null 2>&1; then
    if ufw status 2>/dev/null | grep -qi '^Status: active'; then
      info "Firewall status: UFW active"
    elif [ -r /etc/ufw/ufw.conf ] && grep -q '^ENABLED=yes' /etc/ufw/ufw.conf; then
      info "Firewall status: UFW active"
    else
      warning "Firewall is inactive or UFW status is unavailable"
    fi
    return 0
  fi

  if command -v firewall-cmd >/dev/null 2>&1; then
    if firewall-cmd --state 2>/dev/null | grep -qx 'running'; then
      info "Firewall status: firewalld running"
    else
      warning "Firewall is inactive or firewalld status is unavailable"
    fi
    return 0
  fi

  warning "No supported firewall command found: ufw or firewall-cmd"
}

trim_value() {
  awk '{ gsub(/^[ \t]+|[ \t]+$/, "", $0); print $0 }'
}

read_process_resources() {
  local pid="$1"

  ps -p "$pid" -o pcpu= -o pmem= 2>/dev/null | awk 'NR == 1 && NF >= 2 { print $1, $2; exit }'
}

is_number() {
  local value="$1"

  awk -v value="$value" 'BEGIN { exit (value ~ /^[0-9]+([.][0-9]+)?$/) ? 0 : 1 }'
}

greater_than() {
  local actual="$1"
  local threshold="$2"

  awk -v actual="$actual" -v threshold="$threshold" 'BEGIN { exit (actual > threshold) ? 0 : 1 }'
}

main() {
  local pid
  local cpu_usage
  local mem_usage
  local disk_used
  local resource_values
  local timestamp

  printf '====== SYSTEM MONITOR RESULT ======\n\n'
  printf '[HEALTH CHECK]\n'

  if ! pid="$(find_agent_pid)"; then
    error "Agent process is not running. Tried patterns: ${PROCESS_PATTERNS[*]}"
    exit 1
  fi
  printf "Checking agent process... [OK] (PID: %s)\n" "$pid"

  if ! check_port_listen; then
    error "TCP port $AGENT_PORT is not LISTEN"
    exit 1
  fi
  printf "Checking port %s... [OK]\n\n" "$AGENT_PORT"

  check_firewall

  resource_values="$(read_process_resources "$pid" || true)"
  cpu_usage="$(printf '%s\n' "$resource_values" | awk '{ print $1 }' | trim_value)"
  mem_usage="$(printf '%s\n' "$resource_values" | awk '{ print $2 }' | trim_value)"
  disk_used="$(df -P / | awk 'NR == 2 { gsub(/%/, "", $5); print $5 }')"

  if ! is_number "$cpu_usage" || ! is_number "$mem_usage" || ! is_number "$disk_used"; then
    error "Failed to collect resource usage"
    error "Collected values: CPU='$cpu_usage' MEM='$mem_usage' DISK_USED='$disk_used'"
    exit 1
  fi

  printf '\n[RESOURCE MONITORING]\n'
  printf 'CPU Usage : %s%%\n' "$cpu_usage"
  printf 'MEM Usage : %s%%\n' "$mem_usage"
  printf 'DISK Used : %s%%\n' "$disk_used"

  if greater_than "$cpu_usage" "$CPU_THRESHOLD"; then
    warning "CPU threshold exceeded (${cpu_usage}% > ${CPU_THRESHOLD}%)"
  fi

  if greater_than "$mem_usage" "$MEM_THRESHOLD"; then
    warning "MEM threshold exceeded (${mem_usage}% > ${MEM_THRESHOLD}%)"
  fi

  if greater_than "$disk_used" "$DISK_THRESHOLD"; then
    warning "DISK_USED threshold exceeded (${disk_used}% > ${DISK_THRESHOLD}%)"
  fi

  if [ ! -d "$AGENT_LOG_DIR" ]; then
    error "Log directory does not exist: $AGENT_LOG_DIR"
    exit 1
  fi

  if [ ! -w "$AGENT_LOG_DIR" ]; then
    error "Log directory is not writable: $AGENT_LOG_DIR"
    exit 1
  fi

  timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
  printf '[%s] PID:%s CPU:%s%% MEM:%s%% DISK_USED:%s%%\n' \
    "$timestamp" "$pid" "$cpu_usage" "$mem_usage" "$disk_used" >>"$MONITOR_LOG"

  printf '\n[INFO] Log appended: %s\n' "$MONITOR_LOG"
}

main "$@"
