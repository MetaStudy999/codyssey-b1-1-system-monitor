# B1-1 시스템 관제 자동화 스크립트 개발

## 1. 프로젝트 개요

이 저장소는 코디세이 B1-1 미션인 시스템 관제 자동화 스크립트 개발을 수행하기 위한 제출 자료다.

목표는 제공 앱을 안전한 Linux 운영 환경에 배치하고, SSH/방화벽/계정/권한/로그/cron/관제 스크립트를 초보자도 재현할 수 있게 문서화하는 것이다.

이 README는 명령을 처음 보는 사람도 위에서 아래로 한 블록씩 실행할 수 있게 작성했다. 한 단계에서 오류가 나면 다음 단계로 넘어가지 말고, 그 단계의 **정상 결과**와 **오류 해결**을 먼저 확인한다.

> **가장 중요한 구분:** `sudo`, `useradd`, `ufw`, `systemctl`, `/var/log`가 나오는 명령은 OrbStack Ubuntu 24.04 Machine에서 실행한다. macOS에서는 OrbStack 접속, Git, 문서 편집만 한다.

### 1.1 이 README를 읽는 방법

명령 앞의 실행 위치를 먼저 확인한다.

| 표시 | 실행하는 곳 | 주로 하는 작업 |
|---|---|---|
| **macOS 터미널** | Mac의 Terminal 또는 VS Code 터미널 | `orb` 접속, Git, 저장소 확인 |
| **Ubuntu 관리자 터미널** | OrbStack Ubuntu에 처음 접속한 일반 계정 | `sudo`가 필요한 설치·계정·권한·SSH·UFW 작업 |
| **Ubuntu 앱 터미널** | `sudo -iu agent-admin`으로 전환한 터미널 | 앱을 일반 계정으로 실행하고 계속 켜 두기 |
| **출력 예시** | 입력하지 않음 | 명령이 정상일 때 화면에 보일 수 있는 내용 |

이후 별도 표시가 없는 `scripts/...`, `bin/...` 명령은 **Ubuntu 관리자 터미널의 저장소 최상위 폴더**에서 실행한다. 다음 명령이 성공하면 올바른 위치다.

```bash
test -f README.md && test -f agent-app.zip && test -d scripts && echo "[OK] 저장소 최상위 폴더입니다."
```

`[OK]`가 보이지 않으면 명령을 계속 실행하지 않는다. `pwd`와 `ls -la`로 현재 위치를 확인하고, `README.md`가 있는 폴더로 `cd`한다.

### 1.2 복사해서 입력하는 부분과 입력하지 않는 부분

아래처럼 `bash`라고 표시된 코드 블록은 터미널에서 실행할 수 있는 명령이다. 단, 바로 위의 **실행 위치와 실행 조건을 먼저 읽고**, 자신의 현재 단계에 해당할 때만 실행한다. 특히 “오류 해결”과 “복구” 아래의 명령은 그 오류가 실제로 발생했을 때만 사용한다.

```bash
whoami
```

아래 내용은 **출력 예시**이므로 입력하지 않는다. 실제 사용자 이름이나 숫자는 달라도 정상이다.

```text
my-user
```

- `bash` 블록: 표시된 터미널에서 조건을 확인한 뒤 실행한다.
- `text` 블록: 정상 출력, 설정값, 형식 예시이므로 터미널에 입력하지 않는다.
- `cron` 블록: `crontab -e` 편집기 안에 넣는 내용이며 일반 터미널 명령이 아니다.

문서의 `$`, `...`, `<PID>`, `/path/to/...`는 그대로 입력하는 값이 아닐 수 있다.

- `$AGENT_HOME`처럼 `$`로 시작하면 셸이 환경 변수의 값으로 바꾼다.
- `...`는 생략 표시다.
- `<PID>`는 실제 프로세스 번호로 바꿔야 하는 자리다.
- `/path/to/...`는 자신의 실제 경로로 바꿔야 하는 예시다.
- `#`으로 시작하는 줄은 설명용 주석이라 입력해도 실행되지 않는다.

`sudo`를 처음 실행하면 현재 Ubuntu 사용자의 비밀번호를 물을 수 있다. 비밀번호를 입력하는 동안 글자나 `*`가 화면에 보이지 않는 것이 정상이다. 입력 후 Enter를 누른다.

### 1.3 터미널을 세 개로 나누는 이유

앱을 실행하면 그 터미널은 앱이 종료될 때까지 프롬프트가 돌아오지 않는다. 16단계부터는 다음처럼 창이나 탭을 나누면 덜 헷갈린다.

| 터미널 | 상태 | 닫아도 되는 시점 |
|---|---|---|
| A: macOS | Git과 OrbStack 접속용 | 필요 없을 때 |
| B: Ubuntu 관리자 | 저장소 폴더에서 설치·검증 명령 실행 | 전체 검증 후 |
| C: Ubuntu 앱 | `agent-admin`으로 앱 실행, `Agent READY` 상태 유지 | monitor와 cron 검증 후 |

한 개의 터미널만 사용하면 앱을 켜 둔 채 다음 명령을 실행할 수 없다. OrbStack에서 새 터미널 탭을 하나 더 열어 같은 Machine에 접속한다.

### 1.4 Machine 이름이 다를 때

이 README의 실행 증빙에는 Machine 이름 `cds-ubuntu24`를 사용했다. 세부 문서 일부에는 예시 이름 `codyssey-b1-1-ubuntu24`가 보일 수 있다. Machine 이름 자체는 평가 항목이 아니므로, macOS 터미널에서 실제 이름을 확인해 자신의 이름으로 바꿔 사용한다.

```bash
orb list
orb -m cds-ubuntu24
```

두 번째 명령에서 `machine not found`가 나오면 `orb list`의 `NAME` 열에 표시된 이름으로 `cds-ubuntu24`를 바꾼다.

### 1.5 오류가 나면 먼저 확인할 다섯 가지

오류 메시지를 지우거나 같은 명령을 무작정 반복하지 말고 다음 순서로 확인한다.

```bash
printf 'USER=%s\n' "$(whoami)"
printf 'PWD=%s\n' "$PWD"
printf 'OS=%s\n' "$(uname -s)"
if [ -r /etc/os-release ]; then
  grep PRETTY_NAME /etc/os-release
else
  sw_vers -productVersion 2>/dev/null || true
fi
git rev-parse --show-toplevel 2>/dev/null || echo "[확인] 현재 폴더는 Git 저장소가 아닙니다."
```

- `USER`: 지금 명령을 실행하는 계정이 맞는가?
- `PWD`: `README.md`, `scripts`, `bin`이 있는 저장소 폴더인가?
- `OS`와 `PRETTY_NAME`: macOS(`Darwin`)인지 Ubuntu(`Linux`)인지 구분한다.
- `git rev-parse`: 저장소 최상위 경로가 어디인가?

실패한 명령의 종료 코드는 **그 명령 바로 다음에** 확인한다. 다른 명령을 먼저 실행하면 값이 바뀐다.

```bash
echo "직전 명령 종료 코드: $?"
```

일반적으로 `0`은 성공, `0`이 아니면 실패다.

`bash -n 파일.sh`처럼 **성공하면 아무것도 출력하지 않는 명령**도 있다. 이때 바로 `echo $?`를 실행해 `0`이면 정상이다.

자주 보이는 오류의 뜻:

| 오류 | 쉬운 뜻 | 먼저 할 일 |
|---|---|---|
| `command not found` | 프로그램이 설치되지 않았거나 명령을 잘못 입력함 | 7단계의 패키지 설치 확인 |
| `No such file or directory` | 현재 경로가 다르거나 앞 단계에서 파일을 만들지 못함 | `pwd`, `ls -la`, 앞 단계의 완료 기준 확인 |
| `Permission denied` | 현재 계정에 읽기·쓰기·실행 권한이 없음 | `whoami`, `ls -l`, 필요한 경우에만 `sudo` 확인 |
| `Connection refused` | 해당 포트에서 앱이 듣고 있지 않음 | 앱 터미널의 Boot Sequence와 `ss` 확인 |
| `Operation timed out` | 연결 후 응답을 기다리다 제한 시간이 끝남 | 18단계처럼 먼저 `Connected`와 LISTEN 여부 확인 |
| 환경 변수가 빈 줄 | 현재 셸에 설정이 로드되지 않음 | `source ~/.profile` 후 다시 `echo` |

더 자세한 사례는 [트러블슈팅 보고서](docs/troubleshooting.md)와 [단계별 트러블슈팅](docs/14-트러블슈팅.md)에 있다.

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

### 2.1 처음 알아둘 용어

| 용어 | 쉬운 설명 | 이 미션에서 확인하는 것 |
|---|---|---|
| 프로세스 | 실행 중인 프로그램 한 개 | `agent-app`이 살아 있는가? |
| PID | 실행 중인 프로세스에 붙는 번호 | 어떤 앱의 CPU/MEM을 잴 것인가? |
| 포트 | 프로그램이 네트워크 요청을 받는 번호표가 붙은 문 | 앱은 `15034`, SSH는 `20022`에서 기다리는가? |
| LISTEN | 프로그램이 포트를 열고 연결을 기다리는 상태 | `ss` 결과에 `15034`와 `20022`가 보이는가? |
| 방화벽 | 허용한 포트만 통과시키는 출입문 | `20022/tcp`, `15034/tcp`만 허용했는가? |
| 사용자·그룹 | 사람과 역할에 따라 권한을 나누는 기준 | 테스트 계정이 키 파일을 읽지 못하게 했는가? |
| 권한 `rwx` | 읽기(read), 쓰기(write), 실행·통과(execute) 권한 | 필요한 역할에 필요한 권한만 주었는가? |
| 환경 변수 | 경로와 포트 같은 설정값에 붙인 이름 | 앱과 cron이 같은 경로를 사용하는가? |
| 로그 | 시간순으로 남기는 상태 기록 | 장애가 나중에 재현되지 않아도 원인을 찾을 수 있는가? |
| cron | 정해진 시각마다 명령을 자동 실행하는 예약 기능 | monitor가 매분 실행되는가? |
| logrotate | 커진 로그를 나누고 오래된 파일을 정리하는 도구 | 로그가 디스크를 계속 차지하지 않는가? |

## 3. 개발 환경

| 구분 | 사용 환경 |
|---|---|
| Host OS | macOS |
| Linux 실습 | 자신의 미션 전용 OrbStack Ubuntu Machine (예: `cds-ubuntu24`) |
| Container Runtime | Docker, 필요 시 보조 |
| Version Control | Git / GitHub |
| Editor | VS Code |
| Shell Script | Bash |

모든 Linux 실습 증빙은 자신의 미션 전용 Ubuntu Machine에서 남긴다. 제공 앱 실행 중 `GLIBC_2.38 not found`가 발생하면 같은 Machine에서 `ldd --version`, `cat /etc/os-release`, `sudo file /home/agent-admin/agent-app/agent-app`로 앱 바이너리와 Ubuntu 24.04 호환성을 확인한다.

## 4. 전체 수행 순서

먼저 [전체 목차](docs/00-목차.md)를 읽고, 아래 순서로 진행한다. README에는 전체 흐름을 담았고, 링크한 문서에는 단계별 설명과 증빙 위치를 더 자세히 담았다.

처음 실습할 때는 **이 README를 주 실행 경로**로 삼고, 이해가 안 되거나 오류가 날 때 해당 단계의 상세 문서를 연다. README와 상세 문서의 같은 설정 명령을 연달아 두 번 실행하라는 뜻은 아니다. 이미 한쪽에서 완료한 단계는 검증 명령만 다시 확인하고 다음 번호로 넘어간다.

- [환경 준비](docs/01-환경준비.md)
- [계정·그룹 생성](docs/02-계정-그룹-생성.md)
- [디렉터리·권한 설정](docs/03-디렉토리-권한-설정.md)
- [agent-app 압축 해제와 배치](docs/04-agent-app-압축해제와-배치.md)
- [SSH·방화벽 설정](docs/05-SSH-방화벽-설정.md)
- [환경 변수·키 파일 설정](docs/06-환경변수-키파일-설정.md)
- [agent-app 실행·검증](docs/07-agent-app-실행-검증.md)
- [monitor.sh 구현·검증](docs/08-monitor-sh-구현-검증.md)
- [logrotate 로그 용량 관리](docs/10-logrotate-로그용량관리.md)
- [cron 자동 실행](docs/09-cron-자동실행.md)
- [보너스 report.sh](docs/11-보너스-report-sh.md)
- [보너스 로그 아카이브](docs/12-보너스-로그-아카이브.md)
- [전체 검증 체크리스트](docs/13-전체-검증-체크리스트.md)
- [단계별 트러블슈팅](docs/14-트러블슈팅.md)
- [동료 평가 대비 질문과 답변](docs/15-동료평가-대비-질문답변.md)

상세 문서의 파일 번호는 파일을 찾기 위한 이름이다. 실제 실행은 위에 적힌 순서를 따르며, 로그가 쌓이기 전에 보존 정책을 준비하기 위해 `docs/10` logrotate를 `docs/09` cron보다 먼저 확인한다.

순서를 바꾸지 않는 이유는 뒤 단계가 앞 단계의 결과를 사용하기 때문이다.

```text
계정 생성 → 디렉터리 권한 → 앱 배치·설정 → 앱 실행
          → monitor 직접 실행 → logrotate 준비 → cron 자동 실행
```

특히 앱이 켜지기 전에 monitor를 실행하면 프로세스·포트 검사가 실패하고, monitor를 운영 위치에 복사하기 전에 cron을 등록하면 자동 실행이 실패한다.

## 5. 요구사항 반영표

| 미션 요구사항 | 구현 내용 | 검증 명령 | 결과 |
|---|---|---|---|
| SSH 포트 20022 | `/etc/ssh/sshd_config` 수정 안내 | `grep`, `ss` | 구현·검증 절차 준비 |
| Root 접속 차단 | `PermitRootLogin no` 설정 안내 | `grep` | 구현·검증 절차 준비 |
| 방화벽 포트 제한 | UFW 스크립트 제공 | `ufw status` | 구현·검증 절차 준비 |
| 계정/그룹 생성 | `scripts/setup-users.sh` | `id`, `getent` | 구현·검증 절차 준비 |
| 디렉터리 권한 | `scripts/setup-dirs.sh` | `ls -ld`, `getfacl` | 구현·검증 절차 준비 |
| 앱 실행 | `agent-admin` 실행 안내 | Boot Sequence, `ss`, 제한 시간 있는 `curl` | 구현·검증 절차 준비 |
| monitor.sh 구현 | `bin/monitor.sh` | `bash -n`, 직접 실행 | 스크립트 준비·VM 증빙 필요 |
| 로그 누적 | `monitor.log` append | `tail`, `wc` | 구현·검증 절차 준비 |
| cron 등록 | `scripts/install-cron.sh` | `crontab`, `tail` | 스크립트 준비·VM 증빙 필요 |
| 로그 용량 관리 | `scripts/setup-logrotate.sh` | `logrotate -d` | 스크립트 준비·VM 증빙 필요 |
| 보너스 report.sh | `bin/report.sh` | `report.sh` 실행 | 스크립트 준비·VM 증빙 필요 |
| 보너스 아카이브 | `scripts/archive-old-logs.sh` | archive script 실행 | 스크립트 준비·VM 증빙 필요 |

위 표의 “준비”는 **현재 학습자의 Machine에서 실행까지 끝났다는 뜻이 아니다.** 스크립트와 검증 방법이 준비됐다는 뜻이다. 각 단계를 직접 실행한 뒤 명령 출력과 날짜를 [명령 기록](docs/command-log.md)에 남겨야 실제 검증 완료가 된다.

아래 내용은 2026-05-31에 `cds-ubuntu24`에서 확인했던 **참고용 실행 예시**다. 그대로 자신의 증빙으로 제출하지 말고, 자신의 Machine에서 나온 최신 출력으로 교체한다.

참고용 실행 환경:

```text
검증일: 2026-05-31
검증 VM: cds-ubuntu24
OS: Ubuntu 24.04.4 LTS
Architecture: x86_64
```

실행 검증 중 확인한 핵심 결과:

- SSH: `Port 20022`, `PermitRootLogin no`, `sshd`가 `0.0.0.0:20022`와 `[::]:20022`에서 LISTEN
- UFW: `Status: active`, 허용 규칙은 `20022/tcp`, `15034/tcp`, 각 v6 규칙만 존재
- 계정/그룹: `agent-common`은 `agent-admin`, `agent-dev`, `agent-test`; `agent-core`는 `agent-admin`, `agent-dev`
- 앱 실행: Boot Sequence 5단계 `[OK]`, `Agent READY`, `0.0.0.0:15034 LISTEN`
- `curl`: `Connected to localhost` 확인 후 앱이 본문을 반환하지 않아 제한 시간 종료 가능
- `monitor.sh`: 프로세스와 포트 `[OK]`, UFW active 인식, `/var/log/agent-app/monitor.log` append 성공
- cron: `monitor.log`가 70초 대기 중 4줄에서 5줄로 증가
- logrotate: `su agent-admin agent-core` 포함 후 드라이런에서 rotate 대상 정상 판단
- `report.sh`: 샘플 수, CPU/MEM/DISK_USED 평균/최대/최소 출력
- `archive-old-logs.sh`: 오래된 로그가 없어도 INFO 메시지 후 안전 종료

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

### 7.1 macOS에서 Machine과 저장소 확인

**실행 위치: macOS 터미널**

```bash
pwd
ls -la
git status
orb list
```

`git status`에 다른 작업의 수정 파일이 보이면 지우거나 되돌리지 않는다. 현재 작업과 관계없는 변경일 수 있으므로 그대로 보존한다.

OrbStack Machine에 접속한다. 이름이 다르면 `orb list`의 실제 이름으로 바꾼다.

```bash
orb -m cds-ubuntu24
```

프롬프트가 바뀐 뒤 `cat /etc/os-release`에서 Ubuntu가 확인되면 다음으로 진행한다.

### 7.2 Ubuntu와 저장소 위치 확인

**실행 위치: Ubuntu 관리자 터미널**

```bash
cat /etc/os-release
uname -m
whoami
id
hostname
pwd
ls -la
test -f README.md && test -d scripts && echo "[OK] 저장소 확인"
```

정상 기준:

- OS에 `Ubuntu 24.04`가 보인다.
- `uname -m`은 `x86_64`, `aarch64`, `arm64` 중 하나다.
- `whoami`는 `root`가 아니라 평소 사용하는 sudo 가능 계정이다.
- 마지막 줄에 `[OK] 저장소 확인`이 보인다.

`README.md`가 없으면 현재 폴더에서 스크립트를 실행할 수 없다. 저장소 위치를 모를 때는 다음 명령으로 후보를 찾는다.

```bash
find "$HOME" /Users -maxdepth 5 -type f -name B1-1-Mission.md 2>/dev/null
```

출력된 경로에서 마지막 `/B1-1-Mission.md`를 뺀 폴더로 이동한다. 예를 들어 `/some/path/B1-1-Mission.md`가 나왔다면 `cd /some/path`를 실행한다.

아무 경로도 나오지 않으면 Ubuntu에서 저장소를 아직 볼 수 없는 상태다. OrbStack이 공유한 macOS `/Users/...` 경로를 확인하거나, 네트워크와 Git 접근이 가능한 경우 홈 디렉터리에 한 번만 복제한다.

```bash
cd "$HOME"
git clone https://github.com/MetaStudy999/codyssey-b1-1-system-monitor
cd codyssey-b1-1-system-monitor
test -f README.md && test -f agent-app.zip && echo "[OK] 저장소 준비 완료"
```

이미 같은 이름의 폴더가 있다면 다시 clone하지 말고 그 폴더의 `git status`와 파일을 확인한다.

### 7.3 필요한 명령 확인과 설치

**실행 위치: Ubuntu 관리자 터미널 · 저장소 최상위 폴더**

각 명령이 설치되어 있는지 한 줄씩 확인한다.

```bash
for cmd in unzip ss sshd ufw logrotate crontab getfacl curl file nano gzip ping; do
  if command -v "$cmd" >/dev/null 2>&1; then
    echo "[OK] $cmd"
  else
    echo "[MISSING] $cmd"
  fi
done
```

모두 `[OK]`면 설치 명령은 건너뛴다. 하나라도 `[MISSING]`이면 Ubuntu에서 설치한다.

```bash
sudo apt update
sudo apt install -y openssh-server unzip iproute2 ufw logrotate cron acl curl file nano gzip iputils-ping
```

설치 후 위 확인 명령을 다시 실행한다.

오류 해결:

- `sudo: command not found`: Ubuntu 관리자 계정이 아닌 제한된 환경일 수 있다. `whoami`, `id`를 확인한다.
- `user is not in the sudoers file`: 현재 계정에는 시스템 변경 권한이 없다. OrbStack Machine을 만든 원래 관리자 계정으로 다시 접속한다.
- `Could not get lock /var/lib/dpkg/lock...`: 다른 패키지 설치가 진행 중이다. 잠시 기다린 뒤 다시 실행한다. 잠금 파일을 임의로 삭제하지 않는다.
- `Temporary failure resolving...`: Ubuntu의 네트워크 연결 문제다. `ping -c 1 1.1.1.1`과 `ping -c 1 archive.ubuntu.com`으로 네트워크와 DNS를 구분해 확인한다.

**완료 기준:** 필요한 명령이 모두 `[OK]`이고, Ubuntu 관리자 터미널이 저장소 최상위 폴더에 있다.

## 8. agent-app.zip 내부 확인

**실행 위치: Ubuntu 관리자 터미널 · 저장소 최상위 폴더**

압축 파일이 존재하고 손상되지 않았는지 먼저 확인한다. `unzip -t`는 파일을 실제로 풀지 않고 무결성만 검사한다.

```bash
ls -lh agent-app.zip
unzip -t agent-app.zip
unzip -l agent-app.zip
```

정상이면 `No errors detected in compressed data`가 보이고, 목록에는 다음 파일이 있다.

```text
agent-app-linux-x86
agent-app-linux-arm64
__MACOSX/._agent-app-linux-x86
__MACOSX/._agent-app-linux-arm64
```

`cds-ubuntu24`의 아키텍처에 맞는 파일을 선택한다.

```bash
uname -m
```

선택 기준:

| `uname -m` 결과 | 복사할 파일 |
|---|---|
| `x86_64` | `agent-app-linux-x86` |
| `aarch64` 또는 `arm64` | `agent-app-linux-arm64` |

`__MACOSX`로 시작하는 파일은 macOS가 ZIP을 만들 때 넣은 부가 정보다. Linux 앱이 아니므로 복사하거나 실행하지 않는다.

앱 배치는 `agent-admin`, `agent-core`, `$AGENT_HOME` 디렉터리가 있어야 성공한다. 따라서 계정/그룹 생성과 디렉터리/권한 설정을 먼저 끝낸 뒤 `10.1 agent-app 배치`에서 진행한다.

오류 해결:

- `cannot find or open agent-app.zip`: 저장소 최상위 폴더가 아니다. `pwd`와 `ls -la`를 확인한다.
- `End-of-central-directory signature not found`: ZIP이 손상됐거나 다른 파일을 ZIP 이름으로 저장했다. 원본 `agent-app.zip`을 다시 준비한다.
- `unzip: command not found`: 7단계의 패키지 설치를 다시 확인한다.

**완료 기준:** ZIP 무결성 검사에 오류가 없고, `uname -m`에 맞는 앱 파일명을 선택할 수 있다.

## 9. 계정/그룹 생성

**실행 위치: Ubuntu 관리자 터미널 · 저장소 최상위 폴더**

세 계정을 나누는 이유는 “모두에게 모든 권한을 주지 않기” 위해서다.

- `agent-admin`: 앱과 cron을 실행한다.
- `agent-dev`: 운영 스크립트의 소유자다.
- `agent-test`: 공용 업로드 영역만 테스트하며 키와 로그에는 접근하지 않는다.
- `agent-common`: 세 계정이 함께 쓰는 업로드용 그룹이다.
- `agent-core`: 관리자와 개발자만 속하는 민감 정보용 그룹이다.

스크립트는 이미 존재하는 계정과 그룹은 다시 만들지 않으므로 같은 Machine에서 재실행해도 된다.

```bash
sudo bash scripts/setup-users.sh
```

`[INFO] User/group setup completed`가 보이면 아래 명령으로 최종 상태를 검증한다.

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

`getent group`의 실제 출력은 다음처럼 그룹명, 암호 자리, GID, 구성원 순서로 보인다. 숫자와 구성원 순서는 환경마다 달라도 된다.

```text
agent-common:x:1001:agent-admin,agent-dev,agent-test
agent-core:x:1002:agent-admin,agent-dev
```

오류 해결:

- `scripts/setup-users.sh: No such file or directory`: 저장소 최상위 폴더로 이동한다.
- `This script must be run with sudo`: 앞에 `sudo bash`를 빠뜨리지 않았는지 확인한다.
- `useradd: user ... already exists`: 스크립트가 아닌 명령을 따로 실행했을 수 있다. 위 검증 명령으로 이미 최종 정책이 맞는지 확인한다.
- 이전 실습 때문에 `agent-test`가 `agent-core`에도 보임: 최소 권한 정책 위반이다. 미션 전용 Machine인지 확인한 뒤 `sudo gpasswd -d agent-test agent-core`로 잘못된 멤버십만 제거하고 다시 검증한다.
- 그룹을 만들었는데 기존 로그인 세션에 보이지 않음: 새 로그인 세션에서 그룹 정보가 반영된다. `sudo -iu agent-admin id`처럼 새 세션으로 확인한다.

**완료 기준:** `agent-common`에는 세 계정, `agent-core`에는 `agent-admin`과 `agent-dev`만 보인다.

## 10. 디렉터리/권한 설정

**실행 위치: Ubuntu 관리자 터미널 · 저장소 최상위 폴더**

먼저 앱 폴더, 공용 업로드 폴더, 키 폴더, 스크립트 폴더, 로그 폴더를 만들고 역할별 권한을 적용한다.

```bash
sudo bash scripts/setup-dirs.sh
```

`upload_files` 자체가 `agent-common`에 열려 있어도, `agent-test`가 상위 폴더를 통과하지 못하면 접근할 수 없다. 상위 폴더의 목록은 보여 주지 않고 이미 알고 있는 `upload_files` 경로로 통과만 할 수 있도록 최소 `--x` ACL을 명시적으로 보강한다.

```bash
export AGENT_HOME=/home/agent-admin/agent-app
sudo setfacl -m g:agent-common:--x /home/agent-admin "$AGENT_HOME"
```

스크립트 끝에 `[INFO] Directory setup completed`가 보이면 검증한다. `export`는 현재 터미널에서 긴 경로를 `$AGENT_HOME`이라는 짧은 이름으로 쓰게 해 주며, 새 터미널에는 자동으로 이어지지 않는다.

```bash
sudo namei -l "$AGENT_HOME"
sudo ls -ld "$AGENT_HOME"
sudo ls -ld "$AGENT_HOME/upload_files"
sudo ls -ld "$AGENT_HOME/api_keys"
sudo ls -ld "$AGENT_HOME/bin"
sudo ls -ld /var/log/agent-app
sudo getfacl /home/agent-admin
sudo getfacl "$AGENT_HOME"
sudo getfacl "$AGENT_HOME/upload_files"
sudo getfacl "$AGENT_HOME/api_keys"
sudo getfacl /var/log/agent-app
```

권한 정책:

```text
/home/agent-admin: agent-core와 agent-common 그룹에 --x ACL 부여
$AGENT_HOME: 기본 agent-core r-x, agent-common에는 --x ACL만 추가
upload_files: agent-common 그룹 읽기/쓰기
api_keys: agent-core 그룹만 접근
/var/log/agent-app: agent-core 그룹만 접근
```

기대 권한:

| 경로 | 소유자:그룹 | 권한 | 쉬운 의미 |
|---|---|---|---|
| `$AGENT_HOME` | `agent-admin:agent-core` | `750` | 관리자 쓰기, core 읽기·진입 |
| `upload_files` | `agent-admin:agent-common` | `2770` | common 구성원이 함께 읽고 쓰기 |
| `api_keys` | `agent-admin:agent-core` | `2770` | core만 키 관리 |
| `bin` | `agent-dev:agent-core` | `750` | dev가 스크립트 관리, core가 실행 |
| `/var/log/agent-app` | `agent-admin:agent-core` | `2770` | core만 로그 관리 |

권한 숫자는 소유자·그룹·그 외 사용자의 권한을 압축해서 나타낸다. `7=rwx`, `5=r-x`, `0=---`이다. `2770`의 맨 앞 `2`는 setgid로, 이 폴더 안에서 만든 새 파일이 폴더의 그룹을 이어받게 한다.

ACL은 기본 `rwx`만으로 표현하기 어려운 추가 권한이다. `/home/agent-admin`의 `agent-core:--x`, `agent-common:--x`와 `$AGENT_HOME`의 `agent-common:--x`는 폴더 목록을 읽는 권한이 아니다. `agent-core`는 운영 경로로, `agent-common`은 이미 알고 있는 `upload_files` 경로로 **통과만 하는 최소 권한**이다. `api_keys` 자체는 `agent-core`로 막혀 있어 `agent-test`가 이름을 알아도 들어갈 수 없다.

먼저 `agent-test`가 공용 업로드 폴더에는 파일을 만들고 지울 수 있는지 확인한다.

```bash
if sudo -u agent-test touch "$AGENT_HOME/upload_files/.permission-test" \
  && sudo -u agent-test rm "$AGENT_HOME/upload_files/.permission-test"; then
  echo "[OK] agent-test가 upload_files에 만들고 지울 수 있습니다."
else
  echo "[FAIL] upload_files의 상위 경로 ACL과 그룹 권한을 확인하세요."
fi
```

이어서 같은 `agent-test`가 키 파일은 읽지 못하는지 확인한다. 아래 결과가 `[OK] 접근 차단`이어야 정상이다.

```bash
if ! sudo test -f "$AGENT_HOME/api_keys/t_secret.key"; then
  echo "[FAIL] 먼저 t_secret.key 파일이 존재해야 합니다."
elif sudo -u agent-test test -r "$AGENT_HOME/api_keys/t_secret.key"; then
  echo "[FAIL] agent-test가 키를 읽을 수 있습니다."
else
  echo "[OK] agent-test의 키 접근이 차단됐습니다."
fi
```

오류 해결:

- `getfacl: command not found`: `sudo apt install -y acl`을 실행한 뒤 다시 확인한다.
- 일반 계정에서 `Permission denied`: 의도한 최소 권한 때문에 정상일 수 있다. 증빙 명령은 위처럼 `sudo`로 실행한다.
- `agent-test`의 upload 쓰기만 실패: `getfacl /home/agent-admin "$AGENT_HOME" "$AGENT_HOME/upload_files"`로 `agent-common:--x`와 `agent-common:rwx`를 차례로 확인한다.
- `Missing user` 또는 `Missing group`: 9단계가 끝나지 않았다. `sudo bash scripts/setup-users.sh`부터 다시 확인한다.
- 키 파일 내용이 다르다는 `[WARNING]`: 스크립트는 기존 파일을 안전을 위해 덮어쓰지 않는다. 이 미션 전용 Machine인지 확인하고 15단계의 키 값을 점검한다.

**완료 기준:** 표의 소유자·그룹·권한이 맞고, `agent-test`는 upload 파일을 만들고 지울 수 있지만 키는 읽지 못한다.

### 10.1 agent-app 배치

**실행 위치: Ubuntu 관리자 터미널 · 저장소 최상위 폴더**

계정/그룹과 디렉터리 권한 설정이 끝난 뒤 앱 바이너리를 운영 위치로 복사한다. `/tmp`는 재부팅하면 지워질 수 있는 임시 작업 공간이고, `unzip -o`는 이미 같은 파일이 있으면 질문 없이 덮어쓴다는 뜻이다.

아래 블록은 `if`부터 `fi`까지 한 번에 붙여 넣는다. `uname -m`이 지원 목록과 다르면 복사하지 않고 중단 메시지를 출력한다.

```bash
unzip -o agent-app.zip -d /tmp/agent-app-extract
export AGENT_HOME=/home/agent-admin/agent-app
ARCH="$(uname -m)"
APP_SOURCE=""

if [ "$ARCH" = "x86_64" ]; then
  APP_SOURCE=/tmp/agent-app-extract/agent-app-linux-x86
elif [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
  APP_SOURCE=/tmp/agent-app-extract/agent-app-linux-arm64
else
  echo "[ERROR] 지원하지 않는 아키텍처: $ARCH"
fi

if [ -n "$APP_SOURCE" ]; then
  if sudo cp "$APP_SOURCE" "$AGENT_HOME/agent-app" \
    && sudo chown agent-admin:agent-core "$AGENT_HOME/agent-app" \
    && sudo chmod 750 "$AGENT_HOME/agent-app"; then
    echo "[OK] 앱 배치 완료: $APP_SOURCE"
  else
    echo "[FAIL] 앱 복사 또는 권한 설정에 실패했습니다."
  fi
else
  echo "[중단] 앱을 복사하지 않았습니다."
fi
```

`chown`은 소유자와 그룹을 정하고, `chmod 750`은 소유자 `rwx`, 그룹 `r-x`, 기타 사용자 `---`로 제한한다.

배치 후 바이너리 아키텍처와 권한을 확인한다. 현재 로그인한 일반 계정은 `/home/agent-admin`을 직접 탐색하지 못할 수 있으므로 `sudo`로 증빙을 수집한다. `test -x`는 성공해도 출력이 없으므로 확인 문구를 붙인다.

```bash
sudo file "$AGENT_HOME/agent-app"
sudo ls -l "$AGENT_HOME/agent-app"
sudo -u agent-admin test -x "$AGENT_HOME/agent-app" \
  && echo "[OK] agent-admin이 앱을 실행할 수 있습니다." \
  || echo "[FAIL] 앱 경로와 권한을 확인하세요."
```

정상 기준:

- `file` 결과에 `ELF 64-bit`가 보인다.
- x86_64 Machine은 `x86-64`, ARM64 Machine은 `ARM aarch64`가 보인다.
- `ls -l` 결과가 `-rwxr-x--- ... agent-admin agent-core ... agent-app` 형태다.
- 마지막 줄에 `[OK] agent-admin이 앱을 실행할 수 있습니다.`가 보인다.

`./agent-app` 실행 시 다음 오류가 발생하면 Ubuntu 아키텍처와 다른 바이너리를 복사한 것이다.

```text
[qemu-arm64]: Could not open '/lib/ld-linux-aarch64.so.1': No such file or directory
```

예를 들어 `uname -m`이 `x86_64`인데 위 오류가 발생하면 ARM64 파일이 복사된 상태일 가능성이 높다. 이 경우 저장소 최상위 폴더로 이동한 뒤 x86 파일로 다시 복사한다.

```bash
test -f README.md && test -f agent-app.zip && echo "[OK] 저장소 최상위 폴더"
```

`[OK]`가 확인됐을 때만 다음 블록을 실행한다.

```bash
unzip -o agent-app.zip -d /tmp/agent-app-extract
export AGENT_HOME=/home/agent-admin/agent-app

if sudo cp /tmp/agent-app-extract/agent-app-linux-x86 "$AGENT_HOME/agent-app" \
  && sudo chown agent-admin:agent-core "$AGENT_HOME/agent-app" \
  && sudo chmod 750 "$AGENT_HOME/agent-app"; then
  sudo file "$AGENT_HOME/agent-app"
  echo "[OK] x86_64 앱으로 교체했습니다."
else
  echo "[FAIL] x86_64 앱 교체에 실패했습니다."
fi
```

추가 오류 해결:

- `cp: cannot stat ...`: ZIP 압축 해제 또는 아키텍처별 파일 선택이 잘못됐다. `ls -l /tmp/agent-app-extract`를 확인한다.
- `Operation not permitted` 또는 `Permission denied`: 복사와 소유권 변경 명령에 `sudo`가 있는지 확인한다.
- `Exec format error`: `uname -m`과 `file "$AGENT_HOME/agent-app"`의 아키텍처가 서로 다르다.

**완료 기준:** 앱 파일의 아키텍처가 Machine과 같고, 소유자·그룹·권한이 `agent-admin:agent-core`, `750`이다.

## 11. SSH 20022 설정

**실행 위치: Ubuntu 관리자 터미널**

> **접속 중단 주의:** SSH 설정을 잘못 적용하면 원격 접속이 끊길 수 있다. 현재 터미널을 닫지 말고, macOS에서 `orb -m <Machine 이름>`으로 들어갈 수 있는 두 번째 Ubuntu 터미널을 먼저 열어 둔다. `sshd -t` 문법 검사가 성공하기 전에는 SSH 서비스를 재시작하지 않는다.

SSH는 서버에 원격으로 들어오는 통로다. 기본 포트 `22`를 `20022`로 바꾸면 무작위 기본 포트 스캔 노출을 줄일 수 있지만, 비밀번호·키 인증을 대신하는 보안 수단은 아니다. Root 원격 로그인을 함께 막아 권한이 가장 큰 계정에 직접 로그인하는 경로를 없앤다.

### 11.1 현재 상태와 백업 확인

현재 설정과 서비스 상태를 먼저 확인한다.

```bash
sudo grep -RInE '^[[:space:]]*(Port|PermitRootLogin)[[:space:]]+' \
  /etc/ssh/sshd_config /etc/ssh/sshd_config.d 2>/dev/null || true
sudo ss -ltnp | grep ssh || true
sudo systemctl status ssh --no-pager
sudo ufw status verbose
```

`grep` 결과가 없는 것은 모든 값이 기본값 또는 주석 상태라는 뜻일 수 있다. `|| true`는 검색 결과가 없을 때 다음 확인을 계속하기 위한 처리다.

재실행할 때도 이전 백업을 덮어쓰지 않도록 현재 시각을 파일명에 넣는다.

```bash
SSH_BACKUP="/etc/ssh/sshd_config.bak.$(date +%Y%m%d-%H%M%S)"
if sudo cp -a /etc/ssh/sshd_config "$SSH_BACKUP" \
  && sudo test -f "$SSH_BACKUP"; then
  echo "[OK] 백업 파일: $SSH_BACKUP"
else
  echo "[FAIL] SSH 설정을 편집하지 말고 백업 오류를 먼저 해결하세요."
  SSH_BACKUP=""
fi
```

### 11.2 설정 파일 편집

위에서 `[OK] 백업 파일`이 확인됐을 때만 편집한다.

```bash
sudo nano /etc/ssh/sshd_config
```

`nano`에서 `Ctrl+W`로 `Port`와 `PermitRootLogin`을 각각 찾는다. `#`은 주석이므로 설정으로 적용되지 않는다. 기존 활성 줄을 수정하거나 새 줄을 추가해, 활성 설정이 다음 값이 되게 한다.

```text
Port 20022
PermitRootLogin no
```

저장은 `Ctrl+O`를 누르고 Enter, 종료는 `Ctrl+X`다. 화면 아래의 `^O`에서 `^`는 Ctrl 키를 뜻한다.

편집 후 중복되거나 다른 파일에서 충돌하는 설정이 없는지 확인한다.

```bash
sudo grep -RInE '^[[:space:]]*(Port|PermitRootLogin)[[:space:]]+' \
  /etc/ssh/sshd_config /etc/ssh/sshd_config.d 2>/dev/null
```

여러 줄이 나오거나 값이 서로 다르면 재시작하지 않는다. 출력된 파일을 열어 활성 설정을 하나의 정책으로 정리한다.

### 11.3 문법과 실제 적용값 검사

일부 환경에서는 `/run/sshd`가 없어 검사가 실패할 수 있으므로 디렉터리를 먼저 준비한다. `sshd -t`는 설정 문법만 검사하며, 성공하면 아무 출력도 하지 않는다.

```bash
if sudo install -d -m 0755 -o root -g root /run/sshd \
  && sudo sshd -t; then
  echo "[OK] sshd 문법 검사"
  sudo sshd -T | grep -E '^(port|permitrootlogin)'
else
  echo "[FAIL] sshd 설정 오류: 서비스를 재시작하지 마세요."
fi
```

정상 결과:

```text
[OK] sshd 문법 검사
port 20022
permitrootlogin no
```

문법 오류나 다른 적용값이 나오면 아래 서비스 변경 명령을 실행하지 않는다. 같은 터미널에서 방금 만든 백업을 복원한다.

```bash
if sudo cp -a "$SSH_BACKUP" /etc/ssh/sshd_config \
  && sudo sshd -t; then
  echo "[OK] SSH 백업 복원과 문법 검사"
else
  echo "[FAIL] 백업 경로와 오류 메시지를 확인하세요."
fi
```

새 터미널이라 `$SSH_BACKUP` 값이 비어 있다면 `ls -1t /etc/ssh/sshd_config.bak.* | head -n 3`으로 백업 목록을 확인하고, 복원할 **정확한 파일 경로**를 `sudo cp -a <백업파일> /etc/ssh/sshd_config`에 넣는다.

### 11.4 문법 검사 성공 후 서비스 적용

Ubuntu 24.04에서는 `ssh.socket`이 22번 포트를 대신 열 수 있다. 미션 포트가 설정 파일대로 적용되게 socket 활성화를 끄고 `ssh.service`를 사용한다.

UFW가 이미 활성 상태라면 서비스를 바꾸기 전에 새 SSH 포트를 먼저 임시 허용한다. UFW가 inactive면 바로 서비스 적용 조건을 통과한다. 선허용에 실패하면 22번 리스너를 끄지 않도록 한 블록 안에서 성공 여부를 연결한다.

```bash
SSH_SWITCH_READY=false
UFW_STATUS=""

if ! UFW_STATUS="$(sudo ufw status)"; then
  echo "[FAIL] UFW 상태를 읽지 못해 SSH 서비스를 전환하지 않습니다."
elif printf '%s\n' "$UFW_STATUS" | grep -q '^Status: active'; then
  if sudo ufw allow 20022/tcp; then
    echo "[OK] 활성 UFW에 20022/tcp를 먼저 허용했습니다."
    SSH_SWITCH_READY=true
  else
    echo "[FAIL] 20022/tcp 선허용 실패: SSH 서비스를 전환하지 않습니다."
  fi
elif printf '%s\n' "$UFW_STATUS" | grep -q '^Status: inactive'; then
  echo "[INFO] UFW가 아직 비활성이므로 임시 규칙을 추가하지 않습니다."
  SSH_SWITCH_READY=true
else
  echo "[FAIL] 알 수 없는 UFW 상태라 SSH 서비스를 전환하지 않습니다."
fi

if [ "$SSH_SWITCH_READY" = true ]; then
  if sudo systemctl disable --now ssh.socket \
    && sudo systemctl enable ssh.service \
    && sudo systemctl restart ssh.service; then
    echo "[OK] ssh.service를 적용했습니다."
  else
    echo "[FAIL] SSH 서비스 전환 실패: 현재 터미널을 닫지 마세요."
  fi
else
  echo "[중단] UFW의 20022/tcp 허용 문제를 먼저 해결하세요."
fi
```

`[FAIL]` 또는 `[중단]`이 보이면 현재 터미널을 닫지 않고 11.1단계의 상태를 다시 확인한다. 서비스 전환 중 실패했다면 OrbStack의 두 번째 Ubuntu 터미널에서 백업을 복원한 뒤 서비스를 다시 시작한다.

### 11.5 적용 결과 확인

```bash
sudo sshd -T | grep -E '^(port|permitrootlogin)'
sudo grep -E '^(Port|PermitRootLogin)' /etc/ssh/sshd_config
sudo ss -ltnp | grep ':20022'
sudo systemctl is-active ssh.service
systemctl is-active ssh.socket || true
```

정상 기준:

- 적용값은 `port 20022`, `permitrootlogin no`다.
- `ss` 결과에 `0.0.0.0:20022` 또는 `[::]:20022`와 `sshd`가 보인다.
- `ssh.service`는 `active`다.
- `ssh.socket`은 `inactive` 또는 `failed`로 보일 수 있으며, 이 구성에서는 비활성 상태가 정상이다.

기존 터미널을 닫기 전에 **복구 가능한 두 번째 접속을 반드시 확인**한다.

- 현재 터미널을 `orb -m ...`으로 열었다면 macOS의 새 탭에서 같은 Machine에 `orb -m ...`으로 한 번 더 들어간다. 이 접속은 SSH와 별도 통로라 복구 콘솔로 쓸 수 있다.
- 현재 서버에 SSH로 접속 중이라면 새 터미널에서 같은 사용자와 서버 주소에 포트 `20022`를 지정해 실제 로그인까지 성공해야 한다.

서버 쪽 사용자와 IP 후보는 다음으로 확인한다.

```bash
whoami
hostname -I
```

**실행 위치: 새 macOS 또는 SSH 클라이언트 터미널**

아래 두 따옴표 안을 방금 확인한 실제 사용자와 IP로 바꾼 뒤 실행한다.

```bash
SSH_USER="내 Ubuntu 사용자"
SSH_HOST="내 Machine IP"
ssh -p 20022 "${SSH_USER}@${SSH_HOST}"
```

두 번째 접속이 열리지 않으면 13단계 UFW를 적용하거나 기존 터미널을 닫지 않는다.

오류 해결:

- `sshd: no hostkeys available`: `sudo ssh-keygen -A`로 서버 host key를 준비한 뒤 `sudo sshd -t`를 다시 실행한다.
- `Address already in use`: `sudo ss -ltnp | grep ':20022'`로 이미 포트를 쓰는 프로세스를 확인한다.
- 적용값이 계속 `port 22`: `/etc/ssh/sshd_config.d`의 활성 `Port` 설정과 `ssh.socket` 상태를 다시 확인한다.
- 재시작 뒤 서비스 실패: `sudo journalctl -u ssh.service -n 50 --no-pager`에서 첫 오류를 확인하고 백업을 복원한다.

**완료 기준:** `sshd -T`의 두 값이 정확하고, `sshd`가 TCP `20022`에서 LISTEN하며, 두 번째 OrbStack 콘솔 또는 새 `20022` SSH 접속이 실제로 열린다.

## 12. Root 원격 접속 차단 증빙 재확인

**실행 위치: Ubuntu 관리자 터미널**

Root는 시스템의 모든 권한을 가진 계정이다. Root 원격 로그인을 막으면 공격자가 먼저 일반 계정으로 인증한 뒤 별도로 권한을 올려야 하므로, 직접적인 최고 권한 로그인 경로와 무차별 대입 공격 표면을 줄일 수 있다.

설정 파일의 작성값과 sshd가 실제로 해석한 값을 함께 확인한다.

```bash
sudo grep -E '^PermitRootLogin[[:space:]]+' /etc/ssh/sshd_config
sudo sshd -T | grep '^permitrootlogin '
```

둘 다 다음 의미의 값이어야 한다.

```text
PermitRootLogin no
permitrootlogin no
```

파일의 대문자·소문자 표시는 달라도 되지만 실제 적용값은 반드시 `no`여야 한다. `prohibit-password`는 Root의 비밀번호 로그인을 막아도 키 로그인을 허용하므로 이 미션의 `no`와 같지 않다.

**완료 기준:** `sudo sshd -T` 결과가 `permitrootlogin no`다.

## 13. UFW 방화벽 설정

**실행 위치: Ubuntu 관리자 터미널 · 저장소 최상위 폴더**

UFW는 서버로 들어오는 네트워크 연결을 거르는 도구다. 기본은 모두 차단하고 SSH `20022/tcp`와 앱 `15034/tcp`만 허용한다.

> **규칙 초기화 주의:** `--apply`를 붙이면 기존 UFW 규칙을 모두 지운 뒤 미션 규칙만 만든다. 다른 서비스를 운영하는 서버에서는 실행하지 말고 이 미션 전용 OrbStack Machine에서만 실행한다.

먼저 SSH가 새 포트에서 실제로 기다리고 있는지 확인한다. 아무 출력도 없으면 UFW를 적용하지 말고 11단계로 돌아간다.

```bash
sudo ss -ltnp | grep ':20022'
```

11.5단계의 두 번째 OrbStack 콘솔 또는 새 SSH 접속도 계속 열 수 있어야 한다. 복구 접속을 확인하지 못했다면 `--apply`를 실행하지 않는다.

현재 터미널과 OrbStack 복구용 터미널을 유지한 채, 실제 변경 없이 적용 계획만 확인한다.

```bash
sudo bash scripts/setup-firewall-ufw.sh
```

드라이런(dry run)에는 다음 네 가지가 보여야 한다.

```text
Default incoming: deny
Default outgoing: allow
Allow: 20022/tcp
Allow: 15034/tcp
```

`Dry run only`는 오류가 아니라 아직 변경하지 않았다는 뜻이다. 계획이 정확할 때만 실제 적용한다.

```bash
sudo bash -e scripts/setup-firewall-ufw.sh --apply
```

`bash -e`는 reset, 기본 정책, 두 허용 규칙 중 하나라도 실패하면 다음 단계로 진행하지 않고 즉시 멈추게 한다. 특히 `20022/tcp` 허용 실패 뒤 UFW가 활성화되는 상황을 막기 위한 안전장치다.

적용 직후 규칙을 검증한다.

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

IPv6가 활성화된 환경에서는 `(v6)`가 붙은 같은 두 규칙도 함께 보일 수 있다. 이는 새로운 포트를 더 연 것이 아니라 IPv6용 동일 정책이므로 정상이다. `22/tcp` 또는 다른 `ALLOW` 포트가 보이면 완료가 아니다.

오류 해결:

- `Status: inactive`: `--apply` 없이 드라이런만 했는지 확인하고, 안전 조건을 다시 확인한 뒤 적용한다.
- 적용 중 SSH 연결 문제: 기존 창을 닫지 말고 OrbStack 콘솔로 접속한다. 필요하면 `sudo ufw disable`로 방화벽을 임시 비활성화한 뒤 SSH 설정과 규칙을 다시 점검한다.
- `problem running iptables`: `sudo ufw status verbose`와 `sudo journalctl -n 50 --no-pager`를 확인한다. Docker 컨테이너가 아닌 OrbStack Ubuntu Machine인지도 확인한다.
- 예상하지 못한 허용 규칙: 이 스크립트를 다시 실행하면 규칙을 초기화한다. 미션 전용 Machine이 맞는지 확인한 뒤에만 `--apply`를 재실행한다.

**완료 기준:** UFW가 `active`이고 허용 포트는 `20022/tcp`, `15034/tcp`와 각각의 선택적 v6 규칙뿐이다.

## 14. 환경 변수 설정

환경 변수는 긴 경로와 포트를 이름으로 저장해 앱과 스크립트가 같은 설정을 사용하게 한다. `export`를 터미널에서 한 번만 실행하면 그 셸을 닫을 때 사라지므로, `agent-admin`의 `~/.profile`에 저장한다.

### 14.1 agent-admin 로그인 셸로 전환

**실행 위치: Ubuntu 관리자 터미널**

```bash
sudo -iu agent-admin
whoami
```

기대 결과는 `agent-admin`이다. 이제부터 `exit` 전까지는 **Ubuntu agent-admin 터미널**이다.

### 14.2 중복 없이 환경 변수 저장

아래 `sed`는 이전 실습에서 같은 변수로 시작하는 줄만 지우고, 이어지는 다섯 줄을 한 번씩 다시 저장한다. 따라서 재실행해도 같은 설정이 계속 중복되지 않는다.

```bash
sed -i \
  -e '/^export AGENT_HOME=/d' \
  -e '/^export AGENT_PORT=/d' \
  -e '/^export AGENT_UPLOAD_DIR=/d' \
  -e '/^export AGENT_KEY_PATH=/d' \
  -e '/^export AGENT_LOG_DIR=/d' \
  "$HOME/.profile"

cat >> "$HOME/.profile" <<'EOF'
export AGENT_HOME=/home/agent-admin/agent-app
export AGENT_PORT=15034
export AGENT_UPLOAD_DIR=$AGENT_HOME/upload_files
export AGENT_KEY_PATH=$AGENT_HOME/api_keys/t_secret.key
export AGENT_LOG_DIR=/var/log/agent-app
EOF

source ~/.profile
```

`cat` 명령 뒤에 `>` 모양의 프롬프트만 계속 보이면 셸이 끝 표시를 기다리는 중이다. `EOF`를 **앞뒤 공백 없이 단독 줄**로 입력한다. 잘못 붙여 넣었다면 `Ctrl+C`로 취소한 뒤 블록 전체를 다시 실행한다.

### 14.3 제공 앱과 미션 문서의 경로 차이

여기에는 반드시 증빙에 남겨야 할 예외가 있다.

| 기준 | 기대하는 `AGENT_KEY_PATH` |
|---|---|
| 미션 원문 | `$AGENT_HOME/api_keys/t_secret.key` 파일 전체 경로 |
| 실제 제공 바이너리 Boot Sequence | `$AGENT_HOME/api_keys` 디렉터리 경로 |

제공 바이너리는 파일 전체 경로를 그대로 전달하면 2단계에서 `Key Path Mismatch`로 실패한다. 두 기준을 모두 증빙하기 위해 다음처럼 구분한다.

- `~/.profile`에는 미션 원문대로 `t_secret.key` **파일 경로**를 영구 저장한다.
- 16단계에서 제공 앱을 실행하는 한 명령에만 `AGENT_KEY_PATH="$AGENT_HOME/api_keys"`를 임시 전달한다.
- 키 디렉터리에는 앱용 `secret.key`와 미션 확인용 `t_secret.key`를 모두 둔다.

명령 앞에 `변수=값 명령`을 붙이면 그 명령과 자식 프로세스에서만 값이 바뀌며, `~/.profile`의 원래 값은 바뀌지 않는다. 이 호환 처리와 이유를 자신의 검증 기록에도 적는다.

### 14.4 값 확인 후 관리자 셸로 복귀

**실행 위치: Ubuntu agent-admin 터미널**

```bash
printf 'AGENT_HOME=%s\n' "$AGENT_HOME"
printf 'AGENT_PORT=%s\n' "$AGENT_PORT"
printf 'AGENT_UPLOAD_DIR=%s\n' "$AGENT_UPLOAD_DIR"
printf 'AGENT_KEY_PATH=%s\n' "$AGENT_KEY_PATH"
printf 'AGENT_LOG_DIR=%s\n' "$AGENT_LOG_DIR"
cat "$AGENT_KEY_PATH"
cat "$AGENT_HOME/api_keys/secret.key"
exit
```

정상 결과:

```text
AGENT_HOME=/home/agent-admin/agent-app
AGENT_PORT=15034
AGENT_UPLOAD_DIR=/home/agent-admin/agent-app/upload_files
AGENT_KEY_PATH=/home/agent-admin/agent-app/api_keys/t_secret.key
AGENT_LOG_DIR=/var/log/agent-app
agent_api_key_test
agent_api_key_test
```

`exit` 뒤에는 원래 Ubuntu 관리자 계정으로 돌아온다. `whoami`로 확인한다. 이후 `sudo cp`, `systemctl`, `ufw`, `cron` 명령은 관리자 터미널에서 실행한다.

오류 해결:

- 값이 빈 줄: `source ~/.profile`을 다시 실행하고 `grep '^export AGENT_' ~/.profile`로 저장 여부를 확인한다.
- `agent-admin is not in the sudoers file`: 아직 `agent-admin` 셸에서 시스템 설정 명령을 실행한 것이다. `exit`로 관리자 셸에 돌아간다.
- 새 로그인에서 값이 없음: `sudo -iu agent-admin`으로 로그인 셸을 열었는지 확인한다. 단순 `sudo -u agent-admin bash`는 프로필을 읽지 않을 수 있다.

**완료 기준:** 다섯 값이 위 경로와 일치하고 `exit` 후 관리자 계정으로 돌아온다.

## 15. 키 파일 검증 및 복구

**실행 위치: Ubuntu 관리자 터미널**

10단계의 `scripts/setup-dirs.sh`가 두 키 파일을 생성한다. `agent_api_key_test`는 미션에서 지정한 테스트 문자열이며 실제 비밀 키가 아니다. 실제 서비스 키나 개인 토큰은 저장소에 커밋하지 않는다.

경로:

```text
/home/agent-admin/agent-app/api_keys/secret.key
/home/agent-admin/agent-app/api_keys/t_secret.key
```

내용:

```text
agent_api_key_test
```

검증:

```bash
sudo -u agent-admin cat /home/agent-admin/agent-app/api_keys/secret.key
sudo -u agent-admin cat /home/agent-admin/agent-app/api_keys/t_secret.key
sudo ls -l /home/agent-admin/agent-app/api_keys/secret.key
sudo ls -l /home/agent-admin/agent-app/api_keys/t_secret.key
```

정상 기준:

- 두 파일 내용이 모두 `agent_api_key_test` 한 줄이다.
- 두 파일은 `agent-admin:agent-core` 소유이고 권한은 `640`, 즉 `-rw-r-----`다.
- `agent-test`는 10단계의 접근 차단 검사처럼 읽을 수 없다.

`./agent-app`만 실행해 다음 오류가 나오면 미션용 파일 경로가 제공 바이너리에 그대로 전달된 상태다.

```text
[2/5] Verifying Environment Variables     [FAIL]
   >>> Key Path Mismatch. Expected: /home/agent-admin/agent-app/api_keys
```

복구:

`~/.profile`은 바꾸지 않는다. Ubuntu agent-admin 터미널에서 디렉터리 경로를 해당 앱 실행에만 임시 전달한다.

```bash
whoami
printf '영구 미션 값: %s\n' "$AGENT_KEY_PATH"
AGENT_KEY_PATH="$AGENT_HOME/api_keys" ./agent-app
```

앱을 `Ctrl+C`로 종료한 뒤 `echo "$AGENT_KEY_PATH"`를 실행하면 다시 `.../t_secret.key` 파일 경로가 보인다.

`./agent-app` 실행 중 다음 오류가 나오면 앱이 요구하는 `secret.key`가 없는 상태다.

```text
[3/5] Checking Required Files             [FAIL]
   >>> Missing File: secret.key
   >>>    (Expected location: /home/agent-admin/agent-app/api_keys/secret.key)
```

복구:

먼저 현재 계정을 확인한다.

```bash
whoami
```

결과가 `agent-admin`이면 `exit`를 한 번 실행해 Ubuntu 관리자 셸로 돌아간다. 이미 관리자 계정이면 `exit`하지 않는다.

```bash
if [ "$(whoami)" = "agent-admin" ]; then
  echo "[INFO] agent-admin 셸을 나가 관리자 셸로 돌아갑니다."
  exit
else
  echo "[INFO] 이미 관리자 계정이므로 현재 셸을 유지합니다."
fi
```

**실행 위치: Ubuntu 관리자 터미널**

```bash
whoami
sudo install -o agent-admin -g agent-core -m 0640 /dev/null /home/agent-admin/agent-app/api_keys/secret.key
printf '%s\n' 'agent_api_key_test' | sudo tee /home/agent-admin/agent-app/api_keys/secret.key >/dev/null
sudo chown agent-admin:agent-core /home/agent-admin/agent-app/api_keys/secret.key
sudo chmod 640 /home/agent-admin/agent-app/api_keys/secret.key
sudo -u agent-admin cat /home/agent-admin/agent-app/api_keys/secret.key
```

핵심은 키 생성 명령을 sudo 가능한 Ubuntu 관리자 계정에서 실행하는 것이다.

**완료 기준:** 두 키 파일의 내용·소유자·그룹·권한이 정상 기준과 일치한다.

## 16. agent-app 실행

이 단계부터 Ubuntu 터미널을 두 개 사용한다.

- **Ubuntu 앱 터미널:** `agent-admin`으로 앱을 실행한 채 유지한다.
- **Ubuntu 관리자 터미널:** 저장소 최상위 폴더에서 포트, monitor, logrotate, cron을 검증한다.

**실행 위치: Ubuntu 앱 터미널**

앱은 피해 범위를 줄이기 위해 root 실행을 금지한다. `agent-admin` 로그인 셸로 전환하고 계정과 환경 변수를 한 번 더 확인한다.

```bash
sudo -iu agent-admin
whoami
env | grep '^AGENT_' | sort
cd "$AGENT_HOME"
AGENT_KEY_PATH="$AGENT_HOME/api_keys" ./agent-app
```

`Agent READY`가 나온 뒤 프롬프트가 돌아오지 않는 것이 정상이다. 앱이 포그라운드에서 실행 중이라는 뜻이다. 이 터미널에 다음 단계 명령을 입력하지 않고 그대로 둔다.

- 명령 앞의 임시 `AGENT_KEY_PATH`는 제공 바이너리 호환용이다. 프로필의 미션용 파일 경로는 변경하지 않는다.
- 앱을 의도적으로 종료할 때만 `Ctrl+C`를 누른다.
- 앱 터미널을 닫거나 `Ctrl+C`를 누르면 프로세스와 포트가 사라져 monitor와 cron이 실패한다.
- 이후 앱 파일을 다시 복사해야 한다면 먼저 `Ctrl+C`로 앱을 중지한다. 실행 중인 바이너리를 교체하면 `Text file busy`가 날 수 있다.
- monitor와 cron 검증이 끝날 때까지 앱을 유지한다.

## 17. Boot Sequence 확인

**확인 위치: Ubuntu 앱 터미널**

앱 터미널에서 다음 5단계가 모두 `[OK]`이고 마지막에 `Agent READY`가 보여야 한다.

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

한 단계라도 `[FAIL]`이면 18단계나 monitor로 넘어가지 않는다.

| 실패 단계 | 쉬운 뜻 | 먼저 확인할 것 |
|---|---|---|
| `[1/5] User Account` | 실행 계정이 잘못됨 | 앱 터미널에서 `whoami`가 `agent-admin`인지 확인 |
| `[2/5] Environment Variables` | 경로·포트 값이 없거나 다름 | `env \| grep '^AGENT_'`, 특히 14단계의 Key Path 예외 |
| `[3/5] Required Files` | 키 파일이 없거나 내용이 다름 | `ls -l "$AGENT_HOME/api_keys"`, 두 키 파일 내용 |
| `[4/5] Port Availability` | 15034를 다른 프로세스가 사용함 | 관리자 터미널에서 `sudo ss -ltnp \| grep ':15034'` |
| `[5/5] Log Permission` | agent-admin이 로그 폴더에 쓸 수 없음 | 관리자 터미널에서 `sudo -u agent-admin test -w /var/log/agent-app` |

대표 오류:

- `Running as 'root' is forbidden`: 먼저 앱 명령이 끝난 현재 셸에서 `whoami`를 확인한다. `sudo ./agent-app` 한 명령만 잘못 실행했다면 현재 셸은 이미 일반 관리자이므로 `exit`하지 않는다. 실제 root 셸에 들어가 있을 때만 아래 조건문이 root 셸을 한 단계 빠져나온다.
- `GLIBC_... not found`: 관리자 터미널에서 `cat /etc/os-release`, `ldd --version`, `sudo file "$AGENT_HOME/agent-app"`를 비교한다.
- `Permission denied`로 앱 자체가 실행 안 됨: 10.1단계의 소유자·그룹·`750`과 `sudo -u agent-admin test -x /home/agent-admin/agent-app/agent-app` 결과를 확인한다.
- 바로 프롬프트로 돌아옴: 화면의 첫 `[FAIL]` 또는 오류 문장을 기록하고 해당 단계부터 해결한다.

```bash
if [ "$(whoami)" = "root" ]; then
  echo "[INFO] 실제 root 셸을 나갑니다."
  exit
else
  echo "[INFO] 현재 일반 관리자 셸을 유지합니다."
fi
```

일반 관리자 셸로 돌아온 뒤 16단계의 `sudo -iu agent-admin`과 임시 Key Path가 포함된 앱 실행 명령을 다시 따른다.

**완료 기준:** 5단계가 모두 `[OK]`, 마지막 줄이 `Agent READY`이고 앱이 종료되지 않은 채 실행 중이다.

## 18. 15034 LISTEN 확인

**실행 위치: Ubuntu 관리자 터미널**

앱 터미널은 그대로 둔 채 다른 터미널에서 확인한다. 프로세스가 있다는 것은 프로그램이 실행 중이라는 뜻이고, LISTEN 포트가 있다는 것은 네트워크 요청을 받을 준비까지 됐다는 뜻이다. 둘 다 확인해야 한다.

```bash
ps -ef | grep '[a]gent-app'
sudo ss -ltnp | grep ':15034'
curl -v --max-time 3 http://localhost:15034
```

기대 결과:

```text
0.0.0.0:15034 LISTEN
curl 출력에 Connected to localhost 또는 Connected to 127.0.0.1 표시
```

제공 앱은 HTTP 응답 본문을 즉시 반환하지 않을 수 있다. 이 경우 `curl`이 `Connected to localhost`를 출력한 뒤 `Operation timed out`으로 끝나고 종료 코드 `28`을 반환할 수 있다. 여기서는 `ss`의 TCP LISTEN과 `curl`의 `Connected` 줄이 함께 보이면 **포트 연결 증빙은 성공**이다. HTTP 응답 본문이 없는 점은 별도로 기록한다.

오류 해결:

- `ps` 결과 없음: 앱 터미널이 닫혔거나 Boot Sequence에서 종료됐다. 16단계부터 다시 실행한다.
- `ps`는 있지만 `ss` 결과 없음: 앱 터미널의 4단계 이후 오류와 `sudo journalctl -n 50 --no-pager`를 확인한다.
- `curl: (7) Failed to connect`: `ss` 결과의 주소와 포트가 `15034`인지, 앱이 계속 실행 중인지 확인한다.
- `curl: (28) Operation timed out`: 먼저 `Connected`가 있었는지 확인한다. 있었다면 이 제공 앱의 알려진 응답 특성일 수 있다.

**완료 기준:** 앱 프로세스, TCP `0.0.0.0:15034` LISTEN, curl 연결이 모두 확인되고 앱 터미널이 계속 실행 중이다.

## 19. monitor.sh 실행

**실행 위치: Ubuntu 관리자 터미널 · 저장소 최상위 폴더**

`monitor.sh`는 두 가지를 구분한다.

- **Health Check:** 앱 프로세스나 TCP 포트가 없으면 서비스를 사용할 수 없으므로 `exit 1`로 실패한다.
- **Warning Check:** 방화벽이나 자원 사용률은 조사가 필요하지만 앱 상태 기록은 계속할 가치가 있으므로 경고만 남긴다.

먼저 저장소 원본의 Bash 문법을 검사한다. 성공하면 출력이 없으므로 확인 문구를 붙인다.

```bash
bash -n bin/monitor.sh && echo "[OK] 저장소 monitor.sh 문법"
```

그다음 운영 위치로 복사하고 요구된 소유자·그룹·권한을 적용한다.

```bash
export AGENT_HOME=/home/agent-admin/agent-app
if sudo cp bin/monitor.sh "$AGENT_HOME/bin/monitor.sh" \
  && sudo chown agent-dev:agent-core "$AGENT_HOME/bin/monitor.sh" \
  && sudo chmod 750 "$AGENT_HOME/bin/monitor.sh"; then
  echo "[OK] 최신 monitor.sh를 운영 위치에 배치했습니다."
else
  echo "[FAIL] monitor.sh 복사 또는 권한 설정에 실패했습니다."
fi
```

운영 위치 파일은 `agent-dev:agent-core`, `750`이라 일반 관리자 계정이 직접 읽지 못할 수 있다. 실제 실행자인 `agent-admin` 권한으로 문법과 실행 가능 여부를 확인한다.

```bash
sudo ls -l "$AGENT_HOME/bin/monitor.sh"
sudo -u agent-admin bash -n "$AGENT_HOME/bin/monitor.sh" \
  && echo "[OK] 운영 monitor.sh 문법과 읽기 권한"
sudo -u agent-admin "$AGENT_HOME/bin/monitor.sh"
echo "monitor.sh 종료 코드: $?"
```

정상 실행 예시:

```text
====== SYSTEM MONITOR RESULT ======

[HEALTH CHECK]
Checking agent process... [OK] (PID: 1234)
Checking port 15034... [OK]
[INFO] Firewall status: UFW active

[RESOURCE MONITORING]
CPU Usage : 2.3%
MEM Usage : 0.1%
DISK Used : 37%

[INFO] Log appended: /var/log/agent-app/monitor.log
monitor.sh 종료 코드: 0
```

PID와 자원 숫자는 실행할 때마다 달라도 된다.

`monitor.sh` 동작:

- 앱 프로세스 미실행 시 `exit 1`
- TCP `15034` 포트가 LISTEN 상태가 아니면 `exit 1`
- 방화벽 비활성은 `[WARNING]`만 출력
- CPU `> 20%`면 `[WARNING]`
- MEM `> 10%`면 `[WARNING]`
- DISK_USED `> 80%`면 `[WARNING]`
- `/var/log/agent-app/monitor.log`에 `>>`로 누적

값을 수집하는 방법:

- `ps` 전체 실행 인자와 `awk`를 함께 사용해 앱이 상대 경로, 절대 경로, 아키텍처별 이름 중 어느 방식으로 실행돼도 PID를 찾는다.
- `ss`는 현재 Linux의 소켓과 LISTEN 포트를 직접 보여 주므로 `netstat`보다 우선 사용한다.
- `ps -p PID -o pcpu= -o pmem=`으로 **앱 프로세스의** CPU와 메모리 비율을 읽는다.
- `df -P /`의 사용률 열에서 `%`를 제거해 루트 파티션의 디스크 사용률을 읽는다.
- Bash는 소수 비교가 불편하므로 `awk`로 `20.0` 같은 임계값과 비교한다.

소유자는 `agent-dev`지만 실행자는 `agent-admin`인 이유는 작성·변경 역할과 운영 실행 역할을 나누기 위해서다. 두 계정이 모두 `agent-core`이고 권한이 `750`이므로 개발자는 수정하고 관리자는 그룹 실행 권한으로 실행할 수 있다. `agent-test`와 기타 사용자는 실행할 수 없다.

오류 해결:

- `Agent process is not running`: 앱 터미널이 살아 있는지 확인하고 16단계부터 다시 실행한다.
- `TCP port 15034 is not LISTEN`: `sudo ss -ltnp | grep ':15034'`와 앱의 Boot Sequence를 확인한다.
- `Permission denied`로 문법 검사 실패: 일반 `bash -n` 대신 위의 `sudo -u agent-admin bash -n "$AGENT_HOME/bin/monitor.sh"` 형태인지 확인한다.
- `Log directory is not writable`: `sudo ls -ld /var/log/agent-app`, `id agent-admin`, `sudo -u agent-admin test -w /var/log/agent-app`를 확인한다.
- 기존 `monitor.log` 때문에 append 실패: `sudo ls -l /var/log/agent-app/monitor.log`로 소유자를 확인한다. 미션 파일이 맞다면 `sudo chown agent-admin:agent-core /var/log/agent-app/monitor.log`와 `sudo chmod 640 /var/log/agent-app/monitor.log`로 정책을 복구한다.
- `[WARNING]`만 있고 마지막 로그 append와 종료 코드 `0`이 보임: Health Check는 통과했다. 경고 원인을 조사하되 로그 수집은 성공한 상태다.

**완료 기준:** 프로세스·포트가 `[OK]`, 종료 코드가 `0`, 운영 파일이 `agent-dev:agent-core`와 `750`이다.

## 20. monitor.log 확인

**실행 위치: Ubuntu 관리자 터미널**

실행 전후 줄 수를 비교하면 로그가 덮어쓰기되지 않고 한 줄씩 늘어나는지 쉽게 확인할 수 있다. 앱 터미널을 계속 유지한 상태에서 실행한다.

```bash
sudo wc -l /var/log/agent-app/monitor.log
sudo -u agent-admin /home/agent-admin/agent-app/bin/monitor.sh
sudo wc -l /var/log/agent-app/monitor.log
sudo tail -n 5 /var/log/agent-app/monitor.log
```

두 번째 `wc -l`의 숫자가 첫 번째보다 1 커야 한다.

로그 포맷:

```text
[YYYY-MM-DD HH:MM:SS] PID:... CPU:..% MEM:..% DISK_USED:..%
```

예:

```text
[2026-07-21 14:10:00] PID:1234 CPU:2.3% MEM:0.1% DISK_USED:37%
```

시간, 필드명, 순서를 고정하면 사람이 시간순으로 읽기 쉽고 `report.sh`가 각 값을 안정적으로 찾을 수 있다.

`>`와 `>>`의 차이:

- `>`는 기존 파일을 덮어쓴다.
- `>>`는 기존 파일 뒤에 누적한다.
- 관제 로그는 시간순 기록이 중요하므로 `>>`를 사용한다.

오류 해결:

- `monitor.log: No such file or directory`: monitor가 성공한 적이 없다. 19단계의 마지막 오류를 확인한다.
- 줄 수가 늘지 않음: monitor의 종료 코드와 `/var/log/agent-app/monitor.log` 파일 쓰기 권한을 확인한다.
- 기존 내용이 사라짐: 운영 위치의 `monitor.sh`가 최신 저장소 파일인지 다시 복사하고, 로그 기록 부분이 `>>`인지 확인한다.

**완료 기준:** 직접 실행할 때마다 지정 형식의 새 줄이 정확히 하나씩 뒤에 추가된다.

## 21. logrotate 설정

**실행 위치: Ubuntu 관리자 터미널 · 저장소 최상위 폴더**

cron을 등록하기 전에 logrotate를 먼저 설정한다. 관제 스크립트 안에 회전 로직을 직접 넣는 대신 Linux 표준 도구를 선택하면 관제 로직과 로그 보존 정책을 분리해 관리하고, `missingok`, 압축, 보존 개수 같은 기능을 검증된 방식으로 사용할 수 있다.

```bash
sudo bash scripts/setup-logrotate.sh
```

검증:

```bash
sudo cat /etc/logrotate.d/agent-app-monitor
sudo logrotate -d /etc/logrotate.d/agent-app-monitor
systemctl list-timers --all | grep logrotate || true
```

정책:

```text
su agent-admin agent-core
size 10M
rotate 10
missingok
notifempty
copytruncate
compress
delaycompress
create 0640 agent-admin agent-core
```

정책의 쉬운 의미:

- `size 10M`: **logrotate가 실행되는 시점에** 현재 로그가 10MB 이상이면 회전 대상으로 본다. 파일 크기를 매 순간 10MB 이하로 강제하는 기능은 아니다.
- `rotate 10`: 현재 `monitor.log`와 별도로 이전 회전본을 최대 10개 보관한다.
- `compress`, `delaycompress`: 오래된 회전본을 압축하되 가장 최근 회전본은 다음 회전까지 압축을 미룬다.
- `copytruncate`: 현재 내용을 회전본에 복사하고 원본을 비워, monitor가 같은 경로에 계속 쓸 수 있게 한다.
- `missingok`, `notifempty`: 로그가 없거나 비어 있어도 설치 직후 오류로 처리하지 않는다.
- `su agent-admin agent-core`: 그룹 쓰기 가능한 로그 디렉터리에서 지정 계정·그룹으로 안전하게 회전한다.
- `create 0640 agent-admin agent-core`: 회전 뒤 새 로그가 필요할 때 소유자·그룹·권한을 같은 정책으로 맞춘다.

`logrotate -d`는 설정을 읽고 계획만 보여 주는 드라이런이다. 로그를 실제로 회전하지 않는 것이 정상이다. Ubuntu의 `logrotate.timer` 또는 주기 실행 시점에 크기를 검사한다.

이 미션의 필수 용량 정책은 `monitor.log` 대상이다. `cron.log`도 계속 쌓일 수 있으므로 실제 운영으로 확장할 때는 별도 회전 정책을 추가해야 한다.

오류 해결:

- `logrotate: command not found`: `sudo apt install -y logrotate`
- `parent directory has insecure permissions`: 설정에 `su agent-admin agent-core`가 있는지 확인하고 설치 스크립트를 다시 실행한다.
- `error: ... bad rotation count`: `/etc/logrotate.d/agent-app-monitor` 내용이 위 정책과 같은지 확인한다.
- 강제 회전 `-f`는 파일 상태를 실제로 바꾸므로 제출용 전용 Machine에서만 의도적으로 테스트한다.

**완료 기준:** 설정 파일이 존재하고 드라이런에 문법 오류가 없으며 `size 10M`, `rotate 10`, `su agent-admin agent-core`가 보인다.

## 22. cron 등록

**실행 위치: Ubuntu 관리자 터미널 · 저장소 최상위 폴더**

cron은 정해진 시각에 명령을 실행하는 예약 기능이다. 등록 전에 앱과 monitor 직접 실행이 정상인지 확인한다. 앱이 꺼진 상태에서 cron만 등록하면 매분 Health Check가 실패한다.

```bash
ps -ef | grep '[a]gent-app'
sudo -u agent-admin /home/agent-admin/agent-app/bin/monitor.sh
```

cron 서비스를 지금 시작하고 재부팅 후에도 자동 시작되게 한 뒤, `agent-admin`의 crontab에 등록한다.

```bash
sudo systemctl enable --now cron
sudo systemctl status cron --no-pager
sudo bash scripts/install-cron.sh
```

등록 내용:

```cron
* * * * * /home/agent-admin/agent-app/bin/monitor.sh >> /var/log/agent-app/cron.log 2>&1
```

각 부분의 의미:

- `* * * * *`: 분, 시, 일, 월, 요일을 모두 `*`로 두어 매분 실행한다.
- 절대 경로: cron은 현재 작업 폴더를 보장하지 않으므로 `/home/...` 전체 경로를 쓴다.
- `>> cron.log`: 일반 출력(stdout)을 기존 내용 뒤에 누적한다.
- `2>&1`: 오류 출력(stderr)도 같은 로그로 보낸다.
- 실행 계정은 root가 아니라 `agent-admin`이다.

cron은 대화형 셸처럼 `~/.profile`을 항상 읽지 않는다. 그래서 `monitor.sh`는 핵심 변수에 기본값을 갖고 있다. 시스템 명령 검색 경로도 더 짧을 수 있으므로, cron에서만 UFW를 찾지 못한다는 경고가 나면 다음을 실행해 `agent-admin` crontab 맨 위에 PATH 한 줄을 추가한다.

```bash
sudo crontab -u agent-admin -e
```

편집기에 다음 줄을 기존 monitor 작업보다 위에 넣는다.

```cron
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
```

처음 편집기를 고르라는 화면이 나오면 `nano`를 선택해도 된다. 저장은 `Ctrl+O`, Enter, 종료는 `Ctrl+X`다. 최종 등록 내용을 확인한다.

```bash
sudo crontab -u agent-admin -l
```

`install-cron.sh`를 다시 실행해도 같은 monitor 항목을 중복 등록하지 않는다.

**완료 기준:** cron 서비스가 `active`이고 `agent-admin` crontab에 monitor 명령이 정확히 한 줄 있다.

## 23. cron 자동 실행 확인

**실행 위치: Ubuntu 관리자 터미널**

cron은 등록 버튼을 누른 시점부터 60초를 세는 것이 아니라 시계의 다음 분 경계에서 실행한다. `sleep 70`은 이를 한 번 넘기기 위해 70초 기다리는 명령이며, 기다리는 동안 출력이 없는 것이 정상이다. 앱 터미널을 닫지 않는다.

```bash
echo "[BEFORE]"
sudo wc -l /var/log/agent-app/monitor.log

echo "최대 70초 기다립니다..."
sleep 70

echo "[AFTER]"
sudo wc -l /var/log/agent-app/monitor.log
sudo tail -n 10 /var/log/agent-app/monitor.log
sudo tail -n 10 /var/log/agent-app/cron.log
```

기대 결과:

```text
1분 뒤 monitor.log 줄 수 증가
```

`AFTER`의 줄 수가 `BEFORE`보다 최소 1 커야 한다. Machine이 잠자기 상태였거나 분 경계와 겹쳤다면 한 번 더 기다릴 수 있다.

줄 수가 늘지 않으면 다음 순서로 확인한다.

```bash
sudo systemctl is-active cron
sudo crontab -u agent-admin -l
sudo tail -n 20 /var/log/agent-app/cron.log
ps -ef | grep '[a]gent-app'
sudo ss -ltnp | grep ':15034'
sudo ls -l /home/agent-admin/agent-app/bin/monitor.sh
sudo ls -ld /var/log/agent-app
```

- `cron.log`가 아직 없음: cron이 한 번도 실행되지 않았거나 출력 파일을 만들 권한이 없다. 한 분 더 기다린 뒤 디렉터리 권한을 확인한다.
- `Agent process is not running`: 앱 터미널을 다시 실행한다.
- `TCP port 15034 is not LISTEN`: 앱 Boot Sequence와 포트를 다시 확인한다.
- `Permission denied`: monitor 파일 `750`, `agent-dev:agent-core`, 로그 폴더의 `agent-core` 쓰기 권한을 확인한다.
- cron에서만 방화벽 경고: 22단계의 PATH 줄을 확인한다. 이 경고 자체는 Health Check 실패가 아니므로 monitor 로그는 계속 남을 수 있다.

**완료 기준:** crontab 등록을 바꾸거나 직접 monitor를 실행하지 않았는데 1분 뒤 `monitor.log` 줄 수가 증가한다.

## 24. 보너스 report.sh 실행

이 단계는 보너스다. `report.sh`는 고정된 monitor 로그 형식을 읽어 샘플 수와 CPU, MEM, DISK_USED의 평균·최대·최소를 계산한다.

**실행 위치: Ubuntu 관리자 터미널 · 저장소 최상위 폴더**

저장소 원본 문법을 검사한 뒤 운영 위치로 복사한다.

```bash
bash -n bin/report.sh && echo "[OK] 저장소 report.sh 문법"
export AGENT_HOME=/home/agent-admin/agent-app
if sudo cp bin/report.sh "$AGENT_HOME/bin/report.sh" \
  && sudo chown agent-dev:agent-core "$AGENT_HOME/bin/report.sh" \
  && sudo chmod 750 "$AGENT_HOME/bin/report.sh"; then
  echo "[OK] 최신 report.sh를 운영 위치에 배치했습니다."
else
  echo "[FAIL] report.sh 복사 또는 권한 설정에 실패했습니다."
fi
```

운영 위치 파일은 실제 실행자 권한으로 검사하고 실행한다.

```bash
sudo ls -l "$AGENT_HOME/bin/report.sh"
sudo -u agent-admin bash -n "$AGENT_HOME/bin/report.sh" \
  && echo "[OK] 운영 report.sh 문법과 읽기 권한"
sudo -u agent-admin "$AGENT_HOME/bin/report.sh"
```

출력 예시:

```text
====== STATISTICS REPORT ======
Log File    : /var/log/agent-app/monitor.log
From        : (not set)
To          : (not set)
Samples     : 5
Parse Skip  : 0

[CPU]
Average     : 2.30%
Maximum     : 4.10% at 2026-07-21 14:04:00
Minimum     : 1.20% at 2026-07-21 14:01:00

[MEM]
Average     : 0.10%
Maximum     : 0.20% at 2026-07-21 14:04:00
Minimum     : 0.10% at 2026-07-21 14:01:00

[DISK_USED]
Average     : 37.00%
Maximum     : 37.00% at 2026-07-21 14:01:00
Minimum     : 37.00% at 2026-07-21 14:01:00
```

숫자와 시간은 실제 로그에 따라 달라진다.

계산 방식:

- 한 줄에서 `CPU:`, `MEM:`, `DISK_USED:` 값을 찾아 `%`를 제거한다.
- 분석 가능한 줄마다 합계와 샘플 수를 늘리고 최소·최대값과 그 시각을 갱신한다.
- 평균은 `합계 ÷ 정상 샘플 수`다.
- 형식이 깨진 줄은 `[WARNING] Skipping unparsable line`으로 알리고 통계에서 제외한다.
- 정상 샘플이 0개면 0으로 나누지 않고 오류로 안전하게 종료한다.

시간 구간 분석 전에 최근 로그의 실제 시각을 확인한다.

```bash
sudo tail -n 10 /var/log/agent-app/monitor.log
```

최근 10분을 자동으로 범위로 잡는 예:

```bash
sudo -u agent-admin "$AGENT_HOME/bin/report.sh" \
  --from "$(date -d '10 minutes ago' '+%F %T')" \
  --to "$(date '+%F %T')"
```

오류 해결:

- `Log file does not exist`: monitor를 먼저 정상 실행해 `/var/log/agent-app/monitor.log`를 만든다.
- `Log file is empty`: monitor 로그가 한 줄 이상 생긴 뒤 다시 실행한다.
- `Skipping unparsable line`: 해당 줄의 필드명·순서·숫자 형식을 확인한다. 나머지 정상 줄은 계속 분석한다.
- `No analyzable monitor samples found`: 지정 시간 안에 샘플이 없거나 모든 줄의 형식이 잘못됐다. `tail`의 실제 시각으로 범위를 바꾼다.
- 시간 인자를 직접 넣을 때는 `"YYYY-MM-DD HH:MM:SS"` 전체를 큰따옴표로 묶는다.

**완료 기준:** 파일이 `agent-dev:agent-core`, `750`이고 샘플 수와 세 지표의 평균·최대·최소가 출력된다.

## 25. 보너스 archive-old-logs.sh 실행

이 단계는 보너스이며 압축 파일 생성과 30일 경과 아카이브 삭제를 포함한다. 먼저 시스템 로그가 아닌 `/tmp`에서 정책을 안전하게 연습한다.

### 25.1 `/tmp`에서 안전하게 동작 확인

**실행 위치: Ubuntu 관리자 터미널 · 저장소 최상위 폴더**

```bash
bash -n scripts/archive-old-logs.sh
DEMO_ROOT=/tmp/agent-archive-demo
mkdir -p "$DEMO_ROOT/logs" "$DEMO_ROOT/archive"

printf '%s\n' 'old monitor sample' > "$DEMO_ROOT/logs/old.log"
touch -d '8 days ago' "$DEMO_ROOT/logs/old.log"

printf '%s\n' 'expired archive sample' | gzip > "$DEMO_ROOT/archive/expired.log.gz"
touch -d '31 days ago' "$DEMO_ROOT/archive/expired.log.gz"

AGENT_LOG_DIR="$DEMO_ROOT/logs" \
ARCHIVE_DIR="$DEMO_ROOT/archive" \
bash scripts/archive-old-logs.sh

find "$DEMO_ROOT" -maxdepth 3 -type f -ls
```

정상이라면 8일 된 `old.log`의 `.gz`가 archive에 생기고, 31일 된 `expired.log.gz`는 삭제됐다는 INFO 메시지가 나온다.

```text
[INFO] Archive directory checked: /tmp/agent-archive-demo/archive
[INFO] Compressed: /tmp/agent-archive-demo/logs/old.log.<실행시각>.gz
[INFO] Moved to archive: /tmp/agent-archive-demo/archive/old.log.<실행시각>.gz
[INFO] Deleted old archive: /tmp/agent-archive-demo/archive/expired.log.gz
[INFO] Archive cleanup completed
```

마지막 `find` 결과에는 보존된 원본 `logs/old.log`와 새 `archive/old.log.<실행시각>.gz`가 보여야 하고, `expired.log.gz`는 보이지 않아야 한다. `<실행시각>`은 실제 14자리 숫자로 표시된다.

### 25.2 실제 미션 경로 실행

**실행 위치: Ubuntu 관리자 터미널 · 저장소 최상위 폴더**

문법과 `/tmp` 테스트가 성공했을 때만 실제 경로에서 실행한다.

```bash
sudo bash scripts/archive-old-logs.sh
sudo find /var/log/monitor/agent-app/archive -type f -name "*.gz" -ls
```

정책:

- `/var/log/agent-app/*.log` 중 7일 이상 경과 파일 압축
- 압축 파일을 `/var/log/monitor/agent-app/archive/`로 이동
- archive의 `.gz` 중 30일 이상 경과 파일 삭제
- 대상 없음, 권한 부족, 디렉터리 없음, gzip 실패를 메시지로 처리

대상이 없을 때 다음 메시지는 오류가 아니라 할 일이 없다는 정상 안내다.

```text
[INFO] No old log files found for compression
[INFO] No old archive files found for deletion
[INFO] Archive cleanup completed
```

현재 구현은 `gzip -c`로 압축본을 만들고 원본 `.log`는 보존한다. 데이터 손실을 피하는 대신 같은 오래된 원본에 대해 다시 실행하면 시각이 다른 압축본이 또 생길 수 있다. 주기 자동화로 확장할 때는 성공한 원본의 삭제·이름 변경·처리 완료 표시 중 하나를 설계해야 한다.

오류 해결:

- `Cannot create archive directory`: 실제 경로는 `/var/log` 아래이므로 sudo 권한을 확인한다.
- `Skipping due to insufficient permission`: 원본 로그 읽기와 로그 폴더 쓰기 권한을 확인한다.
- `gzip failed` 또는 `Move failed`: 디스크 여유 공간과 두 디렉터리의 권한을 확인한다.
- `find: Permission denied`: 실제 아카이브 확인에는 위처럼 `sudo find`를 사용한다.

**완료 기준:** `/tmp` 테스트에서 7일 압축·이동과 30일 삭제가 재현되고, 실제 실행은 대상 유무와 관계없이 명확한 INFO/WARNING 메시지로 끝난다.

## 26. 전체 검증 체크리스트

최종 검증 명령은 [검증 명령 모음](docs/verification-log.md)과 [전체 검증 체크리스트](docs/13-전체-검증-체크리스트.md)를 따른다.

### 26.1 저장소에서 할 수 있는 정적 검증

정적 검증은 파일 존재와 Bash 문법을 확인할 뿐, Ubuntu 계정·SSH·UFW·앱·cron이 실제로 동작한다는 증빙은 아니다.

**실행 위치: macOS 또는 Ubuntu 관리자 터미널 · 저장소 최상위 폴더**

```bash
pwd
ls -la
find README.md bin scripts docs -type f | sort
bash -n scripts/setup-users.sh
bash -n scripts/setup-dirs.sh
bash -n scripts/setup-firewall-ufw.sh
bash -n scripts/setup-logrotate.sh
bash -n scripts/install-cron.sh
bash -n scripts/archive-old-logs.sh
bash -n bin/monitor.sh
bash -n bin/report.sh
git diff --check
git status
```

모든 `bash -n`이 아무 출력 없이 끝나고 `git diff --check`에도 오류가 없으면 정적 검증은 통과다.

### 26.2 Ubuntu에서 반드시 별도로 남길 실행 증빙

다음 항목은 자신의 Machine에서 실제 출력과 실행 날짜를 남겨야 한다.

- `sshd -T`와 `ss`의 `20022`, `PermitRootLogin no`
- UFW active와 허용 규칙
- 세 계정과 두 그룹
- 디렉터리 권한, upload 성공, 키 접근 차단
- Boot Sequence 5단계와 `Agent READY`
- TCP `15034` LISTEN과 curl 연결
- monitor 직접 실행, 종료 코드, 누적 로그
- cron 등록 전후 줄 수 증가
- logrotate 설정과 드라이런
- 보너스 report 통계와 archive `/tmp` 재현

출력을 붙일 때 비밀번호, 개인 토큰, 실제 API 키, 사설 정보는 가린다. 현재 [명령 기록](docs/command-log.md)의 `TODO`를 자신의 결과로 교체하고 [요구사항 체크리스트](docs/requirements-checklist.md)의 상태를 그때 갱신한다.

## 27. 트러블슈팅

자세한 내용은 [트러블슈팅 보고서](docs/troubleshooting.md)와 [단계별 트러블슈팅](docs/14-트러블슈팅.md)에 정리했다. 오류가 나면 증상만 보고 바로 설정을 바꾸지 말고, 아래 순서로 범위를 좁힌다.

대표 사례:

| 문제 | 확인 명령 | 해결 방향 |
|---|---|---|
| root로 앱 실행 실패 | `whoami` | `sudo -iu agent-admin` |
| 저장소 파일 없음 | `pwd`, `ls -la` | `README.md`가 있는 저장소 최상위로 이동 |
| 환경 변수 없음 | `env \| grep '^AGENT_'` | `source ~/.profile`, 로그인 셸 확인 |
| 프로세스 없음 | `ps -ef \| grep '[a]gent-app'` | 앱 터미널과 첫 Boot 실패 확인 |
| 15034 포트 없음 | `sudo ss -ltnp \| grep ':15034'` | 앱 Boot Sequence 4단계 확인 |
| cron 실패 | `sudo tail /var/log/agent-app/cron.log` | 앱, 절대 경로, 권한, PATH 순으로 확인 |
| monitor.log 권한 오류 | `ls -ld`, `ls -l`, `id agent-admin` | 디렉터리와 기존 로그 파일 모두 확인 |
| 리소스 수집 실패 | `ps -p <PID> -o %cpu=,%mem=`, `df -P /` | 최신 `monitor.sh`를 운영 위치로 다시 복사 |
| `[qemu-arm64]` 실행 오류 | `uname -m`, `file $AGENT_HOME/agent-app` | Ubuntu 아키텍처에 맞는 앱 바이너리로 다시 복사 |
| GLIBC 오류 | `ldd --version` | Ubuntu 24.04 VM에서 glibc와 바이너리 호환성 확인 |

### 27.1 프로세스는 있는데 포트가 없을 때

다음 순서로 확인하면 원인을 빠르게 좁힐 수 있다.

1. `ps -ef | grep '[a]gent-app'`으로 실제 앱 PID와 실행 명령을 확인한다.
2. 앱 터미널에 `Agent READY` 이후 오류가 있는지 확인한다.
3. `sudo ss -ltnp | grep ':15034'`로 다른 주소·포트에 열렸는지 확인한다.
4. `env | grep '^AGENT_'`에서 `AGENT_PORT=15034`인지 확인한다.
5. `sudo ss -ltnp`로 다른 프로세스가 15034를 선점했는지 확인한다.
6. 키·로그 권한 실패로 앱이 초기화 중 멈췄는지 Boot Sequence를 다시 본다.

프로세스 존재만으로 서비스 정상이라고 판단하지 않는 이유가 바로 이 경우 때문이다.

### 27.2 로그가 갑자기 급증할 때

- **단기 대응:** `df -P /`, `du -h /var/log/agent-app/*`, `tail`로 디스크 여유와 급증 파일·반복 오류를 먼저 확인한다. 앱과 보안 증빙을 보존한 채 불필요한 디버그 출력의 원인을 멈춘다.
- **중기 개선:** logrotate 실행 주기와 보존 개수 조정, `cron.log` 별도 회전, 반복 경고 억제, 임계값·수집 주기 재검토, 디스크 사용률 경보를 적용한다.
- 원인을 확인하지 않고 `/var/log` 전체를 삭제하면 장애 증거와 다른 서비스 로그까지 잃을 수 있으므로 실행하지 않는다.

## 28. 동료 평가 대비 질문답변

자세한 답변은 [동료 평가 대비 질문과 답변](docs/15-동료평가-대비-질문답변.md)에 있다. 최소한 아래 내용은 자신의 말로 설명할 수 있어야 한다.

| 질문 | 답변 핵심 |
|---|---|
| SSH 포트 변경과 Root 차단은 왜 필요한가? | 기본 포트 자동 스캔 노출을 줄이고 최고 권한 계정의 직접 인증 경로를 없앤다. 포트 변경만으로 인증 보안을 대신할 수는 없다. |
| 왜 두 포트만 허용하는가? | 필요한 서비스만 외부에 노출하는 최소 허용 정책으로 공격 표면을 줄인다. |
| 왜 common과 core를 나누는가? | upload는 세 역할이 협업하지만 키·로그는 운영 역할만 접근하게 최소 권한을 적용한다. |
| 왜 프로세스와 포트를 모두 보는가? | 프로세스가 살아 있어도 초기화 실패나 포트 충돌로 요청을 못 받을 수 있다. |
| 왜 `ps + awk`와 `ss`를 쓰는가? | 전체 실행 인자에서 다양한 앱 이름을 찾고, 커널의 현재 LISTEN 소켓을 직접 확인하기 쉽다. |
| CPU/MEM/DISK는 어떻게 구하는가? | PID 기준 `ps`에서 CPU·MEM, `df -P /`에서 루트 파티션 사용률을 읽고 `%`를 제거한다. |
| 왜 로그 포맷을 고정하는가? | 시간순 비교와 `awk` 자동 파싱이 가능하고, 필드가 빠진 깨진 줄을 구분하기 쉽다. |
| 왜 소유자와 실행자가 다른가? | `agent-dev`가 코드를 관리하고 `agent-admin`이 운영 실행하며 `agent-core` 그룹 실행 권한으로 연결한다. |
| 왜 일부는 `exit 1`, 일부는 WARNING인가? | 프로세스·포트 부재는 서비스 불능이지만, 자원 순간 상승은 기록을 계속하며 조사할 수 있는 상태다. |
| 왜 `>>`인가? | `>`는 과거 기록을 지우지만 `>>`는 기존 로그 뒤에 새 기록을 보존한다. |
| 왜 logrotate인가? | 관제 코드와 보존 정책을 분리하고 크기, 압축, 보존 개수를 표준 도구로 관리하기 쉽다. |
| cron에서 왜 직접 실행과 다를 수 있는가? | 작업 폴더, PATH, 프로필 환경 변수가 대화형 로그인 셸보다 제한적이기 때문이다. |
| Nginx를 관제한다면 무엇을 바꾸는가? | 프로세스 패턴을 `nginx`, 포트를 `80/443`, 로그 경로를 Nginx 로그로 바꾸고 서비스 특성에 맞춰 임계값을 다시 정한다. |
| 프로세스는 있는데 포트가 없으면? | Boot 로그 → 실제 환경 변수 → 포트 선점 → 권한·키 초기화 실패 순으로 확인한다. |
| 로그가 급증하면? | 단기에는 용량·급증 원인을 확인하고, 중기에는 회전 주기·보존·수집 주기·경보를 개선한다. |
| 7일 압축·30일 삭제는 왜 필요한가? | 최근 원본은 빠르게 보고, 오래된 기록은 공간을 줄여 보존하며, 무기한 누적으로 디스크가 차는 것을 막는다. |

## 29. Git 커밋 이력 관리 방법

커밋은 “지금 무엇을 바꿨는지” 확인한 뒤 관련 파일만 선택한다. 과거 예시 명령을 그대로 실행해 다른 사람이나 이전 작업의 변경까지 한꺼번에 올리지 않는다.

**실행 위치: macOS 또는 Ubuntu 관리자 터미널 · 저장소 최상위 폴더**

```bash
git status
git diff -- README.md
git diff --check
git add README.md
git diff --cached
git commit -m "docs: improve beginner system monitor guide"
git log --oneline --graph --all --decorate -n 20
```

`git diff --cached`에서 의도하지 않은 파일이나 민감 정보가 보이면 커밋하지 말고 먼저 staging 범위를 점검한다.

기능 단위 커밋 메시지 예:

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
- `/var/log`와 `/etc` 변경은 자신의 미션 전용 Ubuntu Machine에서만 실행한다.
- macOS에서는 `useradd`, `ufw`, `systemctl`, `crontab` 실습을 직접 실행하지 않는다.

## 부록: 증빙 작성 위치

- 실제 명령 기록: [docs/command-log.md](docs/command-log.md)
- 검증 명령 모음: [docs/verification-log.md](docs/verification-log.md)
- 요구사항 체크: [docs/requirements-checklist.md](docs/requirements-checklist.md)
- 보안 설명: [docs/security-notes.md](docs/security-notes.md)
- 문제 해결 기록: [docs/troubleshooting.md](docs/troubleshooting.md)

Linux 명령과 용어가 낯설면 다음 입문 자료를 먼저 읽어도 된다.

- [Linux 기초 자료 목차](docs/linux-basics/README.md)
- [기초 명령어](docs/linux-basics/01-commands.md)
- [기초 용어](docs/linux-basics/02-terms.md)
- [핵심 개념](docs/linux-basics/03-concepts.md)
- [Bash 셸 단계별 따라하기](docs/linux-basics/shell-training/README.md)
