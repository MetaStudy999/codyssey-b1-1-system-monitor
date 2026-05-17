# Part 1. B1-1 평가 제출편

## 1. 실습 환경 구축

```
1. 실습 환경 구축
├── 1.1 실습 환경 선택 기준
│   ├── macOS + OrbStack
│   ├── Windows + WSL2
│   ├── VM Ubuntu
│   ├── 클라우드 Ubuntu
│   └── 최종 선택 환경과 이유
│
├── 1.2 macOS + OrbStack Ubuntu 구성
├── 1.3 Windows + WSL2 Ubuntu 구성
├── 1.4 VM Ubuntu 구성
├── 1.5 클라우드 Ubuntu 구성
├── 1.6 공통 필수 패키지 설치
│   ├── openssh-server
│   ├── ufw 또는 firewalld
│   ├── acl
│   ├── cron
│   ├── python3
│   ├── curl
│   ├── git
│   ├── iproute2
│   └── net-tools
│
├── 1.7 초기 환경 점검 및 증거 기록
│   ├── cat /etc/os-release
│   ├── uname -a
│   ├── whoami
│   ├── id
│   ├── ip addr
│   ├── systemctl status ssh
│   ├── systemctl status cron
│   ├── ufw status 또는 firewall-cmd --list-all
│   └── ss -tulnp
│
├── 1.8 환경별 대체 방안
└── 1.9 환경 구축 명령어 실행 구조
    ├── 목적
    ├── 실행 순서
    ├── 핵심 명령어와 설명
    ├── 기대 결과
    └── 증거: evidence/00-environment.txt
```

---

## 2. 보안·네트워크 설정

```
2. 보안·네트워크 설정
├── 2.1 서버 보안 기본 개념
│   ├── 공격 표면 최소화
│   ├── 기본 포트 사용 위험
│   ├── Root 직접 접속 위험
│   └── 필요한 포트만 허용하는 원칙
│
├── 2.2 SSH 설정 백업과 복구 계획
│   ├── sshd_config 백업
│   ├── 변경 전 설정 기록
│   ├── 20022/tcp 방화벽 선허용
│   ├── 기존 SSH 세션 유지
│   ├── 새 터미널에서 20022 접속 검증
│   ├── 변경 후 검증
│   └── 접속 실패 시 복구 절차
│
├── 2.3 SSH 포트 20022 변경
├── 2.4 Root 원격 접속 차단
├── 2.5 방화벽 설정
│   ├── UFW 또는 firewalld 선택
│   ├── 20022/tcp 허용
│   ├── 15034/tcp 허용
│   ├── 그 외 인바운드 차단
│   └── 방화벽 상태 증거 캡처
│
├── 2.6 sudo 사용 원칙
│   ├── 시스템 설정에만 sudo 사용
│   ├── 앱 실행은 일반 계정으로 수행
│   ├── monitor.sh는 agent-admin이 실행
│   ├── 불필요한 root 실행 금지
│   ├── sudo 사용 명령어와 이유 기록
│   └── evidence에 실행 계정 정보 포함
│
├── 2.7 위협 모델 기반 보안 설명
│   ├── SSH 22번 포트 자동 스캔
│   ├── Root 계정 무차별 대입 공격
│   ├── 불필요 포트 노출
│   ├── 키 파일 접근 권한 과다
│   ├── 로그 파일 임의 수정·삭제
│   ├── Docker 이미지에 민감정보가 포함되는 위험
│   └── 위협별 대응 설정 매핑표
│
├── 2.8 보안 설정 명령어 실행 구조
│   ├── 목적
│   ├── 실행 순서
│   ├── 핵심 명령어와 설명
│   ├── 기대 결과
│   ├── 실패 시 확인 명령
│   └── 증거: evidence/01-ssh-config.txt, evidence/02-firewall-status.txt
│
└── 2.9 보안 기준선 자동 점검
    ├── bin/security_check.sh
    ├── SSH 설정 점검
    ├── 방화벽 점검
    ├── 권한 점검
    ├── 키 파일 권한 점검
    ├── 로그 디렉토리 권한 점검
    └── 증거: evidence/17-security-baseline-check.txt
```

---

## 3. 계정·그룹·권한 체계 구성

```
3. 계정·그룹·권한 체계 구성
├── 3.1 최소 권한 원칙
├── 3.2 사용자 계정 생성
│   ├── agent-admin: 운영/관리, cron 실행자
│   ├── agent-dev: 개발/운영, monitor.sh 작성자
│   └── agent-test: QA/테스트
│
├── 3.3 그룹 생성
│   ├── agent-common: admin/dev/test
│   └── agent-core: admin/dev
│
├── 3.4 계정별 그룹 배정
├── 3.5 디렉토리 구조 생성
│   ├── $AGENT_HOME
│   ├── $AGENT_HOME/upload_files
│   ├── $AGENT_HOME/api_keys
│   ├── $AGENT_HOME/bin
│   └── /var/log/agent-app
│
├── 3.6 디렉토리 권한 정책
│   ├── upload_files: agent-common R/W
│   ├── api_keys: agent-core ONLY R/W
│   └── /var/log/agent-app: agent-core ONLY R/W
│
├── 3.7 ACL 적용 및 검증
├── 3.8 권한 정책 설명
└── 3.9 계정·그룹·권한 명령어 실행 구조
    ├── 목적
    ├── 실행 순서
    ├── 핵심 명령어와 설명
    ├── 기대 결과
    └── 증거: evidence/03-users-groups.txt, evidence/04-permissions-acl.txt
```

---

## 4. 애플리케이션 실행 환경 구성

```
4. 애플리케이션 실행 환경 구성
├── 4.1 제공 Python 앱 역할 이해
│   ├── 제공 앱은 실행 대상
│   ├── 과제 핵심은 관제·자동화
│   └── 앱 수정 최소화 원칙
│
├── 4.2 제공 앱 원본 보존 원칙
│   ├── 제공 앱은 원칙적으로 수정하지 않음
│   ├── 수정이 필요한 경우 사유와 변경 내역 기록
│   ├── 원본 파일과 수정 파일 구분
│   ├── 앱 실행 로그만 evidence로 보관
│   └── README에 앱 원본 보존 여부 명시
│
├── 4.3 Root 실행 금지
├── 4.4 환경 변수 설정
│   ├── AGENT_HOME
│   ├── AGENT_PORT=15034
│   ├── AGENT_UPLOAD_DIR
│   ├── AGENT_KEY_PATH
│   └── AGENT_LOG_DIR
│
├── 4.5 키 파일 생성 및 보호
│   ├── t_secret.key 생성
│   ├── agent_api_key_test 입력
│   ├── 키 파일 권한 제한
│   └── GitHub 업로드 전 민감정보 점검
│
├── 4.6 앱 실행 검증
│   ├── Boot Sequence 5단계 [OK]
│   ├── Agent READY 출력
│   ├── 0.0.0.0:15034 LISTEN 확인
│   └── curl 또는 ss로 검증
│
├── 4.7 관제 기준값 정리
└── 4.8 앱 실행 명령어 실행 구조
    ├── 목적
    ├── 실행 순서
    ├── 핵심 명령어와 설명
    ├── 기대 결과
    └── 증거: evidence/05-env-vars.txt, evidence/06-app-ready.txt, evidence/07-port-15034-listen.txt
```

---

## 5. `monitor.sh` 시스템 관제 자동화 스크립트 구현

```
5. monitor.sh 시스템 관제 자동화 스크립트 구현
├── 5.1 monitor.sh 요구사항 분석
├── 5.2 Bash 구현 제약
│   ├── monitor.sh는 Bash로 작성
│   ├── Python / Node.js / Go 등으로 대체하지 않음
│   ├── report.sh도 Bash 기준으로 작성
│   ├── log_retention.sh도 Bash 기준으로 작성
│   ├── Bash 사용 이유 설명
│   └── ShellCheck로 Bash 스크립트 정적 점검
│
├── 5.3 파일 위치와 권한
│   ├── $AGENT_HOME/bin/monitor.sh
│   ├── owner: agent-dev
│   ├── group: agent-core
│   └── mode: 750
│
├── 5.4 Bash 기본 구조
├── 5.5 프로세스 식별 로직
├── 5.6 포트 확인 로직
├── 5.7 방화벽 상태 점검
├── 5.8 CPU / MEM / DISK 수집과 파싱
├── 5.9 임계값 경고 정책
│   ├── CPU > 20%: WARNING
│   ├── MEM > 10%: WARNING
│   └── DISK_USED > 80%: WARNING
│
├── 5.10 로그 기록
├── 5.11 정상 실행 검증
├── 5.12 실패 케이스 검증
├── 5.13 monitor.sh 실행 구조와 명령어 설명
│   ├── 실행 흐름
│   ├── 핵심 명령어와 설명
│   ├── 명령어 선택 이유
│   ├── 정상 실행 순서
│   ├── 실패 실행 순서
│   └── 증거: evidence/08-monitor-success.txt, evidence/09-monitor-fail-exit1.txt
│
└── 5.14 스크립트 보안 원칙
    ├── set -euo pipefail
    ├── 변수 quote 처리
    ├── 절대경로 사용
    ├── 입력값 검증
    ├── eval 사용 금지
    ├── rm/find 안전장치
    ├── 민감정보 하드코딩 금지
    ├── 로그 secret 마스킹
    ├── 종료 코드 표준화
    ├── ShellCheck 검사
    └── chmod 750 유지
```

---

## 6. 로그 관리 및 용량 관리

```
6. 로그 관리 및 용량 관리
├── 6.1 로그 운영 원칙
├── 6.2 monitor.log 누적 및 포맷 검증
│   └── [YYYY-MM-DD HH:MM:SS] PID:... CPU:..% MEM:..% DISK_USED:..%
│
├── 6.3 용량 기반 로그 관리
│   ├── 10MB 기준
│   ├── 최대 10개 파일 유지
│   ├── logrotate 방식
│   └── Bash 스크립트 방식
│
├── 6.4 로그 용량 관리 동작 검증
├── 6.5 로그 급증 대응 전략
├── 6.6 로그 관리 결과 문서화
└── 6.7 로그 관리 명령어 실행 구조
    ├── 목적
    ├── 실행 순서
    ├── 핵심 명령어와 설명
    ├── 기대 결과
    └── 증거: evidence/10-monitor-log-format.txt, evidence/12-log-rotation.txt
```

---

## 7. cron 자동 실행 설정

```
7. cron 자동 실행 설정
├── 7.1 cron 개념
├── 7.2 agent-admin crontab 등록
├── 7.3 cron 실행 권한 검증
├── 7.4 cron 자동 증가 검증
│   ├── 등록 전 monitor.log 라인 수 확인
│   ├── 1~2분 후 라인 수 증가 확인
│   └── cron 실행 로그 확인
│
├── 7.5 cron 실패 대응
├── 7.6 Docker 환경에서 cron 실행 방식
└── 7.7 cron 실행 구조와 명령어 설명
    ├── 목적
    ├── 실행 순서
    ├── 핵심 명령어와 설명
    ├── 기대 결과
    └── 증거: evidence/11-cron-log-growth.txt
```

---

## 8. 보너스 과제

```
8. 보너스 과제
├── 8.1 report.sh 요약 리포트 자동 생성
│   ├── report.sh 목적
│   ├── CPU/MEM/DISK 평균·최대·최소
│   ├── 샘플 수 출력
│   ├── 시작/종료 시간 구간 분석
│   ├── 예외 처리
│   └── 실행 검증
│
├── 8.2 시간 기반 로그 보존 정책
│   ├── 7일 경과 로그 압축
│   ├── /var/log/monitor/agent-app/archive/ 이동
│   ├── 30일 경과 .gz 삭제
│   ├── 디렉토리 미존재 예외 처리
│   ├── 권한 부족 예외 처리
│   └── 대상 파일 0개 예외 처리
│
├── 8.3 보너스 명령어 실행 구조
└── 8.4 보너스 크레딧 대응
```

---

## 9. evidence 정리

```
9. evidence 정리
├── 9.1 evidence 폴더 목적
├── 9.2 필수 증거 파일
│   ├── 00-environment.txt
│   ├── 01-ssh-config.txt
│   ├── 02-firewall-status.txt
│   ├── 03-users-groups.txt
│   ├── 04-permissions-acl.txt
│   ├── 05-env-vars.txt
│   ├── 06-app-ready.txt
│   ├── 07-port-15034-listen.txt
│   ├── 08-monitor-success.txt
│   ├── 09-monitor-fail-exit1.txt
│   ├── 10-monitor-log-format.txt
│   ├── 11-cron-log-growth.txt
│   └── 12-log-rotation.txt
│
├── 9.3 evidence 생성 예시
├── 9.4 명령어 → 기대 결과 → evidence 연결표
└── 9.5 참고 예시와 실제 제출 결과 구분
    ├── 미션 문서의 출력 예시는 정답 고정 형식이 아님
    ├── 실제 출력 문구가 달라도 요구 필드를 포함하면 인정 가능
    ├── 실제 결과는 evidence 기준으로 제출
    ├── README에 예시 출력과 실제 출력 구분 표시
    ├── screenshots는 참고 자료로 사용
    └── evidence/*.txt는 실제 검증 자료로 사용
```

---

## 10. 트러블슈팅

```
10. 트러블슈팅
├── 10.1 SSH 접속 실패
├── 10.2 방화벽 포트 차단
├── 10.3 권한 부족으로 앱 실행 실패
├── 10.4 환경 변수 누락
├── 10.5 키 파일 경로 오류
├── 10.6 15034 포트 충돌
├── 10.7 monitor.sh 실행 권한 오류
├── 10.8 cron에서만 실행 실패
├── 10.9 로그 파일 쓰기 실패
├── 10.10 로그 로테이션 실패
├── 10.11 Docker 빌드 실패
├── 10.12 Docker 컨테이너 포트 매핑 실패
├── 10.13 Docker volume 로그 기록 실패
├── 10.14 Docker 비-root 권한 문제
└── 10.15 공통 트러블슈팅 템플릿
```

---

## 11. 평가문항 대응

```
11. 평가문항 대응
├── 11.1 명령 선택 이유
├── 11.2 CPU / MEM / DISK 파싱 설명
├── 11.3 로그 포맷 설계 이유
├── 11.4 운영 판단 기준
├── 11.5 대상이 Nginx로 바뀌는 경우
├── 11.6 프로세스는 살아있는데 포트가 안 열리는 상황
├── 11.7 로그 급증·디스크 고갈 상황
├── 11.8 5분 기능 시연 순서
├── 11.9 보안·운영 원리 답변
├── 11.10 장애 시나리오 답변
└── 11.11 최종 자기 점검표
```

---

## 12. GitHub 제출 및 GitHub Flow

```
12. GitHub 제출 및 GitHub Flow
├── 12.1 README.md 작성
├── 12.2 SUBMISSION.md 작성
├── 12.3 요구사항 수행 내역서 작성
├── 12.4 평가문항 대응표 작성
├── 12.5 스크린샷 정리
├── 12.6 보안·민감정보 점검
├── 12.7 GitHub Repository 구성
├── 12.8 GitHub 초기 설정
├── 12.9 Git 원격 저장소 연결
├── 12.10 Git 커밋·푸시 이력 정리
├── 12.11 Default branch 확인
├── 12.12 GitHub 제출 링크 정리
├── 12.13 평가 전 최종 점검
├── 12.14 개발 보안 점검
├── 12.15 GitHub Flow 기반 작업 브랜치 전략
├── 12.16 장별 브랜치 운영 계획
└── 12.17 최종 진행순서와 GitHub Flow 실행 계획
```
