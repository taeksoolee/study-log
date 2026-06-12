# 4. GitLab Flow

## 목차

1. [개요](#1-개요)
2. [브랜치 구조](#2-브랜치-구조)
3. [환경별 브랜치 전략 및 git 명령어](#3-환경별-브랜치-전략-및-git-명령어)
4. [Issue 기반 개발 흐름](#4-issue-기반-개발-흐름)
5. [Merge Request(MR) 흐름](#5-merge-requestmr-흐름)
6. [GitFlow vs GitHub Flow vs GitLab Flow 비교](#6-gitflow-vs-github-flow-vs-gitlab-flow-비교)
7. [장점과 단점](#7-장점과-단점)
8. [면접 포인트](#8-면접-포인트)

---

## 1. 개요

GitLab Flow는 GitLab이 2014년에 제안한 브랜치 전략으로, GitFlow와 GitHub Flow 사이의 중간 지점을 목표로 설계되었다.

- **GitFlow의 문제점**: 브랜치가 너무 많고 복잡하며, 릴리즈 주기가 길어지는 경향이 있다.
- **GitHub Flow의 문제점**: main 브랜치가 곧 프로덕션이라는 전제가 있어, 실제 배포 환경(staging, production 등)을 구분하기 어렵다.
- **GitLab Flow의 해결책**: main 브랜치를 중심으로 하되, 환경(environment) 별 브랜치를 추가하여 배포 상태를 명확하게 추적한다.

GitLab Flow의 핵심 철학은 **"upstream-first"** 원칙이다. 변경 사항은 반드시 상위(upstream) 브랜치에서 하위 브랜치로 흘러야 한다. 예를 들어, 코드는 `main` → `staging` → `production` 순서로만 merge된다.

GitLab Flow는 두 가지 방식으로 나뉜다.

- **환경 기반 브랜치(Environment Branches)**: staging, production 같은 환경 브랜치를 사용
- **릴리즈 기반 브랜치(Release Branches)**: 버전별 릴리즈 브랜치를 사용하는 방식 (모바일 앱 등에 적합)

---

## 2. 브랜치 구조

### 주요 브랜치

| 브랜치 이름 | 역할 |
|---|---|
| `main` | 항상 배포 가능한 최신 코드. 개발의 기준 브랜치 |
| `feature/*` | 기능 개발을 위한 단기 브랜치. main에서 분기, MR로 main에 합류 |
| `staging` | QA 및 통합 테스트 환경. main에서만 merge를 받음 |
| `pre-production` | 프로덕션 배포 직전 최종 검증 환경 (선택적) |
| `production` | 실제 서비스 환경. staging(또는 pre-production)에서만 merge를 받음 |

### upstream-first 원칙

```
feature/* → main → staging → pre-production → production
```

- 모든 코드는 반드시 `main`에 먼저 적용된다.
- `main`의 내용을 `staging`으로 merge한다.
- `staging`이 검증되면 `production`으로 merge한다.
- **핫픽스도 예외 없이** `main`에 먼저 적용한 뒤 아래로 내려보낸다.

### 브랜치 네이밍 규칙

```
feature/이슈번호-간단한-설명    # 예: feature/42-user-login
bugfix/이슈번호-간단한-설명     # 예: bugfix/55-fix-null-pointer
hotfix/이슈번호-간단한-설명     # 예: hotfix/60-critical-payment-bug
```

---

## 3. 환경별 브랜치 전략 및 git 명령어

### 환경 브랜치 초기 설정

```bash
# 저장소 초기화 및 환경 브랜치 생성
git checkout -b main
git push -u origin main

git checkout -b staging
git push -u origin staging

git checkout -b production
git push -u origin production
```

### 기능 개발 흐름

```bash
# 1. main 브랜치를 최신 상태로 업데이트
git checkout main
git pull origin main

# 2. 이슈 번호를 포함한 feature 브랜치 생성
git checkout -b feature/42-add-payment-method

# 3. 개발 진행 및 커밋
git add .
git commit -m "feat(payment): 신규 결제 수단 추가 (#42)"

# 4. main 브랜치의 최신 변경 사항을 rebase (충돌 최소화)
git fetch origin
git rebase origin/main

# 5. 원격 저장소에 push 후 MR 생성
git push origin feature/42-add-payment-method
```

### main → staging 배포

```bash
# staging 브랜치에 main의 내용을 merge
git checkout staging
git pull origin staging
git merge origin/main
git push origin staging

# GitLab CI/CD가 staging 환경에 자동 배포
```

### staging → production 배포

```bash
# QA 통과 후 production 브랜치에 merge
git checkout production
git pull origin production
git merge origin/staging
git push origin production

# GitLab CI/CD가 production 환경에 자동 배포
```

### 핫픽스 처리 (upstream-first 엄수)

```bash
# 1. main에서 핫픽스 브랜치 생성 (production이 아님!)
git checkout main
git pull origin main
git checkout -b hotfix/60-critical-payment-bug

# 2. 수정 및 커밋
git commit -m "fix(payment): 결제 오류 긴급 수정 (#60)"

# 3. main에 MR → merge
# 4. main → staging → production 순서로 내려보냄
git checkout staging && git merge origin/main && git push origin staging
git checkout production && git merge origin/staging && git push origin production
```

---

## 4. Issue 기반 개발 흐름

GitLab Flow는 GitLab Issue와 긴밀하게 연동되도록 설계되어 있다.

### 전체 흐름

```
[GitLab Issue 생성]
       ↓
[Issue 할당 및 브랜치 자동 생성]
       ↓
[로컬에서 개발 진행]
       ↓
[Merge Request 생성 (Draft MR 권장)]
       ↓
[코드 리뷰 및 피드백 반영]
       ↓
[MR Approve → main에 Merge]
       ↓
[Issue 자동 Close (close #이슈번호)]
```

### Issue와 브랜치 연결

GitLab에서는 Issue 페이지의 "Create merge request" 버튼을 누르면 이슈 번호가 포함된 브랜치와 Draft MR이 자동으로 생성된다.

```bash
# GitLab이 자동 생성하는 브랜치명 예시
42-add-payment-method

# 또는 수동으로 생성 시 명명 규칙 준수
git checkout -b feature/42-add-payment-method
```

### MR 본문에서 Issue 자동 Close

MR의 설명(description)이나 커밋 메시지에 다음 키워드를 사용하면 MR이 merge될 때 해당 Issue가 자동으로 Close된다.

```
Closes #42
Fixes #42
Resolves #42
```

---

## 5. Merge Request(MR) 흐름

### Draft MR (작업 중 공개)

기능 개발 초반부터 MR을 열어 진행 상황을 팀과 공유한다. 리뷰 요청 전까지는 Draft 상태로 유지한다.

```
MR 제목 예시:
Draft: feat(auth): 소셜 로그인 기능 추가 (#42)
```

### MR 체크리스트 예시

```markdown
## 변경 사항
- [ ] 카카오 소셜 로그인 API 연동
- [ ] 로그인 성공/실패 처리
- [ ] 단위 테스트 작성

## 테스트 방법
1. 로컬 서버 실행
2. /login 페이지에서 카카오 로그인 버튼 클릭
3. 정상 리다이렉트 확인

Closes #42
```

### MR Approve 및 Merge 정책

- **최소 1명 이상의 Approve** 필요 (Protected Branch 설정)
- CI 파이프라인 통과 필수
- **Squash and merge** 또는 **Merge commit** 선택
  - Squash: feature 브랜치의 커밋을 하나로 합쳐 main을 깔끔하게 유지
  - Merge commit: 개발 히스토리를 그대로 보존

---

## 6. GitFlow vs GitHub Flow vs GitLab Flow 비교

| 항목 | GitFlow | GitHub Flow | GitLab Flow |
|---|---|---|---|
| 핵심 브랜치 | main, develop, feature, release, hotfix | main, feature | main, feature, environment |
| 복잡도 | 높음 | 낮음 | 중간 |
| 릴리즈 주기 | 정해진 주기 (주기적 배포) | 수시 배포 | 환경 기반 점진적 배포 |
| 환경 구분 | 명시적이지 않음 | 없음 (main = production) | staging, production 브랜치로 명확히 구분 |
| 핫픽스 처리 | hotfix 브랜치 | main에서 직접 처리 | main → 환경 브랜치 순서 |
| Issue 연동 | 없음 | 없음 | GitLab Issue와 긴밀하게 연동 |
| CI/CD 친화도 | 보통 | 높음 | 매우 높음 |
| 적합한 팀 | 레거시, 정형화된 릴리즈 | 소규모, 스타트업 | 중규모, 다중 환경 운영 |

---

## 7. 장점과 단점

### 장점

1. **환경별 배포 상태 추적이 명확하다**
   - 어떤 코드가 어느 환경에 배포되어 있는지 브랜치만 보면 즉시 알 수 있다.
   - `git log staging..production` 명령으로 아직 프로덕션에 반영되지 않은 커밋을 확인할 수 있다.

2. **upstream-first 원칙으로 배포 사고를 예방한다**
   - main을 거치지 않고 production에 직접 merge하는 실수를 구조적으로 방지한다.

3. **GitHub Flow보다 실무 환경에 적합하다**
   - 대부분의 서비스는 개발, 스테이징, 프로덕션 등 복수의 환경을 운영하므로 GitLab Flow가 현실적이다.

4. **GitLab Issue, CI/CD 파이프라인과 자연스럽게 통합된다**
   - 이슈 트래킹, 코드 리뷰, 자동 배포가 하나의 플랫폼에서 처리된다.

5. **GitFlow보다 단순하다**
   - develop 브랜치, release 브랜치 등 불필요한 브랜치가 줄어든다.

### 단점

1. **팀 규모와 환경 수에 따라 복잡도가 증가한다**
   - 환경 브랜치가 늘어날수록 (dev → qa → staging → pre-prod → prod) 관리 부담이 증가한다.
   - merge 체인이 길어져 배포 속도가 느려질 수 있다.

2. **upstream-first 원칙을 팀 전체가 엄격히 지켜야 한다**
   - 실수로 production에 직접 push하는 경우를 방지하기 위해 Protected Branch 설정이 필수다.

3. **소규모 팀에게는 과도한 구조일 수 있다**
   - 1~2명의 팀에서는 GitHub Flow가 더 효율적일 수 있다.

---

## 8. 면접 포인트

**Q1. GitLab Flow에서 upstream-first 원칙이란 무엇인가요?**

> 코드 변경 사항이 반드시 상위 브랜치에서 하위 브랜치 방향으로만 흘러야 한다는 원칙입니다. `main` → `staging` → `production` 순서로만 merge가 이루어지며, 핫픽스도 예외 없이 main에 먼저 적용한 뒤 아래로 내려보냅니다. 이를 통해 배포 환경 간 코드 불일치를 방지합니다.

**Q2. GitLab Flow와 GitHub Flow의 가장 큰 차이점은 무엇인가요?**

> GitHub Flow는 main 브랜치가 곧 프로덕션이라는 단순한 구조입니다. 반면 GitLab Flow는 staging, production 같은 환경 브랜치를 별도로 두어 실제 배포 환경을 명시적으로 구분합니다. 따라서 다중 배포 환경을 운영하는 팀에는 GitLab Flow가 더 적합합니다.

**Q3. GitLab Flow에서 핫픽스는 어떻게 처리하나요?**

> 반드시 main 브랜치에서 핫픽스 브랜치를 생성하여 수정하고, MR을 통해 main에 먼저 merge합니다. 그 후 main → staging → production 순서로 내려보냅니다. production에 직접 hotfix를 적용하면 main과 코드가 달라지는 문제가 발생하므로 upstream-first 원칙을 반드시 지켜야 합니다.

**Q4. GitLab Flow에서 Draft MR을 사용하는 이유는 무엇인가요?**

> 개발 초기 단계부터 MR을 열어 팀원들과 방향성을 공유하고, 조기에 피드백을 받기 위해 사용합니다. Draft 상태에서는 실수로 merge되는 것을 방지할 수 있으며, WIP(Work In Progress) 상태임을 명시적으로 알릴 수 있습니다.

**Q5. GitLab Flow의 환경 브랜치는 몇 개까지 만들 수 있나요? 많으면 어떤 문제가 생기나요?**

> 기술적으로는 제한이 없지만, 환경 브랜치가 많아질수록 merge 체인이 길어져 배포 속도가 느려지고 관리 부담이 증가합니다. 각 merge 단계마다 CI/CD 파이프라인이 실행되므로 총 배포 시간도 길어집니다. 실무에서는 main, staging, production 세 개의 브랜치가 가장 일반적인 구성입니다.

**Q6. GitLab Flow에서 Issue와 MR은 어떻게 연동되나요?**

> GitLab에서 Issue 페이지의 "Create merge request" 버튼을 통해 이슈 번호가 포함된 브랜치와 Draft MR을 자동으로 생성할 수 있습니다. MR 설명이나 커밋 메시지에 `Closes #42`와 같은 키워드를 작성하면, MR이 merge될 때 해당 Issue가 자동으로 Close됩니다.

**Q7. GitLab Flow가 GitFlow보다 CI/CD 친화적인 이유는 무엇인가요?**

> GitFlow는 develop, release, hotfix 등 여러 브랜치가 동시에 존재하여 CI/CD 파이프라인 구성이 복잡합니다. GitLab Flow는 main 브랜치를 항상 배포 가능한 상태로 유지하고, 환경 브랜치 push 이벤트에 자동 배포를 트리거하도록 구성하면 됩니다. 따라서 파이프라인 구성이 단순하고 환경별 배포 상태가 브랜치로 명확히 표현됩니다.
