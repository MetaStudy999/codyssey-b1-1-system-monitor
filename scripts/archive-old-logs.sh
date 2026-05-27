#!/usr/bin/env bash

# Bonus script: compress old logs, move them to archive, and remove stale archives.

set -u

LOG_DIR="${AGENT_LOG_DIR:-/var/log/agent-app}"
ARCHIVE_DIR="${ARCHIVE_DIR:-/var/log/monitor/agent-app/archive}"
COMPRESS_DAYS="${COMPRESS_DAYS:-7}"
DELETE_DAYS="${DELETE_DAYS:-30}"

info() {
  printf '[INFO] %s\n' "$*"
}

warning() {
  printf '[WARNING] %s\n' "$*"
}

error() {
  printf '[ERROR] %s\n' "$*" >&2
}

ensure_archive_dir() {
  if [ -d "$ARCHIVE_DIR" ]; then
    info "Archive directory checked: $ARCHIVE_DIR"
    return 0
  fi

  if mkdir -p "$ARCHIVE_DIR" 2>/dev/null; then
    info "Created archive directory: $ARCHIVE_DIR"
  else
    error "Cannot create archive directory: $ARCHIVE_DIR"
    return 1
  fi
}

compress_and_move_old_logs() {
  local found=0
  local compressed_path
  local archive_path

  if [ ! -d "$LOG_DIR" ]; then
    warning "Log directory does not exist: $LOG_DIR"
    return 0
  fi

  while IFS= read -r -d '' log_file; do
    found=1

    if [ ! -r "$log_file" ] || [ ! -w "$(dirname "$log_file")" ]; then
      warning "Skipping due to insufficient permission: $log_file"
      continue
    fi

    compressed_path="${log_file}.$(date +%Y%m%d%H%M%S).gz"
    if gzip -c "$log_file" >"$compressed_path"; then
      info "Compressed: $compressed_path"
    else
      warning "gzip failed: $log_file"
      rm -f "$compressed_path" 2>/dev/null || true
      continue
    fi

    archive_path="$ARCHIVE_DIR/$(basename "$compressed_path")"
    if mv "$compressed_path" "$archive_path"; then
      info "Moved to archive: $archive_path"
    else
      warning "Move failed: $compressed_path -> $archive_path"
      continue
    fi
  done < <(find "$LOG_DIR" -maxdepth 1 -type f -name '*.log' -mtime +"$((COMPRESS_DAYS - 1))" -print0 2>/dev/null)

  if [ "$found" -eq 0 ]; then
    info "No old log files found for compression"
  fi
}

delete_old_archives() {
  local found=0

  while IFS= read -r -d '' archive_file; do
    found=1
    if rm -f "$archive_file"; then
      info "Deleted old archive: $archive_file"
    else
      warning "Failed to delete old archive: $archive_file"
    fi
  done < <(find "$ARCHIVE_DIR" -maxdepth 1 -type f -name '*.gz' -mtime +"$((DELETE_DAYS - 1))" -print0 2>/dev/null)

  if [ "$found" -eq 0 ]; then
    info "No old archive files found for deletion"
  fi
}

main() {
  if ! ensure_archive_dir; then
    warning "Archive cleanup stopped because archive directory is unavailable"
    exit 0
  fi

  compress_and_move_old_logs
  delete_old_archives
  info "Archive cleanup completed"
}

main "$@"
