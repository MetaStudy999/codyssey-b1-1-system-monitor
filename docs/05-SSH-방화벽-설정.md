# SSH와 방화벽 설정

## 이 단계의 목표

SSH 포트를 `20022`로 변경하고 Root 원격 접속을 차단한 뒤, UFW에서 `20022/tcp`, `15034/tcp`만 허용한다.

## 왜 이 작업을 하는가?

기본 SSH 포트와 Root 원격 접속은 공격 표면을 넓힌다. 방화벽은 필요한 서비스 포트만 외부에 노출하기 위한 최소 허용 정책이다.

## 사전 확인

```bash
sudo grep -E '^(#)?(Port|PermitRootLogin)' /etc/ssh/sshd_config
sudo ss -tulnp | grep ssh || true
sudo ufw status verbose
```

## 실행 명령어

SSH 설정은 접속이 끊길 수 있으므로 신중하게 수동 편집한다.

```bash
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
sudo nano /etc/ssh/sshd_config
```

다음 값을 설정한다.

```text
Port 20022
PermitRootLogin no
```

설정 문법을 확인하고 SSH를 재시작한다.

```bash
sudo sshd -t
sudo systemctl restart ssh
```

UFW는 먼저 dry run으로 계획을 확인한다.

```bash
sudo bash scripts/setup-firewall-ufw.sh
```

정말 적용할 때만 실행한다.

```bash
sudo bash scripts/setup-firewall-ufw.sh --apply
```

## 명령어 설명

- `sshd -t`: SSH 설정 문법 오류를 먼저 확인한다.
- `systemctl restart ssh`: Ubuntu의 SSH 데몬을 재시작한다.
- `ufw default deny incoming`: 들어오는 연결을 기본 차단한다.
- `ufw allow 20022/tcp`: SSH 접속을 허용한다.
- `ufw allow 15034/tcp`: agent-app 접속을 허용한다.

## 기대 결과

```text
Port 20022
PermitRootLogin no
UFW active
20022/tcp ALLOW
15034/tcp ALLOW
```

## 결과 확인 명령어

```bash
sudo grep -E '^(Port|PermitRootLogin)' /etc/ssh/sshd_config
sudo ss -tulnp | grep ssh
sudo ufw status numbered
sudo ufw status verbose
```

## README에 붙여넣을 증빙

위 네 명령의 결과를 붙인다.

## 자주 발생하는 오류

- SSH 재시작 후 접속 불가: 기존 터미널을 닫지 말고 새 터미널에서 접속 테스트 후 진행한다.
- `sshd: no hostkeys available`: SSH 서버 패키지 상태를 확인한다.
- UFW 활성화 후 접속 불가: `20022/tcp` 허용 전에 UFW를 켜지 않았는지 확인한다.

## 다음 단계로 넘어가는 기준

SSH가 `20022`에서 LISTEN이고 UFW가 `20022/tcp`, `15034/tcp`를 허용하면 다음 단계로 넘어간다.

## Git 커밋 시점

SSH/UFW 가이드를 추가한 뒤 커밋한다.

## 추천 커밋 메시지

```bash
git commit -m "feat: add SSH and UFW hardening guide"
```
