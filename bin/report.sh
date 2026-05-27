#!/usr/bin/env bash

# Bonus report script for B1-1.
# It parses monitor.log and prints sample count plus CPU/MEM/DISK statistics.

set -u

LOG_FILE="${LOG_FILE:-/var/log/agent-app/monitor.log}"
FROM_TIME=""
TO_TIME=""

info() {
  printf '[INFO] %s\n' "$*"
}

error() {
  printf '[ERROR] %s\n' "$*" >&2
}

usage() {
  cat <<'USAGE'
Usage:
  bin/report.sh
  bin/report.sh --from "2026-05-27 10:00:00" --to "2026-05-27 11:00:00"

Environment:
  LOG_FILE=/path/to/monitor.log
USAGE
}

parse_args() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --from)
        FROM_TIME="${2:-}"
        shift 2
        ;;
      --to)
        TO_TIME="${2:-}"
        shift 2
        ;;
      --help|-h)
        usage
        exit 0
        ;;
      *)
        error "Unknown argument: $1"
        usage
        exit 1
        ;;
    esac
  done
}

main() {
  parse_args "$@"

  if [ ! -f "$LOG_FILE" ]; then
    error "Log file does not exist: $LOG_FILE"
    exit 1
  fi

  if [ ! -s "$LOG_FILE" ]; then
    error "Log file is empty: $LOG_FILE"
    exit 1
  fi

  awk -v from_time="$FROM_TIME" -v to_time="$TO_TIME" '
    function clean_percent(value) {
      gsub(/%/, "", value)
      return value
    }

    function update_stats(name, value, ts) {
      sum[name] += value
      if (!(name in min) || value < min[name]) {
        min[name] = value
        min_time[name] = ts
      }
      if (!(name in max) || value > max[name]) {
        max[name] = value
        max_time[name] = ts
      }
    }

    function is_number(value) {
      return value ~ /^[0-9]+([.][0-9]+)?$/
    }

    BEGIN {
      parse_errors = 0
    }

    {
      ts = substr($0, 2, 19)

      if (from_time != "" && ts < from_time) {
        next
      }
      if (to_time != "" && ts > to_time) {
        next
      }

      cpu = mem = disk = ""
      for (i = 1; i <= NF; i++) {
        if ($i ~ /^CPU:/) {
          cpu = clean_percent(substr($i, 5))
        } else if ($i ~ /^MEM:/) {
          mem = clean_percent(substr($i, 5))
        } else if ($i ~ /^DISK_USED:/) {
          disk = clean_percent(substr($i, 11))
        }
      }

      if (!is_number(cpu) || !is_number(mem) || !is_number(disk)) {
        printf("[WARNING] Skipping unparsable line %d: %s\n", NR, $0) > "/dev/stderr"
        parse_errors++
        next
      }

      count++
      update_stats("CPU", cpu + 0, ts)
      update_stats("MEM", mem + 0, ts)
      update_stats("DISK_USED", disk + 0, ts)
    }

    END {
      if (count == 0) {
        print "[ERROR] No analyzable monitor samples found" > "/dev/stderr"
        exit 1
      }

      print "====== STATISTICS REPORT ======"
      printf("Log File    : %s\n", FILENAME)
      printf("From        : %s\n", from_time == "" ? "(not set)" : from_time)
      printf("To          : %s\n", to_time == "" ? "(not set)" : to_time)
      printf("Samples     : %d\n", count)
      printf("Parse Skip  : %d\n\n", parse_errors)

      printf("[CPU]\n")
      printf("Average     : %.2f%%\n", sum["CPU"] / count)
      printf("Maximum     : %.2f%% at %s\n", max["CPU"], max_time["CPU"])
      printf("Minimum     : %.2f%% at %s\n\n", min["CPU"], min_time["CPU"])

      printf("[MEM]\n")
      printf("Average     : %.2f%%\n", sum["MEM"] / count)
      printf("Maximum     : %.2f%% at %s\n", max["MEM"], max_time["MEM"])
      printf("Minimum     : %.2f%% at %s\n\n", min["MEM"], min_time["MEM"])

      printf("[DISK_USED]\n")
      printf("Average     : %.2f%%\n", sum["DISK_USED"] / count)
      printf("Maximum     : %.2f%% at %s\n", max["DISK_USED"], max_time["DISK_USED"])
      printf("Minimum     : %.2f%% at %s\n", min["DISK_USED"], min_time["DISK_USED"])
    }
  ' "$LOG_FILE"

  info "Report completed"
}

main "$@"
