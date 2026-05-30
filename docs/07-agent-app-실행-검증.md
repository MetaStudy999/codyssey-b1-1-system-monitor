# agent-app 실행 검증

## 이 단계의 목표

제공 앱을 root가 아닌 `agent-admin`으로 실행하고 Boot Sequence 5단계와 `Agent READY`를 확인한다.

## 왜 이 작업을 하는가?

관제 스크립트는 실제 앱 프로세스와 포트를 점검해야 한다. 앱이 정상 실행되지 않으면 monitor.sh 검증도 의미가 없다.

## 사전 확인

```bash
sudo ls -l /home/agent-admin/agent-app/agent-app
sudo -iu agent-admin env | grep '^AGENT_'
sudo -u agent-admin cat /home/agent-admin/agent-app/api_keys/t_secret.key
```

## 실행 명령어

```bash
sudo -iu agent-admin
source ~/.profile
env | grep '^AGENT_'
cd "$AGENT_HOME"
./agent-app
```

다른 터미널에서 확인한다.

```bash
ps -ef | grep '[a]gent-app'
ss -tulnp | grep 15034
curl http://localhost:15034
```

## 명령어 설명

- `sudo -iu agent-admin`: 로그인 환경으로 일반 계정 실행을 보장한다.
- `./agent-app`: 제공 앱 실행 파일이다.
- `ss -tulnp`: TCP/UDP LISTEN 포트를 확인한다.

## 기대 결과

앱 실행 터미널:

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

포트 확인:

```text
0.0.0.0:15034 LISTEN
```

## 결과 확인 명령어

```bash
ps -ef | grep '[a]gent-app'
ss -tulnp | grep 15034
curl http://localhost:15034
```

## README에 붙여넣을 증빙

Boot Sequence 출력, `Agent READY`, `ss`, `curl` 결과를 붙인다.

## 자주 발생하는 오류

- `Running as root is forbidden`: `agent-admin` 계정으로 실행한다.
- `Critical Env 'AGENT_HOME' is missing`: `agent-admin` 셸에서 환경 변수가 로드되지 않은 상태다. `source ~/.profile`을 실행하고 `env | grep '^AGENT_'`로 확인한 뒤 다시 실행한다.
- `Port 15034 is not available`: 이미 같은 포트를 쓰는 프로세스를 확인한다.
- `GLIBC_2.38 not found`: `codyssey-b1-1-ubuntu24`에서 `ldd --version`, `cat /etc/os-release`, `file "$AGENT_HOME/agent-app"`로 glibc와 바이너리 호환성을 확인한다.

## 다음 단계로 넘어가는 기준

Boot Sequence 5단계가 모두 `[OK]`이고 `15034`가 LISTEN이면 다음 단계로 넘어간다.

## Git 커밋 시점

앱 실행 검증 문서를 추가한 뒤 커밋한다.

## 추천 커밋 메시지

```bash
git commit -m "docs: add agent app execution verification guide"
```
