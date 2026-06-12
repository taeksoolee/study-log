# 7. XP & Lean 개발 방법론

## 목차
1. XP (eXtreme Programming) 개요
2. XP의 5가지 가치
3. XP의 12가지 프랙티스
4. 개발자에게 직접 관련된 프랙티스 상세
5. Lean Software Development 개요
6. 린의 7가지 원칙
7. 낭비의 종류
8. XP vs Scrum vs Kanban 비교
9. 면접 포인트

---

## 1. XP (eXtreme Programming) 개요

XP는 1999년 Kent Beck이 체계화한 애자일 소프트웨어 개발 방법론입니다. "좋은 실천들을 극단적으로(extreme) 적용하면 어떨까?"라는 아이디어에서 출발했습니다.

```
핵심 철학:
  변화는 불가피하다 → 변화를 비용 없이 수용할 수 있도록 코드를 유지하라
  불확실성을 제거하려 하지 말고 → 변화에 빠르게 대응하는 역량을 키워라

XP가 주목받는 이유:
  - TDD, 리팩토링, CI 등 현재 당연시되는 실천들을 체계화
  - 코드 품질과 팀 협업을 동시에 다룸
  - 기술적 탁월성(technical excellence)을 방법론의 핵심으로 삼음
```

---

## 2. XP의 5가지 가치

### Communication (의사소통)

```
문제의 대부분은 소통 부재에서 발생한다.

실천:
  - 페어 프로그래밍: 실시간 지식 공유
  - 팀 전체가 같은 공간(또는 채널)에서 작업
  - 코드 자체가 문서: 명확한 이름, 주석 대신 리팩토링
```

### Simplicity (단순성)

```
"오늘 필요한 것만 만들어라. 내일 필요한 것은 내일 만들어라."
YAGNI (You Aren't Gonna Need It)

실천:
  - 과설계(over-engineering) 금지
  - 현재 요구사항에만 집중
  - 단순한 해결책이 복잡한 것보다 항상 우선
```

### Feedback (피드백)

```
빠른 피드백이 리스크를 줄인다.

피드백 루프 (빠른 순):
  1. 테스트 실행 (초 단위)
  2. 페어 프로그래밍 (분 단위)
  3. 일일 통합 CI (시간 단위)
  4. 이터레이션 리뷰 (주 단위)
  5. 릴리즈 후 고객 피드백 (월 단위)
```

### Courage (용기)

```
올바른 일을 할 수 있는 용기

실천이 필요한 상황:
  - 나쁜 코드를 발견했을 때 리팩토링하는 용기
  - 일정 압박 속에서 테스트를 작성하는 용기
  - 추정이 틀렸을 때 솔직히 말하는 용기
  - 기술 부채를 팀에 공유하는 용기
```

### Respect (존중)

```
팀원 간, 고객과의 상호 존중

실천:
  - 코드 리뷰에서 코드를 비판하되 사람을 비판하지 않음
  - 페어가 다른 방식을 제안할 때 경청
  - 모든 팀원의 기여를 동등하게 인정
```

---

## 3. XP의 12가지 프랙티스

```
계획 관련:
  1.  계획 게임 (Planning Game)
  2.  소규모 릴리즈 (Small Releases)
  3.  은유 (Metaphor)

개발 관련:
  4.  단순한 설계 (Simple Design)
  5.  테스트 주도 개발 (TDD)
  6.  리팩토링 (Refactoring)
  7.  페어 프로그래밍 (Pair Programming)

팀 관련:
  8.  공동 코드 소유 (Collective Ownership)
  9.  지속적 통합 (Continuous Integration)
  10. 주당 40시간 근무 (Sustainable Pace)
  11. 현장 고객 (On-site Customer)
  12. 코딩 표준 (Coding Standards)
```

---

## 4. 개발자에게 직접 관련된 프랙티스 상세

### 테스트 주도 개발 (TDD)

```
Red → Green → Refactor 사이클

1. Red:    실패하는 테스트 먼저 작성
2. Green:  테스트를 통과하는 최소한의 코드 작성
3. Refactor: 코드 품질 개선 (테스트는 여전히 통과)
```

```typescript
// 1. Red: 실패하는 테스트 작성
describe('calculateDiscount', () => {
  it('VIP 고객은 20% 할인을 받는다', () => {
    const result = calculateDiscount(10000, 'VIP');
    expect(result).toBe(8000); // 아직 함수가 없으므로 실패
  });
});

// 2. Green: 최소한의 구현
function calculateDiscount(price: number, tier: string): number {
  if (tier === 'VIP') return price * 0.8;
  return price;
}

// 3. Refactor: 개선
type CustomerTier = 'VIP' | 'GOLD' | 'STANDARD';
const DISCOUNT_RATES: Record<CustomerTier, number> = {
  VIP: 0.2,
  GOLD: 0.1,
  STANDARD: 0,
};

function calculateDiscount(price: number, tier: CustomerTier): number {
  const discountRate = DISCOUNT_RATES[tier] ?? 0;
  return price * (1 - discountRate);
}
```

### 페어 프로그래밍 (Pair Programming)

```
두 개발자가 한 컴퓨터에서 작업

역할:
  Driver:   코드를 직접 작성
  Navigator: 전략적 방향 제시, 오류 검토

교대: 25~30분마다 역할 전환

원격 페어링 도구:
  - VS Code Live Share
  - JetBrains Code With Me
  - Tuple

효과:
  - 실시간 코드 리뷰
  - 지식 전파 (버스 팩터 감소)
  - 집중력 향상 (소셜 압력)

오해: 생산성이 절반으로 줄지 않나?
현실: 버그가 적고, 리뷰 시간이 줄고, 온보딩이 빨라짐
```

### 리팩토링 (Refactoring)

```
"기능을 바꾸지 않고 코드 구조를 개선한다"

리팩토링이 안전한 조건:
  → 테스트가 있어야 한다 (테스트 없는 리팩토링은 도박)

보이 스카우트 규칙:
  "캠핑장을 처음보다 깨끗하게 남겨라"
  → 내가 건드린 코드는 조금이라도 더 나은 상태로 남긴다
```

```typescript
// Before: 리팩토링 전
function processOrder(o: any) {
  if (o.s === 'p') {
    const t = o.i * o.p;
    const d = t * 0.1;
    return t - d;
  }
  return 0;
}

// After: 리팩토링 후 (동일한 동작, 명확한 의도)
function calculateOrderTotal(order: Order): number {
  if (order.status !== 'PAID') return 0;

  const subtotal = order.quantity * order.unitPrice;
  const discount = subtotal * PAID_ORDER_DISCOUNT_RATE;
  return subtotal - discount;
}

const PAID_ORDER_DISCOUNT_RATE = 0.1;
```

### 지속적 통합 (Continuous Integration)

```
원칙:
  - 매일 (또는 수시로) 메인 브랜치에 통합
  - 통합 후 자동 빌드 및 테스트
  - 빌드 실패 시 즉시 수정 (최우선 과제)

장기 브랜치의 문제:
  1주 작업 후 머지 → 충돌 해결에 또 수 시간
  매일 머지 → 충돌은 있지만 작고 빠르게 해결
```

### 소규모 릴리즈 (Small Releases)

```
자주, 작게 배포하면:
  ✓ 위험 분산 (문제 발생 시 되돌리기 쉬움)
  ✓ 빠른 피드백 (실제 사용자 반응 확인)
  ✓ 배포 프로세스 개선 (자주 하면 능숙해짐)

Feature Flag를 이용한 소규모 릴리즈:
```

```typescript
// Feature Flag로 점진적 릴리즈
const featureFlags = {
  newCheckoutFlow: process.env.FEATURE_NEW_CHECKOUT === 'true',
};

function CheckoutPage() {
  if (featureFlags.newCheckoutFlow) {
    return <NewCheckoutFlow />;
  }
  return <LegacyCheckoutFlow />;
}
```

---

## 5. Lean Software Development 개요

린(Lean)은 도요타 생산 시스템(TPS)을 소프트웨어에 적용한 방법론입니다. 2003년 Mary & Tom Poppendieck이 저서 "Lean Software Development"에서 체계화했습니다.

```
린의 핵심 질문:
  "고객에게 가치를 전달하는 흐름에서 낭비(waste)는 무엇인가?"

린 vs 애자일:
  애자일: 불확실성에 적응하는 방법
  린:     가치 흐름에서 낭비를 제거하는 방법
  → 상호 보완적 (린의 원칙 + 애자일의 프랙티스)
```

---

## 6. 린의 7가지 원칙

### 1. 낭비 제거 (Eliminate Waste)

```
가치를 추가하지 않는 모든 것이 낭비
→ 고객이 기꺼이 비용을 지불할 만한 활동만 가치 있음
```

### 2. 품질 내재화 (Build Quality In)

```
테스트로 품질을 검증하는 게 아니라
코드 작성 단계에서 품질을 만든다

TDD, 페어 프로그래밍, 코드 리뷰가 이를 실현하는 도구
```

### 3. 지식 창출 (Create Knowledge)

```
소프트웨어 개발은 반복이 아닌 학습 과정
→ 실험하고, 배우고, 문서화하라

스파이크(Spike): 기술적 불확실성 해소를 위한 탐구 작업
```

### 4. 늦은 결정 (Defer Commitment)

```
결정을 가능한 한 늦추어 더 많은 정보를 확보

나쁜 예: 1월에 12월 아키텍처를 확정
좋은 예: 필요한 시점에 가장 많은 정보로 결정

취소 가능한 옵션을 유지하라 (가역적 결정)
```

### 5. 빠른 전달 (Deliver Fast)

```
빠른 전달 ≠ 서두름
빠른 전달 = 낭비 없는 효율적 흐름

속도를 높이는 방법:
  - WIP 감소
  - 배치 크기 감소
  - 대기 시간 감소
```

### 6. 사람 존중 (Respect People)

```
팀원을 비용이 아닌 지식 자원으로 바라봄

실천:
  - 현장 지식 존중: 개발자가 기술적 결정에 참여
  - 자율성 부여: 어떻게 할지는 팀이 결정
  - 성장 투자: 학습 시간, 컨퍼런스 지원
```

### 7. 전체 최적화 (Optimize the Whole)

```
부분 최적화의 함정:
  개발팀의 속도를 높였지만 QA 팀이 병목이 됨
  → 전체 처리량은 변화 없음

시스템 사고:
  → 가치 흐름 전체를 보고 병목을 제거
  → 한 팀의 KPI가 다른 팀에 역효과를 낳지 않도록
```

---

## 7. 낭비의 종류

```
도요타 7가지 낭비를 소프트웨어에 적용:

┌────────────────────┬─────────────────────────────────────────────┐
│ 제조업 낭비         │ 소프트웨어 낭비                               │
├────────────────────┼─────────────────────────────────────────────┤
│ 재고 과잉           │ 미완성 작업 (WIP 쌓기)                       │
│ 과잉 생산           │ 사용되지 않는 기능 개발                       │
│ 불필요한 처리        │ 과잉 프로세스 (불필요한 문서, 승인)           │
│ 불필요한 이동        │ 수작업 핸드오프, 작업 전환                    │
│ 대기                │ 요구사항 대기, 코드 리뷰 대기, 배포 대기       │
│ 결함                │ 버그, 기술 부채                               │
│ 재능 낭비           │ 관료주의, 역량을 살리지 못하는 업무 배치      │
└────────────────────┴─────────────────────────────────────────────┘
```

### 가장 큰 낭비: 사용되지 않는 기능

```
연구 결과: 출시된 기능의 64%가 거의 또는 전혀 사용되지 않음
           (Standish Group, Chaos Report)

해결책:
  - MVP (Minimum Viable Product): 핵심 기능만 먼저
  - A/B 테스트: 데이터로 검증 후 개발
  - 고객 인터뷰: 만들기 전에 필요한지 확인
```

---

## 8. XP vs Scrum vs Kanban 비교

| 구분 | XP | Scrum | Kanban |
|------|-----|-------|--------|
| 분류 | 방법론 (기술 집중) | 프레임워크 (팀 집중) | 방법론 (흐름 집중) |
| 이터레이션 | 1~2주 (짧음) | 1~4주 스프린트 | 없음 (연속 흐름) |
| 기술 프랙티스 | TDD, 페어링, CI 등 명시 | 명시 없음 | 명시 없음 |
| 역할 | 고객, 코치, 팀 | PO, SM, Dev 팀 | 없음 |
| 계획 단위 | 릴리즈 + 이터레이션 | 스프린트 | 수시 |
| 변경 수용 | 환영 (기술로 대응) | 스프린트 중 지양 | 언제든 가능 |
| WIP 제한 | 암묵적 (작은 배치) | 스프린트 용량 | 명시적 |
| 코드 품질 | 최우선 관심사 | 팀 자율 | 팀 자율 |
| 진입 장벽 | 높음 (TDD 등 학습) | 중간 | 낮음 |
| 적합 팀 | 기술적으로 성숙한 팀 | 제품 개발 팀 | 운영/지원 팀 |

### 실무 조합 예시

```
대부분의 성숙한 팀은 복합적으로 활용:

  스크럼 프레임워크
    + XP의 기술 프랙티스 (TDD, CI, 리팩토링)
    + 린의 낭비 제거 관점
    + 칸반의 시각화와 WIP 제한

→ "애자일 팀"이라 불리는 대부분의 팀이 이 형태
```

---

## 9. 면접 포인트

**Q. TDD를 실제 프로젝트에서 적용할 때 어려운 점은?**

가장 큰 어려움은 테스트 작성에 익숙해지는 학습 비용과, 외부 의존성(API, DB)을 처리하는 방법입니다. 실제로는 모든 코드에 TDD를 적용하기보다, 핵심 비즈니스 로직과 버그가 발생했던 영역에 먼저 적용합니다. Mock/Stub을 활용해 외부 의존성을 격리하고, 단위 테스트 중심으로 시작하는 것이 현실적입니다.

**Q. 페어 프로그래밍의 장단점을 설명해주세요.**

장점은 실시간 코드 리뷰로 버그를 조기에 발견하고, 지식을 팀 전체에 빠르게 전파하며, 복잡한 문제 해결 시 두 뇌가 더 나은 해결책을 찾는다는 것입니다. 단점은 초기에는 생산성 저하로 느껴질 수 있고, 두 사람의 스타일 차이로 피로감이 생길 수 있다는 것입니다. 원격 환경에서는 화상통화와 Live Share 같은 도구가 필수입니다.

**Q. 린에서 "늦은 결정" 원칙을 실무에서 어떻게 적용하나요?**

아키텍처 결정을 최대한 미루고 옵션을 열어두는 방식입니다. 예를 들어 데이터베이스를 확정하기 전에 인터페이스(Repository 패턴)를 먼저 정의해 나중에 교체 가능하게 설계합니다. Feature Flag를 사용해 배포와 릴리즈를 분리하고, 사용자 피드백을 얻은 후 기능을 확정하는 것도 이 원칙의 적용입니다.

**Q. XP의 YAGNI 원칙이 기술 부채와 충돌하지 않나요?**

충돌처럼 보이지만 사실 보완 관계입니다. YAGNI는 "지금 필요하지 않은 기능을 미리 만들지 마라"는 원칙입니다. 반면 기술 부채를 만들지 않는 것은 "지금 해야 할 일을 올바르게 하라"는 것입니다. YAGNI로 범위를 제한하고, 제한된 범위 내에서 TDD와 리팩토링으로 품질을 지키면 두 원칙이 서로 상충하지 않습니다.
