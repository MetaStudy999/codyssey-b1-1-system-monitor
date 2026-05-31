# 리눅스 쉘 프로그램 따라하기 트레이닝 교재

## 교재 목표

이 교재는 B1-1 시스템 관제 자동화 미션을 바탕으로 Bash 쉘 프로그램을 단계적으로 익히기 위한 따라하기 자료다.

단순히 명령어를 외우는 것이 아니라, 실제 저장소에 구현된 스크립트를 읽고 작은 실습으로 다시 만들어 보면서 다음 능력을 기른다.

- Linux에서 안전하게 명령을 실행할 위치를 구분한다.
- Bash 스크립트의 기본 구조를 이해한다.
- 사용자, 그룹, 권한, 프로세스, 포트, 로그를 스크립트로 점검한다.
- `monitor.sh`, `report.sh`, `archive-old-logs.sh` 같은 운영 자동화 스크립트를 설명할 수 있다.
- 최종적으로 B1-1 관제 자동화 프로젝트를 재현하고 검증한다.

## 학습 환경 원칙

Linux 전용 실습은 OrbStack Ubuntu VM에서 수행한다.

```bash
pwd
ls -la
git status
```

사용자/그룹, 권한, SSH, 방화벽, cron, `/var/log` 작업은 macOS Terminal에서 직접 실행하지 않는다.

권장 실습 위치:

```bash
cd /Users/metastudy9997479/OrbStack/cds-ubuntu24/home/metastudy9997479/basic/b1-1
```

## 교재 구성

| 단계 | 문서 | 핵심 주제 | 현재 구현과 연결 |
|---|---|---|---|
| 입문 | `01-entry.md` | 셸, 스크립트, 변수, 실행 권한 | `pwd`, `ls`, `bash -n`, 환경 변수 |
| 기초 | `02-basic.md` | 조건문, 함수, 반복문, 인자 처리 | `setup-users.sh`, `setup-dirs.sh` |
| 심화 | `03-advanced.md` | 프로세스/포트/리소스 관제, 로그 append | `bin/monitor.sh` |
| 응용 | `04-application.md` | cron, logrotate, awk 통계, 아카이브 | `install-cron.sh`, `report.sh`, `archive-old-logs.sh` |
| 프로젝트 | `05-project.md` | B1-1 관제 자동화 완성 과제 | 전체 README와 docs 검증 흐름 |
| 문제 모음 | `06-problems.md` | 단계별 복습 문제와 제출 체크 | 전체 스크립트 |

## 현재 구현 파일 학습 지도

| 구현 파일 | 배울 수 있는 내용 |
|---|---|
| `scripts/setup-users.sh` | root 권한 검사, 멱등성, 배열, 반복문, 그룹 멤버십 |
| `scripts/setup-dirs.sh` | 경로 변수, `install -d`, 권한 모드, 테스트 키 생성, ACL 안내 |
| `scripts/setup-firewall-ufw.sh` | UFW 최소 허용 정책, SSH/앱 포트 제한 |
| `bin/monitor.sh` | Health Check, Warning Check, `ps`, `ss`, `df`, 로그 누적 |
| `scripts/install-cron.sh` | crontab 자동 등록, 중복 방지, stdout/stderr 누적 |
| `scripts/setup-logrotate.sh` | `10MB / 10개` 로그 보존 정책, logrotate 설정 생성 |
| `bin/report.sh` | `awk` 파싱, 평균/최대/최소 계산, 시간 범위 옵션 |
| `scripts/archive-old-logs.sh` | `find`, `gzip`, `mv`, 오래된 아카이브 삭제, 예외 처리 |

## 추천 학습 방법

1. 각 단계의 "따라하기"를 순서대로 실행한다.
2. 실행 전에는 항상 `bash -n`으로 문법을 확인한다.
3. 실습 스크립트는 먼저 `/tmp`나 홈 디렉터리에서 연습한다.
4. `sudo`가 필요한 명령은 문서의 의미를 이해한 뒤 Ubuntu VM에서만 실행한다.
5. 각 단계 마지막의 문제를 풀고, 답을 말로 설명해 본다.

## 완료 기준

- `01-entry.md`부터 `05-project.md`까지 따라하기를 완료했다.
- `06-problems.md`의 필수 문제를 풀었다.
- `bin/monitor.sh`가 왜 프로세스와 포트를 모두 확인하는지 설명할 수 있다.
- `report.sh`가 평균/최대/최소를 어떻게 계산하는지 설명할 수 있다.
- `cron`, `logrotate`, 로그 아카이브의 차이를 설명할 수 있다.
