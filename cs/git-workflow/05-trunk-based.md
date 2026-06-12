# 5. Trunk-Based Development

## 목차

1. [개요](#1-개요)
2. [핵심 원칙](#2-핵심-원칙)
3. [Feature Flag (기능 토글)](#3-feature-flag-기능-토글)
4. [CI/CD 필수 조건](#4-cicd-필수-조건)
5. [대규모 팀 사례](#5-대규모-팀-사례)
6. [Short-lived Feature Branches 방식](#6-short-lived-feature-branches-방식)
7. [장점과 단점](#7-장점과-단점)
8. [GitFlow와 비교](#8-gitflow와-비교)
9. [면접 포인트](#9-면접-포인트)

---

## 1. 개요

Trunk-Based Development(TBD)는 **하나의 trunk(줄기) 브랜치**를 중심으로 모든 개발자가 지속적으로 통합하는 브랜치 전략이다. 여기서 trunk는 보통 `main` 또는 `master` 브랜치를 의미한다.

핵심 아이디어는 다음과 같다.

- 개발자들은 **하루에 한 번 이상** main 브랜치에 코드를 push한다.
- 브랜치를 사용하더라도 **1~2일 이내**에 main으로 merge한다.
- main 브랜치는 **항상 배포 가능한(shippable) 상태**를 유지한다.
- 장기 브랜치(long-lived branch)를 완전히 금지하거나 최소화한다.

TBD는 **지속적 통합(Continuous Integration)**의 철학과 가장 잘 맞는 브랜치 전략이며, Google, Facebook(Meta), Microsoft 같은 대형 기술 기업들이 실제로 사용하는 방식이다.

### 등장 배경

기존 GitFlow 방식에서는 feature 브랜치가 수 주 동안 main(develop)과 멀어지다가 merge할 때 대규모 충돌이 발생하는 "merge hell" 문제가 빈번했다. TBD는 이 문제를 근본적으로 해결하기 위해, 통합 주기를 극단적으로 짧게 만드는 접근법을 택했다.

---

## 2. 핵심 원칙

### 원칙 1: 하루 한 번 이상 main 브랜치에 통합

```bash
# 매일 아침: main 최신화
git checkout main
git pull origin main

# 작업 후 당일 push
git add .
git commit -m "feat(cart): 장바구니 아이템 수량 변경 기능 추가"
git push origin main
```

- 코드가 main과 분리된 시간이 길수록 merge 비용이 지수적으로 증가한다.
- 소규모 단위로 자주 통합하면 충돌이 작고, 발견도 빠르다.

### 원칙 2: 브랜치는 짧게 (1~2일)

```bash
# 브랜치를 사용할 경우에도 최대 2일 이내 merge
git checkout -b feature/add-coupon-input
# ... 개발 ...
git push origin feature/add-coupon-input
# 당일 또는 다음 날 PR/MR 생성 및 merge
```

- 브랜치 수명이 길어질수록 TBD의 장점이 사라진다.
- 브랜치가 2일을 넘기면 "작업을 쪼갤 수 있는지" 먼저 검토한다.

### 원칙 3: 항상 배포 가능한 main

```bash
# main에 push 또는 merge 시 자동으로 CI 파이프라인 실행
# 테스트 실패 시 즉시 수정 또는 revert
git revert HEAD  # 문제가 되는 커밋 즉시 되돌리기
git push origin main
```

- main이 깨지면 팀 전체의 개발이 멈추므로, main 보호는 팀의 최우선 과제다.
- "빨간 빌드(red build)를 10분 이상 방치하지 않는다"는 문화가 중요하다.

---

## 3. Feature Flag (기능 토글)

Feature Flag(기능 토글, Feature Toggle)는 **아직 완성되지 않은 코드를 main에 merge하면서도 사용자에게는 노출하지 않는** 기법이다. TBD에서 가장 핵심적인 기술적 도구다.

### 기본 원리

```javascript
// featureFlags.js - 플래그 관리 모듈
const featureFlags = {
  newCheckout: process.env.FEATURE_NEW_CHECKOUT === 'true',
  darkMode: process.env.FEATURE_DARK_MODE === 'true',
  aiRecommendation: process.env.FEATURE_AI_RECOMMENDATION === 'true',
};

module.exports = featureFlags;
```

```javascript
// checkout.js - 미완성 기능을 플래그로 감싸기
const featureFlags = require('./featureFlags');

function renderCheckoutPage(user) {
  if (featureFlags.newCheckout) {
    // 신규 체크아웃 UI (개발 중)
    return renderNewCheckoutUI(user);
  }
  // 기존 체크아웃 UI (안정적)
  return renderLegacyCheckoutUI(user);
}
```

```python
# Python 예시 - A/B 테스트와 결합
def get_recommendation(user_id):
    if feature_flags.get('ai_recommendation') and is_beta_user(user_id):
        return ai_based_recommendation(user_id)
    return rule_based_recommendation(user_id)
```

### 환경별 플래그 설정 예시

```yaml
# .env.development
FEATURE_NEW_CHECKOUT=true
FEATURE_DARK_MODE=true
FEATURE_AI_RECOMMENDATION=true

# .env.production
FEATURE_NEW_CHECKOUT=false   # 아직 개발 중
FEATURE_DARK_MODE=true       # 완성 및 검증 완료
FEATURE_AI_RECOMMENDATION=false
```

### Feature Flag의 종류

| 종류 | 목적 | 수명 |
|---|---|---|
| Release Toggle | 미완성 기능 숨기기 (TBD의 핵심) | 기능 완성 후 제거 |
| Experiment Toggle | A/B 테스트 | 실험 종료 후 제거 |
| Ops Toggle | 장애 시 기능 끄기 (Circuit Breaker) | 반영구적 |
| Permission Toggle | 특정 사용자/그룹에만 노출 | 비교적 장기 |

### 배포와 릴리즈의 분리

TBD + Feature Flag의 가장 큰 이점은 **배포(Deploy)와 릴리즈(Release)를 분리**할 수 있다는 점이다.

```
배포: 코드를 서버에 올리는 행위 → 언제든 가능
릴리즈: 사용자에게 기능을 노출하는 행위 → 플래그로 제어
```

이를 통해 언제든 안전하게 main을 프로덕션에 배포할 수 있고, 비즈니스 결정에 따라 원하는 시점에 기능을 활성화할 수 있다.

### Feature Flag 주의사항: 기술 부채

```javascript
// 나쁜 예: 플래그를 제거하지 않고 오래 방치
if (featureFlags.newCheckout) {
  // 이미 모든 환경에서 true인데 플래그가 남아 있음
  return renderNewCheckoutUI(user);
}
return renderLegacyCheckoutUI(user); // 이제 죽은 코드
```

기능이 완전히 릴리즈된 후에는 반드시 Feature Flag와 관련 레거시 코드를 제거하는 후속 작업이 필요하다.

---

## 4. CI/CD 필수 조건

TBD는 강력한 CI/CD 파이프라인 없이는 동작하지 않는다. 다음 세 가지가 반드시 갖춰져야 한다.

### 자동화 테스트 필수

```yaml
# .github/workflows/ci.yml 예시
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: 단위 테스트 실행
        run: npm test
      - name: 통합 테스트 실행
        run: npm run test:integration
      - name: 코드 커버리지 확인 (80% 이상 필수)
        run: npm run test:coverage
```

- main에 push할 때마다 자동으로 테스트가 실행되어야 한다.
- 테스트 실패 시 배포가 차단되어야 한다.
- 테스트 실행 시간은 10분 이내가 이상적이다 (빠른 피드백을 위해).

### Feature Flag 관리

- LaunchDarkly, Flagsmith, Unleash 같은 전용 Feature Flag 관리 도구 사용을 권장한다.
- 플래그 이름, 담당자, 만료 예정일을 관리하는 레지스트리를 유지한다.

```javascript
// flagsmith 또는 LaunchDarkly 연동 예시
const flagsmith = require('flagsmith-nodejs');

await flagsmith.init({ environmentKey: process.env.FLAGSMITH_KEY });

const isNewCheckoutEnabled = flagsmith.hasFeature('new_checkout');
```

### 모니터링

```
코드 push → CI 테스트 → 자동 배포 → 실시간 모니터링
                                          ↓
                               에러율 급증 감지 시 자동 알림
                                          ↓
                              즉시 feature flag off 또는 revert
```

- 배포 후 에러율, 응답 시간, 비즈니스 지표를 실시간으로 관찰한다.
- 이상 징후 감지 시 Feature Flag를 끄거나 즉시 revert할 수 있는 체계를 갖춘다.

---

## 5. 대규모 팀 사례

### Google

Google은 수만 명의 엔지니어가 하나의 모노레포(monorepo)에서 TBD 방식으로 개발한다. "Piper"라는 내부 버전 관리 시스템을 사용하며, 모든 엔지니어가 head(trunk)에 직접 커밋한다. 강력한 자동화 테스트와 코드 리뷰 시스템(Critique)이 이를 뒷받침한다.

### Facebook(Meta)

Facebook은 "land to trunk" 정책을 사용하며, 모든 코드가 main 브랜치에 직접 통합된다. Gatekeeper라는 Feature Flag 시스템을 통해 새 기능을 점진적으로 (1% → 10% → 100%) 사용자에게 노출한다.

### Microsoft

Visual Studio Team Services(현 Azure DevOps) 팀은 TBD를 도입한 후, 이전에 3주마다 하던 배포를 하루 여러 번으로 바꿨다. Ring-based deployment를 통해 내부 직원 → 얼리어답터 → 전체 사용자 순으로 릴리즈한다.

공통점: 세 회사 모두 **강력한 자동화 테스트**, **Feature Flag**, **점진적 롤아웃** 시스템을 기반으로 TBD를 운영한다.

---

## 6. Short-lived Feature Branches 방식

순수 TBD(main에 직접 push)가 아닌, 짧은 수명의 feature 브랜치를 사용하는 변형 방식이다. 코드 리뷰 문화가 있는 팀에 더 적합하다.

### 규칙

- 브랜치 수명은 **최대 2일(48시간)**
- PR/MR을 열면 당일 리뷰 완료를 목표로 한다.
- 브랜치가 2일을 넘기면 강제로 main에 merge하거나 작업을 쪼갠다.

### 실제 예시

```bash
# Day 1 오전: 브랜치 생성 및 개발 시작
git checkout main && git pull origin main
git checkout -b feature/user-profile-avatar

# Day 1 오후: 작업 완료 및 PR 생성
git add src/components/Avatar.jsx src/components/Avatar.test.jsx
git commit -m "feat(profile): 사용자 프로필 아바타 업로드 기능 추가"
git push origin feature/user-profile-avatar
# GitHub/GitLab에서 PR/MR 생성

# Day 2 오전: 리뷰 피드백 반영
git commit -m "fix(profile): 파일 크기 제한 유효성 검사 추가"
git push origin feature/user-profile-avatar

# Day 2 오후: Approve 후 merge → 브랜치 삭제
git checkout main
git branch -d feature/user-profile-avatar
git push origin --delete feature/user-profile-avatar
```

### 작업이 2일 이내에 끝나지 않을 경우

```bash
# 미완성 코드를 Feature Flag로 감싸서 main에 merge
# flag: profile_avatar_upload = false (기본값)

git checkout main
git merge feature/user-profile-avatar
git push origin main  # CI 통과 후 배포 (기능은 비활성)

# 이후 남은 작업을 새 브랜치에서 계속 진행
git checkout -b feature/user-profile-avatar-part2
```

---

## 7. 장점과 단점

### 장점

1. **CI/CD 친화적**
   - main이 항상 배포 가능한 상태이므로, 원하는 시점에 즉시 배포할 수 있다.
   - 배포 주기를 일 단위, 시간 단위로 단축할 수 있다.

2. **머지 충돌 최소화**
   - 자주 통합하므로 충돌이 작고, 발생 즉시 해결된다.
   - "merge hell"이 발생하지 않는다.

3. **코드 리뷰 품질 향상**
   - 작은 단위의 변경을 자주 리뷰하므로 리뷰어의 부담이 줄고, 더 꼼꼼한 검토가 가능하다.

4. **빠른 피드백 루프**
   - 코드가 main에 통합되는 즉시 CI가 실행되어 문제를 빠르게 발견한다.

5. **배포와 릴리즈 분리 (Feature Flag 사용 시)**
   - 비즈니스 타이밍에 맞춰 기능을 노출할 수 있다.
   - 문제 발생 시 플래그만 끄면 즉시 롤백 효과를 낼 수 있다.

### 단점

1. **팀 성숙도와 규율이 필요하다**
   - 모든 팀원이 작은 단위로 작업을 분해하고 자주 통합하는 습관을 길러야 한다.
   - 테스트 작성 문화가 없는 팀에서는 main이 자주 깨진다.

2. **Feature Flag 관리 부담**
   - 플래그가 쌓이면 코드베이스가 복잡해지고 기술 부채가 된다.
   - 플래그 청소(cleanup) 작업을 지속적으로 해야 한다.

3. **강력한 자동화 인프라가 필수**
   - CI 파이프라인, 자동화 테스트, 모니터링 시스템을 구축하는 초기 투자 비용이 크다.

4. **작업 단위 분해가 어렵다**
   - 대규모 리팩터링이나 DB 스키마 변경 같은 작업을 작은 단위로 쪼개는 것이 쉽지 않다.

---

## 8. GitFlow와 비교

| 항목 | GitFlow | Trunk-Based Development |
|---|---|---|
| 브랜치 수 | 많음 (main, develop, feature, release, hotfix) | 최소 (main 하나, 또는 단기 feature) |
| 통합 주기 | 길다 (feature 완성 후) | 매우 짧다 (하루 1회 이상) |
| 배포 주기 | 정기 릴리즈 (주 단위, 월 단위) | 수시 (하루 여러 번) |
| 충돌 빈도 | 높음 (장기 브랜치로 인한 merge hell) | 낮음 (소규모 충돌이지만 자주) |
| Feature Flag | 불필요 (브랜치로 격리) | 필수 |
| 자동화 테스트 | 권장 | 필수 |
| 학습 곡선 | 낮음 (브랜치 규칙만 따르면 됨) | 높음 (팀 규율, 인프라 필요) |
| 적합한 팀 | 정기 릴리즈, 레거시 시스템 | 고성숙도 팀, 빠른 배포 지향 |
| 핫픽스 | hotfix 브랜치 별도 생성 | main에서 즉시 수정 후 배포 |

### 언제 TBD를 선택하고, 언제 GitFlow를 선택하는가?

**TBD가 적합한 경우**
- 하루에도 여러 번 배포해야 하는 서비스
- 팀 전체의 테스트 작성 문화가 정착된 경우
- SaaS 제품 (항상 최신 버전을 서버에서 운영)

**GitFlow가 적합한 경우**
- 모바일 앱, 패키지 등 버전 관리가 중요한 경우
- 정해진 릴리즈 주기가 있는 경우 (예: 매월 1일 배포)
- 레거시 시스템으로 자동화 인프라 구축이 어려운 경우

---

## 9. 면접 포인트

**Q1. Trunk-Based Development란 무엇이며, 왜 사용하나요?**

> TBD는 모든 개발자가 하루 한 번 이상 main(trunk) 브랜치에 코드를 통합하는 브랜치 전략입니다. 장기 브랜치로 인한 머지 충돌(merge hell)을 방지하고, 지속적 통합(CI)과 지속적 배포(CD)를 가능하게 하기 위해 사용합니다.

**Q2. Feature Flag가 TBD에서 왜 중요한가요?**

> TBD에서는 미완성 코드도 main에 merge해야 하므로, Feature Flag를 사용하여 아직 준비되지 않은 기능을 프로덕션 환경에서 비활성화합니다. 이를 통해 코드 배포와 기능 릴리즈를 분리하여 언제든 안전하게 배포할 수 있습니다.

**Q3. TBD를 도입하기 위해 팀에 반드시 필요한 조건은 무엇인가요?**

> 세 가지가 필수입니다. 첫째, 자동화 테스트 (main이 항상 통과해야 하므로). 둘째, Feature Flag 시스템 (미완성 기능 격리를 위해). 셋째, 팀 전체의 규율 (작업 분해, 빠른 통합 습관). 이 중 하나라도 없으면 main이 자주 깨지는 문제가 발생합니다.

**Q4. Short-lived Feature Branch란 무엇이고, 순수 TBD와 어떻게 다른가요?**

> Short-lived Feature Branch는 TBD의 변형으로, main에 직접 push하는 대신 최대 1~2일 수명의 짧은 브랜치를 사용하고 PR/MR로 코드 리뷰를 거친 후 merge합니다. 순수 TBD보다 코드 리뷰를 통한 품질 관리가 가능하며, 코드 리뷰 문화가 있는 팀에 더 현실적인 방식입니다.

**Q5. Google이나 Facebook 같은 대기업이 TBD를 사용할 수 있는 이유는 무엇인가요?**

> 이들 기업은 수천 개의 자동화 테스트, Feature Flag 시스템(Facebook의 Gatekeeper 등), 점진적 롤아웃(1% → 100%) 인프라, 그리고 강력한 모니터링 시스템을 갖추고 있습니다. 기술 인프라와 팀 문화가 충분히 성숙했기 때문에 가능합니다.

**Q6. TBD에서 장기 리팩터링이나 대규모 변경 작업은 어떻게 처리하나요?**

> 두 가지 방법을 사용합니다. 첫째, 작업을 여러 개의 작은 커밋으로 쪼개서 단계적으로 main에 통합합니다. 둘째, Feature Flag로 새 구현을 감싸고 점진적으로 전환합니다 (Branch by Abstraction 패턴). DB 스키마 변경의 경우 Expand-Contract 패턴을 사용합니다.

**Q7. TBD에서 "main이 깨졌을 때" 어떻게 대응하나요?**

> 빨간 빌드는 최우선 해결 과제입니다. 원인 파악이 10분 이내에 가능하면 즉시 수정, 그렇지 않으면 `git revert`로 문제 커밋을 즉시 되돌립니다. 팀 전체에 Slack 등으로 알림을 보내 새로운 push를 잠시 멈춥니다. "깨진 빌드를 절대 방치하지 않는다"는 팀 문화가 핵심입니다.
