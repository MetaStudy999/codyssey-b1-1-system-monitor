# logrotate 로그 용량 관리

## 이 단계의 목표

`monitor.log`가 10MB를 초과하면 회전하고 최대 10개 파일만 보존하도록 설정한다.

## 왜 이 작업을 하는가?

관제 로그는 계속 증가한다. 용량 제한이 없으면 디스크를 가득 채워 서비스 장애를 만들 수 있다.

## 사전 확인

```bash
command -v logrotate
ls -ld /var/log/agent-app
```

## 실행 명령어

```bash
sudo bash scripts/setup-logrotate.sh
```

설정 파일을 확인한다.

```bash
sudo cat /etc/logrotate.d/agent-app-monitor
```

문법과 동작 계획을 dry run으로 확인한다.

```bash
sudo logrotate -d /etc/logrotate.d/agent-app-monitor
```

## 명령어 설명

- `size 10M`: 10MB 초과 시 rotate한다.
- `rotate 10`: 최대 10개 보존한다.
- `missingok`: 로그 파일이 없어도 오류로 보지 않는다.
- `notifempty`: 빈 로그는 rotate하지 않는다.
- `copytruncate`: 실행 중인 프로세스가 파일을 계속 잡고 있어도 안전하게 잘라낸다.

## 기대 결과

```text
/etc/logrotate.d/agent-app-monitor 생성
monitor.log 10MB / 10개 보존 정책 설정
```

## 결과 확인 명령어

```bash
sudo cat /etc/logrotate.d/agent-app-monitor
sudo logrotate -d /etc/logrotate.d/agent-app-monitor
```

## README에 붙여넣을 증빙

logrotate 설정 파일 내용과 dry run 결과 중 핵심 줄을 붙인다.

## 자주 발생하는 오류

- `logrotate: command not found`: `sudo apt install -y logrotate`
- 설정 파일 권한 오류: `/etc/logrotate.d`는 root 권한이 필요하다.
- 강제 테스트가 필요한 경우: 실습용 환경에서만 `sudo logrotate -f /etc/logrotate.d/agent-app-monitor`를 사용한다.

## 다음 단계로 넘어가는 기준

logrotate 설정 파일이 존재하고 dry run에서 문법 오류가 없으면 다음 단계로 넘어간다.

## Git 커밋 시점

logrotate 스크립트와 문서를 추가한 뒤 커밋한다.

## 추천 커밋 메시지

```bash
git commit -m "feat: add monitor log rotation setup"
```
