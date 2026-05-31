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

## 자기 점검

- [ ] 스크립트 실행 전 `bash -n`을 수행했다.
- [ ] 변수에는 따옴표를 사용했다.
- [ ] 실패해야 하는 조건에서 `exit 1`을 사용했다.
- [ ] 경고 조건과 실패 조건을 구분했다.
- [ ] 로그는 append 방식으로 남겼다.
- [ ] 결과를 말로 설명할 수 있다.
