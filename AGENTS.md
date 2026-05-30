# B1-1 전용 AGENTS.md
# 시스템 관제 자동화 스크립트 개발

## 0. 이 파일의 목적

이 저장소는 코디세이 B1-1 미션인 “시스템 관제 자동화 스크립트 개발”을 수행하기 위한 프로젝트다.

Codex는 이 저장소에서 작업할 때 다음 목표를 우선한다.

1. B1-1 미션 요구사항을 빠짐없이 만족한다.
2. 초보 학습자가 명령어와 코드를 설명할 수 있게 작성한다.
3. 실행 결과와 증빙을 README에 남긴다.
4. 동료 평가자가 재현 가능한 방식으로 검증할 수 있게 한다.
5. 보안, 권한, 로그, cron, 트러블슈팅을 운영 관점으로 정리한다.
6. 가능하면 보너스 과제까지 반영한다.

---

## 1. 미션 핵심 요약

B1-1의 핵심은 단순 Bash 스크립트 작성이 아니다.

목표는 다음 전체 흐름을 구현하고 증빙하는 것이다.

1. 안전한 Linux 서버 운영 환경 구성
2. SSH 기본 보안 설정
3. 방화벽 최소 허용 정책 구성
4. 역할 기반 계정/그룹/디렉토리 권한 설정
5. 제공 앱 실행 환경 구성
6. 앱 Boot Sequence 성공 확인
7. Bash 기반 monitor.sh 작성
8. 프로세스/포트/리소스 관제
9. 로그 누적 기록
10. cron 기반 자동 실행
11. 로그 용량 관리
12. 보너스 report.sh 리포트 생성
13. 보너스 시간 기반 로그 아카이브
14. README와 증빙 문서화

---

## 2. 현재 개발 환경 전제

이 미션은 다음 환경을 기준으로 수행한다.

- Host OS: macOS
- VM / Container Tool: OrbStack
- Linux Practice Environment:
  - Ubuntu 24.04 LTS 우선
- Container Runtime: Docker
- Version Control: Git / GitHub
- Editor: VS Code
- Agent: Codex Extension

B1-1은 사용자/그룹/권한/cron/방화벽/로그를 다루므로 Docker 컨테이너보다 OrbStack Ubuntu Machine을 우선 사용한다.

Docker 컨테이너에서는 다음 기능이 제한될 수 있다.

- systemd
- sshd
- ufw
- firewalld
- cron daemon
- 사용자/그룹/ACL 실습
- /var/log 권한 실습

따라서 가능하면 다음 환경에서 실습한다.

    OrbStack Ubuntu 24.04 Machine

Ubuntu 24.04에서 제공 앱 실행 중 GLIBC 관련 오류가 발생하면 Ubuntu 25.04 환경을 검토한다.

---

## 3. 작업 시작 전 확인 명령

Codex는 작업 시작 시 먼저 현재 위치와 저장소 상태를 확인한다.

    pwd
    ls -la
    git status

Linux 실습 환경에서는 다음도 확인한다.

    cat /etc/os-release
    whoami
    id
    hostname
    ip addr
    ss -tulnp

---

## 4. 기본 작업 원칙

Codex는 다음 순서로 작업한다.

1. AGENTS.md 확인
2. B1-1-Mission.md 확인
3. B1-1-Evaluation.md 확인
4. agent-app.zip 내부 구조 확인
5. 미션 요구사항과 평가문항 정리
6. 구현 계획 제시
7. 사용자의 승인 또는 요청 후 파일 생성/수정
8. bash -n 등 안전한 검증 수행
9. README와 docs 증빙 정리
10. 평가 항목 기준 자체 점검

주의:

- sudo가 필요한 실제 시스템 변경은 무단 실행하지 않는다.
- 시스템 변경 명령은 README에 따라하기 형식으로 작성한다.
- 민감정보를 만들거나 커밋하지 않는다.
- root로 앱을 실행하지 않는다.
- 위험 명령어는 실행 전 반드시 설명한다.

---

## 5. 필수 요구사항

## 5.1 SSH 보안 설정

다음 조건을 만족해야 한다.

- SSH 포트를 20022로 변경한다.
- Root 원격 접속을 차단한다.

확인해야 할 항목:

    sudo grep -E '^(Port|PermitRootLogin)' /etc/ssh/sshd_config
    sudo ss -tulnp | grep ssh

기대 기준:

- Port 20022
- PermitRootLogin no
- sshd가 20022 포트에서 LISTEN

주의:

SSH 설정 변경 전에는 현재 접속이 끊길 수 있으므로 새 터미널 접속 가능 여부를 먼저 고려한다.

---

## 5.2 방화벽 설정

UFW 또는 firewalld 중 하나를 선택한다.

기본 권장: UFW

허용 포트는 다음만 유지한다.

- 20022/tcp
- 15034/tcp

금지:

- 전체 포트 허용
- 0.0.0.0/0 전체 포트 허용
- 불필요한 포트 상시 개방

UFW 확인 명령:

    sudo ufw status numbered
    sudo ufw status verbose

firewalld 확인 명령:

    sudo firewall-cmd --list-all

---

## 5.3 계정과 그룹

필수 계정:

- agent-admin
- agent-dev
- agent-test

필수 그룹:

- agent-common
- agent-core

그룹 정책:

- agent-common:
  - agent-admin
  - agent-dev
  - agent-test

- agent-core:
  - agent-admin
  - agent-dev

확인 명령:

    id agent-admin
    id agent-dev
    id agent-test
    getent group agent-common
    getent group agent-core

---

## 5.4 디렉토리 구조

AGENT_HOME 예시:

    /home/agent-admin/agent-app

필수 디렉토리:

    $AGENT_HOME
    $AGENT_HOME/upload_files
    $AGENT_HOME/api_keys
    $AGENT_HOME/bin
    /var/log/agent-app

권한 정책:

- upload_files
  - group: agent-common
  - agent-common 그룹이 읽기/쓰기 가능

- api_keys
  - group: agent-core
  - agent-core 그룹만 읽기/쓰기 가능

- /var/log/agent-app
  - group: agent-core
  - agent-core 그룹만 읽기/쓰기 가능

확인 명령:

    ls -ld $AGENT_HOME
    ls -ld $AGENT_HOME/upload_files
    ls -ld $AGENT_HOME/api_keys
    ls -ld $AGENT_HOME/bin
    ls -ld /var/log/agent-app
    getfacl $AGENT_HOME/upload_files
    getfacl $AGENT_HOME/api_keys
    getfacl /var/log/agent-app

ACL 사용 시 반드시 README에 이유와 확인 결과를 남긴다.

---

## 5.5 환경 변수

필수 환경 변수:

    AGENT_HOME=/home/agent-admin/agent-app
    AGENT_PORT=15034
    AGENT_UPLOAD_DIR=$AGENT_HOME/upload_files
    AGENT_KEY_PATH=$AGENT_HOME/api_keys/t_secret.key
    AGENT_LOG_DIR=/var/log/agent-app

환경 변수 확인:

    echo $AGENT_HOME
    echo $AGENT_PORT
    echo $AGENT_UPLOAD_DIR
    echo $AGENT_KEY_PATH
    echo $AGENT_LOG_DIR

환경 변수는 실행 계정인 agent-admin 기준으로 적용되어야 한다.

cron에서 환경 변수가 사라질 수 있으므로 monitor.sh 내부 기본값 또는 crontab 환경 변수 선언을 함께 고려한다.

---

## 5.6 키 파일

필수 키 파일:

    $AGENT_HOME/api_keys/t_secret.key

내용:

    agent_api_key_test

주의:

실제 API Key가 아니다. 미션용 테스트 키다.

권한 확인:

    ls -l $AGENT_HOME/api_keys/t_secret.key

내용 확인:

    sudo -u agent-admin cat $AGENT_HOME/api_keys/t_secret.key

---

## 5.7 앱 실행 조건

앱은 root로 실행하면 안 된다.

반드시 일반 계정으로 실행한다.

권장 실행 계정:

    agent-admin

성공 기준:

- Boot Sequence 5단계가 모두 [OK]
- 마지막에 Agent READY 출력
- 0.0.0.0:15034 LISTEN 상태

확인 명령:

    ps -ef | grep agent
    ss -tulnp | grep 15034
    curl http://localhost:15034

root 실행 금지 오류가 나오면 agent-admin 계정으로 다시 실행한다.

---

## 6. monitor.sh 요구사항

## 6.1 파일 위치와 권한

monitor.sh 위치:

    $AGENT_HOME/bin/monitor.sh

저장소 기준 위치:

    bin/monitor.sh

권한 정책:

- 소유자: agent-dev
- 그룹: agent-core
- 권한: 750
- 실행자: agent-admin

확인 명령:

    ls -l $AGENT_HOME/bin/monitor.sh

기대 예시:

    -rwxr-x--- 1 agent-dev agent-core ... monitor.sh

---

## 6.2 monitor.sh 필수 기능

monitor.sh는 다음 기능을 포함해야 한다.

### Health Check

비정상 시 exit 1로 종료한다.

1. 프로세스 실행 상태 확인
2. TCP 15034 LISTEN 상태 확인

프로세스 이름은 제공 앱 파일명에 맞게 조정한다.

예시 후보:

- agent-app
- agent_app.py
- python app process

프로세스 식별은 pgrep 또는 ps를 사용할 수 있다.

포트 확인은 ss 사용을 우선한다.

---

### Warning Check

다음 항목은 경고만 출력하고 스크립트는 종료하지 않는다.

1. 방화벽 비활성
2. CPU 임계값 초과
3. MEM 임계값 초과
4. DISK_USED 임계값 초과

임계값:

- CPU > 20%
- MEM > 10%
- DISK_USED > 80%

경고 형식 예시:

    [WARNING] CPU usage is over threshold
    [WARNING] Firewall is inactive

---

### Resource Collection

수집 항목:

- PID
- CPU 사용률
- MEM 사용률
- Root partition 디스크 사용률

로그 파일:

    /var/log/agent-app/monitor.log

로그 포맷:

    [YYYY-MM-DD HH:MM:SS] PID:... CPU:..% MEM:..% DISK_USED:..%

예시:

    [2026-05-27 14:10:00] PID:1234 CPU:2.3% MEM:4.1% DISK_USED:37%

---

## 6.3 로그 누적

로그는 덮어쓰면 안 된다.

반드시 append 방식으로 누적한다.

사용:

    >>

사용 금지:

    >

README에 다음을 설명한다.

- > 는 기존 파일을 덮어쓴다.
- >> 는 기존 파일 뒤에 누적한다.
- 관제 로그는 시간순 기록이 중요하므로 >>를 사용해야 한다.

---

## 6.4 로그 용량 관리

monitor.log 용량 정책:

- 최대 10MB
- 최대 10개 파일 보존

구현 방식은 둘 중 하나를 선택한다.

1. logrotate 사용
2. monitor.sh 내부 로테이션 로직 구현

권장 방식:

    logrotate 사용

logrotate 사용 시 설정 파일 예시 위치:

    /etc/logrotate.d/agent-app-monitor

스크립트 내부 구현 시 다음을 만족한다.

- monitor.log가 10MB 초과인지 확인
- 기존 monitor.log.1, monitor.log.2 등을 순환
- 최대 monitor.log.10까지만 유지
- 오래된 파일 삭제

반드시 README에 선택한 방식과 이유를 설명한다.

---

## 6.5 cron 자동 실행

cron 실행 계정:

    agent-admin

등록 내용:

    * * * * * /home/agent-admin/agent-app/bin/monitor.sh

권장:

stdout/stderr도 로그에 남긴다.

예시:

    * * * * * /home/agent-admin/agent-app/bin/monitor.sh >> /var/log/agent-app/cron.log 2>&1

확인 명령:

    sudo crontab -u agent-admin -l

또는 agent-admin으로 전환 후:

    crontab -l

검증:

1. monitor.log 현재 라인 수 확인
2. 1~2분 대기
3. monitor.log 라인 수 증가 확인

명령:

    wc -l /var/log/agent-app/monitor.log
    tail -n 5 /var/log/agent-app/monitor.log

---

## 7. 보너스 과제 요구사항

B1-1 미션에서는 필수 요구사항 완료 후 가능하면 다음 보너스 과제도 구현한다.

보너스 과제는 필수 통과 조건은 아니지만, 관제 자동화 역량과 운영 자동화 역량을 강화하기 위한 추가 구현 항목이다.

---

## 7.1 보너스 1: report.sh 요약 리포트 자동 생성

### 목적

/var/log/agent-app/monitor.log를 분석하여 CPU, MEM, DISK_USED의 통계값을 콘솔에 출력한다.

### 추가 파일

    $AGENT_HOME/bin/report.sh

또는 저장소 기준:

    bin/report.sh

### 필수 출력 항목

report.sh는 다음 값을 출력해야 한다.

- 샘플 수
- CPU 평균
- CPU 최대
- CPU 최소
- MEM 평균
- MEM 최대
- MEM 최소
- DISK_USED 평균
- DISK_USED 최대
- DISK_USED 최소

### 기본 실행 방식

    $AGENT_HOME/bin/report.sh

또는 저장소에서:

    ./bin/report.sh

### 선택 기능

가능하면 시작/종료 시간을 입력받아 특정 구간만 분석할 수 있게 한다.

예시:

    ./bin/report.sh --from "2026-05-27 10:00:00" --to "2026-05-27 11:00:00"

### 구현 원칙

- Bash로 작성한다.
- Python으로 대체하지 않는다.
- awk, grep, sed, date 등 표준 Linux 도구 사용은 허용한다.
- monitor.log가 없으면 친절한 오류 메시지를 출력한다.
- 분석 가능한 로그가 0개이면 안전하게 종료한다.
- 숫자 파싱 실패 시 해당 라인은 건너뛰고 경고를 출력한다.
- 평균 계산 시 0으로 나누는 오류가 발생하지 않도록 처리한다.
- 출력은 평가자가 이해하기 쉽게 표 또는 항목별 목록으로 정리한다.

### report.sh 권장 권한

- 소유자: agent-dev
- 그룹: agent-core
- 권한: 750

확인 명령:

    ls -l $AGENT_HOME/bin/report.sh

기대 예시:

    -rwxr-x--- 1 agent-dev agent-core ... report.sh

### 검증 명령

    bash -n $AGENT_HOME/bin/report.sh
    $AGENT_HOME/bin/report.sh

저장소 기준:

    bash -n bin/report.sh
    ./bin/report.sh

### README 증빙 항목

README에는 다음 내용을 포함한다.

- report.sh 파일 위치
- report.sh 소유자/그룹/권한
- 실행 명령
- 샘플 출력 결과
- CPU/MEM/DISK_USED 평균·최대·최소 계산 방식
- 로그 파일 없음, 빈 로그, 파싱 실패에 대한 예외 처리 방식

---

## 7.2 보너스 2: 시간 기반 로그 보존 정책

### 목적

오래된 로그를 압축하고 아카이브 디렉토리로 이동하며, 오래된 아카이브 파일을 삭제한다.

### 추가 파일 후보

권장 저장소 위치:

    scripts/archive-old-logs.sh

또는 실행 환경 위치:

    $AGENT_HOME/bin/archive-old-logs.sh

### 필수 정책

다음 정책을 구현한다.

1. /var/log/agent-app/*.log 중 7일 이상 경과한 로그 파일을 압축한다.
2. 압축한 .gz 파일을 /var/log/monitor/agent-app/archive/로 이동한다.
3. /var/log/monitor/agent-app/archive/*.gz 중 30일 이상 경과한 파일을 삭제한다.

### 대상 경로

    /var/log/agent-app/*.log

### 아카이브 경로

    /var/log/monitor/agent-app/archive/

### 삭제 대상

    /var/log/monitor/agent-app/archive/*.gz

### 필수 예외 처리

스크립트는 다음 상황에서 비정상 종료하지 않고 명확한 메시지를 출력해야 한다.

- 대상 로그 파일이 0개인 경우
- 아카이브 디렉토리가 없는 경우
- 아카이브 디렉토리 생성 권한이 없는 경우
- 압축 권한이 부족한 경우
- gzip 실패
- 이동 실패
- 삭제 대상 .gz 파일이 없는 경우

### 권장 출력 예시

    [INFO] Archive directory checked: /var/log/monitor/agent-app/archive
    [INFO] No old log files found for compression
    [INFO] Compressed: /var/log/agent-app/monitor.log.20260520.gz
    [INFO] Moved to archive: /var/log/monitor/agent-app/archive/monitor.log.20260520.gz
    [INFO] Deleted old archive: /var/log/monitor/agent-app/archive/monitor.log.20260420.gz
    [INFO] Archive cleanup completed

### 검증 명령

문법 검사:

    bash -n scripts/archive-old-logs.sh

실행 예시:

    sudo scripts/archive-old-logs.sh

아카이브 확인:

    find /var/log/monitor/agent-app/archive -type f -name "*.gz" -ls

### README 증빙 항목

README에는 다음 내용을 포함한다.

- 시간 기반 로그 보존 정책 설명
- 7일 경과 로그 압축 방식
- 아카이브 이동 경로
- 30일 경과 아카이브 삭제 방식
- 권한 부족, 대상 없음, 디렉토리 없음에 대한 예외 처리
- 실행 명령
- 실행 결과 예시
- find 명령을 통한 아카이브 확인 결과

---

## 7.3 보너스 과제 완료 기준

보너스 과제까지 완료라고 판단하려면 다음 조건을 만족해야 한다.

- [ ] bin/report.sh 존재
- [ ] report.sh가 Bash 문법 검사 통과
- [ ] report.sh가 monitor.log에서 CPU 통계 출력
- [ ] report.sh가 monitor.log에서 MEM 통계 출력
- [ ] report.sh가 monitor.log에서 DISK_USED 통계 출력
- [ ] report.sh가 샘플 수 출력
- [ ] report.sh가 평균/최대/최소 출력
- [ ] 로그 없음/빈 로그 예외 처리 가능
- [ ] 숫자 파싱 실패 라인 예외 처리 가능
- [ ] scripts/archive-old-logs.sh 또는 동등 스크립트 존재
- [ ] archive-old-logs.sh가 Bash 문법 검사 통과
- [ ] 7일 이상 로그 압축 정책 구현
- [ ] archive 디렉토리 이동 정책 구현
- [ ] 30일 이상 gz 삭제 정책 구현
- [ ] 대상 파일 없음 예외 처리 가능
- [ ] 권한 부족 예외 처리 가능
- [ ] 디렉토리 없음 예외 처리 가능
- [ ] README에 보너스 과제 섹션 포함
- [ ] docs/verification-log.md에 보너스 검증 명령 포함

---

## 8. 권장 파일 구조

최종 저장소 구조는 다음을 권장한다.

    .
    ├── AGENTS.md
    ├── B1-1-Mission.md
    ├── B1-1-Evaluation.md
    ├── README.md
    ├── agent-app.zip
    ├── bin/
    │   ├── monitor.sh
    │   └── report.sh
    ├── scripts/
    │   ├── setup-users.sh
    │   ├── setup-dirs.sh
    │   ├── setup-firewall-ufw.sh
    │   ├── setup-logrotate.sh
    │   └── archive-old-logs.sh
    └── docs/
        ├── requirements-checklist.md
        ├── command-log.md
        ├── verification-log.md
        ├── troubleshooting.md
        ├── security-notes.md
        └── screenshots/

---

## 9. 생성 또는 수정 대상 파일

Codex는 사용자의 요청에 따라 다음 파일을 생성 또는 수정할 수 있다.

필수:

- README.md
- bin/monitor.sh
- scripts/setup-users.sh
- scripts/setup-dirs.sh
- scripts/setup-firewall-ufw.sh
- scripts/setup-logrotate.sh
- docs/verification-log.md
- docs/troubleshooting.md
- docs/requirements-checklist.md

보너스:

- bin/report.sh
- scripts/archive-old-logs.sh

---

## 10. README 필수 증빙 목록

README에는 아래 증빙을 반드시 포함한다.

### 10.1 설정 증빙

- SSH 포트 20022 변경 확인
- Root 원격 접속 차단 확인
- 방화벽 활성화 확인
- 20022/tcp, 15034/tcp만 허용 확인
- agent-admin / agent-dev / agent-test 생성 확인
- agent-common / agent-core 그룹 확인
- 디렉토리 권한 확인
- ACL 사용 시 getfacl 결과

### 10.2 앱 실행 증빙

- 환경 변수 확인
- 키 파일 확인
- Boot Sequence 5단계 [OK]
- Agent READY 출력
- 15034 LISTEN 확인
- localhost 접속 확인

### 10.3 monitor.sh 증빙

- monitor.sh 파일 위치
- 소유자/그룹/권한 확인
- 직접 실행 결과
- 프로세스 정상 확인
- 포트 정상 확인
- CPU/MEM/DISK_USED 출력
- WARNING 조건 설명
- exit 1 조건 설명

### 10.4 로그와 cron 증빙

- monitor.log 생성 확인
- monitor.log 누적 확인
- crontab 등록 확인
- 1분 후 로그 증가 확인
- 로그 용량 관리 방식 확인

### 10.5 보너스 증빙

- report.sh 파일 위치
- report.sh 실행 결과
- CPU/MEM/DISK_USED 통계 출력
- archive-old-logs.sh 실행 결과
- 7일 경과 로그 압축 정책
- 30일 경과 아카이브 삭제 정책

---

## 11. README 요구사항 반영표 형식

README에는 다음 표를 포함한다.

| 미션 요구사항 | 구현 내용 | 검증 명령 | 결과 |
|---|---|---|---|
| SSH 포트 20022 | sshd_config 수정 | grep, ss | 완료/미완료 |
| Root 접속 차단 | PermitRootLogin no | grep | 완료/미완료 |
| 방화벽 포트 제한 | UFW 설정 | ufw status | 완료/미완료 |
| 계정/그룹 생성 | agent 계정/그룹 생성 | id, getent | 완료/미완료 |
| 앱 실행 | agent-admin 실행 | Boot Sequence | 완료/미완료 |
| monitor.sh 구현 | 프로세스/포트/리소스 관제 | 직접 실행 | 완료/미완료 |
| 로그 누적 | monitor.log append | tail, wc | 완료/미완료 |
| cron 등록 | 매분 실행 | crontab, tail | 완료/미완료 |
| 로그 용량 관리 | logrotate 또는 script | 설정 확인 | 완료/미완료 |
| 보너스 report.sh | 로그 통계 분석 | report.sh 실행 | 완료/미완료 |
| 보너스 아카이브 | 7일 압축/30일 삭제 | archive script 실행 | 완료/미완료 |

---

## 12. docs/verification-log.md 구성

docs/verification-log.md에는 평가자가 실행할 검증 명령과 기대 결과를 정리한다.

필수 검증 항목:

- 시스템 환경 확인
- SSH 설정 확인
- 방화벽 확인
- 계정/그룹 확인
- 디렉토리 권한 확인
- 환경 변수 확인
- 키 파일 확인
- 앱 실행 확인
- 15034 포트 확인
- monitor.sh 문법 검사
- monitor.sh 직접 실행
- monitor.log 확인
- cron 등록 확인
- cron 자동 실행 확인
- logrotate 또는 로그 용량 관리 확인

보너스 검증 항목:

- report.sh 문법 검사
- report.sh 실행
- archive-old-logs.sh 문법 검사
- archive-old-logs.sh 실행
- archive 디렉토리 확인

---

## 13. 트러블슈팅 문서 형식

docs/troubleshooting.md는 다음 형식을 따른다.

# Troubleshooting Report

## Case 1: 문제 제목

### 1. 증상

- 어떤 문제가 발생했는가?

### 2. 원인 가설

- 가능한 원인은 무엇인가?

### 3. 확인 명령

    사용한 명령어

### 4. 실제 원인

- 증거 기반 실제 원인

### 5. 해결 방법

    수행한 명령어 또는 수정 내용

### 6. 해결 결과

- Before:
- After:

### 7. 재발 방지

- 다음에는 어떻게 방지할 것인가?

---

## 14. 자주 발생하는 문제와 대응

## 14.1 root로 앱 실행 실패

증상:

    Running as 'root' is forbidden

대응:

    sudo -iu agent-admin
    cd $AGENT_HOME
    ./agent-app

원인:

앱은 보안상 root 실행을 금지한다.

---

## 14.2 15034 포트 미사용

확인:

    ss -tulnp | grep 15034

원인 후보:

- 앱이 실행되지 않음
- AGENT_PORT 환경 변수 누락
- 권한 문제
- 키 파일 경로 문제
- 이미 다른 프로세스가 포트 사용 중

---

## 14.3 cron에서는 되지 않는데 직접 실행은 됨

원인 후보:

- cron 환경변수 부족
- PATH 차이
- 로그 디렉토리 권한 부족
- 실행 권한 부족

대응:

- monitor.sh에 절대경로 사용
- crontab에 환경변수 명시
- cron.log로 stderr 확인

---

## 14.4 monitor.log 권한 오류

확인:

    ls -ld /var/log/agent-app
    ls -l /var/log/agent-app/monitor.log
    id agent-admin

대응:

- /var/log/agent-app group을 agent-core로 설정
- agent-admin을 agent-core에 포함
- 디렉토리 쓰기 권한 확인

---

## 14.5 GLIBC 오류

증상:

    GLIBC_2.38 not found

대응:

- Ubuntu 22.04에서 발생하면 Ubuntu 24.04 환경 검토
- 또는 제공 앱과 OS 버전 호환성 확인

---

## 15. 검증 명령 모음

## 15.1 시스템 확인

    cat /etc/os-release
    whoami
    id
    hostname
    ip addr

## 15.2 SSH 확인

    sudo grep -E '^(Port|PermitRootLogin)' /etc/ssh/sshd_config
    sudo ss -tulnp | grep ssh

## 15.3 방화벽 확인

    sudo ufw status verbose

또는:

    sudo firewall-cmd --list-all

## 15.4 계정/그룹 확인

    id agent-admin
    id agent-dev
    id agent-test
    getent group agent-common
    getent group agent-core

## 15.5 디렉토리 권한 확인

    ls -ld $AGENT_HOME
    ls -ld $AGENT_HOME/upload_files
    ls -ld $AGENT_HOME/api_keys
    ls -ld /var/log/agent-app
    getfacl $AGENT_HOME/upload_files
    getfacl $AGENT_HOME/api_keys
    getfacl /var/log/agent-app

## 15.6 앱 확인

    ps -ef | grep agent
    ss -tulnp | grep 15034
    curl http://localhost:15034

## 15.7 monitor.sh 확인

    ls -l $AGENT_HOME/bin/monitor.sh
    bash -n $AGENT_HOME/bin/monitor.sh
    sudo -u agent-admin $AGENT_HOME/bin/monitor.sh
    tail -n 5 /var/log/agent-app/monitor.log

## 15.8 cron 확인

    sudo crontab -u agent-admin -l
    wc -l /var/log/agent-app/monitor.log
    tail -n 10 /var/log/agent-app/monitor.log

## 15.9 보너스 확인

    bash -n bin/report.sh
    ./bin/report.sh
    bash -n scripts/archive-old-logs.sh
    sudo scripts/archive-old-logs.sh
    find /var/log/monitor/agent-app/archive -type f -name "*.gz" -ls

## 15.10 Git 확인

    git status
    git log --oneline --graph --all --decorate -n 20

---

## 16. Bash 스크립트 작성 기준

Bash 스크립트는 다음 기준을 따른다.

- shebang 포함
- 변수는 의미 있는 이름 사용
- 경로는 변수로 관리
- 명령 실패 시 이해 가능한 메시지 출력
- root 전용 명령과 일반 사용자 명령을 구분
- 파싱 로직에는 주석 작성
- exit 1 조건과 warning 조건을 명확히 분리
- bash -n으로 문법 검증 가능해야 함
- 중복 실행해도 가능한 안전하게 동작해야 함

권장 shebang:

    #!/usr/bin/env bash

위험 명령은 바로 실행하지 않고 README에 안내한다.

---

## 17. Git 작업 기준

작업은 기능 단위로 브랜치를 나눈다.

권장 브랜치:

- feature/linux-users-groups
- feature/firewall-ssh-hardening
- feature/agent-runtime-env
- feature/monitor-script
- feature/bonus-report
- feature/bonus-archive
- docs/b1-1-readme
- docs/troubleshooting

권장 커밋:

- docs: add B1-1 mission checklist
- feat: add Linux user and group setup guide
- feat: add monitor script health checks
- feat: add cron execution guide
- feat: add monitor report script
- feat: add old log archive script
- docs: add verification logs for monitor script
- fix: correct log directory permission guide

---

## 18. 위험 명령어 주의

다음 명령어는 조심한다.

- rm -rf /
- rm -rf ~
- sudo rm -rf /var/log
- git reset --hard
- git clean -fdx
- git push --force
- docker system prune -a

실행 전 반드시 위험성과 대안을 설명한다.

---

## 19. 동료 평가 대비 설명 포인트

미션 완료 후 학습자는 다음을 설명할 수 있어야 한다.

1. SSH 포트를 20022로 변경한 이유
2. Root 원격 접속을 차단한 이유
3. 방화벽에서 필요한 포트만 허용하는 이유
4. agent-common과 agent-core를 나눈 이유
5. upload_files와 api_keys 권한을 다르게 둔 이유
6. AGENT_HOME 환경 변수를 사용하는 이유
7. monitor.sh에서 프로세스와 포트를 모두 확인하는 이유
8. 방화벽 비활성은 왜 WARNING이고 exit 1이 아닌지
9. CPU/MEM/DISK 임계값 초과를 왜 경고로 처리하는지
10. > 와 >> 차이
11. cron에서 환경 변수가 사라질 수 있는 이유
12. monitor.log 용량 관리가 필요한 이유
13. logrotate 방식과 스크립트 방식의 차이
14. 프로세스는 있는데 포트가 없는 경우 확인 순서
15. 로그가 급증할 때 단기/중기 대응 방법
16. report.sh가 평균/최대/최소를 어떻게 계산하는지
17. 7일 경과 로그 압축과 30일 경과 아카이브 삭제가 필요한 이유

---

## 20. 완료 기준

Codex는 아래 조건을 모두 만족하기 전까지 완료라고 말하지 않는다.

필수:

- [ ] SSH 20022 설정 증빙 있음
- [ ] Root 원격 접속 차단 증빙 있음
- [ ] 방화벽 포트 제한 증빙 있음
- [ ] 계정/그룹 구성 증빙 있음
- [ ] 디렉토리 권한 증빙 있음
- [ ] 앱 Boot Sequence 성공 증빙 있음
- [ ] Agent READY 증빙 있음
- [ ] 15034 LISTEN 증빙 있음
- [ ] monitor.sh 구현 완료
- [ ] monitor.sh 권한 750 확인
- [ ] monitor.sh 직접 실행 성공
- [ ] monitor.log 누적 기록 확인
- [ ] cron 매분 실행 확인
- [ ] 로그 용량 관리 방식 문서화
- [ ] README 요구사항 반영표 작성
- [ ] 트러블슈팅 문서 작성
- [ ] Git 커밋 이력 정리
- [ ] 민감정보 노출 없음

보너스:

- [ ] report.sh 구현
- [ ] report.sh 검증
- [ ] archive-old-logs.sh 구현
- [ ] archive-old-logs.sh 검증
- [ ] README 보너스 섹션 작성
- [ ] docs/verification-log.md 보너스 검증 항목 작성

---

## 21. 사용자에게 보고할 형식

작업 후에는 다음 형식으로 보고한다.

## 요약

- 수행한 작업 요약

## 변경 파일

| 파일 | 변경 내용 |
|---|---|

## 실행 방법

명령어:

    실행 명령어

## 검증 방법

명령어:

    검증 명령어

## 확인된 결과

- 확인된 결과 정리

## B1-1 요구사항 충족 여부

| 요구사항 | 상태 |
|---|---|
| SSH 20022 | 완료/미완료 |
| Root 접속 차단 | 완료/미완료 |
| 방화벽 설정 | 완료/미완료 |
| 계정/그룹 | 완료/미완료 |
| 앱 실행 | 완료/미완료 |
| monitor.sh | 완료/미완료 |
| cron | 완료/미완료 |
| 로그 관리 | 완료/미완료 |
| report.sh 보너스 | 완료/미완료 |
| 로그 아카이브 보너스 | 완료/미완료 |

## 다음 단계

- 다음에 할 작업
