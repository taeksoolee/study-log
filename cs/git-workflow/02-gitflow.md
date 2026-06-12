# 2. GitFlow

## 목차

1. [GitFlow 개요](#1-gitflow-개요)
2. [브랜치 구조](#2-브랜치-구조)
3. [버전 릴리즈 흐름](#3-버전-릴리즈-흐름)
4. [hotfix 흐름](#4-hotfix-흐름)
5. [git-flow CLI 도구](#5-git-flow-cli-도구)
6. [장점과 단점](#6-장점과-단점)
7. [면접 포인트](#7-면접-포인트)

---

## 1. GitFlow 개요

GitFlow는 2010년 Vincent Driessen이 블로그 포스트 "A successful Git branching model"에서 제안한 브랜칭 전략이다. 소프트웨어 개발 팀이 기능 개발, 릴리즈 준비, 긴급 버그 수정을 체계적으로 관리할 수 있도록 정형화된 브랜치 구조와 워크플로우를 정의한다.

### GitFlow가 적합한 상황

- **버전 관리가 명시적으로 필요한 프로젝트**: 모바일 앱, 패키지 라이브러리, 설치형 소프트웨어처럼 v1.0.0, v2.1.3 같은 버전 태그를 달아 배포하는 경우
- **병렬 기능 개발이 많은 팀**: 여러 개발자가 동시에 독립적인 기능을 개발해야 할 때
- **릴리즈 주기가 정해진 팀**: 주단위, 월단위처럼 스프린트나 릴리즈 사이클이 있는 팀
- **QA 단계가 별도로 존재하는 팀**: 코드 완성 후 릴리즈 전에 별도의 테스트 및 안정화 기간이 필요한 경우

### GitFlow가 적합하지 않은 상황

- 하루에도 수십 번 배포하는 SaaS 환경
- 소규모 팀이나 1인 개발 프로젝트
- 지속적 배포(Continuous Deployment) 파이프라인이 중심인 경우

---

## 2. 브랜치 구조

GitFlow는 5가지 종류의 브랜치를 사용한다. 크게 **장기 유지 브랜치**와 **단기 지원 브랜치**로 나뉜다.

### 2-1. main (또는 master) - 장기 유지

- **역할**: 현재 프로덕션(운영)에 배포된 코드만 존재한다.
- **직접 커밋 금지**: 오직 `release` 또는 `hotfix` 브랜치에서의 머지를 통해서만 업데이트된다.
- **태깅 필수**: 모든 머지 커밋에는 버전 태그(예: `v1.2.0`)를 붙인다.

```bash
# main 브랜치 상태 확인
git checkout main
git log --oneline --decorate
# 예시 출력:
# abc1234 (HEAD -> main, tag: v1.2.0) Merge release/1.2.0 into main
# def5678 (tag: v1.1.0) Merge release/1.1.0 into main
```

### 2-2. develop - 장기 유지

- **역할**: 다음 릴리즈를 위한 개발 통합 브랜치다. 모든 기능 개발은 이 브랜치를 기준으로 시작하고, 완성된 기능은 이 브랜치로 병합된다.
- **항상 최신 개발 상태 유지**: 빌드가 깨지지 않는 안정적인 상태를 유지해야 한다.

```bash
# develop 브랜치 생성 (프로젝트 최초 설정)
git checkout main
git checkout -b develop
git push -u origin develop
```

### 2-3. feature/xxx - 단기 지원

- **역할**: 새 기능을 개발하는 브랜치다. `develop`에서 분기하고, 완성 후 `develop`으로 머지된다.
- **네이밍 컨벤션**: `feature/` 접두사 뒤에 기능을 설명하는 이름을 붙인다.

```bash
# 네이밍 예시
feature/user-authentication
feature/payment-integration
feature/issue-42-dark-mode
feature/JIRA-123-export-csv
```

```bash
# feature 브랜치 생성
git checkout develop
git checkout -b feature/user-authentication

# 작업 후 develop에 머지
git checkout develop
git merge --no-ff feature/user-authentication
git branch -d feature/user-authentication
```

> `--no-ff` (no fast-forward) 옵션을 사용하면 머지 커밋이 명시적으로 생성되어 히스토리에서 기능 단위를 추적하기 쉬워진다.

### 2-4. release/x.x.x - 단기 지원

- **역할**: 릴리즈 직전 최종 준비(버그 수정, 버전 번호 업데이트, 문서 정리)를 위한 브랜치다. `develop`에서 분기하고, 완성 후 `main`과 `develop` 양쪽 모두에 머지된다.
- **네이밍 컨벤션**: `release/` 접두사 뒤에 시맨틱 버전을 붙인다.

```bash
# 네이밍 예시
release/1.2.0
release/2.0.0-beta
```

### 2-5. hotfix/xxx - 단기 지원

- **역할**: 운영 중인 코드에서 발생한 긴급 버그를 수정하는 브랜치다. `main`에서 직접 분기하고, 완성 후 `main`과 `develop` 양쪽 모두에 머지된다.
- **네이밍 컨벤션**: `hotfix/` 접두사 뒤에 수정 내용이나 이슈 번호를 붙인다.

```bash
# 네이밍 예시
hotfix/login-null-pointer
hotfix/v1.2.1
hotfix/critical-payment-bug
```

---

## 3. 버전 릴리즈 흐름

`feature` → `develop` → `release` → `main` 전체 흐름을 git 명령어로 살펴본다.

```bash
# ── 1단계: feature 브랜치에서 기능 개발 ──────────────────────────────
git checkout develop
git pull origin develop                          # 최신 develop 동기화
git checkout -b feature/shopping-cart            # feature 브랜치 생성

# 기능 개발 및 커밋
git add src/cart/Cart.js
git commit -m "feat: 장바구니 아이템 추가 기능 구현"
git add src/cart/CartTotal.js
git commit -m "feat: 장바구니 금액 합산 로직 추가"

# ── 2단계: feature → develop 머지 ─────────────────────────────────────
git checkout develop
git merge --no-ff feature/shopping-cart -m "Merge feature/shopping-cart into develop"
git branch -d feature/shopping-cart              # 로컬 feature 브랜치 삭제
git push origin develop                          # develop 원격 동기화

# ── 3단계: release 브랜치 생성 (릴리즈 준비) ──────────────────────────
git checkout develop
git checkout -b release/1.3.0

# 버전 번호 파일 업데이트
echo "1.3.0" > VERSION
git add VERSION
git commit -m "chore: bump version to 1.3.0"

# 릴리즈 직전 마이너 버그 수정
git add src/utils/format.js
git commit -m "fix: 날짜 포맷 오류 수정"

# ── 4단계: release → main 머지 + 태깅 ─────────────────────────────────
git checkout main
git merge --no-ff release/1.3.0 -m "Merge release/1.3.0 into main"
git tag -a v1.3.0 -m "Release version 1.3.0"
git push origin main
git push origin v1.3.0                           # 태그 원격 푸시

# ── 5단계: release → develop 백머지 ───────────────────────────────────
# release 브랜치에서 수정한 내용을 develop에도 반영
git checkout develop
git merge --no-ff release/1.3.0 -m "Merge release/1.3.0 back into develop"
git push origin develop

# ── 6단계: release 브랜치 정리 ─────────────────────────────────────────
git branch -d release/1.3.0
git push origin --delete release/1.3.0
```

---

## 4. hotfix 흐름

운영 환경에서 긴급 버그가 발생한 경우, `main`에서 직접 `hotfix` 브랜치를 생성하여 수정한 뒤 `main`과 `develop` 양쪽에 모두 머지한다.

```bash
# ── 1단계: main에서 hotfix 브랜치 생성 ────────────────────────────────
git checkout main
git pull origin main
git checkout -b hotfix/login-session-expired

# ── 2단계: 버그 수정 및 커밋 ──────────────────────────────────────────
git add src/auth/session.js
git commit -m "fix: 세션 만료 시 무한 리다이렉트 버그 수정"

# 버전 번호도 패치 버전 올리기 (1.3.0 → 1.3.1)
echo "1.3.1" > VERSION
git add VERSION
git commit -m "chore: bump version to 1.3.1"

# ── 3단계: main에 머지 + 태깅 ─────────────────────────────────────────
git checkout main
git merge --no-ff hotfix/login-session-expired -m "Merge hotfix/login-session-expired into main"
git tag -a v1.3.1 -m "Hotfix version 1.3.1"
git push origin main
git push origin v1.3.1

# ── 4단계: develop에도 머지 (핫픽스 내용 반영) ───────────────────────
git checkout develop
git merge --no-ff hotfix/login-session-expired -m "Merge hotfix/login-session-expired into develop"
git push origin develop

# ── 5단계: hotfix 브랜치 정리 ──────────────────────────────────────────
git branch -d hotfix/login-session-expired
git push origin --delete hotfix/login-session-expired
```

> **주의**: 현재 진행 중인 `release` 브랜치가 있다면, `develop` 대신 `release` 브랜치에 hotfix를 머지하고, 이후 `release`가 `develop`으로 머지될 때 포함되도록 한다.

---

## 5. git-flow CLI 도구

`git-flow`는 GitFlow 워크플로우를 자동화해주는 CLI 확장 도구다. 반복적인 브랜치 생성/머지/삭제 명령어를 단축 명령어로 처리할 수 있다.

### 설치

```bash
# macOS (Homebrew)
brew install git-flow-avh

# Ubuntu/Debian
apt-get install git-flow

# Windows (Git for Windows에 포함)
# 별도 설치 불필요
```

### 초기화

```bash
git flow init

# 대화형 프롬프트 예시:
# Branch name for production releases: [master] main
# Branch name for "next release" development: [develop]
# Feature branches? [feature/]
# Bugfix branches? [bugfix/]
# Release branches? [release/]
# Hotfix branches? [hotfix/]
# Support branches? [support/]
# Version tag prefix? [] v
```

### feature 브랜치

```bash
# feature 시작 (develop에서 feature/user-profile 생성)
git flow feature start user-profile

# feature 완료 (develop에 --no-ff 머지 후 브랜치 삭제)
git flow feature finish user-profile

# 원격에 feature 브랜치 공유 (협업 시)
git flow feature publish user-profile

# 원격 feature 브랜치 가져오기
git flow feature pull origin user-profile
```

### release 브랜치

```bash
# release 시작 (develop에서 release/1.3.0 생성)
git flow release start 1.3.0

# release 완료 (main + develop 머지, 태그 생성, 브랜치 삭제)
git flow release finish 1.3.0

# 원격 푸시
git push origin main develop
git push origin --tags
```

### hotfix 브랜치

```bash
# hotfix 시작 (main에서 hotfix/1.3.1 생성)
git flow hotfix start 1.3.1

# hotfix 완료 (main + develop 머지, 태그 생성, 브랜치 삭제)
git flow hotfix finish 1.3.1
```

### 현재 상태 확인

```bash
# 진행 중인 feature 목록
git flow feature list

# 진행 중인 release 목록
git flow release list

# 진행 중인 hotfix 목록
git flow hotfix list
```

---

## 6. 장점과 단점

### 장점

| 항목 | 설명 |
|------|------|
| **체계적인 구조** | 브랜치 역할이 명확히 분리되어 있어 대규모 팀에서도 혼선이 줄어든다 |
| **버전 관리 명확** | 릴리즈 브랜치와 태그를 통해 각 버전의 코드를 명확하게 추적할 수 있다 |
| **병렬 개발 지원** | 여러 feature를 동시에 독립적으로 개발하고 통합할 수 있다 |
| **긴급 수정 분리** | hotfix 브랜치가 있어 운영 버그를 개발 중인 코드와 분리하여 수정할 수 있다 |
| **릴리즈 안정화** | release 브랜치에서 마지막 버그 수정과 안정화 작업을 할 시간을 갖는다 |

### 단점

| 항목 | 설명 |
|------|------|
| **복잡성** | 브랜치 종류가 많고 머지 규칙이 복잡하여 팀원 교육이 필요하다 |
| **CI/CD 환경 비적합** | 지속적 배포 환경에서는 release 브랜치가 오히려 배포 속도를 늦춘다 |
| **브랜치 오래 유지** | long-lived feature 브랜치는 머지 충돌(conflict)을 키울 수 있다 |
| **백머지 부담** | release/hotfix를 develop에 반드시 백머지해야 해서 절차가 번거롭다 |
| **소규모 팀 과도함** | 1~3인 팀에서는 불필요한 오버헤드가 된다 |

---

## 7. 면접 포인트

### Q1. GitFlow의 핵심 브랜치 두 가지는 무엇인가요?

`main`(또는 `master`)과 `develop`입니다. `main`은 항상 프로덕션에 배포된 안정적인 코드만 유지하고, `develop`은 다음 릴리즈를 위한 개발 통합 브랜치입니다. 나머지 `feature`, `release`, `hotfix`는 이 두 브랜치를 지원하는 단기 브랜치입니다.

### Q2. feature 브랜치를 develop에 머지할 때 --no-ff를 사용하는 이유는 무엇인가요?

`--no-ff`(no fast-forward)를 사용하면 fast-forward 머지가 가능한 경우에도 강제로 머지 커밋을 생성합니다. 이로 인해 히스토리에 해당 기능이 언제 통합되었는지 명확한 흔적이 남아, 이후 특정 기능 단위로 되돌리거나(revert) 변경 이력을 추적하기 쉬워집니다.

### Q3. hotfix를 main에만 머지하고 develop에 반영하지 않으면 어떤 문제가 생기나요?

다음 릴리즈 때 develop 브랜치에는 hotfix 수정 내용이 없으므로, 이미 운영에서 고친 버그가 다시 배포될 수 있습니다(regression). 반드시 main과 develop 양쪽 모두에 머지해야 합니다.

### Q4. GitFlow와 GitHub Flow의 가장 큰 차이는 무엇인가요?

GitFlow는 `develop`, `release`, `hotfix` 등 여러 장기/단기 브랜치를 운영하는 반면, GitHub Flow는 `main`과 단기 `feature` 브랜치만 사용합니다. GitFlow는 명시적인 버전 관리가 필요한 제품에, GitHub Flow는 지속적 배포 환경에 적합합니다.

### Q5. GitFlow에서 release 브랜치의 역할은 무엇인가요?

`develop`에서 모든 기능이 통합된 뒤, 릴리즈 직전 최종 안정화 작업(버전 번호 업데이트, 마이너 버그 수정, 문서 정리)을 위한 공간입니다. 이 기간 동안 `develop`에는 다음 릴리즈를 위한 새 기능이 계속 추가될 수 있습니다.

### Q6. GitFlow가 현대 CI/CD 환경에 적합하지 않다고 하는 이유는 무엇인가요?

CI/CD는 짧은 주기로 자주 배포하는 것을 목표로 하는데, GitFlow의 `develop` → `release` → `main` 단계는 배포까지의 리드 타임을 늘립니다. 또한 오래 살아있는 브랜치는 머지 충돌을 유발하고, PR 리뷰 사이클을 느리게 만들어 배포 빈도를 줄입니다. 이런 이유로 GitHub Flow나 Trunk-Based Development가 CI/CD 환경에서 선호됩니다.

### Q7. Vincent Driessen 본인은 GitFlow에 대해 어떤 입장을 밝혔나요?

Vincent Driessen은 2020년에 원본 블로그 포스트에 노트를 추가하여, GitFlow가 처음 작성된 2010년은 지속적 전달(Continuous Delivery) 개념이 주류가 아니었던 시대였음을 인정했습니다. 그는 웹 앱처럼 지속적으로 배포되는 소프트웨어에는 GitHub Flow와 같은 단순한 워크플로우를 권장하고, 명시적인 버전 관리가 필요한 소프트웨어에만 GitFlow를 사용하라고 조언했습니다.
