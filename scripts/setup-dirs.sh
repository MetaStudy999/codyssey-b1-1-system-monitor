#!/usr/bin/env bash

# Create the application directory tree, permission model, and test key.
# Run this script on the OrbStack Ubuntu machine, not on macOS.

set -u

AGENT_HOME="${AGENT_HOME:-/home/agent-admin/agent-app}"
UPLOAD_DIR="${AGENT_UPLOAD_DIR:-$AGENT_HOME/upload_files}"
KEY_DIR="$AGENT_HOME/api_keys"
BIN_DIR="$AGENT_HOME/bin"
LOG_DIR="${AGENT_LOG_DIR:-/var/log/agent-app}"
KEY_FILE="${AGENT_KEY_PATH:-$KEY_DIR/t_secret.key}"
TEST_KEY_VALUE="agent_api_key_test"

info() {
  printf '[INFO] %s\n' "$*"
}

warning() {
  printf '[WARNING] %s\n' "$*"
}

error() {
  printf '[ERROR] %s\n' "$*" >&2
}

require_root() {
  if [ "$(id -u)" -ne 0 ]; then
    error "This script must be run with sudo or as root on Ubuntu."
    error "Example: sudo AGENT_HOME=$AGENT_HOME $0"
    exit 1
  fi
}

require_accounts() {
  local missing=0

  for name in agent-admin agent-dev agent-test; do
    if ! id "$name" >/dev/null 2>&1; then
      error "Missing user: $name. Run scripts/setup-users.sh first."
      missing=1
    fi
  done

  for name in agent-common agent-core; do
    if ! getent group "$name" >/dev/null 2>&1; then
      error "Missing group: $name. Run scripts/setup-users.sh first."
      missing=1
    fi
  done

  if [ "$missing" -ne 0 ]; then
    exit 1
  fi
}

write_key_file() {
  if [ -f "$KEY_FILE" ]; then
    if [ "$(cat "$KEY_FILE")" = "$TEST_KEY_VALUE" ]; then
      info "Key file already exists with expected test value: $KEY_FILE"
    else
      warning "Key file exists but content differs: $KEY_FILE"
      warning "Leaving existing file untouched. Check it manually."
    fi
  else
    printf '%s\n' "$TEST_KEY_VALUE" >"$KEY_FILE"
    info "Created test key file: $KEY_FILE"
  fi
}

ensure_agent_home_traversal() {
  local admin_home

  admin_home="$(getent passwd agent-admin | cut -d: -f6)"
  if [ -z "$admin_home" ] || [ ! -d "$admin_home" ]; then
    warning "Could not find agent-admin home directory. Skipping parent traversal ACL."
    return
  fi

  case "$AGENT_HOME/" in
    "$admin_home"/*)
      if command -v setfacl >/dev/null 2>&1; then
        if setfacl -m g:agent-core:--x "$admin_home"; then
          info "Granted traverse-only ACL to agent-core on: $admin_home"
        else
          warning "Failed to set ACL on $admin_home. agent-core users may not be able to enter $AGENT_HOME."
        fi
      else
        warning "setfacl is not installed. If $admin_home is not searchable, install acl or allow traversal manually."
        warning "Example: sudo setfacl -m g:agent-core:--x $admin_home"
      fi
      ;;
    *)
      warning "AGENT_HOME is not under $admin_home. Check parent directory traversal permissions manually."
      ;;
  esac
}

main() {
  require_root
  require_accounts

  info "Creating application directories"
  ensure_agent_home_traversal
  install -d -o agent-admin -g agent-core -m 0750 "$AGENT_HOME"
  install -d -o agent-admin -g agent-common -m 2770 "$UPLOAD_DIR"
  install -d -o agent-admin -g agent-core -m 2770 "$KEY_DIR"
  install -d -o agent-dev -g agent-core -m 0750 "$BIN_DIR"
  install -d -o agent-admin -g agent-core -m 2770 "$LOG_DIR"

  write_key_file

  chown agent-admin:agent-core "$KEY_FILE"
  chmod 0640 "$KEY_FILE"

  info "Directory setup completed"
  info "AGENT_HOME=$AGENT_HOME"
  info "UPLOAD_DIR=$UPLOAD_DIR"
  info "KEY_FILE=$KEY_FILE"
  info "LOG_DIR=$LOG_DIR"
}

main "$@"
