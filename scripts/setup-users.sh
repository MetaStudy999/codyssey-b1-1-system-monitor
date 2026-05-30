#!/usr/bin/env bash

# B1-1 미션에서 필요한 Linux 사용자와 그룹을 생성하는 스크립트입니다.
#
# 실행 위치:
#   - macOS 호스트가 아니라 OrbStack Ubuntu 24.04 VM codyssey-b1-1-ubuntu24에서 실행합니다.
#   - 저장소 루트에서 다음처럼 실행하는 것을 기준으로 합니다.
#       sudo bash scripts/setup-users.sh
#
# 이 스크립트가 만드는 항목:
#   - 사용자: agent-admin, agent-dev, agent-test
#   - 그룹: agent-common, agent-core
#   - 그룹 정책:
#       agent-common: agent-admin, agent-dev, agent-test
#       agent-core:   agent-admin, agent-dev
#
# 운영 관점의 의미:
#   - agent-common은 업로드 디렉토리처럼 세 계정이 함께 접근할 리소스에 사용합니다.
#   - agent-core는 api_keys, /var/log/agent-app처럼 더 민감한 리소스에 사용합니다.
#   - agent-test는 테스트 계정이므로 agent-core에 넣지 않아 민감 파일 접근을 제한합니다.
#
# idempotent(멱등)하게 작성했습니다.
#   - 이미 존재하는 사용자/그룹은 다시 만들지 않습니다.
#   - 이미 그룹에 포함된 사용자는 중복 추가하지 않습니다.
#   - 따라서 실습 중 여러 번 실행해도 같은 최종 상태를 유지합니다.

# set -u:
#   - 정의되지 않은 변수를 사용하면 즉시 오류로 처리합니다.
#   - 계정/그룹 이름 같은 중요한 값이 비어 있는 상태로 실행되는 실수를 줄입니다.
set -u

# B1-1 미션에서 반드시 생성해야 하는 사용자 목록입니다.
# Bash 배열을 사용하면 main 함수에서 반복문으로 같은 작업을 안전하게 적용할 수 있습니다.
AGENT_USERS=("agent-admin" "agent-dev" "agent-test")

# 공통 작업용 그룹입니다.
# upload_files처럼 세 계정이 함께 읽고 쓸 수 있는 리소스의 그룹으로 사용할 예정입니다.
COMMON_GROUP="agent-common"

# 핵심 운영용 그룹입니다.
# api_keys, /var/log/agent-app처럼 agent-admin과 agent-dev만 접근해야 하는 리소스에 사용합니다.
CORE_GROUP="agent-core"

# 일반 진행 메시지를 표준 출력(stdout)으로 출력합니다.
# 실행 결과를 README 증빙에 붙여 넣을 때 [INFO] prefix가 있으면 단계별 상태를 읽기 쉽습니다.
info() {
  printf '[INFO] %s\n' "$*"
}

# 경고 메시지를 표준 출력(stdout)으로 출력합니다.
# 스크립트가 실패한 것은 아니지만 사용자가 추가로 확인해야 하는 상황에 사용합니다.
warning() {
  printf '[WARNING] %s\n' "$*"
}

# 오류 메시지를 표준 에러(stderr)로 출력합니다.
# stderr로 보내면 cron.log나 터미널에서 정상 출력과 오류 출력을 구분하기 쉽습니다.
error() {
  printf '[ERROR] %s\n' "$*" >&2
}

# 사용자/그룹 생성은 시스템 계정 DB(/etc/passwd, /etc/group)를 수정합니다.
# 그래서 일반 사용자 권한으로 실행하면 useradd/groupadd/usermod가 실패합니다.
# id -u 결과가 0이면 root이며, sudo로 실행한 경우도 이 조건을 만족합니다.
require_root() {
  if [ "$(id -u)" -ne 0 ]; then
    error "This script must be run with sudo or as root on codyssey-b1-1-ubuntu24."
    error "Example: sudo $0"
    exit 1
  fi
}

# 지정한 그룹이 없으면 생성합니다.
# getent group:
#   - /etc/group뿐 아니라 NSS 설정에 연결된 그룹 데이터베이스를 조회합니다.
#   - Ubuntu 로컬 그룹 확인에는 getent group <group_name> 형태가 안전합니다.
# >/dev/null 2>&1:
#   - 조회 성공/실패 여부만 필요하므로 화면 출력은 숨깁니다.
ensure_group() {
  local group_name="$1"

  if getent group "$group_name" >/dev/null 2>&1; then
    info "Group already exists: $group_name"
  else
    groupadd "$group_name"
    info "Created group: $group_name"
  fi
}

# 지정한 사용자가 없으면 생성합니다.
# id <user_name>:
#   - 사용자가 존재하면 0으로 종료하고, 없으면 실패합니다.
# useradd -m:
#   - 홈 디렉토리를 함께 생성합니다. 예: /home/agent-admin
# useradd -s /bin/bash:
#   - 로그인 셸을 bash로 지정해 실습자가 해당 계정으로 전환했을 때 익숙한 셸을 사용하게 합니다.
ensure_user() {
  local user_name="$1"

  if id "$user_name" >/dev/null 2>&1; then
    info "User already exists: $user_name"
  else
    useradd -m -s /bin/bash "$user_name"
    info "Created user with home directory: $user_name"
  fi
}

# 지정한 사용자를 지정한 보조 그룹에 포함합니다.
# local 변수:
#   - 함수 내부에서만 사용하는 값으로 제한하여 다른 함수의 변수와 섞이지 않게 합니다.
# id -nG <user>:
#   - 사용자가 속한 그룹 이름들을 공백으로 출력합니다.
# tr ' ' '\n' | grep -qx:
#   - 그룹 목록을 한 줄에 하나씩 바꾼 뒤 정확히 같은 그룹명이 있는지 검사합니다.
#   - grep -q는 결과를 출력하지 않고 성공/실패만 반환합니다.
#   - grep -x는 줄 전체가 정확히 일치할 때만 성공하므로 비슷한 이름의 그룹과 혼동하지 않습니다.
# usermod -aG:
#   - -G는 보조 그룹 목록을 설정합니다.
#   - -a 없이 -G만 쓰면 기존 보조 그룹이 덮어써질 수 있으므로 반드시 -aG를 함께 사용합니다.
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

# 전체 실행 흐름을 모아 둔 진입 함수입니다.
# 순서가 중요합니다.
#   1. root 권한 확인
#   2. 그룹 생성
#   3. 사용자 생성
#   4. 사용자별 그룹 멤버십 적용
#
# 그룹을 먼저 만드는 이유:
#   - 사용자 멤버십을 적용하려면 대상 그룹이 먼저 존재해야 합니다.
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

  # 그룹 멤버십은 이미 로그인 중인 세션에는 바로 반영되지 않을 수 있습니다.
  # 새 터미널로 다시 로그인하거나 su - <user> 형태로 새 로그인 세션을 열면 최신 그룹 정보가 적용됩니다.
  warning "If these users are already logged in, they may need to log out and back in to refresh group membership."
  info "User/group setup completed"
}

# 스크립트를 실행하면 main 함수부터 시작합니다.
# "$@"는 현재 스크립트로 전달된 인자를 그대로 main에 넘깁니다.
# 지금은 별도 인자를 사용하지 않지만, 나중에 옵션을 추가할 때 구조를 유지하기 좋습니다.
main "$@"
