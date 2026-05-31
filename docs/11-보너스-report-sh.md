# 보너스 report.sh

## 이 단계의 목표

`monitor.log`를 분석해 CPU, MEM, DISK_USED의 평균/최대/최소와 샘플 수를 출력한다.

## 왜 이 작업을 하는가?

로그는 쌓는 것에서 끝나지 않는다. 평균과 최대값을 보면 평소 상태와 이상 상태를 비교할 수 있다.

## 사전 확인

```bash
sudo tail -n 5 /var/log/agent-app/monitor.log
```

## 실행 명령어

운영 위치로 배치한다.

```bash
export AGENT_HOME=/home/agent-admin/agent-app
sudo cp bin/report.sh "$AGENT_HOME/bin/report.sh"
sudo chown agent-dev:agent-core "$AGENT_HOME/bin/report.sh"
sudo chmod 750 "$AGENT_HOME/bin/report.sh"
```

문법 검사와 실행:

```bash
bash -n "$AGENT_HOME/bin/report.sh"
sudo -u agent-admin "$AGENT_HOME/bin/report.sh"
```

시간 구간 분석:

```bash
sudo -u agent-admin "$AGENT_HOME/bin/report.sh" --from "2026-05-27 10:00:00" --to "2026-05-27 11:00:00"
```

## 명령어 설명

- `awk`로 `CPU:`, `MEM:`, `DISK_USED:` 값을 파싱한다.
- 숫자로 파싱되지 않는 라인은 WARNING 후 건너뛴다.
- 샘플 수가 0이면 평균 계산을 하지 않고 오류 메시지를 출력한다.

## 기대 결과

```text
====== STATISTICS REPORT ======
Samples     : 10

[CPU]
Average     : ...
Maximum     : ...
Minimum     : ...
```

## 결과 확인 명령어

```bash
sudo -u agent-admin /home/agent-admin/agent-app/bin/report.sh
```

## README에 붙여넣을 증빙

report.sh 실행 결과 전체 또는 핵심 통계 부분을 붙인다.

## 자주 발생하는 오류

- 로그 파일 없음: `monitor.sh`를 먼저 실행한다.
- 빈 로그: cron 또는 직접 실행으로 샘플을 만든다.
- 시간 구간 결과 0개: `--from`, `--to` 범위가 실제 로그 시간과 맞는지 확인한다.

## 다음 단계로 넘어가는 기준

샘플 수와 CPU/MEM/DISK_USED 평균/최대/최소가 출력되면 다음 단계로 넘어간다.

## Git 커밋 시점

report.sh와 보너스 문서를 추가한 뒤 커밋한다.

## 추천 커밋 메시지

```bash
git commit -m "feat: add monitor log report script"
```
