# cron 자동 실행

## 이 단계의 목표

`agent-admin` 계정의 crontab에 `monitor.sh`를 매분 실행하도록 등록한다.

## 왜 이 작업을 하는가?

모니터링은 사람이 수동으로 실행하는 것이 아니라 정해진 주기로 자동 실행되어야 운영 로그가 지속적으로 쌓인다.

## 사전 확인

```bash
sudo -u agent-admin /home/agent-admin/agent-app/bin/monitor.sh
tail -n 5 /var/log/agent-app/monitor.log
```

## 실행 명령어

```bash
sudo bash scripts/install-cron.sh
```

수동 등록 방식은 다음과 같다.

```bash
sudo crontab -u agent-admin -e
```

```cron
* * * * * /home/agent-admin/agent-app/bin/monitor.sh >> /var/log/agent-app/cron.log 2>&1
```

## 명령어 설명

- `* * * * *`: 매분 실행한다.
- `>> /var/log/agent-app/cron.log`: cron 실행 출력도 누적한다.
- `2>&1`: 에러 출력도 같은 로그에 남긴다.

## 기대 결과

`agent-admin`의 crontab에 동일 항목이 한 번만 등록된다.

## 결과 확인 명령어

```bash
sudo crontab -u agent-admin -l
wc -l /var/log/agent-app/monitor.log
sleep 70
wc -l /var/log/agent-app/monitor.log
tail -n 10 /var/log/agent-app/monitor.log
tail -n 10 /var/log/agent-app/cron.log
```

## README에 붙여넣을 증빙

crontab 등록 결과와 1분 뒤 `monitor.log` 라인 수 증가 결과를 붙인다.

## 자주 발생하는 오류

- 직접 실행은 되는데 cron은 실패: `cron.log`에서 PATH, 권한, 환경 변수 문제를 확인한다.
- 중복 등록: `install-cron.sh`는 기존 동일 항목을 중복 등록하지 않는다.
- cron 서비스 비활성: `sudo systemctl status cron`을 확인한다.

## 다음 단계로 넘어가는 기준

1분 뒤 `monitor.log` 라인 수가 증가하면 다음 단계로 넘어간다.

## Git 커밋 시점

cron 설치 스크립트와 검증 문서를 추가한 뒤 커밋한다.

## 추천 커밋 메시지

```bash
git commit -m "docs: add cron execution verification guide"
```
