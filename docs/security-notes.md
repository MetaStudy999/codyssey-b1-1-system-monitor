# Security Notes

## SSH 보안

SSH 포트를 `20022`로 바꾸면 기본 22번 포트를 대상으로 하는 자동 스캔과 공격 시도를 줄일 수 있다. Root 원격 접속을 차단하면 가장 강력한 계정이 직접 탈취되는 위험을 낮춘다.

검증:

```bash
sudo grep -E '^(Port|PermitRootLogin)' /etc/ssh/sshd_config
sudo ss -tulnp | grep ssh
```

## 방화벽 최소 허용

UFW는 들어오는 연결을 기본 차단하고 필요한 포트만 허용한다.

허용 포트:

```text
20022/tcp: SSH
15034/tcp: agent-app
```

검증:

```bash
sudo ufw status verbose
```

## 역할 기반 권한

`agent-common`은 협업용 그룹이고 `agent-core`는 운영 핵심 그룹이다.

```text
agent-common: agent-admin, agent-dev, agent-test
agent-core: agent-admin, agent-dev
```

## 민감 정보 보호

`api_keys`와 `/var/log/agent-app`은 `agent-core` 그룹만 접근하도록 제한한다. 테스트 계정은 업로드 파일에는 접근할 수 있지만 키와 로그에는 접근하지 못해야 한다.

검증:

```bash
getfacl /home/agent-admin/agent-app/api_keys
getfacl /var/log/agent-app
```

## root 실행 금지

앱은 root로 실행하지 않는다. root로 실행하면 권한 침해 시 피해 범위가 커지고, 앱 자체도 root 실행을 금지한다.

권장:

```bash
sudo -iu agent-admin
cd "$AGENT_HOME"
./agent-app
```

## 로그 보존

관제 로그는 장애 분석에 필요하지만 무한히 커질 수 있다. `logrotate`로 10MB/10개 보존 정책을 적용하고, 보너스 스크립트로 오래된 로그를 압축/아카이브/삭제한다.

## 민감정보 커밋 금지

이 미션의 `agent_api_key_test`는 테스트 문자열이다. 실제 API Key, 비밀번호, 개인 토큰은 절대 Git에 커밋하지 않는다.
