#!/usr/bin/env bash

# Configure UFW for the B1-1 mission.
# Only TCP 20022 for SSH and TCP 15034 for the agent app are allowed.

set -u

SSH_PORT="${SSH_PORT:-20022}"
APP_PORT="${AGENT_PORT:-15034}"
APPLY="false"

info() {
  printf '[INFO] %s\n' "$*"
}

warning() {
  printf '[WARNING] %s\n' "$*"
}

error() {
  printf '[ERROR] %s\n' "$*" >&2
}

usage() {
  cat <<'USAGE'
Usage:
  sudo scripts/setup-firewall-ufw.sh --apply

Without --apply, this script only prints the intended policy.
USAGE
}

require_root() {
  if [ "$(id -u)" -ne 0 ]; then
    error "This script must be run with sudo or as root on Ubuntu."
    exit 1
  fi
}

check_ufw() {
  if ! command -v ufw >/dev/null 2>&1; then
    error "ufw is not installed. Install it first: sudo apt update && sudo apt install -y ufw"
    exit 1
  fi
}

show_plan() {
  info "Planned UFW policy"
  info "Default incoming: deny"
  info "Default outgoing: allow"
  info "Allow: ${SSH_PORT}/tcp"
  info "Allow: ${APP_PORT}/tcp"
  warning "Before enabling UFW over SSH, confirm that SSH is already listening on ${SSH_PORT}/tcp."
}

apply_policy() {
  ufw default deny incoming
  ufw default allow outgoing
  ufw allow "${SSH_PORT}/tcp"
  ufw allow "${APP_PORT}/tcp"
  ufw --force enable
}

main() {
  if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
    usage
    exit 0
  fi

  if [ "${1:-}" = "--apply" ]; then
    APPLY="true"
  fi

  require_root
  check_ufw
  show_plan

  if [ "$APPLY" != "true" ]; then
    warning "Dry run only. Re-run with --apply to change UFW."
    ufw status verbose || true
    exit 0
  fi

  apply_policy
  info "UFW status after applying policy:"
  ufw status verbose
}

main "$@"
