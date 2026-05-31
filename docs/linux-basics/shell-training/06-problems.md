# 문제 모음: 리눅스 쉘 프로그램 트레이닝

## 사용 방법

각 문제는 직접 실행한 명령, 출력 결과, 짧은 설명을 함께 남긴다.

권장 답안 형식:

```text
문제 번호:
실행 명령:
확인 결과:
설명:
```

## 입문 문제

1. 현재 작업 디렉터리를 출력하는 스크립트 `where-am-i.sh`를 작성하라.
2. `USER_NAME` 환경 변수가 없으면 현재 사용자(`whoami`)를 출력하고, 있으면 그 값을 출력하라.
3. `bash -n`으로 문법 오류를 잡는 이유를 설명하라.
4. `chmod 750 script.sh`에서 소유자, 그룹, others 권한을 각각 설명하라.
5. exit code가 `0`이 아닌 명령을 하나 실행하고 `echo $?` 결과를 확인하라.

## 기초 문제

1. `info`, `warning`, `error` 함수를 가진 스크립트를 작성하라.
2. 인자로 받은 파일이 있으면 `[INFO] exists`, 없으면 `[ERROR] missing`을 출력하고 실패 종료하라.
3. 배열 `("agent-admin" "agent-dev" "agent-test")`를 반복해 각 이름을 출력하라.
4. `getent group agent-core` 명령이 성공할 때와 실패할 때를 조건문으로 처리하라.
5. 멱등성을 고려해 이미 있는 디렉터리는 다시 만들지 않는 스크립트를 작성하라.

## 심화 문제

1. 특정 PID의 CPU/MEM 사용률을 출력하는 스크립트를 작성하라.
2. `ss -tuln` 출력에서 인자로 받은 포트가 있는지 확인하라.
3. 로그 한 줄을 `[YYYY-MM-DD HH:MM:SS] PID:... CPU:...% MEM:...% DISK_USED:...%` 형식으로 append하라.
4. CPU 값이 `20`보다 크면 `[WARNING] CPU threshold exceeded`를 출력하라.
5. `bin/monitor.sh`에서 `find_agent_pid` 함수가 자기 자신을 제외해야 하는 이유를 설명하라.

## 응용 문제

1. `/tmp/sample-monitor.log`를 만들고 `LOG_FILE=/tmp/sample-monitor.log bash bin/report.sh`로 분석하라.
2. `report.sh`에 잘못된 로그 한 줄을 넣었을 때 어떤 메시지가 나오는지 확인하라.
3. `archive-old-logs.sh`를 `/tmp` 경로 주입 방식으로 실행하고 `.gz` 파일 생성을 확인하라.
4. cron 등록 줄에서 `2>&1`의 의미를 설명하라.
5. logrotate의 `copytruncate`가 필요한 상황을 설명하라.

## 프로젝트 문제

1. B1-1 전체 흐름을 10단계 이하로 요약하라.
2. `agent-test`가 `agent-core`에 들어가면 어떤 보안 문제가 생길 수 있는지 설명하라.
3. `monitor.sh`가 실패해야 하는 조건과 경고만 해야 하는 조건을 표로 정리하라.
4. `report.sh`의 평균/최대/최소 계산 방식을 말로 설명하라.
5. 로그가 갑자기 커질 때 단기 대응과 장기 대응을 나누어 설명하라.

## 실전 제출 과제

다음 요구사항을 만족하는 `mini-monitor.sh`를 작성하라.

- shebang을 포함한다.
- `set -u`를 사용한다.
- 인자로 받은 프로세스 패턴을 찾는다.
- 인자로 받은 포트를 `ss`로 확인한다.
- PID, CPU, MEM, DISK_USED를 수집한다.
- 로그 파일은 `LOG_FILE` 환경 변수로 바꿀 수 있게 한다.
- 로그는 반드시 `>>`로 누적한다.
- 프로세스 또는 포트가 없으면 `exit 1`로 종료한다.
- CPU가 20보다 크면 WARNING을 출력한다.

실행 예시:

```bash
LOG_FILE=./mini-monitor.log bash mini-monitor.sh bash 22
tail -n 5 mini-monitor.log
```

## 예시 답안

### 입문 문제 답안

1. `where-am-i.sh`

```bash
#!/usr/bin/env bash

pwd
```

2. `USER_NAME` 기본값

```bash
#!/usr/bin/env bash

USER_NAME="${USER_NAME:-$(whoami)}"
echo "$USER_NAME"
```

3. `bash -n`은 스크립트를 실제 실행하지 않고 문법 오류만 확인한다. 시스템 변경 전 안전하게 검사할 때 사용한다.

4. `chmod 750 script.sh`는 소유자 `rwx`, 그룹 `r-x`, others 권한 없음이다.

5. 실패 exit code 확인 예:

```bash
ls /not-existing-path
echo $?
```

존재하지 않는 경로이므로 `echo $?`는 보통 `2` 같은 0이 아닌 값을 출력한다.

### 기초 문제 답안

1. 메시지 함수:

```bash
info() {
  printf '[INFO] %s\n' "$*"
}

warning() {
  printf '[WARNING] %s\n' "$*"
}

error() {
  printf '[ERROR] %s\n' "$*" >&2
}
```

2. 파일 존재 확인:

```bash
#!/usr/bin/env bash

set -u

TARGET_FILE="${1:-}"

if [ -z "$TARGET_FILE" ]; then
  printf '[ERROR] file path is required\n' >&2
  exit 1
fi

if [ -f "$TARGET_FILE" ]; then
  printf '[INFO] exists\n'
else
  printf '[ERROR] missing\n' >&2
  exit 1
fi
```

3. 배열 반복:

```bash
USERS=("agent-admin" "agent-dev" "agent-test")

for user_name in "${USERS[@]}"; do
  echo "$user_name"
done
```

4. 그룹 존재 조건문:

```bash
if getent group agent-core >/dev/null 2>&1; then
  echo "[INFO] group exists: agent-core"
else
  echo "[ERROR] group missing: agent-core" >&2
  exit 1
fi
```

5. 멱등적인 디렉터리 생성:

```bash
TARGET_DIR="${1:-./sample-dir}"

if [ -d "$TARGET_DIR" ]; then
  echo "[INFO] directory already exists: $TARGET_DIR"
else
  mkdir -p "$TARGET_DIR"
  echo "[INFO] created directory: $TARGET_DIR"
fi
```

### 심화 문제 답안

1. PID CPU/MEM 출력:

```bash
#!/usr/bin/env bash

set -u

PID="${1:-$$}"
ps -p "$PID" -o pcpu= -o pmem=
```

2. 포트 확인:

```bash
#!/usr/bin/env bash

set -u

PORT="${1:-15034}"

if ss -tuln 2>/dev/null | awk -v port=":$PORT" '$0 ~ port { found=1 } END { exit found ? 0 : 1 }'; then
  echo "[OK] port is listening: $PORT"
else
  echo "[ERROR] port is not listening: $PORT" >&2
  exit 1
fi
```

3. 로그 append:

```bash
LOG_FILE="${LOG_FILE:-./monitor.log}"
TIMESTAMP="$(date '+%Y-%m-%d %H:%M:%S')"
printf '[%s] PID:%s CPU:%s%% MEM:%s%% DISK_USED:%s%%\n' "$TIMESTAMP" "$$" "0.0" "0.1" "10" >>"$LOG_FILE"
```

4. CPU WARNING:

```bash
CPU="20.5"

if awk -v cpu="$CPU" 'BEGIN { exit (cpu > 20) ? 0 : 1 }'; then
  echo "[WARNING] CPU threshold exceeded"
fi
```

5. `find_agent_pid`가 자기 자신을 제외하지 않으면 `monitor.sh` 명령줄에 포함된 `agent-app` 같은 문자열 때문에 관제 스크립트 자신이나 보조 프로세스를 앱으로 오인할 수 있다.

### 응용 문제 답안

1. 샘플 로그 생성과 분석:

```bash
cat >/tmp/sample-monitor.log <<'EOF'
[2026-05-31 10:00:00] PID:100 CPU:1.0% MEM:2.0% DISK_USED:30%
[2026-05-31 10:01:00] PID:100 CPU:3.0% MEM:4.0% DISK_USED:31%
EOF

LOG_FILE=/tmp/sample-monitor.log bash bin/report.sh
```

2. 잘못된 로그 줄:

```bash
printf 'bad line\n' >>/tmp/sample-monitor.log
LOG_FILE=/tmp/sample-monitor.log bash bin/report.sh
```

예상 결과는 `[WARNING] Skipping unparsable line ...` 메시지가 출력되고, 정상 파싱 가능한 줄만 통계에 포함되는 것이다.

3. `/tmp` 경로로 아카이브 테스트:

```bash
mkdir -p /tmp/agent-log-test /tmp/agent-archive-test
printf 'old log\n' >/tmp/agent-log-test/old.log
touch -d '8 days ago' /tmp/agent-log-test/old.log
AGENT_LOG_DIR=/tmp/agent-log-test ARCHIVE_DIR=/tmp/agent-archive-test bash scripts/archive-old-logs.sh
find /tmp/agent-archive-test -type f -name '*.gz' -ls
```

4. `2>&1`은 stderr를 stdout과 같은 대상으로 보낸다는 뜻이다. cron 등록 줄에서는 오류 메시지도 `cron.log`에 함께 남기기 위해 사용한다.

5. `copytruncate`는 실행 중인 프로세스나 cron이 같은 로그 파일 경로에 계속 쓰는 상황에서 유용하다. 기존 파일 내용을 회전 파일로 복사하고 원본 파일을 비워서, 파일 경로를 바꾸지 않고 로그 기록을 계속할 수 있다.

### 프로젝트 문제 답안

1. B1-1 전체 흐름:

```text
1. Ubuntu 실습 환경 확인
2. 계정과 그룹 생성
3. 디렉터리와 권한 설정
4. 앱 압축 해제와 배치
5. SSH와 UFW 설정
6. 환경 변수와 키 파일 설정
7. 앱 실행과 Boot Sequence 확인
8. monitor.sh 직접 실행 검증
9. cron과 logrotate 적용
10. report.sh와 로그 아카이브 검증
```

2. `agent-test`가 `agent-core`에 들어가면 테스트 계정이 API 키와 운영 로그 같은 민감 리소스에 접근할 수 있다. 최소 권한 원칙에 어긋난다.

3. `monitor.sh` 조건 정리:

| 조건 | 처리 |
|---|---|
| 앱 프로세스 없음 | 실패, `exit 1` |
| `15034` 포트 미LISTEN | 실패, `exit 1` |
| 방화벽 비활성 | WARNING 후 계속 |
| CPU > 20% | WARNING 후 계속 |
| MEM > 10% | WARNING 후 계속 |
| DISK_USED > 80% | WARNING 후 계속 |

4. `report.sh`는 각 로그 줄에서 CPU/MEM/DISK_USED 값을 숫자로 파싱하고, 정상 샘플마다 합계와 최소/최대값을 갱신한다. 마지막에 `합계 / 샘플 수`로 평균을 계산한다.

5. 로그 급증 대응:

| 구분 | 대응 |
|---|---|
| 단기 | `tail`, `du`, `df`로 원인을 확인하고 필요하면 logrotate 강제 실행 또는 임시 압축을 수행한다. |
| 장기 | 로그 레벨 조정, logrotate 정책 점검, 아카이브/보존 기간 정책을 정리한다. |

### 실전 제출 과제 답안: `mini-monitor.sh`

```bash
#!/usr/bin/env bash

set -u

PROCESS_PATTERN="${1:-}"
PORT="${2:-}"
LOG_FILE="${LOG_FILE:-./mini-monitor.log}"

if [ -z "$PROCESS_PATTERN" ] || [ -z "$PORT" ]; then
  echo "[ERROR] Usage: mini-monitor.sh <process-pattern> <port>" >&2
  exit 1
fi

PID="$(pgrep -f "$PROCESS_PATTERN" | awk -v self="$$" '$1 != self { print $1; exit }')"

if [ -z "$PID" ]; then
  echo "[ERROR] process not found: $PROCESS_PATTERN" >&2
  exit 1
fi

if ! ss -tuln 2>/dev/null | awk -v port=":$PORT" '$0 ~ port { found=1 } END { exit found ? 0 : 1 }'; then
  echo "[ERROR] port is not listening: $PORT" >&2
  exit 1
fi

RESOURCE_VALUES="$(ps -p "$PID" -o pcpu= -o pmem= 2>/dev/null | awk 'NR == 1 { print $1, $2 }')"
CPU="$(printf '%s\n' "$RESOURCE_VALUES" | awk '{ print $1 }')"
MEM="$(printf '%s\n' "$RESOURCE_VALUES" | awk '{ print $2 }')"
DISK_USED="$(df -P / | awk 'NR == 2 { gsub(/%/, "", $5); print $5 }')"
TIMESTAMP="$(date '+%Y-%m-%d %H:%M:%S')"

if [ -z "$CPU" ] || [ -z "$MEM" ] || [ -z "$DISK_USED" ]; then
  echo "[ERROR] failed to collect resource usage" >&2
  exit 1
fi

if awk -v cpu="$CPU" 'BEGIN { exit (cpu > 20) ? 0 : 1 }'; then
  echo "[WARNING] CPU threshold exceeded"
fi

printf '[%s] PID:%s CPU:%s%% MEM:%s%% DISK_USED:%s%%\n' "$TIMESTAMP" "$PID" "$CPU" "$MEM" "$DISK_USED" >>"$LOG_FILE"
echo "[INFO] Log appended: $LOG_FILE"
```

검증:

```bash
bash -n mini-monitor.sh
LOG_FILE=./mini-monitor.log bash mini-monitor.sh bash 22
tail -n 5 mini-monitor.log
```

## 자기 점검

- [ ] 스크립트 실행 전 `bash -n`을 수행했다.
- [ ] 변수에는 따옴표를 사용했다.
- [ ] 실패해야 하는 조건에서 `exit 1`을 사용했다.
- [ ] 경고 조건과 실패 조건을 구분했다.
- [ ] 로그는 append 방식으로 남겼다.
- [ ] 결과를 말로 설명할 수 있다.
