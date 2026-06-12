# 1. TDD (테스트 주도 개발)

## 목차
1. TDD란 무엇인가
2. TDD 사이클: Red → Green → Refactor
3. TDD vs BDD vs ATDD
4. Jest/Vitest로 TDD 실습 예제
5. React 컴포넌트 TDD 예제
6. TDD의 장점과 현실적 어려움
7. 언제 TDD가 효과적인지, 언제 과도한지
8. 면접 포인트

---

## 1. TDD란 무엇인가

TDD(Test-Driven Development)는 **코드를 작성하기 전에 테스트를 먼저 작성**하는 개발 방법론입니다. Kent Beck이 XP(Extreme Programming)의 일부로 정립했습니다.

```
전통적 개발:  요구사항 → 코드 작성 → 테스트 작성 (→ 버그 발견 → 수정)
TDD:          요구사항 → 테스트 작성 → 코드 작성 → 리팩터링
```

핵심 철학: **테스트가 설계를 이끈다 (Tests drive the design)**

---

## 2. TDD 사이클: Red → Green → Refactor

```
       ┌─────────────────────────────────────┐
       │                                     │
    🔴 Red                               🔵 Refactor
    실패하는                              코드 구조를
    테스트 작성                           개선한다
       │                                     │
       └──────────→  🟢 Green ───────────────┘
                    테스트를 통과하는
                    최소한의 코드 작성
```

### Red 단계
- 아직 존재하지 않는 기능에 대한 테스트를 작성
- 테스트는 반드시 실패해야 함 (컴파일 에러도 Red)
- 무엇을 구현해야 하는지 명확히 정의

### Green 단계
- 테스트를 통과하는 **최소한의** 코드 작성
- 코드 품질보다 동작에 집중
- "Make it work" 단계

### Refactor 단계
- 테스트를 유지한 채 코드 구조 개선
- 중복 제거, 가독성 향상
- "Make it right" 단계

---

## 3. TDD vs BDD vs ATDD

| 구분 | TDD | BDD | ATDD |
|------|-----|-----|------|
| 풀네임 | Test-Driven Development | Behavior-Driven Development | Acceptance Test-Driven Development |
| 관점 | 개발자 | 개발자 + 비즈니스 | 비즈니스 + QA + 개발자 |
| 단위 | 함수/클래스 단위 | 기능/동작 단위 | 인수 조건 단위 |
| 언어 | 기술적 용어 | Given/When/Then | 자연어 (사용자 스토리) |
| 도구 | Jest, Vitest, Mocha | Jest, Jasmine, Cucumber | Cucumber, FitNesse |

```typescript
// TDD 스타일
test('add(1, 2) returns 3', () => {
  expect(add(1, 2)).toBe(3);
});

// BDD 스타일 (Given/When/Then)
describe('Calculator', () => {
  describe('when adding two numbers', () => {
    it('should return the sum', () => {
      // Given
      const a = 1, b = 2;
      // When
      const result = add(a, b);
      // Then
      expect(result).toBe(3);
    });
  });
});
```

---

## 4. Jest/Vitest로 TDD 실습 예제

### 예제 1 — 간단한 유틸 함수 TDD

**Step 1: Red — 실패하는 테스트 작성**

```typescript
// src/utils/currency.test.ts
import { formatCurrency } from './currency';

describe('formatCurrency', () => {
  it('숫자를 원화 형식으로 변환한다', () => {
    expect(formatCurrency(1000)).toBe('1,000원');
  });

  it('0은 0원으로 표시한다', () => {
    expect(formatCurrency(0)).toBe('0원');
  });

  it('음수는 -1,000원 형식으로 표시한다', () => {
    expect(formatCurrency(-1000)).toBe('-1,000원');
  });

  it('소수점은 버린다', () => {
    expect(formatCurrency(1000.99)).toBe('1,000원');
  });
});
```

**Step 2: Green — 최소 구현**

```typescript
// src/utils/currency.ts
export function formatCurrency(amount: number): string {
  const abs = Math.floor(Math.abs(amount));
  const formatted = abs.toLocaleString('ko-KR');
  return amount < 0 ? `-${formatted}원` : `${formatted}원`;
}
```

**Step 3: Refactor — 개선**

```typescript
// src/utils/currency.ts
export function formatCurrency(amount: number): string {
  const floored = Math.floor(amount);
  const isNegative = floored < 0;
  const abs = Math.abs(floored);
  const formatted = abs.toLocaleString('ko-KR');

  return isNegative ? `-${formatted}원` : `${formatted}원`;
}
```

### 예제 2 — 클래스 TDD (장바구니)

```typescript
// src/domain/Cart.test.ts
import { Cart } from './Cart';

describe('Cart', () => {
  let cart: Cart;

  beforeEach(() => {
    cart = new Cart();
  });

  it('초기 상태는 빈 장바구니다', () => {
    expect(cart.items).toHaveLength(0);
    expect(cart.totalPrice).toBe(0);
  });

  it('상품을 추가하면 items에 반영된다', () => {
    cart.addItem({ id: '1', name: '사과', price: 1000, quantity: 2 });
    expect(cart.items).toHaveLength(1);
    expect(cart.totalPrice).toBe(2000);
  });

  it('같은 상품을 추가하면 수량이 합산된다', () => {
    cart.addItem({ id: '1', name: '사과', price: 1000, quantity: 1 });
    cart.addItem({ id: '1', name: '사과', price: 1000, quantity: 3 });
    expect(cart.items).toHaveLength(1);
    expect(cart.items[0].quantity).toBe(4);
  });

  it('상품을 제거할 수 있다', () => {
    cart.addItem({ id: '1', name: '사과', price: 1000, quantity: 1 });
    cart.removeItem('1');
    expect(cart.items).toHaveLength(0);
  });
});
```

```typescript
// src/domain/Cart.ts
interface CartItem {
  id: string;
  name: string;
  price: number;
  quantity: number;
}

export class Cart {
  private _items: CartItem[] = [];

  get items(): CartItem[] {
    return [...this._items];
  }

  get totalPrice(): number {
    return this._items.reduce((sum, item) => sum + item.price * item.quantity, 0);
  }

  addItem(item: CartItem): void {
    const existing = this._items.find((i) => i.id === item.id);
    if (existing) {
      existing.quantity += item.quantity;
    } else {
      this._items.push({ ...item });
    }
  }

  removeItem(id: string): void {
    this._items = this._items.filter((i) => i.id !== id);
  }
}
```

---

## 5. React 컴포넌트 TDD 예제

```tsx
// src/components/Counter.test.tsx
import { render, screen, fireEvent } from '@testing-library/react';
import { Counter } from './Counter';

describe('Counter', () => {
  it('초기값 0을 표시한다', () => {
    render(<Counter />);
    expect(screen.getByText('0')).toBeInTheDocument();
  });

  it('+1 버튼을 클릭하면 카운트가 증가한다', () => {
    render(<Counter />);
    fireEvent.click(screen.getByRole('button', { name: '+1' }));
    expect(screen.getByText('1')).toBeInTheDocument();
  });

  it('초기값을 props로 받을 수 있다', () => {
    render(<Counter initialValue={5} />);
    expect(screen.getByText('5')).toBeInTheDocument();
  });

  it('리셋 버튼을 클릭하면 초기값으로 돌아간다', () => {
    render(<Counter initialValue={5} />);
    fireEvent.click(screen.getByRole('button', { name: '+1' }));
    fireEvent.click(screen.getByRole('button', { name: '리셋' }));
    expect(screen.getByText('5')).toBeInTheDocument();
  });
});
```

```tsx
// src/components/Counter.tsx
import { useState } from 'react';

interface CounterProps {
  initialValue?: number;
}

export function Counter({ initialValue = 0 }: CounterProps) {
  const [count, setCount] = useState(initialValue);

  return (
    <div>
      <span>{count}</span>
      <button onClick={() => setCount((c) => c + 1)}>+1</button>
      <button onClick={() => setCount(initialValue)}>리셋</button>
    </div>
  );
}
```

---

## 6. TDD의 장점과 현실적 어려움

### 장점

| 장점 | 설명 |
|------|------|
| 설계 개선 | 테스트하기 쉬운 코드 = 결합도 낮은 코드 |
| 회귀 방지 | 리팩터링 시 기존 동작 보장 |
| 문서화 | 테스트가 살아있는 명세서 역할 |
| 자신감 | 변경에 대한 심리적 안전망 |
| 디버깅 감소 | 버그를 일찍 발견, 수정 비용 감소 |

### 현실적 어려움

```
1. 초기 학습 비용
   - 테스트 작성법 자체를 배워야 함
   - 어떤 것을 테스트해야 하는지 판단이 어려움

2. 시간 압박
   - 단기적으로는 코드 작성 시간이 증가
   - 데드라인 앞에서 테스트가 생략되기 쉬움

3. 테스트하기 어려운 코드
   - UI, 애니메이션, 외부 API 의존 코드
   - 전역 상태, 사이드 이펙트

4. 과도한 테스트
   - 구현 세부사항을 테스트하면 리팩터링이 어려워짐
   - 테스트 코드 유지보수 비용 증가
```

---

## 7. 언제 TDD가 효과적인지, 언제 과도한지

### TDD가 효과적인 상황

```
✅ 비즈니스 로직이 복잡한 도메인 코드
✅ 요구사항이 명확한 유틸 함수, 알고리즘
✅ 여러 팀원이 장기간 유지보수할 코드
✅ 버그가 반복적으로 발생하는 영역
✅ 리팩터링이 예정된 레거시 코드
```

### TDD가 과도한 상황

```
❌ 프로토타입 / PoC 단계 (요구사항이 자주 바뀜)
❌ 단순한 CRUD 보일러플레이트
❌ 외부 라이브러리 래퍼 (라이브러리 자체가 테스트됨)
❌ UI 스타일링, 애니메이션
❌ 팀 전체가 TDD 경험이 없는 빠른 스타트업 초기
```

### 실용적 접근 — Testing Trophy

```
        /\
       /E2E\          소수의 E2E 테스트 (핵심 사용자 흐름)
      /──────\
     /Integration\    통합 테스트 (컴포넌트 + API)
    /──────────────\
   /   Unit Tests   \ 단위 테스트 (비즈니스 로직 중심)
  /──────────────────\
 /   Static Analysis  \ TypeScript, ESLint (가장 넓은 커버리지)
/──────────────────────\
```

---

## 8. 면접 포인트

**Q. TDD 사이클을 설명해주세요.**

Red-Green-Refactor 3단계입니다. Red는 실패하는 테스트를 먼저 작성하고, Green은 테스트를 통과하는 최소한의 코드를 작성하고, Refactor는 테스트를 유지하면서 코드 품질을 개선합니다.

**Q. TDD와 BDD의 차이는 무엇인가요?**

TDD는 개발자 관점의 단위 테스트 중심이고, BDD는 Given/When/Then 형식으로 비즈니스 동작을 명세하는 방식입니다. BDD는 개발자와 비즈니스 팀이 공통 언어를 사용한다는 점이 특징입니다.

**Q. 테스트 커버리지 100%를 목표로 해야 하나요?**

100% 커버리지는 오히려 역효과일 수 있습니다. 구현 세부사항을 과도하게 테스트하면 리팩터링이 어려워지고 유지보수 비용이 증가합니다. 비즈니스 로직과 경계 조건에 집중하는 것이 실용적입니다.

**Q. 레거시 코드에 TDD를 적용하려면 어떻게 해야 하나요?**

Michael Feathers의 "레거시 코드 활용 전략"에서는 "seam(솔기)"을 찾아 테스트 가능한 구조로 분리하는 방법을 제안합니다. 새로운 기능 추가 시 해당 부분부터 테스트를 작성하고, 점진적으로 커버리지를 확대합니다.
