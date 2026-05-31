#!/usr/bin/env bash

# B1-1 보너스 스크립트: 오래된 로그 압축 및 아카이브 정리
#
# 이 스크립트의 목적은 운영 중 계속 쌓이는 /var/log/agent-app/*.log 파일을
# 시간 기준으로 정리하는 것이다.
#
# 수행 정책:
# 1. LOG_DIR 아래의 *.log 파일 중 COMPRESS_DAYS일 이상 지난 파일을 gzip으로 압축한다.
# 2. 압축한 .gz 파일을 ARCHIVE_DIR로 이동한다.
# 3. ARCHIVE_DIR 안의 *.gz 파일 중 DELETE_DAYS일 이상 지난 파일을 삭제한다.
#
# 주의:
# - 삭제 대상은 원본 *.log가 아니라, 이미 보관된 오래된 *.gz 아카이브 파일이다.
# - 권한이 부족하거나 대상 파일이 없어도 스크립트가 비정상 종료하지 않고
#   [WARNING] 또는 [INFO] 메시지로 상황을 남기도록 작성했다.

# set -u는 선언되지 않은 변수를 사용하면 오류로 처리한다.
# 운영 스크립트에서 변수 오타가 조용히 넘어가면 잘못된 경로를 대상으로
# 작업할 수 있으므로, 초기에 실수를 발견하기 위해 사용한다.
set -u

# 기본 경로와 보존 정책이다.
#
# ${VAR:-default} 형태는 환경 변수 VAR이 이미 설정되어 있으면 그 값을 사용하고,
# 설정되어 있지 않으면 default 값을 사용한다.
# 따라서 테스트할 때는 다음처럼 임시 경로를 주입할 수 있다.
#
#   AGENT_LOG_DIR=/tmp/agent-log ARCHIVE_DIR=/tmp/archive ./scripts/archive-old-logs.sh
#
# 실제 미션 환경에서는 기본값이 다음 요구사항과 연결된다.
# - 로그 대상: /var/log/agent-app/*.log
# - 아카이브 경로: /var/log/monitor/agent-app/archive
# - 7일 이상 지난 로그 압축
# - 30일 이상 지난 아카이브 삭제
LOG_DIR="${AGENT_LOG_DIR:-/var/log/agent-app}"
ARCHIVE_DIR="${ARCHIVE_DIR:-/var/log/monitor/agent-app/archive}"
COMPRESS_DAYS="${COMPRESS_DAYS:-7}"
DELETE_DAYS="${DELETE_DAYS:-30}"

# 아래 출력 함수들은 메시지 형식을 한 곳에서 통일하기 위한 헬퍼다.
# 평가자가 실행 결과를 볼 때 INFO/WARNING/ERROR를 쉽게 구분할 수 있다.
info() {
  printf '[INFO] %s\n' "$*"
}

warning() {
  printf '[WARNING] %s\n' "$*"
}

error() {
  printf '[ERROR] %s\n' "$*" >&2
}

# 아카이브 디렉토리를 확인하고, 없으면 생성한다.
#
# 반환값:
# - 0: 디렉토리가 이미 있거나 생성에 성공
# - 1: 권한 부족 등으로 생성 실패
#
# mkdir -p는 상위 디렉토리가 없어도 함께 생성한다.
# stderr는 2>/dev/null로 숨기고, 대신 사람이 읽기 쉬운 오류 메시지를 직접 출력한다.
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

# 오래된 원본 로그 파일을 압축한 뒤 아카이브 디렉토리로 이동한다.
#
# 이 함수는 다음 조건을 만족하는 파일만 처리한다.
# - LOG_DIR 바로 아래에 있는 일반 파일
# - 파일명이 *.log로 끝나는 파일
# - 수정 시간이 COMPRESS_DAYS일 이상 지난 파일
#
# 권한이 없거나 gzip/mv에 실패한 파일은 건너뛰고 다음 파일 처리를 계속한다.
# 운영 자동화에서는 일부 파일 하나 때문에 전체 정리가 멈추지 않도록 하는 것이 중요하다.
compress_and_move_old_logs() {
  # find 결과가 하나라도 있었는지 확인하기 위한 플래그다.
  # 대상이 없을 때도 조용히 끝내지 않고 INFO 메시지를 남기기 위해 사용한다.
  local found=0
  local compressed_path
  local archive_path

  # 로그 디렉토리가 없으면 압축할 대상도 없다.
  # 보너스 요구사항에 따라 비정상 종료하지 않고 경고만 출력한다.
  if [ ! -d "$LOG_DIR" ]; then
    warning "Log directory does not exist: $LOG_DIR"
    return 0
  fi

  # find ... -print0와 read -d ''를 함께 사용하면 파일명에 공백이 있어도 안전하다.
  # process substitution(< <(...))을 사용해 while 루프가 현재 셸에서 돌도록 했다.
  # 그래야 루프 안에서 바꾼 found 값이 루프 밖에서도 유지된다.
  while IFS= read -r -d '' log_file; do
    found=1

    # gzip으로 읽어야 하므로 파일 읽기 권한이 필요하고,
    # 압축 파일을 원본 로그와 같은 디렉토리에 잠시 만들기 때문에 디렉토리 쓰기 권한도 필요하다.
    # 권한이 부족하면 해당 파일만 건너뛰고 전체 스크립트는 계속 진행한다.
    if [ ! -r "$log_file" ] || [ ! -w "$(dirname "$log_file")" ]; then
      warning "Skipping due to insufficient permission: $log_file"
      continue
    fi

    # 압축 파일명에는 현재 시각을 붙인다.
    # 예: monitor.log.20260531153010.gz
    #
    # 같은 로그 파일을 여러 번 처리하더라도 파일명이 충돌하지 않도록 하기 위한 방식이다.
    compressed_path="${log_file}.$(date +%Y%m%d%H%M%S).gz"

    # gzip -c는 원본 파일을 삭제하지 않고 압축 결과를 표준 출력으로 보낸다.
    # 그 출력을 compressed_path로 저장하므로 원본 로그는 그대로 남는다.
    # 압축 실패 시에는 불완전하게 만들어졌을 수 있는 .gz 파일을 정리한다.
    if gzip -c "$log_file" >"$compressed_path"; then
      info "Compressed: $compressed_path"
    else
      warning "gzip failed: $log_file"
      rm -f "$compressed_path" 2>/dev/null || true
      continue
    fi

    # 압축 파일을 최종 아카이브 디렉토리로 이동한다.
    # basename을 사용해 경로는 ARCHIVE_DIR로 바꾸고 파일명만 유지한다.
    archive_path="$ARCHIVE_DIR/$(basename "$compressed_path")"
    if mv "$compressed_path" "$archive_path"; then
      info "Moved to archive: $archive_path"
    else
      warning "Move failed: $compressed_path -> $archive_path"
      continue
    fi

  # -mtime +N은 "N일보다 오래된 파일"을 의미한다.
  # COMPRESS_DAYS=7일 때 +6을 사용하면 수정 후 7일 이상 지난 파일이 대상이 된다.
  # -maxdepth 1은 하위 디렉토리까지 내려가지 않게 제한한다.
  done < <(find "$LOG_DIR" -maxdepth 1 -type f -name '*.log' -mtime +"$((COMPRESS_DAYS - 1))" -print0 2>/dev/null)

  if [ "$found" -eq 0 ]; then
    info "No old log files found for compression"
  fi
}

# 오래된 아카이브(.gz) 파일을 삭제한다.
#
# 삭제 대상:
# - ARCHIVE_DIR 바로 아래의 일반 파일
# - 파일명이 *.gz로 끝나는 파일
# - 수정 시간이 DELETE_DAYS일 이상 지난 파일
#
# 원본 로그 파일은 여기서 삭제하지 않는다.
delete_old_archives() {
  local found=0

  # 압축 대상 검색과 마찬가지로 -print0/read -d '' 조합을 사용해
  # 파일명에 공백이나 특수 문자가 있어도 안전하게 처리한다.
  while IFS= read -r -d '' archive_file; do
    found=1

    # rm -f는 파일이 없어도 오류를 내지 않는 삭제 방식이다.
    # 다만 권한 문제 등으로 삭제가 실패할 수 있으므로 결과를 확인해 메시지를 남긴다.
    if rm -f "$archive_file"; then
      info "Deleted old archive: $archive_file"
    else
      warning "Failed to delete old archive: $archive_file"
    fi

  # DELETE_DAYS=30일 때 +29를 사용해 30일 이상 지난 보관 파일을 찾는다.
  done < <(find "$ARCHIVE_DIR" -maxdepth 1 -type f -name '*.gz' -mtime +"$((DELETE_DAYS - 1))" -print0 2>/dev/null)

  if [ "$found" -eq 0 ]; then
    info "No old archive files found for deletion"
  fi
}

# 전체 실행 순서:
# 1. 아카이브 디렉토리 확인/생성
# 2. 오래된 로그 압축 및 이동
# 3. 오래된 아카이브 삭제
# 4. 완료 메시지 출력
main() {
  # 아카이브 디렉토리를 만들 수 없으면 이후 mv/delete 작업도 의미가 없다.
  # 단, 미션 요구사항상 권한 부족 상황에서 비정상 종료하지 않도록 exit 0으로 종료한다.
  if ! ensure_archive_dir; then
    warning "Archive cleanup stopped because archive directory is unavailable"
    exit 0
  fi

  compress_and_move_old_logs
  delete_old_archives
  info "Archive cleanup completed"
}

main "$@"
