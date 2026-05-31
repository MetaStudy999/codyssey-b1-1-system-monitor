# monitor.sh 구현과 검증

## 이 단계의 목표

`monitor.sh`를 앱 실행 상태, 포트 상태, CPU/MEM/DISK 사용률을 확인하고 로그에 누적 기록하는 관제 스크립트로 검증한다.

## 왜 이 작업을 하는가?

장애가 발생했을 때 프로세스, 포트, 리소스 상태가 로그로 남아 있어야 원인을 추적할 수 있다.

## 사전 확인

```bash
ps -ef | grep '[a]gent-app'
ss -tulnp | grep 15034
ls -ld /var/log/agent-app
```

## 실행 명령어

저장소의 스크립트를 운영 위치로 배치한다.

```bash
export AGENT_HOME=/home/agent-admin/agent-app
sudo cp bin/monitor.sh "$AGENT_HOME/bin/monitor.sh"
sudo chown agent-dev:agent-core "$AGENT_HOME/bin/monitor.sh"
sudo chmod 750 "$AGENT_HOME/bin/monitor.sh"
```

문법 검사와 직접 실행을 수행한다.

```bash
bash -n "$AGENT_HOME/bin/monitor.sh"
sudo -u agent-admin "$AGENT_HOME/bin/monitor.sh"
```

## 명령어 설명

- `ps`: 앱 실행 파일 경로와 이름을 기준으로 프로세스를 찾는다.
- `ss -tuln`: `15034` 포트 LISTEN 여부를 확인한다.
- `ps -p PID -o %cpu=,%mem=`: 해당 PID의 CPU/MEM을 수집한다.
- `df -P /`: 루트 파티션 디스크 사용률을 수집한다.
- `>>`: 기존 로그 뒤에 새 줄을 누적한다.

## 기대 결과

```text
[HEALTH CHECK]
Checking agent process... [OK]
Checking port 15034... [OK]

[RESOURCE MONITORING]
CPU Usage : ...
MEM Usage : ...
DISK Used : ...
[INFO] Log appended: /var/log/agent-app/monitor.log
```

## 결과 확인 명령어

```bash
ls -l "$AGENT_HOME/bin/monitor.sh"
sudo tail -n 5 /var/log/agent-app/monitor.log
```

## README에 붙여넣을 증빙

`bash -n`, 직접 실행 결과, `tail -n 5` 결과를 붙인다.

## 자주 발생하는 오류

- 프로세스 없음: agent-app을 먼저 실행한다.
- 포트 없음: 앱이 Boot Sequence를 통과했는지 확인한다.
- 로그 권한 오류: `/var/log/agent-app` 그룹과 권한을 확인한다.
- 방화벽 WARNING: 관제 대상 문제는 아니므로 종료하지 않고 경고만 출력한다.

## 다음 단계로 넘어가는 기준

`monitor.sh`가 exit 0으로 끝나고 `monitor.log`에 지정 포맷이 추가되면 다음 단계로 넘어간다.

## Git 커밋 시점

monitor.sh와 검증 문서를 추가한 뒤 커밋한다.

## 추천 커밋 메시지

```bash
git commit -m "feat: add monitor script health checks"
```
