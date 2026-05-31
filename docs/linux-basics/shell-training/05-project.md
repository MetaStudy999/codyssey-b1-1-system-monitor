# 프로젝트: B1-1 시스템 관제 자동화 완성하기

## 프로젝트 목표

입문, 기초, 심화, 응용 단계에서 익힌 내용을 하나로 묶어 B1-1 운영 자동화 프로젝트를 완성한다.

최종 결과는 다음을 만족해야 한다.

- Linux 운영 환경이 준비되어 있다.
- 사용자/그룹/디렉터리 권한이 역할 기준으로 설정되어 있다.
- 제공 앱이 일반 사용자로 실행된다.
- `monitor.sh`가 프로세스, 포트, 리소스를 관제한다.
- `monitor.log`가 append 방식으로 누적된다.
- cron이 매분 자동 실행한다.
- logrotate가 `10MB / 10개` 정책을 적용한다.
- 보너스로 `report.sh`와 로그 아카이브를 검증한다.

## 프로젝트 수행 순서

자세한 명령은 저장소의 단계별 문서를 따른다.

| 순서 | 문서 | 완료 기준 |
|---|---|---|
| 1 | `docs/01-환경준비.md` | Ubuntu VM과 필수 명령 확인 |
| 2 | `docs/02-계정-그룹-생성.md` | `agent-admin`, `agent-dev`, `agent-test` 생성 |
| 3 | `docs/03-디렉토리-권한-설정.md` | upload/key/log 권한 분리 |
| 4 | `docs/04-agent-app-압축해제와-배치.md` | 아키텍처에 맞는 앱 배치 |
| 5 | `docs/05-SSH-방화벽-설정.md` | SSH `20022`, 앱 `15034` 허용 |
| 6 | `docs/06-환경변수-키파일-설정.md` | AGENT 환경 변수와 테스트 키 확인 |
| 7 | `docs/07-agent-app-실행-검증.md` | Boot Sequence `[OK]`, `Agent READY` |
| 8 | `docs/08-monitor-sh-구현-검증.md` | `monitor.sh` 직접 실행 성공 |
| 9 | `docs/09-cron-자동실행.md` | cron 등록 후 로그 줄 수 증가 |
| 10 | `docs/10-logrotate-로그용량관리.md` | logrotate dry run 확인 |
| 11 | `docs/11-보너스-report-sh.md` | 통계 리포트 출력 |
| 12 | `docs/12-보너스-로그-아카이브.md` | 오래된 로그 압축/보관 검증 |

## 핵심 검증 명령

문법 검사:

```bash
bash -n scripts/setup-users.sh
bash -n scripts/setup-dirs.sh
bash -n scripts/setup-firewall-ufw.sh
bash -n scripts/setup-logrotate.sh
bash -n scripts/install-cron.sh
bash -n scripts/archive-old-logs.sh
bash -n bin/monitor.sh
bash -n bin/report.sh
```

계정/그룹:

```bash
id agent-admin
id agent-dev
id agent-test
getent group agent-common
getent group agent-core
```

권한:

```bash
ls -ld /home/agent-admin/agent-app
ls -ld /home/agent-admin/agent-app/upload_files
ls -ld /home/agent-admin/agent-app/api_keys
ls -ld /var/log/agent-app
```

앱과 관제:

```bash
ps -ef | grep '[a]gent-app'
ss -tulnp | grep 15034
sudo -u agent-admin /home/agent-admin/agent-app/bin/monitor.sh
sudo tail -n 5 /var/log/agent-app/monitor.log
```

cron:

```bash
sudo crontab -u agent-admin -l
sudo wc -l /var/log/agent-app/monitor.log
sleep 70
sudo wc -l /var/log/agent-app/monitor.log
```

보너스:

```bash
sudo -u agent-admin /home/agent-admin/agent-app/bin/report.sh
sudo scripts/archive-old-logs.sh
find /var/log/monitor/agent-app/archive -type f -name '*.gz' -ls
```

## 제출 문제

다음 질문에 답을 작성한다.

1. 왜 앱을 root가 아니라 `agent-admin`으로 실행해야 하는가?
2. 왜 `agent-common`과 `agent-core`를 나눴는가?
3. 왜 `upload_files`와 `api_keys`의 그룹 권한이 다른가?
4. 왜 `monitor.sh`는 프로세스와 포트를 모두 확인하는가?
5. 왜 방화벽 비활성은 WARNING이고, 포트 미LISTEN은 `exit 1`인가?
6. 왜 관제 로그는 `>`가 아니라 `>>`를 써야 하는가?
7. 왜 cron 실행 결과를 `cron.log`에 남기는가?
8. 왜 logrotate와 시간 기반 아카이브가 모두 유용한가?
9. `report.sh`가 평균 계산 시 0으로 나누는 오류를 어떻게 피하는가?
10. 장애 상황에서 `monitor.log`, `cron.log`, `ss`, `ps`를 어떤 순서로 확인할 것인가?

## 평가 루브릭

| 항목 | 좋음 | 보완 필요 |
|---|---|---|
| 재현성 | 문서 명령만으로 검증 가능 | 수동 추정이 많음 |
| 보안 | 최소 권한과 root 실행 금지 설명 가능 | 권한 이유가 불명확 |
| 스크립트 품질 | 문법 검사, 예외 처리, 멱등성 반영 | 재실행 시 상태가 꼬임 |
| 관제 기능 | 프로세스/포트/리소스/로그 확인 가능 | 일부 상태만 확인 |
| 로그 운영 | append, cron, logrotate, archive 설명 가능 | 로그 누적/보존 정책 누락 |
| 설명력 | 동료 평가 질문에 말로 답변 가능 | 명령만 실행하고 의미 설명 부족 |

## 최종 체크리스트

- [ ] `README.md` 요구사항 반영표가 최신이다.
- [ ] `docs/verification-log.md`에 실제 검증 명령과 결과가 있다.
- [ ] `docs/troubleshooting.md`에 문제 해결 사례가 있다.
- [ ] `bin/monitor.sh`와 `bin/report.sh`가 `bash -n`을 통과한다.
- [ ] `scripts/*.sh`가 `bash -n`을 통과한다.
- [ ] 민감정보가 커밋되지 않았다.
- [ ] `git status`로 변경 파일을 확인했다.
