# B1-1 시스템 관제 자동화 스크립트 개발

## 1. 프로젝트 개요

이 저장소는 코디세이 B1-1 미션인 시스템 관제 자동화 스크립트 개발을 수행하기 위한 제출 자료다.

목표는 제공 앱을 안전한 Linux 운영 환경에 배치하고, SSH/방화벽/계정/권한/로그/cron/관제 스크립트를 초보자도 재현할 수 있게 문서화하는 것이다.

주의: 이 저장소에서 작성한 스크립트 중 `sudo`가 필요한 항목은 OrbStack Ubuntu 24.04 VM `codyssey-b1-1-ubuntu24`에서 직접 실행한다. macOS에서는 Git, 문서 편집, 정적 검증만 수행한다.

## 2. 미션 목표

- SSH 포트를 `20022`로 변경한다.
- Root 원격 접속을 차단한다.
- UFW에서 `20022/tcp`, `15034/tcp`만 허용한다.
- `agent-admin`, `agent-dev`, `agent-test` 계정과 `agent-common`, `agent-core` 그룹을 구성한다.
- 앱 실행 환경과 권한을 구성한다.
- 제공 앱의 Boot Sequence 5단계 `[OK]`와 `Agent READY`를 확인한다.
- `monitor.sh`로 프로세스, 포트, CPU, MEM, DISK를 관제한다.
- `/var/log/agent-app/monitor.log`에 로그를 누적한다.
- cron으로 매분 자동 실행한다.
- logrotate로 `10MB / 10개` 로그 보존 정책을 적용한다.
- 보너스로 `report.sh`와 시간 기반 로그 아카이브를 구현한다.

## 3. 개발 환경

| 구분 | 사용 환경 |
|---|---|
| Host OS | macOS |
| Linux 실습 | OrbStack VM `codyssey-b1-1-ubuntu24` (Ubuntu 24.04 LTS, Noble) |
| Container Runtime | Docker, 필요 시 보조 |
| Version Control | Git / GitHub |
| Editor | VS Code |
| Shell Script | Bash |

모든 Linux 실습 증빙은 `codyssey-b1-1-ubuntu24`에서 남긴다. 제공 앱 실행 중 `GLIBC_2.38 not found`가 발생하면 같은 VM에서 `ldd --version`, `cat /etc/os-release`, `file /home/agent-admin/agent-app/agent-app`로 앱 바이너리와 Ubuntu 24.04 호환성을 확인한다.

## 4. 전체 수행 순서

자세한 단계별 안내는 `docs/00-목차.md`부터 순서대로 진행한다.

1. `docs/01-환경준비.md`
2. `docs/02-계정-그룹-생성.md`
3. `docs/03-디렉토리-권한-설정.md`
4. `docs/04-agent-app-압축해제와-배치.md`
5. `docs/05-SSH-방화벽-설정.md`
6. `docs/06-환경변수-키파일-설정.md`
7. `docs/07-agent-app-실행-검증.md`
8. `docs/08-monitor-sh-구현-검증.md`
9. `docs/09-cron-자동실행.md`
10. `docs/10-logrotate-로그용량관리.md`
11. `docs/11-보너스-report-sh.md`
12. `docs/12-보너스-로그-아카이브.md`
13. `docs/13-전체-검증-체크리스트.md`
14. `docs/14-트러블슈팅.md`
15. `docs/15-동료평가-대비-질문답변.md`

## 5. 요구사항 반영표

| 미션 요구사항 | 구현 내용 | 검증 명령 | 결과 |
|---|---|---|---|
| SSH 포트 20022 | `/etc/ssh/sshd_config` 수정 안내 | `grep`, `ss` | `codyssey-b1-1-ubuntu24` 실행 후 갱신 |
| Root 접속 차단 | `PermitRootLogin no` 설정 안내 | `grep` | `codyssey-b1-1-ubuntu24` 실행 후 갱신 |
| 방화벽 포트 제한 | UFW 스크립트 제공 | `ufw status` | 준비 |
| 계정/그룹 생성 | `scripts/setup-users.sh` | `id`, `getent` | 준비 |
| 디렉터리 권한 | `scripts/setup-dirs.sh` | `ls -ld`, `getfacl` | 준비 |
| 앱 실행 | `agent-admin` 실행 안내 | Boot Sequence, `ss`, `curl` | `codyssey-b1-1-ubuntu24` 실행 후 갱신 |
| monitor.sh 구현 | `bin/monitor.sh` | `bash -n`, 직접 실행 | 준비 |
| 로그 누적 | `monitor.log` append | `tail`, `wc` | 준비 |
| cron 등록 | `scripts/install-cron.sh` | `crontab`, `tail` | 준비 |
| 로그 용량 관리 | `scripts/setup-logrotate.sh` | `logrotate -d` | 준비 |
| 보너스 report.sh | `bin/report.sh` | `report.sh` 실행 | 준비 |
| 보너스 아카이브 | `scripts/archive-old-logs.sh` | archive script 실행 | 준비 |

## 6. 파일 구조

```text
.
├── README.md
├── AGENTS.md
├── B1-1-Mission.md
├── B1-1-Evaluation.md
├── agent-app.zip
├── bin/
│   ├── monitor.sh
│   └── report.sh
├── scripts/
│   ├── setup-users.sh
│   ├── setup-dirs.sh
│   ├── setup-firewall-ufw.sh
│   ├── setup-logrotate.sh
│   ├── install-cron.sh
│   └── archive-old-logs.sh
└── docs/
    ├── 00-목차.md
    ├── 01-환경준비.md
    ├── 02-계정-그룹-생성.md
    ├── 03-디렉토리-권한-설정.md
    ├── 04-agent-app-압축해제와-배치.md
    ├── 05-SSH-방화벽-설정.md
    ├── 06-환경변수-키파일-설정.md
    ├── 07-agent-app-실행-검증.md
    ├── 08-monitor-sh-구현-검증.md
    ├── 09-cron-자동실행.md
    ├── 10-logrotate-로그용량관리.md
    ├── 11-보너스-report-sh.md
    ├── 12-보너스-로그-아카이브.md
    ├── 13-전체-검증-체크리스트.md
    ├── 14-트러블슈팅.md
    ├── 15-동료평가-대비-질문답변.md
    ├── command-log.md
    ├── requirements-checklist.md
    ├── security-notes.md
    ├── troubleshooting.md
    └── verification-log.md
```

## 7. 사전 준비

macOS 프로젝트 폴더에서 확인한다.

```bash
pwd
ls -la
git status
```

`codyssey-b1-1-ubuntu24`에서 확인한다.

```bash
cat /etc/os-release
uname -m
whoami
id
command -v unzip ss sshd ufw logrotate crontab getfacl curl file nano
```

필요 시 `codyssey-b1-1-ubuntu24`에서 패키지를 설치한다.

```bash
sudo apt update
sudo apt install -y openssh-server unzip iproute2 ufw logrotate cron acl curl file nano
```

## 8. agent-app.zip 압축 해제와 배치

압축 해제 전 내부 목록을 확인한다.

```bash
unzip -l agent-app.zip
```

현재 확인된 내부 구조:

```text
agent-app-linux-x86
agent-app-linux-arm64
__MACOSX/._agent-app-linux-x86
__MACOSX/._agent-app-linux-arm64
```

`codyssey-b1-1-ubuntu24`의 아키텍처에 맞는 파일을 선택한다.

```bash
uname -m
```

배치 예시:

```bash
unzip agent-app.zip -d /tmp/agent-app-extract
export AGENT_HOME=/home/agent-admin/agent-app

if [ "$(uname -m)" = "x86_64" ]; then
  sudo cp /tmp/agent-app-extract/agent-app-linux-x86 "$AGENT_HOME/agent-app"
else
  sudo cp /tmp/agent-app-extract/agent-app-linux-arm64 "$AGENT_HOME/agent-app"
fi

sudo chown agent-admin:agent-core "$AGENT_HOME/agent-app"
sudo chmod 750 "$AGENT_HOME/agent-app"
```

## 9. 계정/그룹 생성

```bash
sudo bash scripts/setup-users.sh
```

검증:

```bash
id agent-admin
id agent-dev
id agent-test
getent group agent-common
getent group agent-core
```

기대 정책:

```text
agent-common: agent-admin, agent-dev, agent-test
agent-core: agent-admin, agent-dev
```

## 10. 디렉터리/권한 설정

```bash
sudo bash scripts/setup-dirs.sh
```

검증:

```bash
export AGENT_HOME=/home/agent-admin/agent-app
namei -l "$AGENT_HOME"
sudo ls -ld "$AGENT_HOME"
sudo ls -ld "$AGENT_HOME/upload_files"
sudo ls -ld "$AGENT_HOME/api_keys"
sudo ls -ld "$AGENT_HOME/bin"
sudo ls -ld /var/log/agent-app
sudo getfacl /home/agent-admin
sudo getfacl "$AGENT_HOME/upload_files"
sudo getfacl "$AGENT_HOME/api_keys"
sudo getfacl /var/log/agent-app
```

권한 정책:

```text
/home/agent-admin: agent-core 그룹에 --x ACL 부여
upload_files: agent-common 그룹 읽기/쓰기
api_keys: agent-core 그룹만 접근
/var/log/agent-app: agent-core 그룹만 접근
```

`/home/agent-admin` ACL은 홈 디렉터리 목록 읽기 권한이 아니라 `$AGENT_HOME` 하위 경로로 들어가기 위한 최소 탐색 권한이다. `codyssey-b1-1-ubuntu24`의 일반 계정에서 `ls -ld "$AGENT_HOME"`가 `Permission denied`를 출력하면 `sudo` 또는 `agent-admin` 컨텍스트로 증빙을 수집한다.

## 11. SSH 20022 설정

SSH 설정은 접속이 끊길 수 있으므로 수동으로 진행한다.

```bash
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
sudo nano /etc/ssh/sshd_config
```

다음 값을 설정한다.

```text
Port 20022
PermitRootLogin no
```

검증 후 재시작:

```bash
sudo sshd -t
sudo systemctl restart ssh
```

확인:

```bash
sudo grep -E '^(Port|PermitRootLogin)' /etc/ssh/sshd_config
sudo ss -tulnp | grep ssh
```

## 12. Root 원격 접속 차단

Root 원격 접속 차단은 SSH 설정의 다음 줄로 확인한다.

```text
PermitRootLogin no
```

검증:

```bash
sudo grep -E '^PermitRootLogin' /etc/ssh/sshd_config
```

## 13. UFW 방화벽 설정

먼저 적용 계획만 확인한다.

```bash
sudo bash scripts/setup-firewall-ufw.sh
```

SSH 20022 접속 가능성을 확인한 뒤 실제 적용한다.

```bash
sudo bash scripts/setup-firewall-ufw.sh --apply
```

검증:

```bash
sudo ufw status numbered
sudo ufw status verbose
```

기대 결과:

```text
Status: active
20022/tcp ALLOW
15034/tcp ALLOW
```

## 14. 환경변수 설정

`agent-admin` 계정으로 설정한다.

```bash
sudo -iu agent-admin
cat >> ~/.profile <<'EOF'
export AGENT_HOME=/home/agent-admin/agent-app
export AGENT_PORT=15034
export AGENT_UPLOAD_DIR=$AGENT_HOME/upload_files
export AGENT_KEY_PATH=$AGENT_HOME/api_keys/t_secret.key
export AGENT_LOG_DIR=/var/log/agent-app
EOF
source ~/.profile
```

확인:

```bash
echo "$AGENT_HOME"
echo "$AGENT_PORT"
echo "$AGENT_UPLOAD_DIR"
echo "$AGENT_KEY_PATH"
echo "$AGENT_LOG_DIR"
```

## 15. 키 파일 생성

`scripts/setup-dirs.sh`가 키 파일을 생성한다.

경로:

```text
/home/agent-admin/agent-app/api_keys/t_secret.key
```

내용:

```text
agent_api_key_test
```

검증:

```bash
sudo -u agent-admin cat /home/agent-admin/agent-app/api_keys/t_secret.key
ls -l /home/agent-admin/agent-app/api_keys/t_secret.key
```

## 16. agent-app 실행

root가 아닌 `agent-admin`으로 실행한다.

```bash
sudo -iu agent-admin
cd "$AGENT_HOME"
./agent-app
```

## 17. Boot Sequence 확인

기대 출력:

```text
Starting Agent Boot Sequence...
[1/5] Checking User Account               [OK]
[2/5] Verifying Environment Variables     [OK]
[3/5] Checking Required Files             [OK]
[4/5] Checking Port Availability          [OK]
[5/5] Verifying Log Permission            [OK]
All Boot Checks Passed!
Agent READY
```

## 18. 15034 LISTEN 확인

다른 `codyssey-b1-1-ubuntu24` 터미널에서 확인한다.

```bash
ps -ef | grep '[a]gent-app'
ss -tulnp | grep 15034
curl http://localhost:15034
```

기대 결과:

```text
0.0.0.0:15034 LISTEN
```

## 19. monitor.sh 실행

저장소 스크립트를 운영 위치로 복사한다.

```bash
export AGENT_HOME=/home/agent-admin/agent-app
sudo cp bin/monitor.sh "$AGENT_HOME/bin/monitor.sh"
sudo chown agent-dev:agent-core "$AGENT_HOME/bin/monitor.sh"
sudo chmod 750 "$AGENT_HOME/bin/monitor.sh"
```

문법 검사와 실행:

```bash
bash -n "$AGENT_HOME/bin/monitor.sh"
sudo -u agent-admin "$AGENT_HOME/bin/monitor.sh"
```

`monitor.sh` 동작:

- 앱 프로세스 미실행 시 `exit 1`
- `15034` 포트 미LISTEN 시 `exit 1`
- 방화벽 비활성은 `[WARNING]`만 출력
- CPU `> 20%`면 `[WARNING]`
- MEM `> 10%`면 `[WARNING]`
- DISK_USED `> 80%`면 `[WARNING]`
- `/var/log/agent-app/monitor.log`에 `>>`로 누적

## 20. monitor.log 확인

```bash
tail -n 5 /var/log/agent-app/monitor.log
```

로그 포맷:

```text
[YYYY-MM-DD HH:MM:SS] PID:... CPU:..% MEM:..% DISK_USED:..%
```

`>`와 `>>`의 차이:

- `>`는 기존 파일을 덮어쓴다.
- `>>`는 기존 파일 뒤에 누적한다.
- 관제 로그는 시간순 기록이 중요하므로 `>>`를 사용한다.

## 21. logrotate 설정

```bash
sudo bash scripts/setup-logrotate.sh
```

검증:

```bash
sudo cat /etc/logrotate.d/agent-app-monitor
sudo logrotate -d /etc/logrotate.d/agent-app-monitor
```

정책:

```text
size 10M
rotate 10
missingok
notifempty
copytruncate
```

## 22. cron 등록

```bash
sudo bash scripts/install-cron.sh
```

등록 내용:

```cron
* * * * * /home/agent-admin/agent-app/bin/monitor.sh >> /var/log/agent-app/cron.log 2>&1
```

검증:

```bash
sudo crontab -u agent-admin -l
```

## 23. cron 자동 실행 확인

```bash
wc -l /var/log/agent-app/monitor.log
sleep 70
wc -l /var/log/agent-app/monitor.log
tail -n 10 /var/log/agent-app/monitor.log
tail -n 10 /var/log/agent-app/cron.log
```

기대 결과:

```text
1분 뒤 monitor.log 라인 수 증가
```

## 24. 보너스 report.sh 실행

운영 위치로 복사한다.

```bash
export AGENT_HOME=/home/agent-admin/agent-app
sudo cp bin/report.sh "$AGENT_HOME/bin/report.sh"
sudo chown agent-dev:agent-core "$AGENT_HOME/bin/report.sh"
sudo chmod 750 "$AGENT_HOME/bin/report.sh"
```

실행:

```bash
bash -n "$AGENT_HOME/bin/report.sh"
sudo -u agent-admin "$AGENT_HOME/bin/report.sh"
```

시간 구간 분석:

```bash
sudo -u agent-admin "$AGENT_HOME/bin/report.sh" --from "2026-05-27 10:00:00" --to "2026-05-27 11:00:00"
```

출력 항목:

```text
Samples
CPU Average/Maximum/Minimum
MEM Average/Maximum/Minimum
DISK_USED Average/Maximum/Minimum
```

## 25. 보너스 archive-old-logs.sh 실행

```bash
bash -n scripts/archive-old-logs.sh
sudo bash scripts/archive-old-logs.sh
find /var/log/monitor/agent-app/archive -type f -name "*.gz" -ls
```

정책:

- `/var/log/agent-app/*.log` 중 7일 이상 경과 파일 압축
- 압축 파일을 `/var/log/monitor/agent-app/archive/`로 이동
- archive의 `.gz` 중 30일 이상 경과 파일 삭제
- 대상 없음, 권한 부족, 디렉터리 없음, gzip 실패를 메시지로 처리

## 26. 전체 검증 체크리스트

최종 검증 명령은 `docs/verification-log.md`와 `docs/13-전체-검증-체크리스트.md`를 따른다.

macOS 정적 검증:

```bash
pwd
ls -la
find . -maxdepth 3 -type f | sort
bash -n scripts/setup-users.sh
bash -n scripts/setup-dirs.sh
bash -n scripts/setup-firewall-ufw.sh
bash -n scripts/setup-logrotate.sh
bash -n scripts/install-cron.sh
bash -n scripts/archive-old-logs.sh
bash -n bin/monitor.sh
bash -n bin/report.sh
git status
```

## 27. 트러블슈팅

자세한 내용은 `docs/troubleshooting.md`와 `docs/14-트러블슈팅.md`에 정리했다.

대표 사례:

| 문제 | 확인 명령 | 해결 방향 |
|---|---|---|
| root로 앱 실행 실패 | `whoami` | `sudo -iu agent-admin` |
| 15034 포트 없음 | `ss -tulnp \| grep 15034` | 앱 Boot Sequence 확인 |
| cron 실패 | `tail /var/log/agent-app/cron.log` | 절대 경로, 권한, 환경 변수 확인 |
| monitor.log 권한 오류 | `ls -ld /var/log/agent-app` | `agent-core` 그룹 쓰기 권한 확인 |
| GLIBC 오류 | `ldd --version` | Ubuntu 24.04 VM에서 glibc와 바이너리 호환성 확인 |

## 28. 동료 평가 대비 질문답변

자세한 답변은 `docs/15-동료평가-대비-질문답변.md`에 있다.

핵심 설명 포인트:

- SSH 포트를 바꾸고 Root 로그인을 막는 이유
- 필요한 포트만 허용하는 이유
- `agent-common`과 `agent-core`를 분리한 이유
- `upload_files`와 `api_keys` 권한을 다르게 둔 이유
- 프로세스와 포트를 모두 확인하는 이유
- WARNING 조건과 `exit 1` 조건을 분리한 이유
- `>`와 `>>` 차이
- logrotate가 필요한 이유
- 로그 아카이브 정책이 필요한 이유

## 29. Git 커밋 이력 관리 방법

권장 커밋 순서:

```bash
git status
git add docs/00-목차.md docs/requirements-checklist.md
git commit -m "docs: add B1-1 mission analysis and checklist"

git add docs bin scripts README.md
git commit -m "docs: complete B1-1 beginner step-by-step guide"

git log --oneline --graph --all --decorate -n 20
```

기능 단위로 더 세분화할 경우:

```text
docs: add B1-1 mission analysis and checklist
chore: initialize B1-1 project structure
feat: add agent user and group setup script
feat: add agent directory permission setup script
feat: add SSH and UFW hardening guide
docs: add agent app runtime setup guide
feat: add monitor script health checks
feat: add monitor log rotation setup
docs: add cron execution verification guide
feat: add monitor log report script
feat: add old log archive cleanup script
docs: complete B1-1 beginner step-by-step guide
docs: align B1-1 evidence with evaluation checklist
```

## 30. 보안 주의사항

- 실제 API Key, 비밀번호, 토큰은 커밋하지 않는다.
- 이 미션의 `agent_api_key_test`는 테스트 문자열이다.
- 앱은 root로 실행하지 않는다.
- SSH 변경 전 기존 터미널을 닫지 않는다.
- UFW 활성화 전 `20022/tcp` 허용 여부를 확인한다.
- `/var/log`와 `/etc` 변경은 `codyssey-b1-1-ubuntu24`에서만 실행한다.
- macOS에서는 `useradd`, `ufw`, `systemctl`, `crontab` 실습을 직접 실행하지 않는다.

## 증빙 작성 위치

- 실제 명령 기록: `docs/command-log.md`
- 검증 명령 모음: `docs/verification-log.md`
- 요구사항 체크: `docs/requirements-checklist.md`
- 보안 설명: `docs/security-notes.md`
- 문제 해결 기록: `docs/troubleshooting.md`
