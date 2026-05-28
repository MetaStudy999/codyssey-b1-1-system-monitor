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
tail -n 5 /var/log/agent-app/monitor.log
```

- `-n`: `number`, 출력할 줄 수를 지정한다.

최근 로그를 확인할 때 사용한다.

### `wc`

약어 풀이: `word count`

줄 수, 단어 수, 바이트 수를 계산한다.

```bash
wc -l /var/log/agent-app/monitor.log
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

OrbStack Ubuntu Machine에서는 사용할 수 있지만, Docker 컨테이너에서는 제한될 수 있다.

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
