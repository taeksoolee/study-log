# 3. GitHub Flow

## 목차

1. [GitHub Flow 개요](#1-github-flow-개요)
2. [브랜치 구조](#2-브랜치-구조)
3. [전체 흐름](#3-전체-흐름)
4. [PR(Pull Request) 베스트 프랙티스](#4-prpull-request-베스트-프랙티스)
5. [브랜치 보호 규칙 (Branch Protection Rules)](#5-브랜치-보호-규칙-branch-protection-rules)
6. [장점과 단점](#6-장점과-단점)
7. [언제 GitHub Flow를 선택하나](#7-언제-github-flow를-선택하나)
8. [면접 포인트](#8-면접-포인트)

---

## 1. GitHub Flow 개요

GitHub Flow는 GitHub이 자사 서비스를 개발하면서 내부적으로 사용하던 워크플로우를 2011년 Scott Chacon이 블로그에 공개한 것이다. 핵심 철학은 **단순함**이다. 브랜치 전략을 최소화하고, Pull Request와 코드 리뷰를 중심으로 빠르고 지속적인 배포를 추구한다.

### GitFlow 대비 단순함

| 비교 항목 | GitFlow | GitHub Flow |
|-----------|---------|-------------|
| 장기 브랜치 수 | 2개 (main, develop) | 1개 (main) |
| 단기 브랜치 | feature, release, hotfix | feature |
| 릴리즈 절차 | release 브랜치 → 태그 | main 머지 → 즉시 배포 |
| 배포 주기 | 주/월 단위 릴리즈 | 머지 즉시 배포 |
| 복잡도 | 높음 | 낮음 |

GitFlow에서는 `develop`, `release`, `hotfix` 브랜치를 별도로 운영하지만, GitHub Flow에서는 이 모든 역할을 `main`과 단기 `feature` 브랜치, 그리고 PR로 처리한다.

### 핵심 원칙

1. `main` 브랜치는 항상 배포 가능한(deployable) 상태를 유지한다.
2. 새로운 작업은 반드시 `main`에서 브랜치를 만들어 시작한다.
3. 브랜치 이름은 작업 내용을 명확히 설명해야 한다.
4. 코드는 PR을 통해서만 `main`에 머지된다.
5. PR을 열면 즉시 리뷰와 토론을 시작할 수 있다.
6. `main`에 머지되면 즉시 배포한다.

---

## 2. 브랜치 구조

### main 브랜치 - 유일한 장기 브랜치

- **역할**: 프로덕션에 배포된 코드이자 모든 작업의 기준점이다.
- **항상 배포 가능 상태**: `main`에 있는 코드는 언제든 프로덕션에 배포할 수 있어야 한다.
- **직접 push 금지**: 반드시 PR을 통해서만 변경된다(Branch Protection Rules로 강제).

```bash
# main 브랜치 상태 - 항상 배포 가능해야 함
git checkout main
git log --oneline
# 예시:
# a1b2c3d (HEAD -> main, origin/main) Merge pull request #42 from feature/dark-mode
# d4e5f6g Merge pull request #41 from feature/export-csv
# g7h8i9j Merge pull request #40 from feature/user-profile
```

### feature 브랜치 - 단기 브랜치

- **역할**: 기능 개발, 버그 수정, 실험 등 모든 작업을 담는 단기 브랜치다.
- **짧게 유지**: 가능한 한 빨리 `main`으로 머지하여 브랜치 수명을 짧게 유지한다.
- **네이밍 컨벤션**: 작업 내용을 명확하게 설명하는 이름을 사용한다.

```bash
# 네이밍 예시 (기능 개발)
feature/user-authentication
feature/payment-integration
feature/dark-mode

# 네이밍 예시 (버그 수정)
fix/login-redirect-loop
fix/null-pointer-on-checkout

# 네이밍 예시 (개선 및 기타)
chore/upgrade-dependencies
docs/update-api-readme
refactor/simplify-auth-logic
```

---

## 3. 전체 흐름

GitHub Flow의 전체 사이클은 **브랜치 생성 → 개발 → PR 생성 → 리뷰 → CI → 머지 → 배포** 7단계로 이루어진다.

### 3-1. main에서 feature 브랜치 생성

```bash
# 최신 main 기준으로 브랜치 생성
git checkout main
git pull origin main
git checkout -b feature/user-notifications

# 또는 한 번에
git fetch origin
git checkout -b feature/user-notifications origin/main
```

### 3-2. 개발 및 커밋 (작고 자주)

커밋은 작게, 자주 하는 것이 원칙이다. 작은 커밋은 코드 리뷰를 쉽게 하고, 문제 발생 시 롤백 범위를 좁혀준다.

```bash
# 첫 번째 작업 단위 커밋
git add src/notifications/NotificationService.js
git commit -m "feat: 알림 서비스 기본 구조 추가"

# 두 번째 작업 단위 커밋
git add src/notifications/NotificationList.js
git commit -m "feat: 알림 목록 컴포넌트 구현"

# 세 번째 작업 단위 커밋
git add src/notifications/NotificationBadge.js
git commit -m "feat: 읽지 않은 알림 배지 표시 추가"

# 원격 브랜치에 push (작업 중에도 자주 push 권장)
git push -u origin feature/user-notifications
```

> 작업 도중 원격에 push해두면 팀원이 진행 상황을 확인할 수 있고, 로컬 환경 문제 발생 시 코드 손실을 예방할 수 있다.

### 3-3. PR(Pull Request) 생성

작업이 완료되거나 리뷰가 필요한 시점에 PR을 생성한다. 작업이 완전히 끝나지 않아도 `Draft PR`로 일찍 열어 피드백을 받을 수 있다.

```bash
# GitHub CLI를 사용한 PR 생성
gh pr create \
  --title "feat: 사용자 알림 기능 추가" \
  --body "## 변경 사항
- 알림 서비스 구현
- 알림 목록 UI 추가
- 읽지 않은 알림 배지 표시

## 테스트 방법
1. 로그인 후 다른 사용자가 댓글 작성
2. 상단 바 알림 아이콘에 배지 확인
3. 알림 목록 클릭 후 내용 확인" \
  --reviewer team-member1,team-member2 \
  --base main
```

### 3-4. 코드 리뷰 및 토론

PR에서 팀원들이 코드를 검토하고 의견을 남긴다. 리뷰어의 요청에 따라 추가 커밋을 쌓는다.

```bash
# 리뷰 피드백 반영 후 추가 커밋
git add src/notifications/NotificationService.js
git commit -m "fix: 리뷰 반영 - 알림 중복 방지 로직 추가"
git push origin feature/user-notifications
# 푸시하면 PR에 자동으로 반영됨
```

### 3-5. CI 통과 확인

PR이 열리면 CI(Continuous Integration) 파이프라인이 자동 실행된다. 모든 테스트가 통과해야 머지할 수 있다.

```bash
# GitHub CLI로 CI 상태 확인
gh pr checks

# 예시 출력:
# All checks were successful
# ✓  build          2m30s
# ✓  test           1m45s
# ✓  lint           0m30s
```

### 3-6. main에 Merge

코드 리뷰 승인과 CI 통과 후 `main`에 머지한다. 머지 전략은 팀 정책에 따라 선택한다.

```bash
# GitHub CLI로 PR 머지
gh pr merge 42 --squash --delete-branch
# --squash: feature 브랜치의 여러 커밋을 하나로 합쳐 main 히스토리를 깔끔하게 유지
# --merge: 모든 커밋 히스토리 유지 (--no-ff)
# --rebase: 리베이스 후 fast-forward 머지

# git 명령어로 직접 머지하는 경우
git checkout main
git pull origin main
git merge --squash feature/user-notifications
git commit -m "feat: 사용자 알림 기능 추가 (#42)"
git push origin main
git branch -d feature/user-notifications
git push origin --delete feature/user-notifications
```

### 3-7. 즉시 배포

`main`에 머지되는 순간 CI/CD 파이프라인이 자동으로 프로덕션에 배포한다.

```yaml
# GitHub Actions 배포 파이프라인 예시 (.github/workflows/deploy.yml)
name: Deploy to Production

on:
  push:
    branches:
      - main

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Build
        run: npm run build
      - name: Deploy
        run: ./scripts/deploy.sh
```

---

## 4. PR(Pull Request) 베스트 프랙티스

### PR 크기는 작게

- 하나의 PR은 하나의 기능 또는 하나의 버그 수정에 집중한다.
- 변경된 파일 수는 가능한 10개 이하, 코드 라인 수는 400줄 이하를 권장한다.
- 큰 기능은 여러 개의 작은 PR로 나눈다(기능 플래그(Feature Flag)를 활용하면 미완성 기능도 안전하게 머지 가능).

```
# 나쁜 예: 하나의 PR에 너무 많은 변경
- 사용자 인증 시스템 전체 재작성
- 결제 모듈 추가
- 어드민 대시보드 구현
- 의존성 업그레이드

# 좋은 예: 기능별로 분리된 작은 PR
PR #1: 이메일/비밀번호 로그인 구현
PR #2: OAuth 소셜 로그인 추가
PR #3: 비밀번호 재설정 기능
```

### 명확한 PR 설명

PR 설명에는 다음 항목을 포함한다.

```markdown
## 무엇을 변경했나요?
- 변경 내용 요약

## 왜 변경했나요?
- 변경 이유 또는 관련 이슈 링크 (Closes #123)

## 어떻게 테스트했나요?
- 테스트 방법 및 확인 절차

## 스크린샷 (UI 변경 시)
- before/after 화면 캡처
```

### 리뷰어 지정

```bash
# PR 생성 시 리뷰어 지정
gh pr create --reviewer "@team/frontend" --reviewer "specific-member"

# 리뷰어 추가
gh pr edit 42 --add-reviewer "new-reviewer"
```

- 리뷰어는 최소 1명, 권장 2명을 지정한다.
- 코드 소유자(CODEOWNERS)를 설정하면 변경된 파일에 따라 리뷰어가 자동 지정된다.

---

## 5. 브랜치 보호 규칙 (Branch Protection Rules)

`main` 브랜치를 보호하기 위해 GitHub 저장소 설정에서 Branch Protection Rules를 적용한다.

### 주요 보호 규칙

- **직접 push 금지**: `main`에 직접 `git push`하면 거부된다.
- **PR 필수**: 반드시 PR을 통해서만 머지할 수 있다.
- **승인 필수**: 최소 1명(또는 N명) 이상의 리뷰어 승인이 있어야 한다.
- **CI 통과 필수**: 지정한 status checks가 모두 통과해야 한다.
- **브랜치 최신 상태 유지**: 머지 전 `main`의 최신 변경 사항을 브랜치에 반영해야 한다.

### GitHub 설정 예시

```
Settings > Branches > Add branch protection rule

Branch name pattern: main

[✓] Require a pull request before merging
    [✓] Require approvals: 1
    [✓] Dismiss stale pull request approvals when new commits are pushed
    [✓] Require review from Code Owners

[✓] Require status checks to pass before merging
    [✓] Require branches to be up to date before merging
    Status checks: build, test, lint

[✓] Require conversation resolution before merging

[✓] Do not allow bypassing the above settings
```

### CODEOWNERS 파일 예시

```
# .github/CODEOWNERS

# 전체 코드 기본 소유자
*                   @team-lead

# 프론트엔드 코드
/src/components/    @frontend-team
/src/pages/         @frontend-team

# 백엔드 API
/src/api/           @backend-team

# 인프라 및 배포 설정
/.github/           @devops-team
/infrastructure/    @devops-team
```

---

## 6. 장점과 단점

### 장점

| 항목 | 설명 |
|------|------|
| **단순함** | 브랜치 구조가 간단해 팀원 교육과 온보딩이 빠르다 |
| **빠른 배포 주기** | `main` 머지 즉시 배포되므로 빠른 피드백 루프가 가능하다 |
| **PR 중심 협업** | 코드 리뷰와 토론이 PR에 집중되어 협업 흔적이 명확하다 |
| **충돌 최소화** | 브랜치 수명이 짧아 머지 충돌이 적다 |
| **CI/CD 친화적** | 단순한 브랜치 구조가 자동화 파이프라인 구성을 쉽게 한다 |

### 단점

| 항목 | 설명 |
|------|------|
| **릴리즈 버전 관리 어려움** | 명시적인 버전 태그 없이 `main`에 계속 머지되므로, 특정 버전을 고정해 배포하기 어렵다 |
| **여러 환경 관리 어려움** | staging, QA, production 같은 여러 환경을 별도 브랜치로 관리하려면 추가 전략이 필요하다 |
| **배포 전 안정화 기간 없음** | release 브랜치처럼 배포 직전 안정화 기간을 갖기 어렵다 |
| **핫픽스 절차 없음** | 긴급 수정도 일반 feature와 동일한 절차를 거치므로, CI 시간이 긴 경우 느릴 수 있다 |

---

## 7. 언제 GitHub Flow를 선택하나

### GitHub Flow가 적합한 상황

**소규모 팀**

- 5명 이하의 팀에서는 GitFlow의 복잡한 브랜치 전략이 오히려 생산성을 떨어뜨린다.
- 단순한 규칙으로 모든 팀원이 빠르게 적응할 수 있다.

**SaaS 제품 및 웹 서비스**

- 사용자가 항상 최신 버전을 사용하는 웹 서비스는 명시적인 버전 관리보다 빠른 기능 배포가 더 중요하다.
- GitHub 자체, Slack, Notion 같은 서비스가 이 방식을 사용한다.

**지속적 배포(Continuous Deployment) 환경**

- 하루에도 여러 번 배포하는 파이프라인이 갖춰진 팀에 최적화되어 있다.
- 자동화된 테스트와 배포 인프라가 갖춰져 있어야 안전하게 운영된다.

**스타트업 및 초기 단계 제품**

- 빠른 실험과 빠른 피드백이 중요한 초기 단계에서 오버헤드 없이 빠르게 움직일 수 있다.

### GitHub Flow가 적합하지 않은 상황

- v1.0.0, v2.1.3처럼 명시적인 버전을 관리해야 하는 모바일 앱, 오픈소스 라이브러리
- 규정(compliance) 상 배포 전 별도 승인 절차가 있는 엔터프라이즈 환경
- 여러 버전을 동시에 유지보수해야 하는 경우 (예: v1.x 버그 수정과 v2.x 개발 병행)

---

## 8. 면접 포인트

### Q1. GitHub Flow의 핵심 원칙은 무엇인가요?

`main` 브랜치는 항상 배포 가능한 상태를 유지하는 것입니다. 모든 작업은 `main`에서 feature 브랜치를 만들어 시작하고, PR과 코드 리뷰, CI 통과를 거쳐 머지되는 즉시 배포됩니다. 브랜치를 짧게 유지하고 빠르게 통합하는 것이 핵심입니다.

### Q2. GitHub Flow와 GitFlow 중 어떤 것을 선택하겠습니까? 기준은 무엇인가요?

배포 주기와 버전 관리 필요성에 따라 선택합니다. 하루에도 여러 번 배포하는 SaaS나 웹 서비스라면 단순하고 빠른 GitHub Flow를 선택합니다. 반면 명시적인 버전 번호로 배포하는 모바일 앱이나 라이브러리처럼 릴리즈 사이클이 있고 여러 버전을 유지해야 한다면 GitFlow가 적합합니다.

### Q3. PR 크기가 왜 중요한가요?

PR이 크면 리뷰어가 맥락을 파악하기 어렵고, 리뷰 시간이 길어지며, 머지 충돌 가능성이 높아집니다. 또한 롤백이 필요할 때 영향 범위가 넓어집니다. 작은 PR은 빠른 리뷰, 빠른 피드백 루프, 더 안전한 배포를 가능하게 합니다.

### Q4. main 브랜치에 Branch Protection Rule을 설정하는 이유는 무엇인가요?

`main`은 항상 배포 가능한 상태여야 합니다. 실수로 검증되지 않은 코드가 직접 push되면 프로덕션 장애로 이어질 수 있습니다. Branch Protection Rules는 PR 필수, 코드 리뷰 승인 필수, CI 통과 필수를 강제하여 `main`의 품질을 자동으로 보장합니다.

### Q5. GitHub Flow에서 hotfix는 어떻게 처리하나요?

GitHub Flow에서는 별도의 hotfix 브랜치 개념이 없습니다. 일반 feature 브랜치와 동일하게 `main`에서 브랜치를 생성하고 수정 후 PR을 통해 `main`에 머지합니다. 다만 긴급도가 높으므로 PR 생성 시 긴급 레이블을 붙이고, 리뷰어를 즉시 소환하며, CI 파이프라인이 빠르게 실행되도록 설정해둬야 합니다.

### Q6. Squash Merge, Merge Commit, Rebase Merge의 차이는 무엇이며, GitHub Flow에서는 어떤 것을 주로 사용하나요?

- **Merge Commit**: feature 브랜치의 모든 커밋을 그대로 유지하고 머지 커밋을 추가한다. 히스토리가 정직하지만 노이즈가 많다.
- **Squash Merge**: feature 브랜치의 모든 커밋을 하나로 합쳐 `main`에 단일 커밋으로 추가한다. `main` 히스토리가 깔끔해진다.
- **Rebase Merge**: feature 브랜치의 커밋들을 `main` 위에 재배치하여 선형 히스토리를 만든다. 커밋 SHA가 변경된다.

GitHub Flow에서는 `main` 히스토리를 깔끔하게 유지하기 위해 **Squash Merge**를 많이 사용합니다. 각 PR이 `main`에 하나의 커밋으로 남아 `git log`와 `git bisect`가 편해집니다.

### Q7. Draft PR은 무엇이고 언제 사용하나요?

Draft PR은 아직 리뷰 준비가 되지 않은 작업 중인 PR입니다. 작업이 완전히 끝나지 않았지만 팀원에게 진행 방향을 공유하거나 초기 피드백을 받고 싶을 때 사용합니다. CI는 Draft PR에서도 실행되므로 빌드/테스트 결과를 미리 확인할 수 있습니다. 준비가 완료되면 "Ready for review"로 전환하여 정식 리뷰를 요청합니다.
