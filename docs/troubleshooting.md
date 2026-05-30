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
ls -l "$AGENT_KEY_PATH"
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

## Case 3: cron에서는 실패하지만 직접 실행은 성공

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

## Case 4: monitor.log 권한 오류

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

## Case 5: GLIBC 오류

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
