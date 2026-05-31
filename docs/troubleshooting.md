# Troubleshooting Report

## Case 1: root로 앱 실행 실패

### 1. 증상

```text
Running as 'root' is forbidden
```

### 2. 원인 가설

앱이 root 권한 실행을 보안상 차단한다.

### 3. 확인 명령

```bash
whoami
id
```

### 4. 실제 원인

현재 사용자가 `root`였기 때문에 앱의 Boot Sequence 1단계에서 실패했다.

### 5. 해결 방법

```bash
sudo -iu agent-admin
cd "$AGENT_HOME"
./agent-app
```

### 6. 해결 결과

- Before: root 실행으로 실패
- After: `agent-admin` 실행으로 Boot Sequence 통과

### 7. 재발 방지

앱 실행 명령 앞에는 항상 `sudo -iu agent-admin`을 사용한다.

---

## Case 2: 15034 포트가 열리지 않음

### 1. 증상

```bash
ss -tulnp | grep 15034
```

결과가 없다.

### 2. 원인 가설

- 앱이 실행되지 않았다.
- `AGENT_PORT`가 잘못 설정됐다.
- 이미 다른 프로세스가 포트를 사용 중이다.
- 키 파일 또는 로그 권한 문제로 Boot Sequence가 중단됐다.

### 3. 확인 명령

```bash
ps -ef | grep '[a]gent-app'
env | grep '^AGENT_'
ss -tulnp | grep 15034 || true
ls -ld "$AGENT_KEY_PATH"
ls -l "$AGENT_KEY_PATH/secret.key"
ls -l "$AGENT_KEY_PATH/t_secret.key"
ls -ld "$AGENT_LOG_DIR"
```

### 4. 실제 원인

실습 후 실제 원인을 적는다.

### 5. 해결 방법

```bash
sudo -iu agent-admin
cd "$AGENT_HOME"
./agent-app
```

### 6. 해결 결과

- Before: `15034` LISTEN 없음
- After: `0.0.0.0:15034` LISTEN 확인

### 7. 재발 방지

앱 실행 전 환경 변수, 키 파일, 로그 권한을 먼저 확인한다.

---

## Case 3: Key Path Mismatch

### 1. 증상

```text
[2/5] Verifying Environment Variables     [FAIL]
   >>> Key Path Mismatch. Expected: /home/agent-admin/agent-app/api_keys
```

### 2. 원인 가설

`AGENT_KEY_PATH`가 키 디렉터리가 아니라 키 파일 전체 경로로 설정됐다.

### 3. 확인 명령

```bash
sudo -iu agent-admin
echo "$AGENT_KEY_PATH"
ls -ld "$AGENT_KEY_PATH"
ls -l "$AGENT_KEY_PATH/secret.key"
ls -l "$AGENT_KEY_PATH/t_secret.key"
```

### 4. 실제 원인

제공 앱은 `AGENT_KEY_PATH=/home/agent-admin/agent-app/api_keys`를 기대한다.

### 5. 해결 방법

```bash
sudo -iu agent-admin
sed -i 's#^export AGENT_KEY_PATH=.*#export AGENT_KEY_PATH=$AGENT_HOME/api_keys#' ~/.profile
source ~/.profile
echo "$AGENT_KEY_PATH"
cat "$AGENT_KEY_PATH/secret.key"
cat "$AGENT_KEY_PATH/t_secret.key"
```

### 6. 해결 결과

- Before: Boot Sequence 2단계에서 `Key Path Mismatch`
- After: 환경 변수 검증 단계 `[OK]`

### 7. 재발 방지

`AGENT_KEY_PATH`는 디렉터리 경로로 두고, 앱 실행용 키 파일은 `$AGENT_KEY_PATH/secret.key`로 확인한다.

---

## Case 4: Missing File secret.key

### 1. 증상

```text
[3/5] Checking Required Files             [FAIL]
   >>> Missing File: secret.key
   >>>    (Expected location: /home/agent-admin/agent-app/api_keys/secret.key)
```

### 2. 원인 가설

키 디렉터리는 맞지만 앱 실행용 키 파일명인 `secret.key`가 없다.

### 3. 확인 명령

```bash
sudo -iu agent-admin
echo "$AGENT_KEY_PATH"
ls -ld "$AGENT_KEY_PATH"
ls -l "$AGENT_KEY_PATH/secret.key"
cat "$AGENT_KEY_PATH/secret.key"
```

### 4. 실제 원인

미션 문서 기준의 `t_secret.key`만 만들고, 제공 앱이 실제로 검사하는 `secret.key`를 만들지 않았다.

### 5. 해결 방법

```bash
sudo install -o agent-admin -g agent-core -m 0640 /dev/null /home/agent-admin/agent-app/api_keys/secret.key
printf '%s\n' 'agent_api_key_test' | sudo tee /home/agent-admin/agent-app/api_keys/secret.key >/dev/null
sudo chown agent-admin:agent-core /home/agent-admin/agent-app/api_keys/secret.key
sudo chmod 640 /home/agent-admin/agent-app/api_keys/secret.key
sudo -u agent-admin cat /home/agent-admin/agent-app/api_keys/secret.key
```

### 6. 해결 결과

- Before: Boot Sequence 3단계에서 `Missing File: secret.key`
- After: 필수 파일 검증 단계 `[OK]`

### 7. 재발 방지

`scripts/setup-dirs.sh`로 `secret.key`와 `t_secret.key`를 모두 생성한다.

---

## Case 5: cron에서는 실패하지만 직접 실행은 성공

### 1. 증상

직접 실행:

```bash
sudo -u agent-admin /home/agent-admin/agent-app/bin/monitor.sh
```

성공하지만 cron에서는 `monitor.log`가 증가하지 않는다.

### 2. 원인 가설

- cron 환경 변수 부족
- PATH 차이
- monitor.sh 실행 권한 부족
- `/var/log/agent-app` 쓰기 권한 부족

### 3. 확인 명령

```bash
sudo crontab -u agent-admin -l
tail -n 20 /var/log/agent-app/cron.log
ls -l /home/agent-admin/agent-app/bin/monitor.sh
ls -ld /var/log/agent-app
```

### 4. 실제 원인

실습 후 실제 원인을 적는다.

### 5. 해결 방법

```bash
sudo chown agent-dev:agent-core /home/agent-admin/agent-app/bin/monitor.sh
sudo chmod 750 /home/agent-admin/agent-app/bin/monitor.sh
sudo bash scripts/install-cron.sh
```

### 6. 해결 결과

- Before: cron 실행 로그 없음
- After: 1분 뒤 `monitor.log` 라인 수 증가

### 7. 재발 방지

cron 명령에는 절대 경로를 사용하고 stdout/stderr를 `cron.log`에 남긴다.

---

## Case 6: monitor.log 권한 오류

### 1. 증상

```text
[ERROR] Log directory is not writable: /var/log/agent-app
```

### 2. 원인 가설

`agent-admin`이 `/var/log/agent-app`에 쓸 권한이 없다.

### 3. 확인 명령

```bash
id agent-admin
ls -ld /var/log/agent-app
getfacl /var/log/agent-app
```

### 4. 실제 원인

실습 후 실제 원인을 적는다.

### 5. 해결 방법

```bash
sudo chown agent-admin:agent-core /var/log/agent-app
sudo chmod 2770 /var/log/agent-app
```

### 6. 해결 결과

- Before: 로그 append 실패
- After: `/var/log/agent-app/monitor.log` 생성 및 누적

### 7. 재발 방지

로그 디렉터리는 `agent-core` 그룹 쓰기 권한을 유지한다.

---

## Case 7: monitor.sh 리소스 수집 실패

### 1. 증상

```text
[ERROR] Failed to collect resource usage
```

### 2. 원인 가설

`ps` 출력 필드명이 현재 Ubuntu 환경과 맞지 않거나, 운영 위치의 `monitor.sh`가 최신 버전이 아니다.

### 3. 확인 명령

```bash
ps -p <PID> -o %cpu=,%mem=
df -P /
ls -l /home/agent-admin/agent-app/bin/monitor.sh
```

### 4. 실제 원인

`ps -p "$PID" -o %cpu=,%mem=` 출력에서 첫 번째 필드는 CPU, 두 번째 필드는 MEM으로 파싱해야 한다.

### 5. 해결 방법

```bash
cd ~/basic/b1-1
sudo install -o agent-dev -g agent-core -m 0750 bin/monitor.sh /home/agent-admin/agent-app/bin/monitor.sh
bash -n /home/agent-admin/agent-app/bin/monitor.sh
sudo -u agent-admin /home/agent-admin/agent-app/bin/monitor.sh
```

### 6. 해결 결과

- Before: 리소스 수집 실패
- After: CPU/MEM/DISK_USED 출력 및 `monitor.log` 누적

### 7. 재발 방지

저장소의 `bin/monitor.sh`를 수정한 뒤에는 운영 위치인 `/home/agent-admin/agent-app/bin/monitor.sh`로 다시 복사한다.

---

## Case 8: monitor.log 읽기 Permission denied

### 1. 증상

```text
tail: cannot open '/var/log/agent-app/monitor.log' for reading: Permission denied
```

### 2. 원인 가설

현재 로그인 계정이 `agent-core` 그룹에 없어서 `/var/log/agent-app` 내부 로그를 읽을 수 없다.

### 3. 확인 명령

```bash
id
ls -ld /var/log/agent-app
ls -l /var/log/agent-app/monitor.log
```

### 4. 실제 원인

`/var/log/agent-app`는 미션 보안 정책에 따라 `agent-core` 그룹만 접근하도록 제한한다.

### 5. 해결 방법

```bash
sudo tail -n 5 /var/log/agent-app/monitor.log
```

### 6. 해결 결과

- Before: 일반 계정에서 로그 읽기 실패
- After: `sudo tail`로 로그 증빙 확인

### 7. 재발 방지

검증 문서의 로그 확인 명령은 `sudo tail`, `sudo wc`로 작성한다.

---

## Case 9: GLIBC 오류

### 1. 증상

```text
GLIBC_2.38 not found
```

### 2. 원인 가설

실행 파일이 현재 Ubuntu 24.04 VM의 glibc와 맞지 않을 수 있다.

### 3. 확인 명령

```bash
ldd --version
cat /etc/os-release
file /home/agent-admin/agent-app/agent-app
```

### 4. 실제 원인

`codyssey-b1-1-ubuntu24`의 glibc 버전 또는 앱 바이너리 아키텍처가 제공 앱 요구사항과 맞지 않을 수 있다.

### 5. 해결 방법

`codyssey-b1-1-ubuntu24`에서 `ldd --version`, `cat /etc/os-release`, `file /home/agent-admin/agent-app/agent-app`를 확인하고, 제공 앱이 Ubuntu 24.04용 바이너리인지 점검한다.

### 6. 해결 결과

- Before: glibc 버전 오류
- After: Ubuntu 24.04 VM에서 앱 실행 성공 여부 확인

### 7. 재발 방지

바이너리 제공 앱은 OS/아키텍처 호환성을 먼저 확인한다.
