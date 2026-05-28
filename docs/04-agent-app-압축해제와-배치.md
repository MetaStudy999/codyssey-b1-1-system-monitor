# agent-app 압축 해제와 배치

## 이 단계의 목표

`agent-app.zip` 내부 파일을 확인한 뒤, Ubuntu 아키텍처에 맞는 실행 파일을 `$AGENT_HOME/agent-app`으로 배치한다.

## 왜 이 작업을 하는가?

미션의 관제 대상은 제공 앱이다. 앱이 정상 실행되어야 `monitor.sh`가 프로세스와 포트를 점검할 수 있다.

## 사전 확인

이 단계는 `docs/02-계정-그룹-생성.md`와 `docs/03-디렉토리-권한-설정.md`를 완료한 뒤 진행한다. `agent-admin` 계정, `agent-core` 그룹, `/home/agent-admin/agent-app` 디렉터리가 먼저 있어야 앱 파일의 소유자와 권한을 올바르게 설정할 수 있다.

이미 OrbStack Ubuntu VM 안에 들어와 있다면 접속 명령은 다시 실행하지 않는다. VM 터미널에서 프로젝트 폴더로 이동한 뒤 ZIP 파일이 있는지 확인한다.

```bash
cd /mnt/mac/Users/metastudy9997479/codyssey/codyssey-b1-1-system-monitor
ls -l agent-app.zip
```

위 경로가 없다면 다음 경로도 확인한다.

```bash
cd /Users/metastudy9997479/codyssey/codyssey-b1-1-system-monitor
ls -l agent-app.zip
```

ZIP 내부 목록을 먼저 확인한다.

```bash
unzip -l agent-app.zip

Archive:  agent-app.zip
  Length      Date    Time    Name
---------  ---------- -----   ----
  6498144  05-20-2026 11:11   agent-app-linux-x86
      354  05-20-2026 11:11   __MACOSX/._agent-app-linux-x86
  7537848  05-18-2026 17:06   agent-app-linux-arm64
      219  05-18-2026 17:06   __MACOSX/._agent-app-linux-arm64
---------                     -------
 14036565                     4 files

```

확인된 파일:

```text
agent-app-linux-x86
agent-app-linux-arm64
__MACOSX/._agent-app-linux-x86
__MACOSX/._agent-app-linux-arm64
```

Ubuntu에서 아키텍처를 확인한다.

```bash
uname -m
```

계정, 그룹, 앱 홈 디렉터리가 준비되었는지 확인한다.

```bash
id agent-admin
getent group agent-core
ls -ld /home/agent-admin/agent-app
```

## 실행 명령어

Ubuntu의 프로젝트 복사본 또는 공유 폴더에서 실행한다.

```bash
unzip agent-app.zip -d /tmp/agent-app-extract
ls -la /tmp/agent-app-extract
```

아키텍처에 따라 복사한다.

```bash
export AGENT_HOME=/home/agent-admin/agent-app

if [ "$(uname -m)" = "x86_64" ]; then
  sudo cp /tmp/agent-app-extract/agent-app-linux-x86 "$AGENT_HOME/agent-app"
else
  sudo cp /tmp/agent-app-extract/agent-app-linux-arm64 "$AGENT_HOME/agent-app"
fi

sudo chown agent-admin:agent-core "$AGENT_HOME/agent-app"
sudo chmod 750 "$AGENT_HOME/agent-app"
```

## 명령어 설명

- `unzip -l`: 압축을 풀지 않고 내부 목록만 확인한다.
- `uname -m`: `x86_64`, `aarch64`, `arm64` 같은 CPU 아키텍처를 확인한다.
- 실행 파일명은 문서와 스크립트에서 혼동을 줄이기 위해 `agent-app`으로 통일한다.

## 기대 결과

```text
/home/agent-admin/agent-app/agent-app
```

파일이 존재하고 `agent-admin`이 실행할 수 있다.

## 결과 확인 명령어

```bash
ls -l /home/agent-admin/agent-app/agent-app
file /home/agent-admin/agent-app/agent-app
```

## README에 붙여넣을 증빙

```text
agent-app.zip 내부에는 Linux x86, Linux arm64 실행 파일이 있었다.
Ubuntu의 uname -m 결과에 따라 알맞은 파일을 $AGENT_HOME/agent-app으로 배치했다.
```

## 자주 발생하는 오류

- `Permission denied`: 실행 권한이 없을 수 있으므로 `sudo chmod 750 "$AGENT_HOME/agent-app"`을 확인한다.
- `Exec format error`: CPU 아키텍처와 맞지 않는 바이너리를 실행한 것이다.
- `__MACOSX` 파일 실행 시도: macOS 메타데이터이므로 무시한다.

## 다음 단계로 넘어가는 기준

`$AGENT_HOME/agent-app` 파일이 존재하고 실행 권한이 있으면 다음 단계로 넘어간다.

## Git 커밋 시점

앱 배치 가이드를 추가한 뒤 커밋한다.

## 추천 커밋 메시지

```bash
git commit -m "docs: add agent app runtime setup guide"
```
