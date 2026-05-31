#!/usr/bin/env bash

# B1-1 시스템 관제 스크립트.
#
# 이 스크립트의 목적은 제공 앱이 "실제로 서비스 가능한 상태"인지 확인하고,
# CPU/MEM/DISK 사용률을 /var/log/agent-app/monitor.log에 누적 기록하는 것이다.
#
# 판단 기준은 두 단계로 나눈다.
# 1. Health Check
#    - 앱 프로세스가 없거나 TCP 포트가 LISTEN 상태가 아니면 서비스 장애로 본다.
#    - 이 경우 cron이나 운영자가 실패를 감지할 수 있도록 exit 1로 종료한다.
# 2. Warning Check
#    - 방화벽 비활성, CPU/MEM/DISK 임계값 초과는 즉시 장애로 단정하지 않는다.
#    - 경고 메시지는 출력하지만 스크립트는 계속 진행하고 로그도 남긴다.
#
# cron은 사용자의 shell 설정 파일(.bashrc 등)을 읽지 않는 경우가 많다.
# 그래서 AGENT_HOME, AGENT_PORT 같은 핵심 값은 환경 변수가 없을 때를 대비해
# 아래에서 기본값을 지정한다.

set -u

# 앱 설치 기준 경로.
# 외부에서 AGENT_HOME을 미리 지정하면 그 값을 우선 사용하고,
# 없으면 미션 권장 경로인 /home/agent-admin/agent-app을 사용한다.
AGENT_HOME="${AGENT_HOME:-/home/agent-admin/agent-app}"

# 제공 앱이 LISTEN 해야 하는 포트.
# B1-1 미션 기준 포트는 15034이다.
AGENT_PORT="${AGENT_PORT:-15034}"

# 관제 로그가 저장될 디렉토리.
# 이 디렉토리는 agent-core 그룹이 쓰기 가능해야 cron 실행 시 권한 오류가 나지 않는다.
AGENT_LOG_DIR="${AGENT_LOG_DIR:-/var/log/agent-app}"

# monitor.sh가 append(>>) 방식으로 누적 기록할 로그 파일.
MONITOR_LOG="$AGENT_LOG_DIR/monitor.log"

# 기본 앱 실행 파일 경로.
# 앱 파일명이 다르거나 압축 해제 방식이 달라진 경우 AGENT_BINARY 환경 변수로 덮어쓸 수 있다.
AGENT_BINARY="${AGENT_BINARY:-$AGENT_HOME/agent-app}"

# 프로세스 탐색 후보 문자열 목록.
# 제공 앱 파일명이 환경마다 다를 수 있으므로 여러 후보를 순서대로 검사한다.
# find_agent_pid()는 이 문자열 중 하나가 ps 출력에 포함된 프로세스를 앱으로 판단한다.
PROCESS_PATTERNS=("$AGENT_BINARY" "./agent-app" "agent-app-linux-x86" "agent-app-linux-arm64" "agent_app.py")

# 경고 임계값.
# CPU/MEM/DISK가 이 값을 초과하면 [WARNING]을 출력하되 exit 1로 종료하지 않는다.
CPU_THRESHOLD="${CPU_THRESHOLD:-20}"
MEM_THRESHOLD="${MEM_THRESHOLD:-10}"
DISK_THRESHOLD="${DISK_THRESHOLD:-80}"

# 일반 정보 메시지 출력 함수.
# stdout으로 출력하므로 직접 실행하거나 cron.log에서 확인할 수 있다.
info() {
  printf '[INFO] %s\n' "$*"
}

# 경고 메시지 출력 함수.
# 임계값 초과나 방화벽 비활성처럼 "주의가 필요하지만 즉시 장애는 아닌" 상태에 사용한다.
warning() {
  printf '[WARNING] %s\n' "$*"
}

# 오류 메시지 출력 함수.
# Health Check 실패나 로그 기록 불가처럼 스크립트가 실패해야 하는 상태에 사용한다.
# stderr로 출력해 cron에서 stdout과 stderr를 구분하거나 함께 수집할 수 있게 한다.
error() {
  printf '[ERROR] %s\n' "$*" >&2
}

# 실행 중인 앱 프로세스의 PID를 찾는다.
#
# 반환 규칙:
# - PID를 찾으면 stdout에 PID를 출력하고 0을 반환한다.
# - 찾지 못하면 아무 PID도 출력하지 않고 1을 반환한다.
#
# pgrep 대신 ps + awk를 사용하는 이유:
# - 프로세스명(comm)뿐 아니라 전체 실행 인자(args)까지 함께 검사할 수 있다.
# - 앱이 "./agent-app", 절대경로, 아키텍처별 파일명 등으로 실행되어도 대응하기 쉽다.
find_agent_pid() {
  local pattern

  # PROCESS_PATTERNS의 후보 문자열을 하나씩 검사한다.
  for pattern in "${PROCESS_PATTERNS[@]}"; do
    if ps -eo pid=,comm=,args= | awk -v pattern="$pattern" -v self="$$" '
      # 현재 monitor.sh 프로세스 자신은 앱으로 오인하지 않는다.
      $1 == self { next }

      # ps/awk/shell/sudo 같은 보조 프로세스가 후보 문자열을 포함하더라도 제외한다.
      $2 ~ /^(awk|ps|sudo|bash|sh|zsh)$/ { next }

      # monitor.sh 명령줄에 앱 이름이 들어간 경우도 있을 수 있으므로 제외한다.
      $0 ~ /monitor[.]sh/ { next }

      # 전체 ps 출력 라인에 후보 문자열이 포함되면 해당 PID를 앱 PID로 사용한다.
      index($0, pattern) > 0 {
        print $1
        found=1
        exit
      }

      # awk 종료 코드로 "찾음/못 찾음"을 shell if 문에 전달한다.
      END { exit found ? 0 : 1 }
    '; then
      return 0
    fi
  done

  return 1
}

# 앱 포트가 TCP LISTEN 상태인지 확인한다.
#
# 프로세스가 살아 있어도 포트를 열지 못하면 외부 요청을 받을 수 없다.
# 그래서 B1-1에서는 "프로세스 확인"과 "포트 확인"을 모두 Health Check로 둔다.
check_port_listen() {
  # ss -tuln:
  # -t: TCP
  # -u: UDP
  # -l: LISTEN
  # -n: 포트 이름 변환 없이 숫자로 출력
  #
  # 여기서는 :15034 같은 포트 문자열이 출력에 있는지만 확인한다.
  if ss -tuln 2>/dev/null | awk -v port=":$AGENT_PORT" '$0 ~ port { found=1 } END { exit found ? 0 : 1 }'; then
    return 0
  fi

  return 1
}

# 방화벽 활성 상태를 점검한다.
#
# 방화벽이 꺼져 있으면 운영 보안상 문제지만,
# 앱 프로세스와 포트가 정상인 상황에서는 관제 로그 수집 자체를 막을 이유는 없다.
# 따라서 이 함수는 실패해도 exit 1을 반환하지 않고 WARNING만 출력한다.
check_firewall() {
  # Ubuntu 기본 실습 환경에서는 UFW를 우선 확인한다.
  if command -v ufw >/dev/null 2>&1; then
    # 일반적인 확인 경로: ufw status 출력에서 Status: active 확인.
    if ufw status 2>/dev/null | grep -qi '^Status: active'; then
      info "Firewall status: UFW active"
    # ufw status가 권한 문제 등으로 실패할 수 있어 설정 파일도 보조로 확인한다.
    elif [ -r /etc/ufw/ufw.conf ] && grep -q '^ENABLED=yes' /etc/ufw/ufw.conf; then
      info "Firewall status: UFW active"
    else
      warning "Firewall is inactive or UFW status is unavailable"
    fi
    return 0
  fi

  # UFW가 없는 환경에서는 firewalld를 확인한다.
  if command -v firewall-cmd >/dev/null 2>&1; then
    if firewall-cmd --state 2>/dev/null | grep -qx 'running'; then
      info "Firewall status: firewalld running"
    else
      warning "Firewall is inactive or firewalld status is unavailable"
    fi
    return 0
  fi

  # 둘 다 없으면 방화벽 상태를 판단할 수 없으므로 경고만 남긴다.
  warning "No supported firewall command found: ufw or firewall-cmd"
}

# 앞뒤 공백 제거용 helper.
# ps나 awk 출력은 값 앞뒤에 공백이 붙을 수 있으므로 숫자 검증 전에 정리한다.
trim_value() {
  awk '{ gsub(/^[ \t]+|[ \t]+$/, "", $0); print $0 }'
}

# 특정 PID의 CPU/MEM 사용률을 읽는다.
#
# ps 출력 예:
#   2.3 4.1
#
# - pcpu: 해당 프로세스의 CPU 사용률
# - pmem: 해당 프로세스의 메모리 사용률
read_process_resources() {
  local pid="$1"

  ps -p "$pid" -o pcpu= -o pmem= 2>/dev/null | awk 'NR == 1 && NF >= 2 { print $1, $2; exit }'
}

# 값이 0 이상의 정수 또는 소수인지 확인한다.
# CPU/MEM/DISK 값 파싱에 실패하면 잘못된 로그를 남기지 않기 위해 exit 1 처리한다.
is_number() {
  local value="$1"

  awk -v value="$value" 'BEGIN { exit (value ~ /^[0-9]+([.][0-9]+)?$/) ? 0 : 1 }'
}

# actual 값이 threshold보다 큰지 비교한다.
#
# Bash의 [ ] 비교는 소수 비교를 직접 처리하기 어렵다.
# CPU/MEM 사용률은 2.3 같은 소수로 나올 수 있으므로 awk로 비교한다.
greater_than() {
  local actual="$1"
  local threshold="$2"

  awk -v actual="$actual" -v threshold="$threshold" 'BEGIN { exit (actual > threshold) ? 0 : 1 }'
}

# 전체 관제 흐름.
# 1. 프로세스 확인
# 2. 포트 확인
# 3. 방화벽 상태 경고 확인
# 4. 리소스 수집 및 임계값 경고
# 5. monitor.log에 append 방식으로 기록
main() {
  local pid
  local cpu_usage
  local mem_usage
  local disk_used
  local resource_values
  local timestamp

  printf '====== SYSTEM MONITOR RESULT ======\n\n'
  printf '[HEALTH CHECK]\n'

  # Health Check 1: 앱 프로세스 확인.
  # PID를 찾지 못하면 앱이 실행 중이 아니므로 서비스 장애로 보고 exit 1.
  if ! pid="$(find_agent_pid)"; then
    error "Agent process is not running. Tried patterns: ${PROCESS_PATTERNS[*]}"
    exit 1
  fi
  printf "Checking agent process... [OK] (PID: %s)\n" "$pid"

  # Health Check 2: TCP 포트 LISTEN 확인.
  # 프로세스는 있어도 포트가 닫혀 있으면 요청 처리가 불가능하므로 exit 1.
  if ! check_port_listen; then
    error "TCP port $AGENT_PORT is not LISTEN"
    exit 1
  fi
  printf "Checking port %s... [OK]\n\n" "$AGENT_PORT"

  # Warning Check: 방화벽 상태 확인.
  # 보안 경고는 출력하지만 리소스 수집과 로그 기록은 계속 수행한다.
  check_firewall

  # 프로세스 단위 CPU/MEM 사용률과 루트 파티션 디스크 사용률을 수집한다.
  # df -P는 POSIX 형식으로 출력해 awk 컬럼 파싱이 안정적이다.
  resource_values="$(read_process_resources "$pid" || true)"
  cpu_usage="$(printf '%s\n' "$resource_values" | awk '{ print $1 }' | trim_value)"
  mem_usage="$(printf '%s\n' "$resource_values" | awk '{ print $2 }' | trim_value)"
  disk_used="$(df -P / | awk 'NR == 2 { gsub(/%/, "", $5); print $5 }')"

  # 숫자 파싱 실패 시 잘못된 monitor.log 라인을 만들지 않고 실패로 종료한다.
  # 예: ps 실패, df 출력 형식 변경, PID 종료 타이밍 경합 등.
  if ! is_number "$cpu_usage" || ! is_number "$mem_usage" || ! is_number "$disk_used"; then
    error "Failed to collect resource usage"
    error "Collected values: CPU='$cpu_usage' MEM='$mem_usage' DISK_USED='$disk_used'"
    exit 1
  fi

  printf '\n[RESOURCE MONITORING]\n'
  printf 'CPU Usage : %s%%\n' "$cpu_usage"
  printf 'MEM Usage : %s%%\n' "$mem_usage"
  printf 'DISK Used : %s%%\n' "$disk_used"

  # 임계값 초과는 WARNING으로만 처리한다.
  # 일시적인 CPU/MEM 상승이나 디스크 사용률 증가는 장애 조사 대상이지만,
  # 앱 프로세스/포트가 정상이라면 관제 스크립트 자체를 실패시킬 필요는 낮다.
  if greater_than "$cpu_usage" "$CPU_THRESHOLD"; then
    warning "CPU threshold exceeded (${cpu_usage}% > ${CPU_THRESHOLD}%)"
  fi

  if greater_than "$mem_usage" "$MEM_THRESHOLD"; then
    warning "MEM threshold exceeded (${mem_usage}% > ${MEM_THRESHOLD}%)"
  fi

  if greater_than "$disk_used" "$DISK_THRESHOLD"; then
    warning "DISK_USED threshold exceeded (${disk_used}% > ${DISK_THRESHOLD}%)"
  fi

  # 로그 디렉토리가 없으면 운영 환경 준비가 덜 된 상태다.
  # monitor.log를 만들 수 없으므로 실패로 처리한다.
  if [ ! -d "$AGENT_LOG_DIR" ]; then
    error "Log directory does not exist: $AGENT_LOG_DIR"
    exit 1
  fi

  # cron 실행 계정(agent-admin)이 로그 디렉토리에 쓸 수 있는지 확인한다.
  # 권한 문제를 조기에 명확한 오류로 보여 주기 위한 검사다.
  if [ ! -w "$AGENT_LOG_DIR" ]; then
    error "Log directory is not writable: $AGENT_LOG_DIR"
    exit 1
  fi

  # 미션 요구 로그 포맷:
  # [YYYY-MM-DD HH:MM:SS] PID:... CPU:..% MEM:..% DISK_USED:..%
  timestamp="$(date '+%Y-%m-%d %H:%M:%S')"

  # 관제 로그는 시간순 누적 기록이 중요하므로 반드시 >>로 append한다.
  # > 를 사용하면 기존 monitor.log가 매 실행마다 덮어써진다.
  printf '[%s] PID:%s CPU:%s%% MEM:%s%% DISK_USED:%s%%\n' \
    "$timestamp" "$pid" "$cpu_usage" "$mem_usage" "$disk_used" >>"$MONITOR_LOG"

  printf '\n[INFO] Log appended: %s\n' "$MONITOR_LOG"
}

# 스크립트가 실행되면 main 함수부터 시작한다.
# "$@"를 넘겨 두면 향후 옵션을 추가할 때도 함수 내부에서 인자를 받을 수 있다.
main "$@"
