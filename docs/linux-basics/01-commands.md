# Linux 명령어 정리

## 기본 확인 명령어

### `pwd`

약어 풀이: `print working directory`

현재 작업 중인 디렉터리 경로를 출력한다.

```bash
pwd
```

B1-1에서는 현재 위치가 프로젝트 루트인지 확인할 때 사용한다.

### `ls`

약어 풀이: `list`

파일과 디렉터리 목록을 출력한다.

```bash
ls -la
```

- `-l`: `long format`, 자세한 정보를 보여준다.
- `-a`: `all`, 숨김 파일까지 보여준다.

### `cat`

약어 풀이: `concatenate`

파일 내용을 출력한다.

```bash
cat /etc/os-release
```

Ubuntu 버전 확인이나 설정 파일 내용 확인에 사용한다.

### `grep`

약어 풀이: `global regular expression print`

텍스트에서 원하는 줄을 검색한다.

```bash
grep -E '^(Port|PermitRootLogin)' /etc/ssh/sshd_config
```

- `-E`: `extended regular expression`, 확장 정규식을 사용한다.
- `^`: 줄의 시작을 의미한다.

## 사용자와 그룹 명령어

### `whoami`

이름 풀이: `who am I`

현재 로그인한 사용자 이름을 출력한다.

```bash
whoami
```

### `id`

약어 풀이: `identity`

사용자의 UID, GID, 소속 그룹을 확인한다.

- `UID`: `User ID`, 사용자를 구분하는 숫자 ID
- `GID`: `Group ID`, 그룹을 구분하는 숫자 ID

```bash
id agent-admin
```

B1-1에서는 계정이 생성되었는지, 그룹 정책이 맞는지 확인할 때 사용한다.

### `getent`

약어 풀이: `get entries`

시스템 데이터베이스에서 사용자나 그룹 정보를 조회한다.

```bash
getent passwd agent-admin
getent group agent-core
```

- `passwd`: 사용자 계정 데이터베이스를 의미한다.
- `group`: 그룹 데이터베이스를 의미한다.
- `getent passwd <user>`: 사용자 존재 여부 확인
- `getent group <group>`: 그룹 존재 여부 확인

### `groupadd`

이름 풀이: `group add`

새 그룹을 생성한다.

```bash
sudo groupadd -f agent-common
```

- `sudo`: `substitute user do` 또는 관용적으로 `superuser do`, 관리자 권한으로 실행한다.
- `-f`: `force`, 그룹이 이미 있어도 오류로 중단하지 않는다.

### `useradd`

이름 풀이: `user add`

새 사용자를 생성한다.

```bash
sudo useradd -m -s /bin/bash agent-admin
```

- `-m`: `make home directory`, 홈 디렉터리를 생성한다.
- `-s /bin/bash`: `shell`, 로그인 셸을 Bash로 지정한다.

### `usermod`

약어 풀이: `user modify`

기존 사용자 정보를 수정한다.

```bash
sudo usermod -aG agent-core agent-admin
```

- `-G`: `groups`, 보조 그룹을 지정한다.
- `-aG`: `append groups`, 기존 보조 그룹을 유지하면서 새 그룹을 추가한다.

`-a` 없이 `-G`만 쓰면 기존 보조 그룹이 덮어써질 수 있으므로 주의한다.

## 파일과 디렉터리 권한 명령어

### `mkdir`

약어 풀이: `make directory`

디렉터리를 생성한다.

```bash
sudo mkdir -p /var/log/agent-app
```

- `-p`: `parents`, 상위 디렉터리가 없으면 함께 만들고, 이미 있어도 오류로 중단하지 않는다.

### `chown`

약어 풀이: `change owner`

파일 또는 디렉터리의 소유자와 그룹을 변경한다.

```bash
sudo chown agent-admin:agent-core /var/log/agent-app
```

형식은 `소유자:그룹`이다.

### `chmod`

약어 풀이: `change mode`

파일 또는 디렉터리의 권한을 변경한다.

```bash
sudo chmod 750 /home/agent-admin/agent-app/bin/monitor.sh
```

- `7`: 소유자 읽기, 쓰기, 실행
- `5`: 그룹 읽기, 실행
- `0`: others 권한 없음

### `getfacl`

약어 풀이: `get file access control list`

파일 또는 디렉터리의 ACL 권한을 확인한다.

- `ACL`: `Access Control List`, 세밀한 접근 제어 목록

```bash
getfacl /var/log/agent-app
```

일반 권한보다 세밀한 접근 제어가 필요한지 확인할 때 사용한다.

## 프로세스와 포트 확인 명령어

### `ps`

약어 풀이: `process status`

실행 중인 프로세스를 확인한다.

```bash
ps -ef | grep agent
```

- `-e`: `every process`, 모든 프로세스를 표시한다.
- `-f`: `full format`, 자세한 형식으로 표시한다.
- `|`: pipe, 앞 명령의 출력을 뒤 명령의 입력으로 넘긴다.

앱 프로세스가 살아 있는지 확인할 때 사용한다.

### `pgrep`

약어 풀이: `process grep`

이름으로 프로세스 PID를 찾는다.

- `PID`: `Process ID`, 실행 중인 프로세스를 구분하는 숫자 ID

```bash
pgrep -f agent-app
```

- `-f`: `full command line`, 프로세스 이름뿐 아니라 전체 실행 명령줄까지 검색한다.

스크립트에서 프로세스 존재 여부를 확인할 때 유용하다.

### `ss`

약어 풀이: `socket statistics`

네트워크 소켓과 LISTEN 포트를 확인한다.

```bash
ss -tulnp | grep 15034
```

- `-t`: `TCP`, TCP 소켓 표시
- `-u`: `UDP`, UDP 소켓 표시
- `-l`: `listening`, LISTEN 상태 표시
- `-n`: `numeric`, 포트 번호를 숫자로 표시
- `-p`: `processes`, 프로세스 정보 표시

`TCP`는 `Transmission Control Protocol`, `UDP`는 `User Datagram Protocol`이다.

### `curl`

약어 풀이: `client URL`

HTTP 요청을 보내 응답을 확인한다.

- `HTTP`: `HyperText Transfer Protocol`
- `URL`: `Uniform Resource Locator`

```bash
curl http://localhost:15034
```

앱이 실제로 요청에 응답하는지 확인할 때 사용한다.

## 로그와 리소스 확인 명령어

### `tail`

이름 풀이: 파일의 꼬리 부분을 본다는 의미다.

파일의 마지막 부분을 출력한다.

```bash
sudo tail -n 5 /var/log/agent-app/monitor.log
```

- `-n`: `number`, 출력할 줄 수를 지정한다.

최근 로그를 확인할 때 사용한다.

### `wc`

약어 풀이: `word count`

줄 수, 단어 수, 바이트 수를 계산한다.

```bash
sudo wc -l /var/log/agent-app/monitor.log
```

- `-l`: `lines`, 줄 수만 출력한다.

cron 실행 후 로그 줄 수가 증가했는지 확인할 때 사용한다.

### `df`

약어 풀이: `disk free`

파일시스템 디스크 사용량을 확인한다.

```bash
df -h /
```

- `-h`: `human-readable`, 사람이 읽기 쉬운 단위로 보여준다.

monitor.sh에서 root partition 사용률을 확인할 때 사용한다.

### `free`

이름 풀이: 사용 가능한 메모리와 사용 중인 메모리를 보여준다는 의미다.

메모리 사용량을 확인한다.

```bash
free -m
```

- `-m`: `megabytes`, MB 단위로 보여준다.

시스템 메모리 상태를 확인할 때 사용한다.

## 서비스와 자동 실행 명령어

### `systemctl`

약어 풀이: `system control`

systemd 서비스를 확인하거나 제어한다.

```bash
sudo systemctl status ssh
```

- `ctl`: `control`을 줄인 표현이다.
- `ssh`: `Secure Shell`, 원격 접속에 사용하는 보안 셸 서비스다.

`codyssey-b1-1-ubuntu24`에서는 사용할 수 있지만, Docker 컨테이너에서는 제한될 수 있다.

### `ufw`

약어 풀이: `uncomplicated firewall`

Ubuntu의 방화벽을 설정한다.

```bash
sudo ufw status verbose
```

B1-1에서는 `20022/tcp`, `15034/tcp`만 허용하는지 확인한다.

### `crontab`

약어 풀이: `cron table`

cron 작업을 등록하거나 확인한다.

```bash
sudo crontab -u agent-admin -l
```

- `-u`: `user`, 대상 사용자를 지정한다.
- `-l`: `list`, 등록된 crontab 목록을 출력한다.

`monitor.sh`가 매분 자동 실행되도록 등록했는지 확인할 때 사용한다.

## Bash 검증 명령어

### `bash -n`

약어 풀이: `Bourne Again Shell`

Bash 스크립트 문법을 검사한다. 실제 실행은 하지 않는다.

```bash
bash -n scripts/setup-users.sh
bash -n bin/monitor.sh
```

- `-n`: `no execution`, 명령을 실제로 실행하지 않고 문법만 검사한다.

스크립트를 실행하기 전에 문법 오류를 먼저 잡을 때 사용한다.

## 텍스트 처리와 출력 명령어

### `echo`

이름 풀이: 화면에 값을 되돌려 출력한다는 의미다.

문자열이나 변수 값을 간단히 출력한다.

```bash
echo "$AGENT_HOME"
```

환경 변수가 원하는 값으로 설정되었는지 확인할 때 사용한다.

### `printf`

이름 풀이: `print formatted`

형식을 정해서 문자열을 출력한다.

```bash
printf '[INFO] %s\n' "Directory setup completed"
```

`echo`보다 줄바꿈, 퍼센트 기호, 자리 표시자를 예측하기 쉬워 스크립트 메시지와 로그 라인 생성에 적합하다.

### `sed`

약어 풀이: `stream editor`

텍스트 흐름에서 특정 줄을 출력하거나 내용을 치환한다.

```bash
sed -n '1,80p' bin/monitor.sh
sed -i 's#^export AGENT_KEY_PATH=.*#export AGENT_KEY_PATH=$AGENT_HOME/api_keys#' ~/.profile
```

- `-n`: 자동 출력을 끄고 지정한 출력만 보여준다.
- `p`: `print`, 선택한 줄을 출력한다.
- `-i`: `in-place`, 파일 내용을 직접 수정한다.

설정 파일 일부를 확인하거나 `.profile`의 환경 변수 라인을 고칠 때 사용한다.

### `awk`

이름 풀이: 개발자 이름 Aho, Weinberger, Kernighan에서 온 텍스트 처리 도구다.

줄과 필드를 기준으로 텍스트를 분석한다.

```bash
df -P / | awk 'NR == 2 { gsub(/%/, "", $5); print $5 }'
```

- `NR`: 현재까지 읽은 줄 번호
- `NF`: 현재 줄의 필드 개수
- `$1`, `$2`: 공백 기준 첫 번째, 두 번째 필드
- `-v`: shell 변수를 awk 변수로 전달

B1-1에서는 CPU/MEM/DISK 값 파싱, 소수 비교, report.sh 통계 계산에 사용한다.

### `cut`

이름 풀이: 텍스트의 일부를 잘라낸다는 의미다.

구분자를 기준으로 특정 필드를 출력한다.

```bash
getent passwd agent-admin | cut -d: -f6
```

- `-d`: `delimiter`, 필드 구분자를 지정한다.
- `-f`: `field`, 출력할 필드 번호를 지정한다.

`/etc/passwd` 형식에서 홈 디렉터리 경로만 뽑을 때 유용하다.

### `sort`

이름 풀이: 정렬한다는 의미다.

줄 단위로 텍스트를 정렬한다.

```bash
find . -maxdepth 3 -type f | sort
```

파일 목록을 일정한 순서로 보여 주어 README 증빙이나 검토가 쉬워진다.

### `head`

이름 풀이: 파일의 머리 부분을 본다는 의미다.

파일이나 명령 출력의 앞부분을 보여준다.

```bash
ps -eo pid=,comm=,args= | head
```

출력이 너무 길 때 일부만 빠르게 확인할 때 사용한다.

## 환경 변수와 shell 확인 명령어

### `export`

이름 풀이: 변수를 현재 shell 밖의 자식 프로세스에도 전달한다는 의미다.

환경 변수를 설정한다.

```bash
export AGENT_HOME=/home/agent-admin/agent-app
export AGENT_PORT=15034
```

앱이나 스크립트가 같은 값을 읽어야 할 때 사용한다.

### `source`

이름 풀이: 파일 내용을 현재 shell에서 읽어 실행한다는 의미다.

설정 파일을 다시 읽는다.

```bash
source ~/.profile
```

`.profile`에 추가한 환경 변수를 로그아웃 없이 현재 터미널에 반영할 때 사용한다.

### `env`

약어 풀이: `environment`

현재 환경 변수 목록을 출력하거나, 특정 환경 변수를 주입한 상태로 명령을 실행한다.

```bash
env | grep AGENT
AGENT_PORT=18080 bash env-summary.sh
```

cron이나 테스트 실행에서 어떤 환경 변수가 적용되는지 확인할 때 유용하다.

### `command -v`

이름 풀이: shell 내장 명령인 `command`로 실행 파일 위치를 확인한다는 의미다.

명령이 설치되어 있고 PATH에서 찾을 수 있는지 확인한다.

```bash
command -v ufw
command -v logrotate
```

스크립트에서는 필요한 도구가 없을 때 친절한 오류 메시지를 출력하기 위해 사용한다.

## 파일 배치와 아카이브 명령어

### `cp`

약어 풀이: `copy`

파일을 복사한다.

```bash
sudo cp /tmp/agent-app-extract/agent-app-linux-x86 "$AGENT_HOME/agent-app"
```

압축 해제한 앱 바이너리를 운영 위치로 배치할 때 사용한다.

### `install`

이름 풀이: 파일이나 디렉터리를 설치 위치에 배치한다는 의미다.

파일 또는 디렉터리를 만들면서 소유자, 그룹, 권한을 함께 지정한다.

```bash
sudo install -d -o agent-admin -g agent-core -m 0750 "$AGENT_HOME"
```

- `-d`: 디렉터리를 만든다.
- `-o`: `owner`, 소유자를 지정한다.
- `-g`: `group`, 소유 그룹을 지정한다.
- `-m`: `mode`, 권한 모드를 지정한다.

`setup-dirs.sh`처럼 반복 실행 가능한 권한 설정 스크립트에서 유용하다.

### `unzip`

이름 풀이: zip 압축을 푼다는 의미다.

`.zip` 파일을 해제한다.

```bash
unzip -o agent-app.zip -d /tmp/agent-app-extract
```

- `-o`: `overwrite`, 기존 파일이 있으면 덮어쓴다.
- `-d`: `directory`, 압축 해제 대상 디렉터리를 지정한다.

제공 앱 압축 파일 구조를 확인하고 실행 파일을 꺼낼 때 사용한다.

### `basename`

이름 풀이: 경로에서 기본 파일명만 가져온다는 의미다.

전체 경로에서 마지막 파일명만 출력한다.

```bash
basename /var/log/agent-app/monitor.log
```

아카이브 스크립트에서 원래 파일명은 유지하고 디렉터리만 바꿀 때 사용한다.

### `dirname`

이름 풀이: 경로에서 디렉터리 이름을 가져온다는 의미다.

전체 경로에서 부모 디렉터리만 출력한다.

```bash
dirname /home/agent-admin/agent-app/api_keys/t_secret.key
```

키 파일 경로에서 `api_keys` 디렉터리를 계산할 때 사용한다.

### `touch`

이름 풀이: 파일을 건드려 생성하거나 시간을 바꾼다는 의미다.

빈 파일을 만들거나 파일 수정 시간을 변경한다.

```bash
touch -d '8 days ago' /tmp/agent-log-test/old.log
```

아카이브 스크립트 검증에서 오래된 로그 파일을 만들 때 사용한다.

### `find`

이름 풀이: 조건에 맞는 파일을 찾는다는 의미다.

디렉터리 아래에서 파일을 검색한다.

```bash
find /var/log/monitor/agent-app/archive -type f -name "*.gz" -ls
```

- `-maxdepth`: 탐색 깊이를 제한한다.
- `-type f`: 일반 파일만 찾는다.
- `-name`: 파일명 패턴을 지정한다.
- `-mtime`: 파일 수정 시간을 기준으로 찾는다.
- `-print0`: 파일명을 NUL 문자로 구분해 공백이 있는 파일명도 안전하게 처리한다.

보너스 아카이브 스크립트에서 7일 이상 지난 로그와 30일 이상 지난 압축 파일을 찾을 때 사용한다.

### `gzip`

약어 풀이: `GNU zip`

파일을 gzip 형식으로 압축한다.

```bash
gzip -c /var/log/agent-app/monitor.log > /tmp/monitor.log.gz
```

- `-c`: 압축 결과를 파일에 바로 쓰지 않고 표준 출력으로 보낸다.

원본 로그를 보존하면서 압축본을 만들 때 사용한다.

### `mv`

약어 풀이: `move`

파일을 이동하거나 이름을 바꾼다.

```bash
mv monitor.log.20260531153010.gz /var/log/monitor/agent-app/archive/
```

압축된 로그를 아카이브 디렉터리로 옮길 때 사용한다.

### `rm`

약어 풀이: `remove`

파일을 삭제한다.

```bash
rm -f /var/log/monitor/agent-app/archive/old.log.gz
```

- `-f`: `force`, 파일이 없어도 오류를 출력하지 않는다.

삭제 대상 경로를 잘못 잡으면 위험하므로, 운영 스크립트에서는 `find` 조건과 변수를 먼저 검토해야 한다.

## SSH, 패키지, 로그 관리 명령어

### `apt`

약어 풀이: `advanced package tool`

Ubuntu에서 패키지를 설치하거나 업데이트한다.

```bash
sudo apt update
sudo apt install -y openssh-server ufw logrotate cron acl
```

- `update`: 패키지 목록을 갱신한다.
- `install`: 패키지를 설치한다.
- `-y`: 질문에 자동으로 yes를 선택한다.

Linux 전용 명령이므로 macOS Terminal이 아니라 Ubuntu 환경에서 실행한다.

### `sshd`

약어 풀이: `secure shell daemon`

SSH 서버 데몬이다.

```bash
sudo sshd -t
sudo sshd -T | grep -E '^(port|permitrootlogin)'
```

- `-t`: 설정 파일 문법을 검사한다.
- `-T`: 실제 적용될 설정값을 출력한다.

SSH 포트를 바꾸기 전에 설정 오류로 원격 접속이 끊기지 않도록 먼저 확인한다.

### `logrotate`

이름 풀이: 로그를 회전시킨다는 의미다.

로그 파일 크기와 보관 개수를 관리한다.

```bash
sudo logrotate -d /etc/logrotate.d/agent-app-monitor
```

- `-d`: `debug`, 실제 회전은 하지 않고 설정 해석 결과만 보여준다.

B1-1에서는 `monitor.log`를 10MB 기준으로 회전하고 최대 10개까지 보관하는 데 사용한다.

### `firewall-cmd`

이름 풀이: firewalld를 제어하는 command라는 의미다.

firewalld 방화벽 상태와 규칙을 확인한다.

```bash
sudo firewall-cmd --list-all
firewall-cmd --state
```

B1-1 기본 선택은 UFW지만, UFW가 없는 Linux 환경에서는 firewalld 확인에 사용할 수 있다.

### `nano`

이름 풀이: 터미널에서 쓰는 간단한 텍스트 편집기 이름이다.

설정 파일을 직접 편집한다.

```bash
sudo nano /etc/ssh/sshd_config
```

SSH 설정처럼 시스템 파일을 수정할 때 사용한다. 수정 전에는 백업 파일을 만들어 두는 것이 안전하다.

## Git 확인 명령어

### `git status`

이름 풀이: Git 작업 상태를 보여준다는 의미다.

수정, 추가, 삭제된 파일을 확인한다.

```bash
git status
git status --short
```

작업 전후에 예상하지 않은 파일을 건드리지 않았는지 확인할 때 사용한다.

### `git diff`

이름 풀이: 차이를 보여준다는 의미다.

수정된 내용을 비교한다.

```bash
git diff
git diff --check
```

- `--check`: 공백 오류나 충돌 표시 같은 기본 문제를 확인한다.

커밋하기 전에 변경 범위를 검토할 때 사용한다.

## 시스템과 바이너리 확인 명령어

### `uname`

약어 풀이: `unix name`

커널과 시스템 정보를 출력한다.

```bash
uname -a
```

- `-a`: `all`, 가능한 시스템 정보를 모두 출력한다.

macOS에서 실행 중인지, Ubuntu VM에서 실행 중인지 구분할 때 참고한다.

### `hostname`

이름 풀이: 현재 시스템의 호스트 이름을 보여준다는 의미다.

```bash
hostname
```

OrbStack Ubuntu Machine이 의도한 실습 환경인지 확인할 때 사용한다.

### `ip`

이름 풀이: Linux 네트워크 주소와 라우팅 정보를 확인하는 명령이다.

```bash
ip addr
```

현재 Linux 환경의 네트워크 인터페이스와 IP 주소를 확인한다.

### `file`

이름 풀이: 파일 종류를 판별한다는 의미다.

파일 형식과 바이너리 아키텍처를 확인한다.

```bash
file /tmp/agent-app-extract/agent-app-linux-x86
file /tmp/agent-app-extract/agent-app-linux-arm64
```

제공 앱 중 현재 CPU 아키텍처에 맞는 실행 파일을 고를 때 사용한다.

### `ldd`

약어 풀이: `list dynamic dependencies`

실행 파일이 필요로 하는 공유 라이브러리를 확인한다.

```bash
ldd --version
ldd /home/agent-admin/agent-app/agent-app
```

`GLIBC_2.38 not found` 같은 오류가 날 때 Ubuntu 버전과 라이브러리 호환성을 확인하는 데 사용한다.

## 권한과 파일 작성 보조 명령어

### `setfacl`

약어 풀이: `set file access control list`

파일 또는 디렉터리에 ACL 권한을 설정한다.

```bash
sudo setfacl -m g:agent-core:--x /home/agent-admin
```

- `-m`: `modify`, ACL 항목을 추가하거나 수정한다.
- `g:agent-core:--x`: `agent-core` 그룹에 디렉터리 통과 권한만 준다.

상위 홈 디렉터리를 모두 열지 않고 `agent-core`가 하위 앱 경로로 들어갈 수 있게 할 때 사용한다.

### `tee`

이름 풀이: 출력을 화면과 파일 양쪽으로 나누는 T자 연결에서 온 이름이다.

표준 입력을 파일에 기록한다.

```bash
printf '%s\n' 'agent_api_key_test' | sudo tee /home/agent-admin/agent-app/api_keys/t_secret.key >/dev/null
```

`sudo` 권한으로 파일 내용을 쓸 때 redirection 권한 문제를 피할 수 있다. `>`는 현재 shell이 처리하지만, `tee`는 `sudo tee` 프로세스가 파일을 열기 때문이다.

### `sudo -u`

이름 풀이: `sudo`를 특정 사용자로 실행하는 옵션이다.

다른 사용자 권한으로 명령을 실행한다.

```bash
sudo -u agent-admin /home/agent-admin/agent-app/bin/monitor.sh
```

monitor.sh가 실제 cron 실행 계정인 `agent-admin`으로도 동작하는지 확인할 때 사용한다.

### `sudo -iu`

이름 풀이: `i`는 login shell, `u`는 user를 의미한다.

특정 사용자로 로그인한 것과 비슷한 환경을 만든다.

```bash
sudo -iu agent-admin
```

앱을 root가 아니라 `agent-admin` 계정으로 실행해야 할 때 사용한다.

### `journalctl`

이름 풀이: systemd journal 로그를 확인하는 명령이다.

서비스 로그를 조회한다.

```bash
sudo journalctl -u ssh --no-pager -n 50
```

- `-u`: `unit`, 특정 systemd 서비스 로그만 본다.
- `--no-pager`: 별도 pager 화면 없이 바로 출력한다.
- `-n`: 마지막 N줄만 출력한다.

SSH 서비스 재시작 실패 원인을 확인할 때 사용할 수 있다.
