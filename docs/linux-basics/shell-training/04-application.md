# 응용: 자동 실행, 로그 관리, 리포트, 아카이브

## 이 단계의 목표

관제 스크립트를 운영 자동화로 확장한다.

현재 구현과 연결되는 파일:

- `scripts/install-cron.sh`
- `scripts/setup-logrotate.sh`
- `bin/report.sh`
- `scripts/archive-old-logs.sh`

## 따라하기 1: cron 형식 이해

cron은 정해진 시간마다 명령을 실행한다.

```text
* * * * * /home/agent-admin/agent-app/bin/monitor.sh >> /var/log/agent-app/cron.log 2>&1
```

의미:

| 부분 | 의미 |
|---|---|
| `* * * * *` | 매분 실행 |
| 절대 경로 | cron은 작업 위치가 다를 수 있으므로 안전하다 |
| `>>` | cron 로그를 누적한다 |
| `2>&1` | stderr도 stdout과 같은 파일에 남긴다 |

현재 구현된 `scripts/install-cron.sh`는 같은 monitor 경로가 중복 등록되지 않도록 기존 항목을 정리한 뒤 새 항목을 등록한다.

읽기:

```bash
sed -n '1,180p' scripts/install-cron.sh
```

## 따라하기 2: logrotate 정책 읽기

`scripts/setup-logrotate.sh`는 다음 정책을 설치한다.

| 항목 | 정책 |
|---|---|
| 대상 | `/var/log/agent-app/monitor.log` |
| 크기 | `10M` |
| 보관 개수 | `rotate 10` |
| 압축 | `compress` |
| 새 파일 권한 | `create 0640 agent-admin agent-core` |

안전한 검증 명령:

```bash
sudo logrotate -d /etc/logrotate.d/agent-app-monitor
```

`-d`는 실제 회전을 수행하지 않고 설정 해석만 보여 준다.

## 따라하기 3: 샘플 로그로 report.sh 연습

시스템 로그를 건드리지 않고 `/tmp` 샘플로 연습한다.

```bash
cat >/tmp/sample-monitor.log <<'EOF'
[2026-05-31 10:00:00] PID:100 CPU:1.0% MEM:2.0% DISK_USED:30%
[2026-05-31 10:01:00] PID:100 CPU:3.0% MEM:4.0% DISK_USED:31%
[2026-05-31 10:02:00] PID:100 CPU:5.0% MEM:6.0% DISK_USED:32%
bad line
EOF
```

실행:

```bash
bash -n bin/report.sh
LOG_FILE=/tmp/sample-monitor.log bash bin/report.sh
LOG_FILE=/tmp/sample-monitor.log bash bin/report.sh --from "2026-05-31 10:01:00" --to "2026-05-31 10:02:00"
```

확인할 포인트:

- 샘플 수가 출력된다.
- CPU/MEM/DISK_USED 평균, 최대, 최소가 출력된다.
- `bad line`은 `[WARNING]` 후 건너뛴다.
- 분석 가능한 줄이 0개이면 평균 계산을 하지 않고 오류를 낸다.

## 따라하기 4: archive-old-logs.sh 안전 테스트

실제 `/var/log` 대신 `/tmp`에서 테스트한다.

```bash
mkdir -p /tmp/agent-log-test /tmp/agent-archive-test
printf 'old log\n' >/tmp/agent-log-test/old.log
touch -d '8 days ago' /tmp/agent-log-test/old.log
```

실행:

```bash
bash -n scripts/archive-old-logs.sh
AGENT_LOG_DIR=/tmp/agent-log-test ARCHIVE_DIR=/tmp/agent-archive-test bash scripts/archive-old-logs.sh
find /tmp/agent-archive-test -type f -name '*.gz' -ls
```

확인할 포인트:

- 7일 이상 지난 `.log`가 gzip으로 압축된다.
- 압축 파일이 아카이브 디렉터리로 이동한다.
- 삭제 대상 `.gz`가 없으면 INFO 메시지를 출력하고 정상 종료한다.

## 현재 구현과 연결하기

`bin/report.sh`에서 `awk`가 하는 일:

1. 각 줄에서 timestamp를 추출한다.
2. `--from`, `--to` 범위 밖이면 건너뛴다.
3. `CPU:`, `MEM:`, `DISK_USED:` 값을 찾는다.
4. 숫자가 아니면 경고 후 건너뛴다.
5. 합계, 최소, 최대를 갱신한다.
6. 마지막에 평균을 계산한다.

`scripts/archive-old-logs.sh`에서 `find`가 하는 일:

1. 로그 디렉터리 바로 아래만 찾는다.
2. 이름이 `*.log`인 파일만 찾는다.
3. 수정 시간이 7일 이상 지난 파일만 찾는다.
4. 오래된 `*.gz` 아카이브는 30일 기준으로 삭제한다.

## 연습 문제

1. `/tmp/sample-monitor.log`에 CPU가 `20.5%`인 줄을 추가하고 평균 변화를 확인하라.
2. `report.sh --from`만 지정했을 때와 `--to`만 지정했을 때 결과 차이를 확인하라.
3. `archive-old-logs.sh`에서 `COMPRESS_DAYS=1`을 주입해 테스트 대상을 바꿔 보라.
4. `cron`에서 절대 경로를 쓰는 이유를 설명하라.
5. logrotate와 `archive-old-logs.sh`의 역할 차이를 설명하라.

## 통과 기준

- cron 한 줄의 다섯 별 의미를 설명할 수 있다.
- `report.sh`의 통계 계산 흐름을 설명할 수 있다.
- 로그 크기 관리와 시간 기반 아카이브의 차이를 설명할 수 있다.
