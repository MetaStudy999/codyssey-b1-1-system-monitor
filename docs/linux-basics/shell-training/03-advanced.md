# 심화: 프로세스, 포트, 리소스, 로그 관제

## 이 단계의 목표

서비스가 실제로 살아 있는지 확인하는 관제 스크립트를 만든다.

이 단계는 현재 구현된 `bin/monitor.sh`를 이해하기 위한 핵심이다.

## 관제 흐름

`monitor.sh`는 상태를 두 종류로 나눈다.

| 구분 | 조건 | 결과 |
|---|---|---|
| Health Check | 앱 프로세스 없음, TCP 포트 LISTEN 아님 | `exit 1` |
| Warning Check | 방화벽 비활성, CPU/MEM/DISK 임계값 초과 | 경고 출력 후 계속 |

서비스가 동작하려면 프로세스와 포트가 모두 필요하다. 프로세스만 있어도 포트가 닫혀 있으면 요청을 받을 수 없다.

## 따라하기 1: 프로세스 찾기

현재 셸 프로세스를 찾아 본다.

```bash
ps -eo pid=,comm=,args= | head
pgrep -f bash
```

작은 함수로 만든다.

`find-process.sh`:

```bash
#!/usr/bin/env bash

set -u

PATTERN="${1:-bash}"

if pgrep -f "$PATTERN" >/dev/null 2>&1; then
  echo "[OK] Process found: $PATTERN"
else
  echo "[ERROR] Process not found: $PATTERN" >&2
  exit 1
fi
```

확인:

```bash
bash -n find-process.sh
bash find-process.sh bash
bash find-process.sh not-existing-process-name
```

## 따라하기 2: 포트 LISTEN 확인

현재 LISTEN 포트를 확인한다.

```bash
ss -tuln
```

특정 포트를 검사하는 스크립트:

```bash
nano check-port.sh
```

내용:

```bash
#!/usr/bin/env bash

set -u

PORT="${1:-15034}"

if ss -tuln 2>/dev/null | awk -v port=":$PORT" '$0 ~ port { found=1 } END { exit found ? 0 : 1 }'; then
  echo "[OK] TCP/UDP port appears in LISTEN sockets: $PORT"
else
  echo "[ERROR] Port is not LISTEN: $PORT" >&2
  exit 1
fi
```

확인:

```bash
bash -n check-port.sh
bash check-port.sh 15034
```

앱이 실행 중이 아니면 실패하는 것이 정상이다.

## 따라하기 3: CPU/MEM/DISK 수집

현재 셸의 PID를 기준으로 리소스를 확인한다.

```bash
echo $$
ps -p "$$" -o pcpu= -o pmem=
df -P /
```

`resource-line.sh`:

```bash
#!/usr/bin/env bash

set -u

PID="${1:-$$}"
CPU_MEM="$(ps -p "$PID" -o pcpu= -o pmem= 2>/dev/null | awk 'NR == 1 { print $1, $2 }')"
CPU="$(printf '%s\n' "$CPU_MEM" | awk '{ print $1 }')"
MEM="$(printf '%s\n' "$CPU_MEM" | awk '{ print $2 }')"
DISK_USED="$(df -P / | awk 'NR == 2 { gsub(/%/, "", $5); print $5 }')"

printf 'PID:%s CPU:%s%% MEM:%s%% DISK_USED:%s%%\n' "$PID" "$CPU" "$MEM" "$DISK_USED"
```

확인:

```bash
bash -n resource-line.sh
bash resource-line.sh
```

## 따라하기 4: 로그 append

`append-monitor-log.sh`:

```bash
#!/usr/bin/env bash

set -u

LOG_FILE="${LOG_FILE:-./monitor.log}"
PID="${1:-$$}"
TIMESTAMP="$(date '+%Y-%m-%d %H:%M:%S')"

printf '[%s] PID:%s CPU:0.0%% MEM:0.1%% DISK_USED:10%%\n' "$TIMESTAMP" "$PID" >>"$LOG_FILE"
echo "[INFO] Log appended: $LOG_FILE"
```

확인:

```bash
bash -n append-monitor-log.sh
bash append-monitor-log.sh
bash append-monitor-log.sh
tail -n 5 monitor.log
```

`>>`는 기존 로그 뒤에 추가한다. `>`를 쓰면 이전 로그가 덮어써진다.

## 현재 구현과 연결하기

`bin/monitor.sh`에서 다음 함수를 찾아 읽는다.

```bash
grep -nE '^(find_agent_pid|check_port_listen|check_firewall|read_process_resources|greater_than|main)[(]' bin/monitor.sh
```

읽을 때 질문:

- 앱 PID를 찾지 못하면 왜 `exit 1`인가?
- 포트가 닫혀 있으면 왜 `exit 1`인가?
- 방화벽 비활성은 왜 실패가 아니라 경고인가?
- CPU/MEM 소수 비교에 왜 `awk`를 쓰는가?
- 로그 기록에 왜 `>>`를 쓰는가?

## 연습 문제

1. `check-port.sh`가 실패할 때 exit code를 확인하라.
2. `resource-line.sh`에 CPU가 `20`보다 크면 `[WARNING]`을 출력하는 조건을 추가하라.
3. `append-monitor-log.sh`를 세 번 실행한 뒤 `wc -l monitor.log`로 줄 수를 확인하라.
4. `bin/monitor.sh`의 로그 포맷을 보고 `report.sh`가 파싱하기 쉬운 이유를 설명하라.
5. 프로세스는 있는데 포트가 없는 상황에서 확인할 순서를 적어 보라.

## 통과 기준

- `ps`, `pgrep`, `ss`, `df`, `date`를 관제 목적에 맞게 사용할 수 있다.
- Health Check와 Warning Check의 차이를 설명할 수 있다.
- `monitor.log` 한 줄의 각 필드 의미를 설명할 수 있다.
