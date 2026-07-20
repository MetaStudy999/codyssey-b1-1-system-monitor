# B1-1 실제 명령 및 결과 기록

이 문서는 [README.md](../README.md)를 위에서부터 실행하면서 **자신의 Ubuntu Machine에서 나온 실제 결과**를 남기는 양식이다.

명령은 README의 설명과 안전 조건을 먼저 읽은 뒤 실행한다. 이 문서의 `아직 실행하지 않음` 문장은 실행 후 실제 터미널 출력으로 교체한다.

## 0. 기록 방법

### 0.1 작성 규칙

1. README의 단계 하나를 실행한다.
2. 명령이 끝난 시각과 실행 계정을 적는다.
3. 터미널 출력을 해당 단계의 `실제 출력` 블록에 붙여 넣는다.
4. 완료 기준을 체크한다.
5. 실패했다면 오류를 지우지 말고 `오류 및 조치`에 원문과 해결 과정을 기록한다.
6. 재실행에 성공하면 최초 실패와 최종 성공 결과를 모두 남긴다.

상태는 다음 중 하나로 적는다.

| 상태 | 의미 |
|---|---|
| `미실행` | 아직 실행하지 않음 |
| `성공` | README 완료 기준을 모두 만족함 |
| `실패` | 오류가 해결되지 않음 |
| `재검증 완료` | 실패 원인을 해결하고 다시 실행해 성공함 |
| `해당 없음` | 선택 과제이거나 현재 환경에서 수행하지 않음 |

### 0.2 출력 붙여넣기 원칙

- 명령 프롬프트와 실제 출력을 함께 남겨도 된다.
- 성공 시 출력이 없는 `bash -n`, `sshd -t`, `test`는 바로 뒤의 `echo $?` 또는 `[OK]` 문구까지 남긴다.
- 실제 비밀번호, 개인 토큰, SSH 개인키, 실제 API Key는 붙여 넣지 않는다.
- IP나 사용자 이름을 가려야 한다면 값 전체를 지우지 말고 `<가림>`처럼 가렸음을 표시한다.
- 미션 테스트 문자열 `agent_api_key_test`는 실제 비밀값이 아니므로 미션 증빙에 사용할 수 있다.
- 출력이 길어 일부만 남겼다면 `중간 N줄 생략`이라고 명시한다.

### 0.3 실습 기본 정보

| 항목 | 실제 값 |
|---|---|
| 실습 시작 일시 | 작성 필요 |
| 실습 종료 일시 | 작성 필요 |
| macOS 사용자 | 작성 필요 |
| OrbStack Machine 이름 | 작성 필요 |
| Ubuntu 버전 | 작성 필요 |
| CPU 아키텍처 | 작성 필요 |
| Ubuntu 관리자 계정 | 작성 필요 |
| 저장소 경로 | 작성 필요 |
| Git 브랜치 | 작성 필요 |
| Git 커밋 SHA | 작성 필요 |

### 0.4 전체 진행 현황

| README 단계 | 증빙 항목 | 상태 | 실행 일시 | 오류 기록 번호 |
|---|---|---|---|---|
| 7 | 환경과 필수 명령 | 미실행 | 작성 필요 | 없음 |
| 8 | ZIP 무결성과 앱 파일 | 미실행 | 작성 필요 | 없음 |
| 9 | 계정과 그룹 | 미실행 | 작성 필요 | 없음 |
| 10 | 디렉터리, 권한, ACL | 미실행 | 작성 필요 | 없음 |
| 10.1 | 앱 바이너리 배치 | 미실행 | 작성 필요 | 없음 |
| 11~12 | SSH 20022, Root 차단 | 미실행 | 작성 필요 | 없음 |
| 13 | UFW 최소 허용 정책 | 미실행 | 작성 필요 | 없음 |
| 14~15 | 환경 변수와 키 파일 | 미실행 | 작성 필요 | 없음 |
| 16~18 | Boot Sequence와 15034 | 미실행 | 작성 필요 | 없음 |
| 19~20 | monitor와 누적 로그 | 미실행 | 작성 필요 | 없음 |
| 21 | logrotate | 미실행 | 작성 필요 | 없음 |
| 22~23 | cron 등록과 자동 증가 | 미실행 | 작성 필요 | 없음 |
| 24 | 보너스 report | 미실행 | 작성 필요 | 없음 |
| 25 | 보너스 archive | 미실행 | 작성 필요 | 없음 |
| 26 | 전체 정적 검증 | 미실행 | 작성 필요 | 없음 |

---

## 1. 환경과 저장소 확인

연결 단계: [README 7. 사전 준비](../README.md#7-사전-준비)

### 1.1 macOS와 OrbStack Machine

- 실행 위치: macOS 터미널
- 실행 일시: 작성 필요
- 실행 계정: 작성 필요
- 상태: `미실행`

실행 명령:

```bash
date '+%Y-%m-%d %H:%M:%S %Z'
pwd
git status --short --branch
git rev-parse --show-toplevel
git rev-parse --short HEAD
orb list
```

실제 출력:

```text
아직 실행하지 않음
```

판정:

- [ ] 저장소 최상위 폴더가 확인됐다.
- [ ] 현재 브랜치와 커밋 SHA를 기록했다.
- [ ] 사용할 Ubuntu Machine의 정확한 이름과 상태를 확인했다.

오류 및 조치:

```text
없음
```

### 1.2 Ubuntu 환경과 필수 명령

- 실행 위치: Ubuntu 관리자 터미널 · 저장소 최상위 폴더
- 실행 일시: 작성 필요
- 실행 계정: 작성 필요
- 상태: `미실행`

실행 명령:

```bash
date '+%Y-%m-%d %H:%M:%S %Z'
cat /etc/os-release
uname -m
whoami
id
hostname
pwd

for cmd in unzip ss sshd ufw logrotate crontab getfacl curl file nano gzip ping; do
  if command -v "$cmd" >/dev/null 2>&1; then
    echo "[OK] $cmd"
  else
    echo "[MISSING] $cmd"
  fi
done
```

실제 출력:

```text
아직 실행하지 않음
```

판정:

- [ ] Ubuntu 24.04가 확인됐다.
- [ ] 아키텍처가 `x86_64`, `aarch64`, `arm64` 중 하나다.
- [ ] 현재 계정은 root가 아닌 sudo 가능 관리자다.
- [ ] 필요한 명령이 모두 `[OK]`다.
- [ ] Ubuntu에서 저장소 최상위 폴더를 확인했다.

오류 및 조치:

```text
없음
```

---

## 2. agent-app.zip 확인

연결 단계: [README 8. agent-app.zip 내부 확인](../README.md#8-agent-appzip-내부-확인)

- 실행 위치: Ubuntu 관리자 터미널 · 저장소 최상위 폴더
- 실행 일시: 작성 필요
- 실행 계정: 작성 필요
- 상태: `미실행`

실행 명령:

```bash
ls -lh agent-app.zip
unzip -t agent-app.zip
unzip -l agent-app.zip
uname -m
```

실제 출력:

```text
아직 실행하지 않음
```

선택한 앱 파일:

```text
아직 선택하지 않음
```

판정:

- [ ] `No errors detected in compressed data`가 확인됐다.
- [ ] x86과 ARM64 앱 파일이 모두 보인다.
- [ ] `uname -m`에 맞는 앱 파일을 선택했다.
- [ ] `__MACOSX` 파일은 실행 대상에서 제외했다.

오류 및 조치:

```text
없음
```

---

## 3. 계정과 그룹

연결 단계: [README 9. 계정/그룹 생성](../README.md#9-계정그룹-생성)

- 실행 위치: Ubuntu 관리자 터미널 · 저장소 최상위 폴더
- 실행 일시: 작성 필요
- 실행 계정: 작성 필요
- 상태: `미실행`

### 3.1 생성 스크립트 결과

실행 명령:

```bash
sudo bash scripts/setup-users.sh
```

실제 출력:

```text
아직 실행하지 않음
```

### 3.2 최종 계정과 그룹 검증

실행 명령:

```bash
id agent-admin
id agent-dev
id agent-test
getent group agent-common
getent group agent-core
```

실제 출력:

```text
아직 실행하지 않음
```

판정:

- [ ] `agent-admin`, `agent-dev`, `agent-test`가 존재한다.
- [ ] `agent-common`에는 admin, dev, test가 포함된다.
- [ ] `agent-core`에는 admin, dev만 포함된다.
- [ ] `agent-test`는 `agent-core`에 포함되지 않는다.

오류 및 조치:

```text
없음
```

---

## 4. 디렉터리, 권한, ACL

연결 단계: [README 10. 디렉터리/권한 설정](../README.md#10-디렉터리권한-설정)

- 실행 위치: Ubuntu 관리자 터미널 · 저장소 최상위 폴더
- 실행 일시: 작성 필요
- 실행 계정: 작성 필요
- 상태: `미실행`

### 4.1 설정 결과

실행 명령:

```bash
sudo bash scripts/setup-dirs.sh
export AGENT_HOME=/home/agent-admin/agent-app
sudo setfacl -m g:agent-common:--x /home/agent-admin "$AGENT_HOME"
```

실제 출력:

```text
아직 실행하지 않음
```

### 4.2 소유자, 그룹, 모드, ACL

실행 명령:

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

실제 출력:

```text
아직 실행하지 않음
```

### 4.3 upload 허용과 key 차단

실행 명령:

```bash
if sudo -u agent-test touch "$AGENT_HOME/upload_files/.permission-test" \
  && sudo -u agent-test rm "$AGENT_HOME/upload_files/.permission-test"; then
  echo "[OK] agent-test upload write/delete"
else
  echo "[FAIL] agent-test upload permission"
fi

if ! sudo test -f "$AGENT_HOME/api_keys/t_secret.key"; then
  echo "[FAIL] t_secret.key missing"
elif sudo -u agent-test test -r "$AGENT_HOME/api_keys/t_secret.key"; then
  echo "[FAIL] agent-test can read key"
else
  echo "[OK] agent-test key access denied"
fi
```

실제 출력:

```text
아직 실행하지 않음
```

판정:

- [ ] `$AGENT_HOME`은 `agent-admin:agent-core`, `750`이다.
- [ ] `upload_files`는 `agent-admin:agent-common`, `2770`이다.
- [ ] `api_keys`는 `agent-admin:agent-core`, `2770`이다.
- [ ] `bin`은 `agent-dev:agent-core`, `750`이다.
- [ ] `/var/log/agent-app`은 `agent-admin:agent-core`, `2770`이다.
- [ ] `agent-common:--x` 상위 경로 탐색 ACL이 확인된다.
- [ ] `agent-test`는 upload에 쓰고 지울 수 있다.
- [ ] `agent-test`는 키를 읽을 수 없다.

오류 및 조치:

```text
없음
```

---

## 5. agent-app 바이너리 배치

연결 단계: [README 10.1 agent-app 배치](../README.md#101-agent-app-배치)

- 실행 위치: Ubuntu 관리자 터미널 · 저장소 최상위 폴더
- 실행 일시: 작성 필요
- 실행 계정: 작성 필요
- 상태: `미실행`

배치 실행 결과:

```text
아직 실행하지 않음
```

검증 명령:

```bash
export AGENT_HOME=/home/agent-admin/agent-app
uname -m
sudo file "$AGENT_HOME/agent-app"
sudo ls -l "$AGENT_HOME/agent-app"
sudo -u agent-admin test -x "$AGENT_HOME/agent-app" \
  && echo "[OK] agent-admin executable" \
  || echo "[FAIL] path or permission"
```

실제 출력:

```text
아직 실행하지 않음
```

판정:

- [ ] Machine과 앱 바이너리의 아키텍처가 같다.
- [ ] 앱 파일은 `agent-admin:agent-core`, `750`이다.
- [ ] `agent-admin` 실행 가능 검사가 `[OK]`다.

오류 및 조치:

```text
없음
```

---

## 6. SSH 20022와 Root 원격 접속 차단

연결 단계: [README 11~12. SSH와 Root 차단](../README.md#11-ssh-20022-설정)

- 실행 위치: Ubuntu 관리자 터미널, 별도 복구 터미널
- 실행 일시: 작성 필요
- 실행 계정: 작성 필요
- 상태: `미실행`

### 6.1 백업과 문법 검사

생성한 백업 경로:

```text
아직 실행하지 않음
```

문법 및 적용값 확인 명령:

```bash
sudo sshd -t
echo "sshd syntax exit: $?"
sudo sshd -T | grep -E '^(port|permitrootlogin)'
sudo grep -E '^(Port|PermitRootLogin)' /etc/ssh/sshd_config
```

실제 출력:

```text
아직 실행하지 않음
```

### 6.2 서비스와 LISTEN 상태

실행 명령:

```bash
sudo ss -ltnp | grep ':20022'
sudo systemctl is-active ssh.service
systemctl is-active ssh.socket || true
```

실제 출력:

```text
아직 실행하지 않음
```

### 6.3 두 번째 접속 확인

| 항목 | 실제 결과 |
|---|---|
| 접속 방식 | OrbStack 콘솔 / SSH 중 작성 |
| 접속 사용자 | 작성 필요 |
| 접속 주소와 포트 | 작성 필요 |
| 접속 성공 시각 | 작성 필요 |
| 기존 터미널 유지 여부 | 작성 필요 |

접속 결과:

```text
아직 실행하지 않음
```

판정:

- [ ] `sshd -t` 종료 코드가 `0`이다.
- [ ] 실제 적용값은 `port 20022`다.
- [ ] 실제 적용값은 `permitrootlogin no`다.
- [ ] `sshd`가 TCP `20022`에서 LISTEN한다.
- [ ] `ssh.service`는 active다.
- [ ] 별도 복구 콘솔 또는 새 20022 SSH 접속이 성공했다.

오류 및 복구:

```text
없음
```

---

## 7. UFW 방화벽

연결 단계: [README 13. UFW 방화벽 설정](../README.md#13-ufw-방화벽-설정)

- 실행 위치: Ubuntu 관리자 터미널 · 저장소 최상위 폴더
- 실행 일시: 작성 필요
- 실행 계정: 작성 필요
- 상태: `미실행`

### 7.1 드라이런

실행 명령:

```bash
sudo bash scripts/setup-firewall-ufw.sh
```

실제 출력:

```text
아직 실행하지 않음
```

### 7.2 실제 적용과 최종 규칙

실행 명령:

```bash
sudo bash -e scripts/setup-firewall-ufw.sh --apply
sudo ufw status numbered
sudo ufw status verbose
```

실제 출력:

```text
아직 실행하지 않음
```

판정:

- [ ] UFW는 `active`다.
- [ ] 기본 incoming 정책은 `deny`다.
- [ ] `20022/tcp`가 허용된다.
- [ ] `15034/tcp`가 허용된다.
- [ ] 선택적 동일 v6 규칙 외 다른 ALLOW 포트가 없다.
- [ ] `22/tcp` 허용 규칙이 남아 있지 않다.

오류 및 조치:

```text
없음
```

---

## 8. 환경 변수와 키 파일

연결 단계: [README 14~15. 환경 변수와 키](../README.md#14-환경-변수-설정)

- 실행 위치: Ubuntu agent-admin 터미널과 Ubuntu 관리자 터미널
- 실행 일시: 작성 필요
- 실행 계정: 작성 필요
- 상태: `미실행`

### 8.1 agent-admin 환경 변수

실행 명령:

```bash
sudo -iu agent-admin
printf 'AGENT_HOME=%s\n' "$AGENT_HOME"
printf 'AGENT_PORT=%s\n' "$AGENT_PORT"
printf 'AGENT_UPLOAD_DIR=%s\n' "$AGENT_UPLOAD_DIR"
printf 'AGENT_KEY_PATH=%s\n' "$AGENT_KEY_PATH"
printf 'AGENT_LOG_DIR=%s\n' "$AGENT_LOG_DIR"
exit
```

실제 출력:

```text
아직 실행하지 않음
```

### 8.2 키 내용과 권한

실행 명령:

```bash
sudo -u agent-admin cat /home/agent-admin/agent-app/api_keys/secret.key
sudo -u agent-admin cat /home/agent-admin/agent-app/api_keys/t_secret.key
sudo ls -l /home/agent-admin/agent-app/api_keys/secret.key
sudo ls -l /home/agent-admin/agent-app/api_keys/t_secret.key
```

실제 출력:

```text
아직 실행하지 않음
```

호환 처리 설명:

```text
영구 AGENT_KEY_PATH는 미션 요구 파일인 t_secret.key를 가리킨다.
제공 바이너리 실행 시에만 AGENT_KEY_PATH를 api_keys 디렉터리로 임시 재정의한다.
```

판정:

- [ ] 다섯 환경 변수가 README의 값과 같다.
- [ ] 영구 `AGENT_KEY_PATH`는 `.../api_keys/t_secret.key`다.
- [ ] 두 키 파일 내용은 `agent_api_key_test`다.
- [ ] 두 키 파일은 `agent-admin:agent-core`, `640`이다.

오류 및 조치:

```text
없음
```

---

## 9. 앱 Boot Sequence와 15034

연결 단계: [README 16~18. 앱 실행과 검증](../README.md#16-agent-app-실행)

- 앱 실행 위치: Ubuntu 앱 터미널
- 검증 위치: Ubuntu 관리자 터미널
- 실행 일시: 작성 필요
- 상태: `미실행`

### 9.1 앱 실행 명령과 Boot Sequence

실행 명령:

```bash
sudo -iu agent-admin
cd "$AGENT_HOME"
AGENT_KEY_PATH="$AGENT_HOME/api_keys" ./agent-app
```

실제 Boot Sequence 전체 출력:

```text
아직 실행하지 않음
```

### 9.2 프로세스, 포트, 연결

실행 명령:

```bash
ps -ef | grep '[a]gent-app'
sudo ss -ltnp | grep ':15034'
curl -v --max-time 3 http://localhost:15034
echo "curl exit: $?"
```

실제 출력:

```text
아직 실행하지 않음
```

판정:

- [ ] Boot Sequence 1~5단계가 모두 `[OK]`다.
- [ ] `All Boot Checks Passed!`가 보인다.
- [ ] `Agent READY`가 보인다.
- [ ] 앱은 root가 아닌 `agent-admin`으로 실행 중이다.
- [ ] 앱 프로세스가 확인된다.
- [ ] TCP `0.0.0.0:15034`가 LISTEN 상태다.
- [ ] curl에서 `Connected to localhost` 또는 `Connected to 127.0.0.1`이 확인된다.
- [ ] timeout이 발생했다면 `Connected` 이후의 제공 앱 특성임을 기록했다.

오류 및 조치:

```text
없음
```

---

## 10. monitor.sh 직접 실행

연결 단계: [README 19. monitor.sh 실행](../README.md#19-monitorsh-실행)

- 실행 위치: Ubuntu 관리자 터미널 · 저장소 최상위 폴더
- 실행 일시: 작성 필요
- 실행 계정: `agent-admin`
- 상태: `미실행`

### 10.1 파일과 문법

실행 명령:

```bash
bash -n bin/monitor.sh
echo "source syntax exit: $?"
export AGENT_HOME=/home/agent-admin/agent-app
sudo ls -l "$AGENT_HOME/bin/monitor.sh"
sudo -u agent-admin bash -n "$AGENT_HOME/bin/monitor.sh"
echo "deployed syntax exit: $?"
```

실제 출력:

```text
아직 실행하지 않음
```

### 10.2 직접 실행 결과

실행 명령:

```bash
sudo -u agent-admin "$AGENT_HOME/bin/monitor.sh"
echo "monitor exit: $?"
```

실제 출력:

```text
아직 실행하지 않음
```

판정:

- [ ] 운영 파일은 `agent-dev:agent-core`, `750`이다.
- [ ] 원본과 운영 파일의 Bash 문법 검사가 성공했다.
- [ ] 앱 프로세스와 포트가 `[OK]`다.
- [ ] CPU, MEM, DISK_USED가 숫자로 출력된다.
- [ ] 방화벽 active 또는 명확한 WARNING이 출력된다.
- [ ] 정상 상태에서 종료 코드는 `0`이다.
- [ ] `/var/log/agent-app/monitor.log` append 성공 문구가 보인다.

오류 및 조치:

```text
없음
```

---

## 11. monitor.log 누적 확인

연결 단계: [README 20. monitor.log 확인](../README.md#20-monitorlog-확인)

- 실행 위치: Ubuntu 관리자 터미널
- 실행 일시: 작성 필요
- 상태: `미실행`

실행 명령:

```bash
echo "[BEFORE]"
sudo wc -l /var/log/agent-app/monitor.log

sudo -u agent-admin /home/agent-admin/agent-app/bin/monitor.sh

echo "[AFTER]"
sudo wc -l /var/log/agent-app/monitor.log
sudo tail -n 5 /var/log/agent-app/monitor.log
```

실제 출력:

```text
아직 실행하지 않음
```

수치 기록:

| 항목 | 실제 값 |
|---|---|
| 실행 전 줄 수 | 작성 필요 |
| 실행 후 줄 수 | 작성 필요 |
| 증가량 | 작성 필요 |
| 마지막 로그 시각 | 작성 필요 |

판정:

- [ ] 직접 실행 1회 후 줄 수가 정확히 1 증가했다.
- [ ] 이전 로그가 사라지지 않았다.
- [ ] 마지막 줄 형식이 `[시간] PID CPU MEM DISK_USED` 순서다.
- [ ] `>`가 아닌 `>>` append 동작을 실제 증가로 확인했다.

오류 및 조치:

```text
없음
```

---

## 12. logrotate

연결 단계: [README 21. logrotate 설정](../README.md#21-logrotate-설정)

- 실행 위치: Ubuntu 관리자 터미널 · 저장소 최상위 폴더
- 실행 일시: 작성 필요
- 상태: `미실행`

### 12.1 설치 결과

실행 명령:

```bash
sudo bash scripts/setup-logrotate.sh
```

실제 출력:

```text
아직 실행하지 않음
```

### 12.2 설정과 드라이런

실행 명령:

```bash
sudo cat /etc/logrotate.d/agent-app-monitor
sudo logrotate -d /etc/logrotate.d/agent-app-monitor
systemctl list-timers --all | grep logrotate || true
```

실제 출력:

```text
아직 실행하지 않음
```

판정:

- [ ] 대상은 `/var/log/agent-app/monitor.log`다.
- [ ] `size 10M`이 보인다.
- [ ] `rotate 10`이 보인다.
- [ ] `su agent-admin agent-core`가 보인다.
- [ ] `missingok`, `notifempty`, `copytruncate`가 보인다.
- [ ] `compress`, `delaycompress`가 보인다.
- [ ] `create 0640 agent-admin agent-core`가 보인다.
- [ ] 드라이런에 문법 오류가 없다.

오류 및 조치:

```text
없음
```

---

## 13. cron 등록과 자동 실행

연결 단계: [README 22~23. cron](../README.md#22-cron-등록)

- 실행 위치: Ubuntu 관리자 터미널 · 저장소 최상위 폴더
- 실행 일시: 작성 필요
- 상태: `미실행`

### 13.1 서비스와 등록 결과

실행 명령:

```bash
sudo systemctl is-active cron
sudo bash scripts/install-cron.sh
sudo crontab -u agent-admin -l
```

실제 출력:

```text
아직 실행하지 않음
```

### 13.2 70초 전후 자동 증가

실행 명령:

```bash
echo "[BEFORE]"
sudo wc -l /var/log/agent-app/monitor.log

sleep 70

echo "[AFTER]"
sudo wc -l /var/log/agent-app/monitor.log
sudo tail -n 10 /var/log/agent-app/monitor.log
sudo tail -n 10 /var/log/agent-app/cron.log
```

실제 출력:

```text
아직 실행하지 않음
```

수치 기록:

| 항목 | 실제 값 |
|---|---|
| 대기 시작 시각 | 작성 필요 |
| 대기 종료 시각 | 작성 필요 |
| 실행 전 monitor.log 줄 수 | 작성 필요 |
| 실행 후 monitor.log 줄 수 | 작성 필요 |
| 증가량 | 작성 필요 |
| cron.log 마지막 시각 | 작성 필요 |

판정:

- [ ] cron 서비스는 active다.
- [ ] `agent-admin`의 crontab에 monitor 항목이 정확히 한 번 있다.
- [ ] 작업은 `* * * * *` 매분 실행 형식이다.
- [ ] stdout과 stderr가 `cron.log`에 누적된다.
- [ ] 직접 실행하지 않았는데 70초 뒤 monitor.log가 증가했다.
- [ ] cron 실행 중 앱 터미널이 유지됐다.

오류 및 조치:

```text
없음
```

---

## 14. 보너스 report.sh

연결 단계: [README 24. report.sh](../README.md#24-보너스-reportsh-실행)

- 실행 위치: Ubuntu 관리자 터미널 · 저장소 최상위 폴더
- 실행 일시: 작성 필요
- 상태: `미실행`

### 14.1 파일, 문법, 전체 통계

실행 명령:

```bash
bash -n bin/report.sh
echo "source syntax exit: $?"
export AGENT_HOME=/home/agent-admin/agent-app
sudo ls -l "$AGENT_HOME/bin/report.sh"
sudo -u agent-admin bash -n "$AGENT_HOME/bin/report.sh"
echo "deployed syntax exit: $?"
sudo -u agent-admin "$AGENT_HOME/bin/report.sh"
```

실제 출력:

```text
아직 실행하지 않음
```

### 14.2 최근 시간 구간 통계

실행 명령:

```bash
sudo -u agent-admin "$AGENT_HOME/bin/report.sh" \
  --from "$(date -d '10 minutes ago' '+%F %T')" \
  --to "$(date '+%F %T')"
```

실제 출력:

```text
아직 실행하지 않음
```

판정:

- [ ] 운영 파일은 `agent-dev:agent-core`, `750`이다.
- [ ] Bash 문법 검사가 성공했다.
- [ ] Samples가 1 이상이다.
- [ ] CPU 평균, 최대, 최소가 출력된다.
- [ ] MEM 평균, 최대, 최소가 출력된다.
- [ ] DISK_USED 평균, 최대, 최소가 출력된다.
- [ ] 시간 구간 옵션의 범위와 실제 샘플 시각이 맞는다.
- [ ] Parse Skip이 있다면 원인 줄을 기록했다.

오류 및 조치:

```text
없음
```

---

## 15. 보너스 시간 기반 로그 아카이브

연결 단계: [README 25. archive-old-logs.sh](../README.md#25-보너스-archive-old-logssh-실행)

- 실행 위치: Ubuntu 관리자 터미널 · 저장소 최상위 폴더
- 실행 일시: 작성 필요
- 상태: `미실행`

### 15.1 `/tmp` 안전 테스트

실행 명령은 README 25.1의 전체 블록을 사용한다.

실제 스크립트 출력:

```text
아직 실행하지 않음
```

실제 `find "$DEMO_ROOT" ...` 출력:

```text
아직 실행하지 않음
```

판정:

- [ ] 8일 된 `old.log`의 압축본이 만들어졌다.
- [ ] 압축본이 demo archive로 이동했다.
- [ ] 31일 된 `expired.log.gz`가 삭제됐다.
- [ ] 원본 `old.log` 보존 여부를 확인했다.
- [ ] `Archive cleanup completed`가 보인다.

### 15.2 실제 미션 경로

실행 명령:

```bash
sudo bash scripts/archive-old-logs.sh
sudo find /var/log/monitor/agent-app/archive -type f -name "*.gz" -ls
```

실제 출력:

```text
아직 실행하지 않음
```

판정:

- [ ] 아카이브 디렉터리 확인 또는 생성 메시지가 보인다.
- [ ] 대상이 없으면 정상 INFO 메시지로 종료한다.
- [ ] 대상이 있으면 압축과 이동 경로가 기록된다.
- [ ] 30일 경과 파일이 있으면 삭제 경로가 기록된다.
- [ ] 권한 또는 gzip 실패가 있다면 명확한 WARNING/ERROR가 보인다.

오류 및 조치:

```text
없음
```

---

## 16. 최종 정적 검증

연결 단계: [README 26. 전체 검증 체크리스트](../README.md#26-전체-검증-체크리스트)

- 실행 위치: macOS 또는 Ubuntu 관리자 터미널 · 저장소 최상위 폴더
- 실행 일시: 작성 필요
- 상태: `미실행`

실행 명령:

```bash
pwd
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
git status --short --branch
```

실제 출력:

```text
아직 실행하지 않음
```

판정:

- [ ] 모든 Bash 문법 검사가 성공했다.
- [ ] `git diff --check` 오류가 없다.
- [ ] 의도한 변경 파일만 Git 상태에 표시된다.
- [ ] 실제 비밀값이나 불필요한 생성 파일이 없다.

오류 및 조치:

```text
없음
```

---

## 17. 오류 및 해결 기록

오류가 하나도 없었다면 `해당 없음`이라고 적는다. 오류가 있었다면 아래 양식을 복사해 오류마다 하나씩 작성하고, 각 단계의 `오류 기록 번호`에 연결한다.

### 오류 기록 E-01

| 항목 | 실제 기록 |
|---|---|
| 발생 일시 | 작성 필요 |
| README 단계 | 작성 필요 |
| 실행 위치 | 작성 필요 |
| 실행 계정 | 작성 필요 |
| 실행한 명령 | 작성 필요 |
| 종료 코드 | 작성 필요 |
| 최초 상태 | 실패 |
| 최종 상태 | 작성 필요 |

오류 원문:

```text
아직 기록 없음
```

원인 가설:

```text
아직 기록 없음
```

확인 명령과 실제 출력:

```text
아직 기록 없음
```

실제 원인:

```text
아직 기록 없음
```

해결 명령 또는 조치:

```text
아직 기록 없음
```

재검증 결과:

```text
아직 기록 없음
```

재발 방지:

```text
아직 기록 없음
```

---

## 18. 최종 제출 증빙 요약

모든 실행이 끝난 뒤 각 행의 상태와 이 문서의 근거 섹션을 확인한다.

| 요구사항 | 최종 상태 | 근거 섹션 | 핵심 실제 결과 |
|---|---|---|---|
| Ubuntu 24.04 환경 | 미실행 | 1 | 작성 필요 |
| SSH 포트 20022 | 미실행 | 6 | 작성 필요 |
| Root 원격 접속 차단 | 미실행 | 6 | 작성 필요 |
| UFW 최소 허용 | 미실행 | 7 | 작성 필요 |
| 계정과 그룹 | 미실행 | 3 | 작성 필요 |
| 디렉터리와 ACL | 미실행 | 4 | 작성 필요 |
| 환경 변수와 키 | 미실행 | 8 | 작성 필요 |
| Boot Sequence 5단계 | 미실행 | 9 | 작성 필요 |
| Agent READY | 미실행 | 9 | 작성 필요 |
| TCP 15034 LISTEN | 미실행 | 9 | 작성 필요 |
| monitor 직접 실행 | 미실행 | 10 | 작성 필요 |
| monitor.log 누적 | 미실행 | 11 | 작성 필요 |
| logrotate 10MB/10개 | 미실행 | 12 | 작성 필요 |
| cron 매분 자동 증가 | 미실행 | 13 | 작성 필요 |
| 보너스 report | 미실행 | 14 | 작성 필요 |
| 보너스 archive | 미실행 | 15 | 작성 필요 |

최종 종합 판정:

```text
미실행
```

남은 작업:

```text
README를 실행한 뒤 실제 출력과 상태를 작성한다.
```
