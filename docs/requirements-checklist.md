# B1-1 Requirements Checklist

| 구분 | 요구사항 | 구현/문서 위치 | 검증 명령 | 상태 |
|---|---|---|---|---|
| 필수 | SSH 포트 20022 | `docs/05-SSH-방화벽-설정.md` | `sudo grep -E '^(Port|PermitRootLogin)' /etc/ssh/sshd_config` | 준비 |
| 필수 | Root 원격 접속 차단 | `docs/05-SSH-방화벽-설정.md` | `sudo grep -E '^(Port|PermitRootLogin)' /etc/ssh/sshd_config` | 준비 |
| 필수 | UFW 방화벽 | `scripts/setup-firewall-ufw.sh` | `sudo ufw status verbose` | 준비 |
| 필수 | 20022/tcp, 15034/tcp만 허용 | `scripts/setup-firewall-ufw.sh` | `sudo ufw status numbered` | 준비 |
| 필수 | agent 계정/그룹 | `scripts/setup-users.sh` | `id`, `getent group` | 준비 |
| 필수 | 디렉터리 권한 | `scripts/setup-dirs.sh` | `ls -ld`, `getfacl` | 준비 |
| 필수 | 환경 변수 | `docs/06-환경변수-키파일-설정.md` | `env \| grep '^AGENT_'` | 준비 |
| 필수 | 키 파일 | `scripts/setup-dirs.sh` | `cat $AGENT_KEY_PATH` | 준비 |
| 필수 | 앱 일반 계정 실행 | `docs/07-agent-app-실행-검증.md` | `ps`, `ss`, `curl` | 준비 |
| 필수 | Boot Sequence 5단계 OK | `docs/07-agent-app-실행-검증.md` | 앱 실행 출력 | 준비 |
| 필수 | Agent READY | `docs/07-agent-app-실행-검증.md` | 앱 실행 출력 | 준비 |
| 필수 | 15034 LISTEN | `docs/07-agent-app-실행-검증.md` | `ss -tulnp \| grep 15034` | 준비 |
| 필수 | monitor.sh | `bin/monitor.sh` | `bash -n`, 직접 실행 | 준비 |
| 필수 | monitor.log append | `bin/monitor.sh` | `tail /var/log/agent-app/monitor.log` | 준비 |
| 필수 | cron 매분 실행 | `scripts/install-cron.sh` | `sudo crontab -u agent-admin -l` | 준비 |
| 필수 | 10MB/10개 로그 관리 | `scripts/setup-logrotate.sh` | `sudo logrotate -d ...` | 준비 |
| 보너스 | report.sh | `bin/report.sh` | `bash -n`, 직접 실행 | 준비 |
| 보너스 | 7일 로그 압축 | `scripts/archive-old-logs.sh` | `sudo bash scripts/archive-old-logs.sh` | 준비 |
| 보너스 | 30일 archive 삭제 | `scripts/archive-old-logs.sh` | `find /var/log/monitor/...` | 준비 |

## 상태 작성 기준

- `준비`: 문서와 스크립트가 준비됨
- `완료`: `codyssey-b1-1-ubuntu24`에서 직접 실행하고 증빙 확보함
- `미완료`: 아직 실행하지 않았거나 실패함
