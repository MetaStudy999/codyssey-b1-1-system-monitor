# Part 4. 반복 훈련편

## 20. B1-1 반복 훈련 커리큘럼

```
20. B1-1 반복 훈련 커리큘럼
├── 20.1 선수지식 체크리스트
│   ├── Linux 파일·디렉토리 구조
│   ├── 사용자·그룹·권한
│   ├── chmod / chown / chgrp
│   ├── ACL 기본
│   ├── SSH 기본 구조
│   ├── 방화벽 UFW / firewalld
│   ├── 프로세스와 PID
│   ├── 포트와 LISTEN 상태
│   ├── CPU / MEM / DISK 지표
│   ├── Bash 변수·조건문·함수
│   ├── 리다이렉션 > / >>
│   ├── cron 기본
│   └── Git branch / PR / merge
│
├── 20.2 단계별 훈련 로드맵
│   ├── Level 1: 명령어 이해
│   ├── Level 2: 요구사항 따라하기
│   ├── Level 3: 스크립트 직접 구현
│   ├── Level 4: 실패 상황 해결
│   ├── Level 5: evidence와 README 정리
│   ├── Level 6: GitHub Flow 적용
│   └── Level 7: 포트폴리오 확장
│
├── 20.3 명령어 반복 훈련
├── 20.4 장애 상황 재현 훈련
├── 20.5 보안 설정 반복 훈련
├── 20.6 monitor.sh 구현 반복 훈련
├── 20.7 cron·로그 자동화 반복 훈련
├── 20.8 GitHub Flow 반복 훈련
├── 20.9 구술 설명 훈련
├── 20.10 최종 모의평가
├── 20.11 3회 반복 훈련 계획
├── 20.12 장별 통과 기준
├── 20.13 시간 제한 훈련
├── 20.14 오답노트와 재훈련 루프
├── 20.15 훈련 점수표
└── 20.16 최종 훈련 완료 기준
```

---

# 4-Part Repository 구조

```
b1-1-system-monitor/
├── README.md
├── SUBMISSION.md
├── .gitignore
├── .dockerignore
├── Dockerfile
├── docker-compose.yml
│
├── bin/
│   ├── monitor.sh
│   ├── report.sh
│   ├── log_retention.sh
│   ├── security_check.sh
│   ├── secret_scan.sh
│   ├── docker_security_check.sh
│   ├── script_lint.sh
│   └── evidence_collect.sh
│
├── app/
│   ├── agent_app.py
│   └── README.md
│
├── config/
│   ├── sshd_config.example
│   ├── ufw-rules.example.txt
│   ├── firewalld-rules.example.txt
│   ├── crontab.example
│   ├── logrotate-agent-app.example
│   └── env.example
│
├── docs/
│   ├── part1-submission/
│   ├── part2-operations/
│   ├── part3-security-standards/
│   └── part4-training/
│
├── evidence/
│   ├── part1-submission/
│   ├── part2-operations/
│   └── part3-security-standards/
│
├── screenshots/
├── operations/
├── training/
└── archive/
```
