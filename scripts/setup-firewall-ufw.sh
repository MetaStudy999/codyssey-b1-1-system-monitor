#!/usr/bin/env bash

# B1-1 미션의 방화벽 정책을 UFW로 구성하는 스크립트입니다.
#
# 실행 위치:
#   - macOS 호스트가 아니라 OrbStack Ubuntu 24.04 VM cds-ubuntu24에서 실행합니다.
#   - UFW는 Linux 방화벽 관리 도구이므로 macOS Terminal에서 직접 실행하지 않습니다.
#   - 저장소 루트에서 다음처럼 실행하는 것을 기준으로 합니다.
#       sudo bash scripts/setup-firewall-ufw.sh --apply
#
# 이 스크립트가 적용하는 정책:
#   - 기본 inbound 트래픽은 차단합니다.
#   - 기본 outbound 트래픽은 허용합니다.
#   - SSH 접속용 20022/tcp만 허용합니다.
#   - agent 앱 접속용 15034/tcp만 허용합니다.
#
# 운영 관점의 의미:
#   - 필요한 포트만 열어 공격 표면을 줄입니다.
#   - SSH 기본 포트인 22번 대신 20022번을 사용해 무작위 스캔 노출을 낮춥니다.
#   - 앱 포트 15034는 미션 앱의 Boot Sequence 이후 외부 확인에 필요하므로 허용합니다.
#
# 안전장치:
#   - 기본 실행은 dry-run입니다. --apply를 붙이지 않으면 실제 방화벽을 변경하지 않습니다.
#   - --apply를 사용하면 기존 UFW 규칙을 reset한 뒤 미션 포트만 다시 허용합니다.
#   - 원격 SSH 세션에서 실행하기 전에는 sshd가 20022/tcp로 LISTEN 중인지 먼저 확인해야 합니다.
#       sudo ss -tulnp | grep ssh

# set -u:
#   - 정의되지 않은 변수를 사용하면 즉시 오류로 처리합니다.
#   - 포트 값이 비어 있거나 오타가 있는 상태로 방화벽을 적용하는 실수를 줄입니다.
set -u

# SSH_PORT:
#   - B1-1 요구사항의 SSH 포트입니다.
#   - 환경 변수 SSH_PORT를 미리 지정하면 다른 값으로 테스트할 수 있지만 기본값은 20022입니다.
SSH_PORT="${SSH_PORT:-20022}"

# APP_PORT:
#   - agent 앱이 LISTEN해야 하는 포트입니다.
#   - 미션의 필수 환경 변수 이름인 AGENT_PORT를 우선 사용하고, 없으면 15034를 사용합니다.
APP_PORT="${AGENT_PORT:-15034}"

# APPLY:
#   - 실제 UFW 변경 여부를 저장하는 플래그입니다.
#   - 기본값 false는 dry-run을 의미하며, --apply 옵션을 받은 경우에만 true가 됩니다.
APPLY="false"

# 일반 진행 메시지를 표준 출력(stdout)으로 출력합니다.
# README 증빙에 붙여 넣었을 때 단계별 흐름이 보이도록 [INFO] prefix를 붙입니다.
info() {
  printf '[INFO] %s\n' "$*"
}

# 경고 메시지를 표준 출력(stdout)으로 출력합니다.
# 실행을 즉시 중단할 정도는 아니지만 사용자가 확인해야 하는 위험 지점을 표시합니다.
warning() {
  printf '[WARNING] %s\n' "$*"
}

# 오류 메시지를 표준 에러(stderr)로 출력합니다.
# stderr로 보내면 정상 출력과 실패 원인을 분리해서 확인하기 쉽습니다.
error() {
  printf '[ERROR] %s\n' "$*" >&2
}

# 사용법을 출력합니다.
# here document를 작은따옴표로 감싼 이유:
#   - USAGE 블록 안의 $ 같은 문자가 있다면 변수로 확장되지 않고 그대로 출력됩니다.
#   - 도움말은 실행 환경과 무관하게 항상 같은 문구를 보여 주는 편이 안전합니다.
usage() {
  cat <<'USAGE'
Usage:
  sudo scripts/setup-firewall-ufw.sh --apply

Without --apply, this script only prints the intended policy.
USAGE
}

# 방화벽 변경은 시스템 네트워크 정책을 수정하므로 root 권한이 필요합니다.
# id -u 결과가 0이면 root이며, sudo로 실행한 경우도 이 조건을 만족합니다.
# root가 아니면 UFW 명령이 중간에 실패할 수 있으므로 초기에 명확한 메시지로 종료합니다.
require_root() {
  if [ "$(id -u)" -ne 0 ]; then
    error "This script must be run with sudo or as root on cds-ubuntu24."
    exit 1
  fi
}

# UFW 명령이 설치되어 있는지 확인합니다.
# command -v:
#   - PATH에서 실행 파일을 찾을 수 있는지 검사합니다.
#   - 설치되지 않은 상태에서 ufw reset 같은 명령을 실행하기 전에 친절한 안내를 제공합니다.
# >/dev/null 2>&1:
#   - 명령 존재 여부만 필요하므로 화면 출력은 숨깁니다.
check_ufw() {
  if ! command -v ufw >/dev/null 2>&1; then
    error "ufw is not installed. Install it first: sudo apt update && sudo apt install -y ufw"
    exit 1
  fi
}

# 실제 적용 전에 어떤 정책이 들어갈지 출력합니다.
# 이 함수는 dry-run과 --apply 실행 모두에서 먼저 호출됩니다.
# 평가자와 학습자가 "열리는 포트가 정확히 무엇인지" 적용 전에 확인할 수 있게 합니다.
show_plan() {
  info "Planned UFW policy"
  info "Default incoming: deny"
  info "Default outgoing: allow"
  info "Allow: ${SSH_PORT}/tcp"
  info "Allow: ${APP_PORT}/tcp"
  warning "Applying this policy resets existing UFW rules so only the mission ports remain."
  warning "Before enabling UFW over SSH, confirm that SSH is already listening on ${SSH_PORT}/tcp."
}

# 미션 기준 UFW 정책을 실제로 적용합니다.
# ufw --force reset:
#   - 기존 UFW 규칙을 초기화합니다.
#   - B1-1 평가 기준은 "필요한 포트만 허용"이므로 이전 실습에서 남은 규칙을 제거합니다.
# ufw default deny incoming:
#   - 외부에서 들어오는 연결은 기본 차단합니다.
# ufw default allow outgoing:
#   - 서버가 패키지 설치, 업데이트, 외부 API 호출 등을 할 수 있도록 outbound는 허용합니다.
# ufw allow <port>/tcp:
#   - TCP 포트 단위로 필요한 서비스만 허용합니다.
# ufw --force enable:
#   - 대화형 확인 질문 없이 UFW를 활성화합니다.
#   - 스크립트 자동화에서는 중간 프롬프트 때문에 멈추지 않도록 --force를 사용합니다.
apply_policy() {
  ufw --force reset
  ufw default deny incoming
  ufw default allow outgoing
  ufw allow "${SSH_PORT}/tcp"
  ufw allow "${APP_PORT}/tcp"
  ufw --force enable
}

# 전체 실행 흐름을 모아 둔 진입 함수입니다.
# 순서가 중요합니다.
#   1. --help 처리
#   2. --apply 옵션 확인
#   3. root 권한 확인
#   4. ufw 설치 여부 확인
#   5. 적용 예정 정책 출력
#   6. dry-run이면 현재 상태만 보여 주고 종료
#   7. --apply이면 정책 적용 후 결과 출력
main() {
  # 도움말 옵션은 시스템 변경이 필요 없으므로 권한 확인보다 먼저 처리합니다.
  if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
    usage
    exit 0
  fi

  # 첫 번째 인자가 --apply이면 실제 변경 모드로 전환합니다.
  # 그 외의 경우에는 APPLY가 false로 남아 dry-run으로 동작합니다.
  if [ "${1:-}" = "--apply" ]; then
    APPLY="true"
  fi

  require_root
  check_ufw
  show_plan

  # --apply 없이 실행한 경우에는 방화벽을 변경하지 않습니다.
  # ufw status verbose가 실패하더라도 dry-run 안내 자체는 끝난 상태이므로 || true로 종료를 막습니다.
  if [ "$APPLY" != "true" ]; then
    warning "Dry run only. Re-run with --apply to change UFW."
    ufw status verbose || true
    exit 0
  fi

  apply_policy
  info "UFW status after applying policy:"
  # 최종 상태를 즉시 출력해 README 증빙으로 사용할 수 있게 합니다.
  ufw status verbose
}

# 스크립트를 실행하면 main 함수부터 시작합니다.
# "$@"는 현재 스크립트로 전달된 인자를 그대로 main에 넘깁니다.
main "$@"
