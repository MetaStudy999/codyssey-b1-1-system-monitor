#!/usr/bin/env bash

# B1-1 보너스 리포트 스크립트.
#
# 이 스크립트의 목적은 monitor.sh가 누적 기록한 monitor.log를 읽어
# CPU, MEM, DISK_USED 사용률의 평균/최대/최소를 계산하는 것이다.
#
# monitor.log 한 줄은 다음 형식을 기대한다.
#
#   [YYYY-MM-DD HH:MM:SS] PID:1234 CPU:2.3% MEM:4.1% DISK_USED:37%
#
# report.sh는 각 줄에서 시간, CPU, MEM, DISK_USED 값을 파싱한다.
# 파싱 가능한 줄은 통계 계산에 포함하고, 형식이 깨진 줄은 경고를 출력한 뒤 건너뛴다.
#
# 선택적으로 --from, --to 옵션을 받아 특정 시간 구간만 분석할 수 있다.
# 시간 비교는 "YYYY-MM-DD HH:MM:SS" 형식의 문자열 정렬이 시간 순서와 일치한다는 점을 이용한다.

set -u

# 분석 대상 로그 파일.
# 기본값은 미션 기준 경로인 /var/log/agent-app/monitor.log 이다.
# 테스트나 평가 중 다른 파일을 분석해야 하면 LOG_FILE 환경 변수로 덮어쓸 수 있다.
#
# 예:
#   LOG_FILE=./sample-monitor.log ./bin/report.sh
LOG_FILE="${LOG_FILE:-/var/log/agent-app/monitor.log}"

# 시간 필터 기본값.
# 값이 비어 있으면 해당 방향의 필터를 적용하지 않는다.
# FROM_TIME이 비어 있으면 시작 시간 제한 없음, TO_TIME이 비어 있으면 종료 시간 제한 없음이다.
FROM_TIME=""
TO_TIME=""

# 일반 정보 메시지 출력 함수.
# 정상 완료처럼 사용자가 알아두면 좋은 상태를 stdout으로 출력한다.
info() {
  printf '[INFO] %s\n' "$*"
}

# 오류 메시지 출력 함수.
# 로그 파일 없음, 빈 로그, 분석 가능한 샘플 없음처럼 실행을 실패로 끝내야 하는 상황에 사용한다.
# stderr로 출력하면 cron이나 shell에서 일반 출력과 오류 출력을 구분해서 다룰 수 있다.
error() {
  printf '[ERROR] %s\n' "$*" >&2
}

# 사용법 출력 함수.
# --help 또는 잘못된 인자가 들어왔을 때 평가자가 실행 방법을 바로 확인할 수 있게 한다.
usage() {
  cat <<'USAGE'
Usage:
  bin/report.sh
  bin/report.sh --from "2026-05-27 10:00:00" --to "2026-05-27 11:00:00"

Environment:
  LOG_FILE=/path/to/monitor.log
USAGE
}

# 명령행 인자를 해석한다.
#
# 지원 옵션:
# - --from "YYYY-MM-DD HH:MM:SS": 이 시간 이후의 로그만 분석
# - --to   "YYYY-MM-DD HH:MM:SS": 이 시간 이전의 로그만 분석
# - --help, -h: 사용법 출력
#
# 여기서는 시간 형식 자체를 엄격히 검증하지 않는다.
# 대신 awk 단계에서 로그 라인의 timestamp 문자열과 단순 비교한다.
# 따라서 사용자는 monitor.log와 같은 "YYYY-MM-DD HH:MM:SS" 형식으로 입력해야 한다.
parse_args() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --from)
        if [ "$#" -lt 2 ]; then
          error "Missing value for --from"
          usage
          exit 1
        fi
        FROM_TIME="${2:-}"
        shift 2
        ;;
      --to)
        if [ "$#" -lt 2 ]; then
          error "Missing value for --to"
          usage
          exit 1
        fi
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

# 전체 실행 흐름.
# 1. 인자 파싱
# 2. 로그 파일 존재 여부 확인
# 3. 로그 파일이 비어 있는지 확인
# 4. awk로 로그를 한 줄씩 분석해서 통계 출력
main() {
  parse_args "$@"

  # 로그 파일이 없으면 분석 자체가 불가능하다.
  # 친절한 오류 메시지를 남기고 exit 1로 종료해 실패 상태를 명확히 한다.
  if [ ! -f "$LOG_FILE" ]; then
    error "Log file does not exist: $LOG_FILE"
    exit 1
  fi

  # 파일은 있지만 내용이 없으면 평균 계산 시 0으로 나누는 문제가 생길 수 있다.
  # 빈 로그는 정상 리포트가 아니므로 여기서 미리 중단한다.
  if [ ! -s "$LOG_FILE" ]; then
    error "Log file is empty: $LOG_FILE"
    exit 1
  fi

  # awk가 실제 통계 계산을 담당한다.
  #
  # shell에서 FROM_TIME, TO_TIME을 awk 변수로 넘기는 이유:
  # - awk 내부에서 각 로그 줄의 timestamp와 비교하기 위해서다.
  # - shell 변수 직접 참조 대신 -v를 사용하면 공백이 포함된 시간 문자열도 안전하게 전달된다.
  if ! awk -v from_time="$FROM_TIME" -v to_time="$TO_TIME" '
    # CPU:2.3%, MEM:4.1%, DISK_USED:37% 같은 값에서 % 기호를 제거한다.
    # gsub은 value 문자열 안의 모든 %를 지운다.
    # 반환값은 숫자처럼 보이는 문자열이며, 실제 숫자 변환은 update_stats 호출 시 value + 0으로 처리한다.
    function clean_percent(value) {
      gsub(/%/, "", value)
      return value
    }

    # 특정 지표의 합계, 최소값, 최대값을 갱신한다.
    #
    # name:
    #   CPU, MEM, DISK_USED 중 하나
    #
    # value:
    #   현재 로그 줄에서 파싱한 사용률 숫자
    #
    # ts:
    #   현재 로그 줄의 timestamp
    #
    # 배열 역할:
    # - sum[name]      : 평균 계산을 위한 누적 합계
    # - min[name]      : 지금까지 발견한 최소값
    # - max[name]      : 지금까지 발견한 최대값
    # - min_time[name] : 최소값이 기록된 시간
    # - max_time[name] : 최대값이 기록된 시간
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

    # 값이 0 이상의 정수 또는 소수인지 확인한다.
    # monitor.log 형식이 깨져 CPU:abc% 같은 값이 들어오면 통계에 포함하지 않는다.
    function is_number(value) {
      return value ~ /^[0-9]+([.][0-9]+)?$/
    }

    # awk가 로그 파일을 읽기 전에 한 번 실행된다.
    # 파싱 실패 라인 수를 0으로 초기화한다.
    BEGIN {
      parse_errors = 0
    }

    # 여기부터는 monitor.log의 각 줄마다 한 번씩 실행된다.
    {
      # 로그 시작 부분의 [YYYY-MM-DD HH:MM:SS]에서 대괄호를 제외한 timestamp만 뽑는다.
      # substr($0, 2, 19)는 2번째 문자부터 19글자를 가져온다.
      # 예: "[2026-05-27 14:10:00]" -> "2026-05-27 14:10:00"
      ts = substr($0, 2, 19)

      # --from이 지정된 경우, 시작 시간보다 오래된 로그는 분석하지 않는다.
      # timestamp 형식이 YYYY-MM-DD HH:MM:SS이면 문자열 비교 결과가 시간 순서와 일치한다.
      if (from_time != "" && ts < from_time) {
        next
      }
      # --to가 지정된 경우, 종료 시간보다 나중의 로그는 분석하지 않는다.
      if (to_time != "" && ts > to_time) {
        next
      }

      # 한 줄 안에서 CPU/MEM/DISK_USED 필드를 찾기 위해 초기값을 빈 문자열로 둔다.
      # 필드를 끝까지 찾지 못하면 아래 is_number 검사에서 실패한다.
      cpu = mem = disk = ""

      # awk의 NF는 현재 줄의 필드 개수다.
      # 공백 기준으로 나뉜 각 필드를 순회하면서 CPU:, MEM:, DISK_USED: 접두어를 찾는다.
      for (i = 1; i <= NF; i++) {
        if ($i ~ /^CPU:/) {
          # "CPU:"는 4글자이므로 5번째 문자부터 실제 값이다.
          cpu = clean_percent(substr($i, 5))
        } else if ($i ~ /^MEM:/) {
          # "MEM:"도 4글자이므로 5번째 문자부터 실제 값이다.
          mem = clean_percent(substr($i, 5))
        } else if ($i ~ /^DISK_USED:/) {
          # "DISK_USED:"는 10글자이므로 11번째 문자부터 실제 값이다.
          disk = clean_percent(substr($i, 11))
        }
      }

      # CPU, MEM, DISK_USED 중 하나라도 숫자가 아니면 해당 줄은 통계에서 제외한다.
      # 잘못된 줄 전체를 stderr에 남기면 평가자나 운영자가 로그 형식 문제를 추적할 수 있다.
      if (!is_number(cpu) || !is_number(mem) || !is_number(disk)) {
        printf("[WARNING] Skipping unparsable line %d: %s\n", NR, $0) > "/dev/stderr"
        parse_errors++
        next
      }

      # 여기까지 도달한 줄만 정상 샘플로 계산한다.
      # count는 평균 계산의 분모가 된다.
      count++

      # value + 0은 awk에서 문자열을 숫자로 변환하는 관용적인 방식이다.
      # 예: "2.3" + 0 -> 2.3
      update_stats("CPU", cpu + 0, ts)
      update_stats("MEM", mem + 0, ts)
      update_stats("DISK_USED", disk + 0, ts)
    }

    # awk가 모든 줄을 처리한 뒤 한 번 실행된다.
    # 여기에서 최종 리포트를 출력한다.
    END {
      # 시간 필터가 너무 좁거나 모든 줄이 파싱 실패하면 count가 0일 수 있다.
      # 이 상태에서 평균을 계산하면 0으로 나누게 되므로 오류로 종료한다.
      if (count == 0) {
        print "[ERROR] No analyzable monitor samples found" > "/dev/stderr"
        exit 1
      }

      # 리포트 헤더.
      # 분석한 파일, 시간 필터, 샘플 수, 건너뛴 줄 수를 먼저 보여준다.
      print "====== STATISTICS REPORT ======"
      printf("Log File    : %s\n", FILENAME)
      printf("From        : %s\n", from_time == "" ? "(not set)" : from_time)
      printf("To          : %s\n", to_time == "" ? "(not set)" : to_time)
      printf("Samples     : %d\n", count)
      printf("Parse Skip  : %d\n\n", parse_errors)

      # 각 지표의 평균은 누적 합계 / 정상 샘플 수로 계산한다.
      # 최대/최소값 옆에는 해당 값이 나온 시간을 함께 출력한다.
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
  ' "$LOG_FILE"; then
    exit 1
  fi

  # awk가 정상 종료되면 리포트 생성이 끝났음을 알려준다.
  # 위의 if ! awk ... then exit 1 구조 때문에 awk 내부 오류가 발생하면
  # 이 메시지를 출력하지 않고 실패 상태를 호출자에게 전달한다.
  info "Report completed"
}

# 스크립트의 진입점.
# "$@"를 그대로 전달해야 --from, --to 같은 사용자의 인자가 parse_args까지 보존된다.
main "$@"
