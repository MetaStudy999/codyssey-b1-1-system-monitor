#!/usr/bin/env bash

# B1-1 미션의 monitor.log 용량 관리 정책을 logrotate로 설치하는 스크립트입니다.
#
# 실행 위치:
#   - macOS 호스트가 아니라 OrbStack Ubuntu 24.04 VM cds-ubuntu24에서 실행합니다.
#   - logrotate는 Linux 로그 파일 관리 도구이므로 macOS Terminal에서 직접 적용하지 않습니다.
#   - 저장소 루트에서 다음처럼 실행하는 것을 기준으로 합니다.
#       sudo bash scripts/setup-logrotate.sh
#
# 이 스크립트가 만드는 항목:
#   - /etc/logrotate.d/agent-app-monitor 설정 파일
#   - /var/log/agent-app/monitor.log에 대한 rotate 정책
#
# 적용되는 로그 정책:
#   - monitor.log가 10MB 이상이면 회전 대상이 됩니다.
#   - 최대 10개까지 이전 로그를 보관합니다.
#   - 오래된 로그는 압축합니다.
#   - 비어 있거나 없는 로그 파일은 오류로 처리하지 않습니다.
#   - 새 로그 파일은 agent-admin:agent-core, 0640 권한으로 생성합니다.
#
# 운영 관점의 의미:
#   - 관제 로그는 계속 누적되므로 용량 제한이 없으면 /var 파티션을 채울 수 있습니다.
#   - logrotate를 사용하면 monitor.sh 내부 로직을 복잡하게 만들지 않고 운영 표준 방식으로 관리할 수 있습니다.
#   - copytruncate를 사용해 실행 중인 프로세스가 같은 파일에 계속 쓰는 상황에서도 로그 회전이 가능합니다.

# set -u:
#   - 정의되지 않은 변수를 사용하면 즉시 오류로 처리합니다.
#   - 설정 파일 경로나 로그 파일 경로가 비어 있는 상태로 /etc 아래 파일을 쓰는 실수를 줄입니다.
set -u

# CONFIG_PATH:
#   - logrotate가 읽는 개별 정책 파일 경로입니다.
#   - /etc/logrotate.d/ 아래 파일은 보통 root 소유, 0644 권한으로 관리합니다.
CONFIG_PATH="${CONFIG_PATH:-/etc/logrotate.d/agent-app-monitor}"

# MONITOR_LOG:
#   - monitor.sh가 append 방식으로 기록하는 관제 로그입니다.
#   - 환경 변수로 덮어쓸 수 있지만 B1-1 기본 경로는 /var/log/agent-app/monitor.log입니다.
MONITOR_LOG="${MONITOR_LOG:-/var/log/agent-app/monitor.log}"

# 일반 진행 메시지를 표준 출력(stdout)으로 출력합니다.
# 실행 결과를 README 증빙에 넣을 때 어떤 설정이 설치되었는지 확인하기 쉽습니다.
info() {
  printf '[INFO] %s\n' "$*"
}

# 오류 메시지를 표준 에러(stderr)로 출력합니다.
# logrotate 미설치나 권한 부족처럼 실행을 계속할 수 없는 상황에 사용합니다.
error() {
  printf '[ERROR] %s\n' "$*" >&2
}

# /etc/logrotate.d 아래에 설정 파일을 쓰려면 root 권한이 필요합니다.
# id -u 결과가 0이면 root이며, sudo로 실행한 경우도 이 조건을 만족합니다.
# 권한이 부족한 상태에서 redirection을 시도하면 애매한 실패가 날 수 있으므로 먼저 검사합니다.
require_root() {
  if [ "$(id -u)" -ne 0 ]; then
    error "This script must be run with sudo or as root on cds-ubuntu24."
    exit 1
  fi
}

# 전체 실행 흐름을 모아 둔 진입 함수입니다.
# 순서가 중요합니다.
#   1. root 권한 확인
#   2. logrotate 설치 여부 확인
#   3. 정책 파일 생성
#   4. 정책 파일 권한 정리
#   5. 검증 명령 안내
main() {
  require_root

  # logrotate 명령이 설치되어 있는지 확인합니다.
  # command -v는 PATH에서 실행 파일을 찾을 수 있는지 검사합니다.
  # 설치되어 있지 않으면 정책 파일을 만들어도 실제 회전이 수행되지 않으므로 여기서 종료합니다.
  if ! command -v logrotate >/dev/null 2>&1; then
    error "logrotate is not installed. Install it first: sudo apt update && sudo apt install -y logrotate"
    exit 1
  fi

  # /etc/logrotate.d/agent-app-monitor 파일을 새로 작성합니다.
  # 이 스크립트는 미션 기준 정책을 정확히 맞추는 용도라 매번 같은 내용으로 덮어씁니다.
  # heredoc의 EOF를 따옴표로 감싸지 않은 이유:
  #   - $MONITOR_LOG 값을 실제 로그 경로로 확장해 설정 파일에 기록해야 하기 때문입니다.
  cat >"$CONFIG_PATH" <<EOF
$MONITOR_LOG {
    # su:
    #   - logrotate가 회전 작업을 수행할 사용자와 그룹을 지정합니다.
    #   - /var/log/agent-app는 agent-core 그룹 정책을 따르므로 agent-admin agent-core로 맞춥니다.
    su agent-admin agent-core

    # size 10M:
    #   - monitor.log가 10MB 이상일 때 회전합니다.
    #   - B1-1 요구사항의 "최대 10MB" 정책을 반영합니다.
    size 10M

    # rotate 10:
    #   - 이전 로그 파일을 최대 10개까지 보관합니다.
    #   - B1-1 요구사항의 "최대 10개 파일 보존" 정책을 반영합니다.
    rotate 10

    # missingok:
    #   - 아직 monitor.log가 생성되지 않았어도 오류로 처리하지 않습니다.
    #   - 초기 설치 직후에는 로그 파일이 없을 수 있으므로 필요합니다.
    missingok

    # notifempty:
    #   - 빈 로그 파일은 회전하지 않습니다.
    #   - 의미 없는 압축 파일이 쌓이는 것을 방지합니다.
    notifempty

    # copytruncate:
    #   - 현재 로그 내용을 회전 파일로 복사한 뒤 원본 파일을 0바이트로 줄입니다.
    #   - monitor.sh나 cron이 파일 경로를 계속 사용해도 로그 기록이 끊기지 않게 합니다.
    copytruncate

    # compress:
    #   - 회전된 이전 로그를 gzip으로 압축해 디스크 사용량을 줄입니다.
    compress

    # delaycompress:
    #   - 가장 최근 회전 파일은 다음 회전 시점까지 압축을 미룹니다.
    #   - 방금 회전된 로그를 사람이 바로 확인하기 쉽게 하는 운영상 편의 옵션입니다.
    delaycompress

    # create:
    #   - 회전 후 새 monitor.log를 만들 때 사용할 권한, 소유자, 그룹입니다.
    #   - 0640은 소유자 읽기/쓰기, 그룹 읽기, 기타 사용자 접근 차단을 의미합니다.
    create 0640 agent-admin agent-core
}
EOF

  # /etc/logrotate.d의 설정 파일은 일반적으로 root가 관리하고 모든 사용자가 읽을 수 있게 0644로 둡니다.
  # 파일 안에는 비밀값이 없고, logrotate 데몬/관리자가 읽어야 하므로 실행 권한은 주지 않습니다.
  chmod 0644 "$CONFIG_PATH"
  info "Installed logrotate config: $CONFIG_PATH"

  # -d(debug) 모드는 실제 회전을 수행하지 않고 설정 해석 결과만 보여 줍니다.
  # README 검증 단계에서 안전하게 문법과 적용 대상을 확인할 수 있습니다.
  info "Syntax check command: sudo logrotate -d $CONFIG_PATH"
}

# 스크립트를 실행하면 main 함수부터 시작합니다.
# "$@"는 현재 스크립트로 전달된 인자를 그대로 main에 넘깁니다.
main "$@"
