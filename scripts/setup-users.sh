#!/usr/bin/env bash

# Create the Linux users and groups required by the B1-1 mission.
# This script is idempotent: existing users/groups are left in place.

set -u

AGENT_USERS=("agent-admin" "agent-dev" "agent-test")
COMMON_GROUP="agent-common"
CORE_GROUP="agent-core"

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
    error "Example: sudo $0"
    exit 1
  fi
}

ensure_group() {
  local group_name="$1"

  if getent group "$group_name" >/dev/null 2>&1; then
    info "Group already exists: $group_name"
  else
    groupadd "$group_name"
    info "Created group: $group_name"
  fi
}

ensure_user() {
  local user_name="$1"

  if id "$user_name" >/dev/null 2>&1; then
    info "User already exists: $user_name"
  else
    useradd -m -s /bin/bash "$user_name"
    info "Created user with home directory: $user_name"
  fi
}

ensure_membership() {
  local user_name="$1"
  local group_name="$2"

  if id -nG "$user_name" | tr ' ' '\n' | grep -qx "$group_name"; then
    info "$user_name is already a member of $group_name"
  else
    usermod -aG "$group_name" "$user_name"
    info "Added $user_name to $group_name"
  fi
}

main() {
  require_root

  info "Creating required groups"
  ensure_group "$COMMON_GROUP"
  ensure_group "$CORE_GROUP"

  info "Creating required users"
  for user_name in "${AGENT_USERS[@]}"; do
    ensure_user "$user_name"
  done

  info "Applying group membership policy"
  ensure_membership "agent-admin" "$COMMON_GROUP"
  ensure_membership "agent-dev" "$COMMON_GROUP"
  ensure_membership "agent-test" "$COMMON_GROUP"
  ensure_membership "agent-admin" "$CORE_GROUP"
  ensure_membership "agent-dev" "$CORE_GROUP"

  warning "If these users are already logged in, they may need to log out and back in to refresh group membership."
  info "User/group setup completed"
}

main "$@"
