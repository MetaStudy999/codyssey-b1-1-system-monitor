# 입문: 쉘 프로그램 첫걸음

## 이 단계의 목표

쉘이 무엇인지 이해하고, 작은 Bash 스크립트를 직접 만들고 실행한다.

이 단계에서는 시스템 설정을 바꾸지 않는다. 홈 디렉터리나 `/tmp`에서 안전하게 연습한다.

## 핵심 개념

| 개념 | 설명 |
|---|---|
| shell | 사용자가 입력한 명령을 해석해 실행하는 프로그램 |
| Bash | Ubuntu에서 흔히 쓰는 셸 프로그램 |
| script | 여러 명령을 파일에 저장해 순서대로 실행하는 프로그램 |
| shebang | 스크립트를 어떤 해석기로 실행할지 알려주는 첫 줄 |
| exit code | 명령 성공/실패를 숫자로 표현한 결과 |

## 따라하기 1: 실습 디렉터리 만들기

Ubuntu VM에서 실행한다.

```bash
mkdir -p ~/shell-training
cd ~/shell-training
pwd
```

기대 결과:

```text
/home/<사용자>/shell-training
```

## 따라하기 2: 첫 스크립트 작성

`hello.sh` 파일을 만든다.

```bash
nano hello.sh
```

내용:

```bash
#!/usr/bin/env bash

echo "Hello, Linux shell"
echo "Current user: $(whoami)"
echo "Current directory: $(pwd)"
```

문법 검사:

```bash
bash -n hello.sh
```

실행:

```bash
bash hello.sh
```

실행 권한을 주고 직접 실행:

```bash
chmod 755 hello.sh
./hello.sh
```

## 따라하기 3: 변수 사용하기

`env-summary.sh` 파일을 만든다.

```bash
nano env-summary.sh
```

내용:

```bash
#!/usr/bin/env bash

PROJECT_NAME="B1-1 system monitor"
AGENT_PORT="${AGENT_PORT:-15034}"

echo "Project: $PROJECT_NAME"
echo "Agent port: $AGENT_PORT"
echo "Home: $HOME"
```

확인:

```bash
bash -n env-summary.sh
bash env-summary.sh
AGENT_PORT=18080 bash env-summary.sh
```

`"${AGENT_PORT:-15034}"`는 `AGENT_PORT` 환경 변수가 있으면 그 값을 쓰고, 없으면 `15034`를 기본값으로 사용한다. 현재 구현된 `bin/monitor.sh`도 같은 방식으로 `AGENT_HOME`, `AGENT_PORT`, `AGENT_LOG_DIR` 기본값을 정한다.

## 따라하기 4: 성공과 실패 확인

명령의 종료 코드를 확인한다.

```bash
ls hello.sh
echo $?
ls not-exist.txt
echo $?
```

`0`이면 성공이고, `1` 이상이면 실패다.

## 현재 구현과 연결하기

`bin/monitor.sh`의 시작 부분을 읽어 본다.

```bash
sed -n '1,80p' bin/monitor.sh
```

확인할 포인트:

- 첫 줄에 `#!/usr/bin/env bash`가 있다.
- `set -u`로 선언되지 않은 변수 사용을 막는다.
- `AGENT_HOME="${AGENT_HOME:-/home/agent-admin/agent-app}"`처럼 기본값을 둔다.

## 연습 문제

1. `my-info.sh`를 만들고 현재 사용자, 현재 디렉터리, 오늘 날짜를 출력하라.
2. `APP_NAME` 환경 변수가 없으면 `agent-app`을 출력하고, 있으면 입력된 값을 출력하라.
3. `bash -n`과 `bash script.sh`의 차이를 한 문장으로 설명하라.
4. `chmod 755 hello.sh`에서 `755`가 의미하는 권한을 설명하라.

## 예시 답안

### 1. `my-info.sh`

```bash
#!/usr/bin/env bash

echo "Current user: $(whoami)"
echo "Current directory: $(pwd)"
echo "Today: $(date '+%Y-%m-%d')"
```

검증:

```bash
bash -n my-info.sh
bash my-info.sh
```

### 2. `APP_NAME` 기본값 출력

```bash
#!/usr/bin/env bash

APP_NAME="${APP_NAME:-agent-app}"
echo "App name: $APP_NAME"
```

확인:

```bash
bash app-name.sh
APP_NAME=my-agent bash app-name.sh
```

첫 번째 실행은 `agent-app`, 두 번째 실행은 `my-agent`를 출력한다.

### 3. `bash -n`과 `bash script.sh` 차이

`bash -n script.sh`는 스크립트를 실제 실행하지 않고 Bash 문법만 검사하고, `bash script.sh`는 스크립트 안의 명령을 실제로 실행한다.

### 4. `chmod 755 hello.sh` 의미

`755`는 소유자 `7`, 그룹 `5`, others `5` 권한을 뜻한다.

| 대상 | 숫자 | 권한 |
|---|---:|---|
| 소유자 | 7 | 읽기, 쓰기, 실행 |
| 그룹 | 5 | 읽기, 실행 |
| others | 5 | 읽기, 실행 |

## 통과 기준

- `hello.sh`와 `env-summary.sh`를 실행할 수 있다.
- 환경 변수 기본값 문법을 설명할 수 있다.
- exit code `0`과 `1` 이상의 차이를 설명할 수 있다.
