# Verification Log

이 문서는 평가자가 실행할 검증 명령과 기대 결과를 모은 것이다. `sudo`가 필요한 명령은 OrbStack Ubuntu에서 직접 실행한다.

## 1. 시스템 환경 확인

```bash
cat /etc/os-release
uname -a
uname -m
whoami
id
hostname
ip addr
```

기대 결과:

```text
Ubuntu 22.04 또는 Ubuntu 24.04
현재 사용자와 네트워크 정보 확인 가능
```

## 2. SSH 설정 확인

```bash
sudo grep -E '^(Port|PermitRootLogin)' /etc/ssh/sshd_config
sudo ss -tulnp | grep ssh
```

기대 결과:

```text
Port 20022
PermitRootLogin no
sshd가 20022에서 LISTEN
```

## 3. 방화벽 확인

```bash
sudo ufw status verbose
sudo ufw status numbered
```

기대 결과:

```text
Status: active
20022/tcp ALLOW
15034/tcp ALLOW
```

## 4. 계정/그룹 확인

```bash
id agent-admin
id agent-dev
id agent-test
getent group agent-common
getent group agent-core
```

기대 결과:

```text
agent-common: agent-admin, agent-dev, agent-test
agent-core: agent-admin, agent-dev
```

## 5. 디렉터리 권한 확인

```bash
export AGENT_HOME=/home/agent-admin/agent-app
ls -ld "$AGENT_HOME"
ls -ld "$AGENT_HOME/upload_files"
ls -ld "$AGENT_HOME/api_keys"
ls -ld "$AGENT_HOME/bin"
ls -ld /var/log/agent-app
getfacl "$AGENT_HOME/upload_files"
getfacl "$AGENT_HOME/api_keys"
getfacl /var/log/agent-app
```

기대 결과:

```text
upload_files group: agent-common
api_keys group: agent-core
/var/log/agent-app group: agent-core
```

## 6. 환경 변수와 키 파일 확인

```bash
sudo -iu agent-admin env | grep '^AGENT_'
sudo -u agent-admin cat /home/agent-admin/agent-app/api_keys/t_secret.key
```

기대 결과:

```text
AGENT_HOME=/home/agent-admin/agent-app
AGENT_PORT=15034
agent_api_key_test
```

## 7. 앱 실행 확인

```bash
ps -ef | grep '[a]gent-app'
ss -tulnp | grep 15034
curl http://localhost:15034
```

기대 결과:

```text
Agent READY 출력 확인
0.0.0.0:15034 LISTEN
curl 응답 확인
```

## 8. monitor.sh 확인

```bash
export AGENT_HOME=/home/agent-admin/agent-app
bash -n "$AGENT_HOME/bin/monitor.sh"
sudo -u agent-admin "$AGENT_HOME/bin/monitor.sh"
tail -n 5 /var/log/agent-app/monitor.log
```

기대 결과:

```text
프로세스 OK
포트 OK
CPU/MEM/DISK 출력
monitor.log에 지정 포맷 append
```

## 9. cron 확인

```bash
sudo crontab -u agent-admin -l
wc -l /var/log/agent-app/monitor.log
sleep 70
wc -l /var/log/agent-app/monitor.log
tail -n 10 /var/log/agent-app/cron.log
```

기대 결과:

```text
매분 실행 항목 존재
1분 뒤 monitor.log 라인 수 증가
```

## 10. logrotate 확인

```bash
sudo cat /etc/logrotate.d/agent-app-monitor
sudo logrotate -d /etc/logrotate.d/agent-app-monitor
```

기대 결과:

```text
size 10M
rotate 10
missingok
notifempty
copytruncate
```

## 11. 보너스 report.sh 확인

```bash
export AGENT_HOME=/home/agent-admin/agent-app
bash -n "$AGENT_HOME/bin/report.sh"
sudo -u agent-admin "$AGENT_HOME/bin/report.sh"
```

기대 결과:

```text
Samples
CPU Average/Maximum/Minimum
MEM Average/Maximum/Minimum
DISK_USED Average/Maximum/Minimum
```

## 12. 보너스 archive-old-logs.sh 확인

```bash
bash -n scripts/archive-old-logs.sh
sudo bash scripts/archive-old-logs.sh
find /var/log/monitor/agent-app/archive -type f -name "*.gz" -ls
```

기대 결과:

```text
대상 파일이 없어도 INFO 메시지 후 안전 종료
archive 디렉터리 확인 가능
```

## 13. macOS 정적 검증

```bash
pwd
ls -la
find . -maxdepth 3 -type f | sort
bash -n scripts/setup-users.sh
bash -n scripts/setup-dirs.sh
bash -n scripts/setup-firewall-ufw.sh
bash -n scripts/setup-logrotate.sh
bash -n scripts/install-cron.sh
bash -n scripts/archive-old-logs.sh
bash -n bin/monitor.sh
bash -n bin/report.sh
git status
```
