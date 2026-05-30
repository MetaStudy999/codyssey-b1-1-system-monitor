# Command Log

실제 수행한 명령과 결과를 기록하는 문서다. 아래 예시는 템플릿이며, `codyssey-b1-1-ubuntu24` 실습 후 실제 출력으로 교체한다.

## macOS 작업 폴더 확인

```bash
pwd
ls -la
git status
```

결과:

```text
TODO: 실제 출력 붙여넣기
```

## agent-app.zip 내부 확인

```bash
unzip -l agent-app.zip
```

결과:

```text
agent-app-linux-x86
agent-app-linux-arm64
__MACOSX 메타데이터 파일
```

## Ubuntu 24.04 환경 확인

```bash
cat /etc/os-release
uname -m
whoami
id
```

결과:

```text
TODO: 실제 출력 붙여넣기
```

## 계정/그룹 생성

```bash
sudo bash scripts/setup-users.sh
id agent-admin
id agent-dev
id agent-test
getent group agent-common
getent group agent-core
```

결과:

```text
TODO: 실제 출력 붙여넣기
```

## 디렉터리/권한 설정

```bash
sudo bash scripts/setup-dirs.sh
ls -ld /home/agent-admin/agent-app
ls -ld /home/agent-admin/agent-app/upload_files
ls -ld /home/agent-admin/agent-app/api_keys
ls -ld /var/log/agent-app
```

결과:

```text
TODO: 실제 출력 붙여넣기
```

## 앱 실행

```bash
sudo -iu agent-admin
cd "$AGENT_HOME"
./agent-app
```

결과:

```text
TODO: Boot Sequence 출력 붙여넣기
```

## monitor.sh

```bash
sudo -u agent-admin /home/agent-admin/agent-app/bin/monitor.sh
tail -n 5 /var/log/agent-app/monitor.log
```

결과:

```text
TODO: 실제 출력 붙여넣기
```

## cron

```bash
sudo bash scripts/install-cron.sh
sudo crontab -u agent-admin -l
```

결과:

```text
TODO: 실제 출력 붙여넣기
```
