# 기초: 조건문, 함수, 반복문으로 스크립트 구조 만들기

## 이 단계의 목표

반복되는 명령을 함수로 묶고, 조건문과 반복문으로 재실행 가능한 스크립트를 만든다.

B1-1의 `scripts/setup-users.sh`, `scripts/setup-dirs.sh`는 이 단계의 대표 예시다.

## 따라하기 1: 함수로 메시지 출력 통일하기

`basic-functions.sh` 파일을 만든다.

```bash
nano basic-functions.sh
```

내용:

```bash
#!/usr/bin/env bash

set -u

info() {
  printf '[INFO] %s\n' "$*"
}

error() {
  printf '[ERROR] %s\n' "$*" >&2
}

info "Script started"
error "This is an example error message"
```

실행:

```bash
bash -n basic-functions.sh
bash basic-functions.sh
```

현재 구현된 스크립트들은 `[INFO]`, `[WARNING]`, `[ERROR]` 형식을 사용해 실행 결과를 읽기 쉽게 만든다.

## 따라하기 2: root 권한 검사 흉내 내기

실제 사용자 생성은 하지 않고, root 여부만 확인한다.

`check-root.sh`:

```bash
#!/usr/bin/env bash

set -u

error() {
  printf '[ERROR] %s\n' "$*" >&2
}

if [ "$(id -u)" -ne 0 ]; then
  error "This script needs sudo when it changes system settings."
  exit 1
fi

echo "You are root."
```

확인:

```bash
bash -n check-root.sh
bash check-root.sh
```

일반 사용자로 실행하면 실패하는 것이 정상이다. `scripts/setup-users.sh`와 `scripts/setup-dirs.sh`는 실제 시스템 계정과 `/var/log`를 다루므로 같은 방식으로 root 권한을 먼저 검사한다.

## 따라하기 3: 배열과 반복문

`user-list-practice.sh`:

```bash
#!/usr/bin/env bash

set -u

AGENT_USERS=("agent-admin" "agent-dev" "agent-test")

for user_name in "${AGENT_USERS[@]}"; do
  echo "Need user: $user_name"
done
```

확인:

```bash
bash -n user-list-practice.sh
bash user-list-practice.sh
```

`scripts/setup-users.sh`는 이 구조를 사용해 세 계정을 반복 처리한다.

## 따라하기 4: 존재하면 건너뛰기

멱등성은 같은 스크립트를 여러 번 실행해도 최종 상태가 같게 만드는 성질이다.

`ensure-file.sh`:

```bash
#!/usr/bin/env bash

set -u

TARGET_FILE="${1:-./sample.txt}"

if [ -f "$TARGET_FILE" ]; then
  echo "[INFO] File already exists: $TARGET_FILE"
else
  printf 'hello\n' >"$TARGET_FILE"
  echo "[INFO] Created file: $TARGET_FILE"
fi
```

확인:

```bash
bash -n ensure-file.sh
bash ensure-file.sh
bash ensure-file.sh
cat sample.txt
```

첫 실행에서는 파일을 만들고, 두 번째 실행에서는 이미 있다고 안내한다.

## 현재 구현과 연결하기

다음 명령으로 사용자 생성 스크립트의 핵심 함수 이름을 확인한다.

```bash
grep -E '^(require_root|ensure_group|ensure_user|ensure_membership|main)[(]' scripts/setup-users.sh
```

확인할 포인트:

- `require_root`: 시스템 변경 전 권한 확인
- `ensure_group`: 그룹이 없을 때만 생성
- `ensure_user`: 사용자가 없을 때만 생성
- `ensure_membership`: 그룹에 없을 때만 추가
- `main`: 실행 순서를 한 곳에 모음

## 연습 문제

1. `ensure-dir.sh`를 만들고, 인자로 받은 디렉터리가 없으면 생성하라.
2. `ensure-dir.sh`에 `info`, `error` 함수를 추가하라.
3. `("upload_files" "api_keys" "bin")` 배열을 반복해서 필요한 디렉터리 이름을 출력하라.
4. `scripts/setup-dirs.sh`에서 `install -d`를 사용하는 이유를 설명하라.
5. 멱등성이 없는 스크립트가 운영에서 위험한 이유를 예시와 함께 설명하라.

## 통과 기준

- 함수, 조건문, 반복문을 직접 작성할 수 있다.
- `"$@"`, `"$1"`, `"${VAR:-default}"` 형태를 읽을 수 있다.
- `setup-users.sh`가 왜 여러 번 실행해도 안전한지 설명할 수 있다.
