#!/usr/bin/env bash

# B1-1 monitor.sh cron registration helper.
#
# 목적:
# - agent-admin 계정의 crontab에 monitor.sh 자동 실행 항목을 등록한다.
# - 등록 주기는 매분이며, 표준 출력과 표준 에러는 cron.log에 누적한다.
# - 같은 monitor.sh 명령이 여러 번 등록되어 로그가 중복 기록되는 일을 방지한다.
#
# 실행 환경:
# - OrbStack Ubuntu 24.04 VM(cds-ubuntu24)에서 실행하는 것을 기준으로 한다.
# - crontab -u 옵션으로 다른 사용자 crontab을 수정하므로 sudo/root 권한이 필요하다.
# - 실제 운영 앱과 monitor.sh는 agent-admin 계정 기준 경로에 배치되어 있어야 한다.
#
# 사용 예:
#   sudo scripts/install-cron.sh
#
# 환경 변수로 기본값을 바꿀 수 있다:
#   sudo CRON_USER=agent-admin AGENT_HOME=/home/agent-admin/agent-app \
#     AGENT_LOG_DIR=/var/log/agent-app scripts/install-cron.sh

# set -u:
# - 선언되지 않은 변수를 사용하면 즉시 오류로 처리한다.
# - cron 등록 스크립트는 잘못된 경로가 조용히 등록되면 발견이 늦어지므로,
#   변수 오타를 빠르게 잡기 위해 사용한다.
set -u

# cron을 등록할 Linux 계정이다.
# 기본값은 미션 실행 계정인 agent-admin이며, 필요하면 환경 변수로 덮어쓸 수 있다.
CRON_USER="${CRON_USER:-agent-admin}"

# 앱이 설치되는 기준 디렉토리다.
# monitor.sh는 이 디렉토리 아래 bin/monitor.sh에 있다고 가정한다.
AGENT_HOME="${AGENT_HOME:-/home/agent-admin/agent-app}"

# 매분 실행할 관제 스크립트의 절대 경로다.
# cron은 작업 디렉토리와 PATH가 일반 터미널과 다르므로 절대 경로를 사용한다.
MONITOR_SCRIPT="$AGENT_HOME/bin/monitor.sh"

# cron 실행 결과를 누적할 로그 파일이다.
# AGENT_LOG_DIR이 지정되지 않았으면 /var/log/agent-app/cron.log를 사용한다.
CRON_LOG="${AGENT_LOG_DIR:-/var/log/agent-app}/cron.log"

# 실제 crontab에 들어갈 한 줄이다.
# * * * * * 는 매분 실행을 의미한다.
# >> 는 기존 로그를 덮어쓰지 않고 뒤에 누적한다.
# 2>&1 은 표준 에러도 같은 cron.log에 함께 남긴다.
CRON_ENTRY="* * * * * $MONITOR_SCRIPT >> $CRON_LOG 2>&1"

# 안내 메시지를 일정한 형식으로 출력한다.
# 평가자가 실행 결과를 볼 때 정보 메시지와 오류 메시지를 구분하기 쉽다.
info() {
  printf '[INFO] %s\n' "$*"
}

# 오류 메시지는 표준 에러(stderr)로 출력한다.
# 실패 원인을 cron 등록 전에 바로 확인할 수 있게 한다.
error() {
  printf '[ERROR] %s\n' "$*" >&2
}

# agent-admin 같은 다른 사용자의 crontab을 수정하려면 root 권한이 필요하다.
# 권한 없이 실행하면 일부 시스템에서는 crontab -u가 실패하므로 초기에 중단한다.
require_root() {
  if [ "$(id -u)" -ne 0 ]; then
    error "This script must be run with sudo or as root on cds-ubuntu24."
    exit 1
  fi
}

main() {
  # 이후 crontab -u "$CRON_USER" 명령을 안전하게 실행하기 위해 root 여부를 먼저 확인한다.
  require_root

  # cron을 등록할 대상 사용자가 실제로 존재하는지 확인한다.
  # 사용자가 없는데 crontab을 등록하려고 하면 평가 환경에서 재현이 어려운 오류가 날 수 있다.
  if ! id "$CRON_USER" >/dev/null 2>&1; then
    error "Missing user: $CRON_USER"
    exit 1
  fi

  # monitor.sh가 존재하고 실행 권한이 있는지 확인한다.
  # cron은 실행 시 대화형 오류를 보여주지 않으므로, 등록 전에 실행 가능 상태를 강제한다.
  if [ ! -x "$MONITOR_SCRIPT" ]; then
    error "Monitor script is not executable: $MONITOR_SCRIPT"
    error "Copy bin/monitor.sh there and set owner/group/mode first."
    exit 1
  fi

  # 이미 동일한 cron 항목이 있으면 아무것도 바꾸지 않는다.
  # grep -Fqx 옵션 의미:
  # -F: 패턴을 정규식이 아닌 고정 문자열로 비교한다.
  # -q: 검색 결과를 출력하지 않고 성공/실패만 반환한다.
  # -x: 한 줄 전체가 CRON_ENTRY와 정확히 같을 때만 일치로 본다.
  if crontab -u "$CRON_USER" -l 2>/dev/null | grep -Fqx "$CRON_ENTRY"; then
    info "Cron entry already exists for $CRON_USER"
  else
    # 기존 crontab을 유지하되, 같은 monitor.sh 경로를 포함한 오래된 항목은 제거한다.
    # 이렇게 하면 실행 경로나 로그 경로가 바뀌었을 때 기존 항목과 새 항목이 동시에 남지 않는다.
    #
    # crontab -l은 crontab이 아직 없는 사용자에게서 실패할 수 있다.
    # 이 경우에도 새 항목 등록은 계속되어야 하므로 마지막에 || true를 둔다.
    #
    # 중괄호 블록의 출력 전체를 crontab -u "$CRON_USER" - 로 전달하여
    # 정리된 기존 항목 + 새 CRON_ENTRY를 한 번에 설치한다.
    {
      crontab -u "$CRON_USER" -l 2>/dev/null | grep -Fv "$MONITOR_SCRIPT" || true
      printf '%s\n' "$CRON_ENTRY"
    } | crontab -u "$CRON_USER" -
    info "Registered cron entry for $CRON_USER"
  fi

  # 최종 등록 결과를 화면에 출력한다.
  # README 또는 docs/verification-log.md에 붙일 증빙으로 사용할 수 있다.
  info "Current crontab for $CRON_USER:"
  crontab -u "$CRON_USER" -l
}

main "$@"
