#!/usr/bin/env bash

# B1-1 미션용 디렉터리/권한/테스트 키 초기화 스크립트.
#
# 이 스크립트는 앱 실행에 필요한 디렉터리 구조를 만들고, 각 디렉터리에
# 미션 요구사항에 맞는 소유자/그룹/권한을 적용한다. 또한 제공 앱과
# 미션 검증에서 사용할 테스트 키 파일을 생성한다.
#
# 주의:
# - macOS 호스트가 아니라 OrbStack Ubuntu 24.04 Linux Machine(cds-ubuntu24)
#   안에서 실행해야 한다.
# - /home/agent-admin 및 /var/log/agent-app 같은 시스템 경로를 수정하므로
#   sudo 또는 root 권한이 필요하다.
# - agent-admin, agent-dev, agent-test 사용자와 agent-common, agent-core
#   그룹이 먼저 있어야 하므로 scripts/setup-users.sh 실행 후 사용한다.

set -u

# AGENT_HOME은 앱이 설치될 기준 디렉터리다.
# 환경 변수로 값이 들어오면 그 값을 우선 사용하고, 없으면 미션 기본값을 사용한다.
AGENT_HOME="${AGENT_HOME:-/home/agent-admin/agent-app}"

# 업로드 디렉터리는 agent-common 그룹 구성원이 함께 읽고 쓸 수 있어야 한다.
UPLOAD_DIR="${AGENT_UPLOAD_DIR:-$AGENT_HOME/upload_files}"

# AGENT_KEY_PATH는 상황에 따라 "키 파일 경로" 또는 "키 디렉터리 경로"로
# 전달될 수 있다. 아래 분기에서 두 경우를 모두 안전하게 처리한다.
KEY_PATH_VALUE="${AGENT_KEY_PATH:-$AGENT_HOME/api_keys}"
if [ "$(basename "$KEY_PATH_VALUE")" = "secret.key" ] || [ "$(basename "$KEY_PATH_VALUE")" = "t_secret.key" ]; then
  # AGENT_KEY_PATH가 /path/to/secret.key처럼 파일명까지 포함하면 dirname으로 디렉터리만 추출한다.
  KEY_DIR="$(dirname "$KEY_PATH_VALUE")"
else
  # AGENT_KEY_PATH가 /path/to/api_keys처럼 디렉터리만 가리키면 그대로 키 디렉터리로 사용한다.
  KEY_DIR="$KEY_PATH_VALUE"
fi

# 제공 앱은 secret.key를 찾을 수 있고, 미션 요구사항은 t_secret.key를 요구한다.
# 두 파일을 같은 테스트 값으로 만들어 앱 실행과 평가 검증을 모두 만족시킨다.
APP_KEY_FILE="$KEY_DIR/secret.key"
MISSION_KEY_FILE="$KEY_DIR/t_secret.key"

# bin 디렉터리는 monitor.sh, report.sh 같은 운영 스크립트를 배치하는 위치다.
BIN_DIR="$AGENT_HOME/bin"

# 로그 디렉터리는 관제 로그와 cron 로그가 쌓이는 위치다.
LOG_DIR="${AGENT_LOG_DIR:-/var/log/agent-app}"

# 실제 비밀값이 아니라 미션에서 지정한 테스트용 API 키 문자열이다.
TEST_KEY_VALUE="agent_api_key_test"

# 일반 정보 메시지를 표준 출력으로 남긴다.
info() {
  printf '[INFO] %s\n' "$*"
}

# 작업은 계속할 수 있지만 사용자가 확인해야 하는 상황을 표시한다.
warning() {
  printf '[WARNING] %s\n' "$*"
}

# 스크립트를 중단해야 하거나 중요한 실패를 표준 에러로 표시한다.
error() {
  printf '[ERROR] %s\n' "$*" >&2
}

require_root() {
  # id -u가 0이면 root 사용자다. 디렉터리 소유권/권한 변경과 /var/log 생성은 root 권한이 필요하다.
  if [ "$(id -u)" -ne 0 ]; then
    error "This script must be run with sudo or as root on cds-ubuntu24."
    error "Example: sudo AGENT_HOME=$AGENT_HOME $0"
    exit 1
  fi
}

require_accounts() {
  # setup-dirs.sh는 계정과 그룹을 만들지 않는다.
  # 역할 분리를 명확히 하기 위해 사용자/그룹 생성은 setup-users.sh에서 먼저 처리한다.
  local missing=0

  # 앱 실행자(agent-admin), 스크립트 소유자(agent-dev), 테스트 사용자(agent-test)가 모두 있어야 한다.
  for name in agent-admin agent-dev agent-test; do
    if ! id "$name" >/dev/null 2>&1; then
      error "Missing user: $name. Run scripts/setup-users.sh first."
      missing=1
    fi
  done

  # agent-common은 업로드 영역 공유용, agent-core는 키/로그/운영 스크립트 접근용 그룹이다.
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
  # 인자로 받은 키 파일이 없으면 테스트 키를 생성하고, 이미 있으면 내용을 보존한다.
  # 실제 운영 키가 들어간 파일을 실수로 덮어쓰지 않기 위해 다른 내용이면 경고만 출력한다.
  local key_file="$1"

  if [ -f "$key_file" ]; then
    # 파일이 이미 있고 미션 테스트 값과 같으면 재실행해도 변경하지 않는다.
    if [ "$(cat "$key_file")" = "$TEST_KEY_VALUE" ]; then
      info "Key file already exists with expected test value: $key_file"
    else
      warning "Key file exists but content differs: $key_file"
      warning "Leaving existing file untouched. Check it manually."
    fi
  else
    # 새 키 파일은 줄바꿈을 포함해 생성한다. cat으로 확인할 때 출력이 깔끔하고 POSIX 텍스트 파일 형태가 된다.
    printf '%s\n' "$TEST_KEY_VALUE" >"$key_file"
    info "Created test key file: $key_file"
  fi
}

secure_key_file() {
  # 키 파일은 앱 실행 계정(agent-admin)이 소유하고, agent-core 그룹까지만 읽을 수 있게 제한한다.
  # 0640 = 소유자 읽기/쓰기, 그룹 읽기, 기타 사용자 접근 불가.
  local key_file="$1"

  chown agent-admin:agent-core "$key_file"
  chmod 0640 "$key_file"
}

ensure_agent_home_traversal() {
  # agent-dev 등 agent-core 그룹 사용자가 $AGENT_HOME 내부의 bin 디렉터리에 접근하려면
  # 상위 경로인 /home/agent-admin을 "통과(--x)"할 수 있어야 한다.
  # 홈 디렉터리 전체를 열지 않고 실행 권한만 ACL로 부여해 최소 권한 원칙을 지킨다.
  local admin_home

  # /etc/passwd 기준으로 agent-admin의 실제 홈 디렉터리를 조회한다.
  admin_home="$(getent passwd agent-admin | cut -d: -f6)"
  if [ -z "$admin_home" ] || [ ! -d "$admin_home" ]; then
    warning "Could not find agent-admin home directory. Skipping parent traversal ACL."
    return
  fi

  case "$AGENT_HOME/" in
    "$admin_home"/*)
      # setfacl이 있으면 agent-core 그룹에 홈 디렉터리 통과 권한만 부여한다.
      # --x는 파일 목록 조회나 읽기는 막고, 하위 경로로 이동할 수 있는 최소 권한이다.
      if command -v setfacl >/dev/null 2>&1; then
        if setfacl -m g:agent-core:--x "$admin_home"; then
          info "Granted traverse-only ACL to agent-core on: $admin_home"
        else
          warning "Failed to set ACL on $admin_home. agent-core users may not be able to enter $AGENT_HOME."
        fi
      else
        # acl 패키지가 없으면 자동 적용할 수 없으므로 사용자가 수동 조치할 명령을 안내한다.
        warning "setfacl is not installed. If $admin_home is not searchable, install acl or allow traversal manually."
        warning "Example: sudo setfacl -m g:agent-core:--x $admin_home"
      fi
      ;;
    *)
      # AGENT_HOME이 agent-admin 홈 아래에 없으면 상위 경로 권한 구조가 환경마다 다르므로 자동 판단하지 않는다.
      warning "AGENT_HOME is not under $admin_home. Check parent directory traversal permissions manually."
      ;;
  esac
}

main() {
  # 시스템 경로와 권한을 바꾸는 작업이므로 먼저 root 권한과 필수 계정/그룹 존재 여부를 확인한다.
  require_root
  require_accounts

  info "Creating application directories"

  # agent-core 사용자가 AGENT_HOME 내부 운영 파일에 접근할 수 있도록 상위 홈 디렉터리 통과 권한을 확인한다.
  ensure_agent_home_traversal

  # install -d는 디렉터리가 없으면 만들고, 이미 있으면 소유자/그룹/권한을 원하는 상태로 맞춘다.
  # 따라서 스크립트를 여러 번 실행해도 같은 최종 상태를 유지하기 쉽다.

  # 앱 루트: agent-admin이 소유하고 agent-core 그룹만 접근한다. 0750 = 소유자 rwx, 그룹 rx, 기타 접근 불가.
  install -d -o agent-admin -g agent-core -m 0750 "$AGENT_HOME"

  # 업로드 디렉터리: agent-common 그룹이 협업으로 파일을 읽고 쓸 수 있다.
  # 2770의 앞자리 2는 setgid로, 새로 생성되는 파일/디렉터리가 agent-common 그룹을 상속하게 한다.
  install -d -o agent-admin -g agent-common -m 2770 "$UPLOAD_DIR"

  # 키 디렉터리: 민감 파일 영역이므로 agent-core 그룹만 읽고 쓸 수 있게 제한한다.
  # setgid를 켜서 새 키 파일도 agent-core 그룹을 유지하도록 한다.
  install -d -o agent-admin -g agent-core -m 2770 "$KEY_DIR"

  # 운영 스크립트 디렉터리: 스크립트 작성/관리 주체는 agent-dev, 실행/접근 그룹은 agent-core로 둔다.
  install -d -o agent-dev -g agent-core -m 0750 "$BIN_DIR"

  # 로그 디렉터리: 앱/관제 로그를 agent-core 그룹이 관리하고, 기타 사용자는 접근하지 못하게 한다.
  # setgid로 monitor.log, cron.log 같은 새 로그 파일의 그룹 일관성을 유지한다.
  install -d -o agent-admin -g agent-core -m 2770 "$LOG_DIR"

  # 앱 호환용 secret.key와 미션 검증용 t_secret.key를 모두 준비한다.
  write_key_file "$APP_KEY_FILE"
  write_key_file "$MISSION_KEY_FILE"

  # 키 파일 생성 후 최종 소유자/권한을 다시 강제해 재실행 시에도 안전한 상태로 맞춘다.
  secure_key_file "$APP_KEY_FILE"
  secure_key_file "$MISSION_KEY_FILE"

  # 평가자가 확인하기 쉽도록 최종 경로를 출력한다.
  info "Directory setup completed"
  info "AGENT_HOME=$AGENT_HOME"
  info "UPLOAD_DIR=$UPLOAD_DIR"
  info "APP_KEY_FILE=$APP_KEY_FILE"
  info "MISSION_KEY_FILE=$MISSION_KEY_FILE"
  info "LOG_DIR=$LOG_DIR"
}

main "$@"
