# Linux 운영 개념 정리

## macOS와 Ubuntu 역할 분리

B1-1에서는 macOS를 작업 호스트로 사용하고, Linux 실습은 OrbStack Ubuntu 24.04 VM `codyssey-b1-1-ubuntu24`에서 수행한다.

- macOS: VS Code, Git, 문서 작성, 브라우저 검증
- Ubuntu: 사용자/그룹, 권한, SSH, 방화벽, cron, 로그 실습

`useradd`, `ufw`, `systemctl`, `crontab` 같은 Linux 전용 명령은 macOS에서 바로 실행하지 않는다.

## 최소 권한 원칙

사용자에게 필요한 만큼만 권한을 주는 보안 원칙이다.

B1-1 예시는 다음과 같다.

- `agent-test`는 `agent-common`에는 포함한다.
- `agent-test`는 `agent-core`에는 포함하지 않는다.
- API 키와 로그 디렉터리는 `agent-core`만 접근하게 한다.

이렇게 하면 테스트 계정이 민감 파일을 읽는 위험을 줄일 수 있다.

## 역할 기반 접근 제어

사용자 개인마다 권한을 따로 주는 대신 역할에 맞는 그룹을 만들고, 그룹 단위로 권한을 부여하는 방식이다.

B1-1의 역할 구분:

| 역할 | 계정 | 그룹 |
|---|---|---|
| 운영자 | `agent-admin` | `agent-common`, `agent-core` |
| 개발자 | `agent-dev` | `agent-common`, `agent-core` |
| 테스트 | `agent-test` | `agent-common` |

## 멱등성

같은 작업을 여러 번 실행해도 최종 결과가 같은 성질이다.

예:

```bash
sudo groupadd -f agent-common
getent passwd agent-admin >/dev/null 2>&1 || sudo useradd -m -s /bin/bash agent-admin
```

- 그룹이 이미 있으면 다시 만들지 않는다.
- 사용자가 이미 있으면 다시 만들지 않는다.

실습 중 명령을 다시 실행해도 시스템 상태가 망가지지 않게 하려면 멱등성을 고려한다.

## root로 앱을 실행하지 않는 이유

root는 시스템 전체를 바꿀 수 있는 권한을 가진다.

앱에 버그가 있거나 침해가 발생했을 때 root 권한으로 실행 중이면 피해 범위가 커진다. 그래서 B1-1 앱은 `agent-admin` 같은 일반 계정으로 실행한다.

## 프로세스 확인과 포트 확인을 둘 다 하는 이유

프로세스만 살아 있다고 해서 서비스가 정상이라는 뜻은 아니다.

가능한 상황:

- 프로세스는 있지만 포트가 열리지 않았다.
- 포트는 열렸지만 다른 프로그램이 사용 중이다.
- 앱이 시작 중에 오류를 내고 곧 종료된다.

그래서 `monitor.sh`는 프로세스와 `15034` LISTEN 상태를 둘 다 확인해야 한다.

## Health Check와 Warning Check

Health Check는 서비스가 동작하기 위한 필수 조건을 확인한다.

- 앱 프로세스 없음
- `15034` 포트 LISTEN 아님

이 경우 `exit 1`로 실패 처리한다.

Warning Check는 즉시 실패로 볼 수는 없지만 운영자가 확인해야 하는 상태다.

- 방화벽 비활성
- CPU 임계값 초과
- MEM 임계값 초과
- DISK_USED 임계값 초과

경고는 출력하되 스크립트는 계속 실행한다.

## 로그 append와 overwrite

관제 로그는 시간순 기록이 중요하므로 기존 내용을 유지해야 한다.

```bash
echo "new log" >> monitor.log
```

- `>`: 기존 파일 내용을 덮어쓴다.
- `>>`: 기존 파일 뒤에 내용을 추가한다.

monitor.log는 누적 기록이므로 `>>`를 사용한다.

## cron 환경이 일반 터미널과 다른 이유

cron은 사용자가 직접 로그인한 터미널보다 훨씬 적은 환경 변수로 실행된다.

그래서 직접 실행은 되는데 cron에서는 실패할 수 있다.

대응 방법:

- 스크립트 안에서 기본 환경 변수를 선언한다.
- 명령어는 가능하면 절대 경로를 사용한다.
- stdout/stderr를 `cron.log`에 남긴다.

## 로그 용량 관리가 필요한 이유

monitor.sh가 매분 실행되면 로그가 계속 커진다.

로그가 무한히 커지면 다음 문제가 생긴다.

- 디스크 공간 부족
- 로그 분석 속도 저하
- 오래된 로그와 최신 로그 구분 어려움

그래서 logrotate 또는 아카이브 스크립트로 용량과 보관 기간을 관리한다.

## 증빙을 남기는 이유

B1-1은 결과만 만드는 미션이 아니라 운영 과정을 재현 가능하게 설명하는 미션이다.

README와 docs에는 다음을 남긴다.

- 실행한 명령
- 실제 출력
- 기대 결과와 실제 결과 비교
- 문제 발생 시 원인과 해결 과정

이렇게 정리하면 동료 평가자가 같은 절차로 검증할 수 있다.

## SSH 보안 강화 흐름

SSH 설정은 원격 접속에 직접 영향을 주기 때문에 순서가 중요하다.

안전한 흐름:

1. 현재 접속 상태와 기존 설정을 확인한다.
2. `/etc/ssh/sshd_config`를 백업한다.
3. `Port 20022`, `PermitRootLogin no`를 설정한다.
4. `sshd -t`로 문법을 검사한다.
5. `systemctl restart ssh`로 서비스를 재시작한다.
6. `ss -tulnp`로 `20022` LISTEN 상태를 확인한다.

문법 검사 없이 재시작하면 설정 오류로 SSH 접속이 막힐 수 있다. 원격 서버에서는 새 포트로 접속 가능한지 확인하기 전까지 기존 세션을 닫지 않는 것이 안전하다.

## 방화벽 최소 허용 정책

방화벽은 기본적으로 들어오는 연결을 막고, 필요한 포트만 명시적으로 허용하는 방식이 안전하다.

B1-1 정책:

- inbound 기본 차단
- outbound 기본 허용
- `20022/tcp` 허용
- `15034/tcp` 허용

이 방식은 앱 실행에 필요한 통로만 열어 두므로 공격 표면을 줄일 수 있다. 반대로 전체 포트를 허용하면 실습 중 임시로 띄운 서비스나 불필요한 데몬까지 외부에 노출될 수 있다.

## dry-run과 apply 분리

시스템 설정을 바꾸는 스크립트는 실제 적용 전에 변경 내용을 보여주는 단계가 있으면 안전하다.

`scripts/setup-firewall-ufw.sh`는 기본 실행을 dry-run으로 두고, `--apply`가 있을 때만 실제 UFW 정책을 바꾼다.

이런 구조의 장점:

- 적용 전 열릴 포트를 검토할 수 있다.
- 원격 접속 차단 같은 실수를 줄일 수 있다.
- README 증빙에 "계획"과 "실제 적용 결과"를 나누어 기록할 수 있다.

## 환경 변수 기본값 패턴

Bash에서는 다음 형태로 환경 변수 기본값을 둘 수 있다.

```bash
AGENT_HOME="${AGENT_HOME:-/home/agent-admin/agent-app}"
```

의미:

- 외부에서 `AGENT_HOME`이 설정되어 있으면 그 값을 사용한다.
- 설정되어 있지 않으면 `/home/agent-admin/agent-app`을 사용한다.

이 패턴은 cron처럼 환경 변수가 부족한 실행 환경에서 특히 유용하다. 동시에 테스트할 때는 임시 경로를 환경 변수로 주입할 수 있어 스크립트를 더 재사용하기 쉽다.

## 표준 출력과 표준 에러를 로그에 남기는 이유

cron은 화면을 직접 보여주지 않는다. 자동 실행 중 오류가 나도 사용자가 즉시 볼 수 없다.

그래서 crontab에는 다음처럼 등록한다.

```cron
* * * * * /home/agent-admin/agent-app/bin/monitor.sh >> /var/log/agent-app/cron.log 2>&1
```

- `>>`: 정상 출력을 cron.log 뒤에 누적한다.
- `2>&1`: 오류 출력도 같은 cron.log로 보낸다.

이렇게 해두면 직접 실행은 성공하지만 cron에서는 실패하는 문제를 나중에 추적할 수 있다.

## setgid로 그룹 일관성 유지

공유 디렉터리에서는 새 파일의 그룹이 예상과 다르게 만들어질 수 있다.

예를 들어 `agent-dev`가 `/var/log/agent-app` 아래에 파일을 만들었는데 그룹이 개인 기본 그룹으로 잡히면 `agent-admin`이 읽거나 쓰지 못할 수 있다.

디렉터리에 setgid를 설정하면 새 파일과 하위 디렉터리가 부모 디렉터리의 그룹을 상속한다.

예:

```text
2770
```

앞자리 `2`가 setgid를 의미한다. B1-1에서는 `upload_files`, `api_keys`, `/var/log/agent-app`처럼 그룹 정책이 중요한 디렉터리에 유용하다.

## 상위 디렉터리 통과 권한

하위 디렉터리에 권한이 있어도 상위 디렉터리를 통과할 수 없으면 접근할 수 없다.

예:

```text
/home/agent-admin/agent-app/bin/monitor.sh
```

`agent-core`가 `agent-app/bin`에 접근하려면 `/home/agent-admin`을 통과할 수 있어야 한다. 홈 디렉터리 목록을 보여줄 필요는 없으므로 ACL로 `--x`만 부여하면 최소 권한을 지킬 수 있다.

## logrotate와 아카이브 스크립트 차이

두 방식은 모두 로그 관리에 쓰이지만 목적이 다르다.

| 항목 | 목적 | B1-1에서의 역할 |
|---|---|---|
| logrotate | 현재 로그의 크기와 보관 개수 관리 | `monitor.log` 10MB, 최대 10개 보관 |
| archive-old-logs.sh | 오래된 로그의 장기 보관과 삭제 | 7일 이상 로그 압축, 30일 이상 아카이브 삭제 |

logrotate는 현재 운영 로그가 너무 커지지 않게 하는 데 강하고, 아카이브 스크립트는 기간 기준 보존 정책을 설명하기 좋다.

## copytruncate를 사용하는 이유

로그를 회전할 때 단순히 파일 이름만 바꾸면, 이미 실행 중인 프로세스가 예전 파일 핸들에 계속 쓰는 상황이 생길 수 있다.

`copytruncate`는 현재 로그 내용을 회전 파일로 복사한 뒤 원본 파일을 0바이트로 줄인다.

B1-1에서는 cron이 계속 같은 경로인 `/var/log/agent-app/monitor.log`에 append하므로, 파일 경로를 유지한 채 크기를 줄이는 `copytruncate`가 이해하기 쉽다.

## awk로 파싱과 소수 비교를 처리하는 이유

Bash의 기본 비교는 정수에는 편하지만 `2.3 > 20` 같은 소수 비교에는 약하다.

그래서 `monitor.sh`는 CPU/MEM 사용률 비교에 `awk`를 사용한다.

```bash
awk -v actual="$actual" -v threshold="$threshold" 'BEGIN { exit (actual > threshold) ? 0 : 1 }'
```

또한 monitor.log는 다음처럼 일정한 형식이다.

```text
[YYYY-MM-DD HH:MM:SS] PID:1234 CPU:2.3% MEM:4.1% DISK_USED:37%
```

이런 텍스트는 `awk`가 필드 단위로 순회하며 `CPU:`, `MEM:`, `DISK_USED:` 값을 찾기 좋다.

## 장애 조사 순서

서비스가 정상인지 확인할 때는 증상을 좁혀 가는 순서가 중요하다.

권장 순서:

1. `ps` 또는 `pgrep`으로 앱 프로세스가 있는지 확인한다.
2. `ss -tulnp`로 `15034` 포트가 LISTEN인지 확인한다.
3. `curl http://localhost:15034`로 실제 응답을 확인한다.
4. `tail /var/log/agent-app/monitor.log`로 최근 관제 로그를 확인한다.
5. cron 문제라면 `tail /var/log/agent-app/cron.log`로 자동 실행 오류를 확인한다.
6. 권한 문제라면 `ls -ld`, `id`, `getfacl`로 사용자와 그룹 권한을 확인한다.

프로세스, 포트, HTTP 응답, 로그, 권한을 나누어 보면 원인을 더 빠르게 좁힐 수 있다.

## Ubuntu 버전과 바이너리 호환성

제공 앱은 이미 빌드된 바이너리이므로 실행 환경의 CPU 아키텍처와 라이브러리 버전이 맞아야 한다.

확인 흐름:

1. `uname -a`로 시스템과 CPU 계열을 확인한다.
2. `file agent-app-linux-x86` 또는 `file agent-app-linux-arm64`로 바이너리 아키텍처를 확인한다.
3. `ldd --version`으로 glibc 버전을 확인한다.
4. 실행 중 `GLIBC_2.38 not found`가 나오면 Ubuntu 24.04 이상 환경을 검토한다.

이런 오류는 스크립트 문제가 아니라 실행 파일과 OS 라이브러리의 호환성 문제일 수 있다. 그래서 B1-1에서는 Ubuntu 24.04 Machine을 우선 실습 환경으로 둔다.

## 패키지 설치와 사전 도구 확인

운영 스크립트는 필요한 명령이 설치되어 있다는 전제에서 동작한다.

예를 들어 다음 도구가 없으면 일부 단계가 실패한다.

- `ss`: 포트 확인
- `ufw`: 방화벽 설정
- `logrotate`: 로그 회전
- `crontab`: 자동 실행 등록
- `getfacl`, `setfacl`: ACL 확인과 설정
- `curl`: HTTP 응답 확인

그래서 README의 초기 환경 확인에서는 `command -v`로 명령 존재 여부를 먼저 확인하고, 부족하면 Ubuntu에서 `apt install`로 설치한다.

macOS는 작업 호스트이므로 `apt`, `ufw`, `systemctl` 같은 Linux 전용 명령을 직접 실행하지 않는다.
