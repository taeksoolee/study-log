# 3. 유닛 테스트 (Jest & Vitest)

## 목차

1. [Jest 기본 설정 및 구조](#1-jest-기본-설정-및-구조)
2. [모킹 (Mocking)](#2-모킹-mocking)
3. [타이머 모킹](#3-타이머-모킹)
4. [Vitest](#4-vitest)
5. [Jest vs Vitest 비교](#5-jest-vs-vitest-비교)
6. [테스트 작성 전략: AAA 패턴](#6-테스트-작성-전략-aaa-패턴)
7. [코드 커버리지](#7-코드-커버리지)
8. [스냅샷 테스트](#8-스냅샷-테스트)
9. [비동기 테스트](#9-비동기-테스트)
10. [면접 포인트](#10-면접-포인트)

---

## 1. Jest 기본 설정 및 구조

### 설치

```bash
npm install --save-dev jest @types/jest ts-jest
# React 컴포넌트 테스트
npm install --save-dev @testing-library/react @testing-library/jest-dom jest-environment-jsdom
```

### jest.config.ts

```ts
import type { Config } from 'jest';

const config: Config = {
  preset: 'ts-jest',
  testEnvironment: 'jsdom',  // 브라우저 환경 시뮬레이션
  setupFilesAfterFramework: ['@testing-library/jest-dom'],
  moduleNameMapper: {
    '^@/(.*)$': '<rootDir>/src/$1', // 경로 별칭
  },
  collectCoverageFrom: ['src/**/*.{ts,tsx}', '!src/**/*.d.ts'],
};

export default config;
```

### 기본 테스트 구조

```ts
// utils/math.ts
export const add = (a: number, b: number) => a + b;
export const divide = (a: number, b: number) => {
  if (b === 0) throw new Error('0으로 나눌 수 없습니다');
  return a / b;
};

// utils/math.test.ts
import { add, divide } from './math';

describe('math 유틸', () => {
  describe('add', () => {
    it('두 양수를 더한다', () => {
      expect(add(1, 2)).toBe(3);
    });

    it('음수를 더한다', () => {
      expect(add(-1, 1)).toBe(0);
    });
  });

  describe('divide', () => {
    it('두 수를 나눈다', () => {
      expect(divide(10, 2)).toBe(5);
    });

    it('0으로 나누면 에러를 던진다', () => {
      expect(() => divide(10, 0)).toThrow('0으로 나눌 수 없습니다');
    });
  });
});
```

### 주요 matcher

```ts
// 기본
expect(value).toBe(3);              // 원시값 동등 (===)
expect(obj).toEqual({ a: 1 });      // 구조 동등 (깊은 비교)
expect(obj).toStrictEqual({ a: 1 }); // undefined 포함 엄격 비교

// 진위
expect(value).toBeTruthy();
expect(value).toBeFalsy();
expect(value).toBeNull();
expect(value).toBeUndefined();

// 숫자
expect(0.1 + 0.2).toBeCloseTo(0.3);
expect(5).toBeGreaterThan(3);

// 배열/문자열
expect([1, 2, 3]).toContain(2);
expect('hello world').toMatch(/world/);
expect(arr).toHaveLength(3);

// 에러
expect(() => fn()).toThrow();
expect(() => fn()).toThrow(TypeError);
```

---

## 2. 모킹 (Mocking)

### jest.fn()

```ts
// 함수 모킹
const mockFn = jest.fn();
mockFn('arg1');
mockFn('arg2');

expect(mockFn).toHaveBeenCalledTimes(2);
expect(mockFn).toHaveBeenCalledWith('arg1');
expect(mockFn).toHaveBeenLastCalledWith('arg2');

// 반환값 설정
mockFn.mockReturnValue(42);
mockFn.mockReturnValueOnce(100); // 첫 번째 호출만

// 구현 설정
mockFn.mockImplementation((x) => x * 2);
```

### jest.mock()

```ts
// api/userApi.ts
export const fetchUser = async (id: number) => {
  const res = await fetch(`/api/users/${id}`);
  return res.json();
};

// 모듈 전체 모킹
jest.mock('./api/userApi');
import { fetchUser } from './api/userApi';

const mockFetchUser = jest.mocked(fetchUser);
mockFetchUser.mockResolvedValue({ id: 1, name: '홍길동' });

it('유저를 가져온다', async () => {
  const user = await fetchUser(1);
  expect(user.name).toBe('홍길동');
});
```

### jest.spyOn()

```ts
// 특정 메서드만 스파이 — 원본을 유지하거나 교체 가능
const consoleSpy = jest.spyOn(console, 'error').mockImplementation(() => {});

// 테스트 후 복원
afterEach(() => {
  consoleSpy.mockRestore();
});

it('에러 로그를 출력한다', () => {
  triggerError();
  expect(consoleSpy).toHaveBeenCalledWith('에러 발생');
});
```

---

## 3. 타이머 모킹

```ts
// jest.useFakeTimers()로 setTimeout, setInterval 등을 제어
describe('debounce 함수', () => {
  beforeEach(() => {
    jest.useFakeTimers();
  });

  afterEach(() => {
    jest.useRealTimers();
  });

  it('마지막 호출 후 300ms 뒤에 실행된다', () => {
    const callback = jest.fn();
    const debounced = debounce(callback, 300);

    debounced();
    debounced();
    debounced();

    expect(callback).not.toHaveBeenCalled();

    jest.advanceTimersByTime(300);

    expect(callback).toHaveBeenCalledTimes(1);
  });
});
```

---

## 4. Vitest

Vite 기반 테스트 프레임워크. Jest 호환 API.

### 설치

```bash
npm install --save-dev vitest @vitest/ui jsdom
npm install --save-dev @testing-library/react @testing-library/jest-dom
```

### vitest.config.ts

```ts
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    environment: 'jsdom',
    globals: true,           // describe, it, expect 전역 사용
    setupFiles: ['./src/setupTests.ts'],
    coverage: {
      provider: 'v8',        // 'istanbul' | 'v8'
      reporter: ['text', 'lcov'],
    },
  },
});
```

### 코드 차이 (거의 없음)

```ts
// Jest
import { describe, it, expect, vi } from '@jest/globals';

// Vitest — 거의 동일, vi가 jest 대신
import { describe, it, expect, vi } from 'vitest';

vi.fn()           // jest.fn()
vi.mock()         // jest.mock()
vi.spyOn()        // jest.spyOn()
vi.useFakeTimers() // jest.useFakeTimers()
```

---

## 5. Jest vs Vitest 비교

| 항목 | Jest | Vitest |
|------|------|--------|
| 속도 | 보통 (babel/ts-jest 변환) | 빠름 (Vite 기반, esbuild) |
| 설정 | 별도 jest.config 필요 | vite.config에 통합 가능 |
| 호환성 | 거의 모든 환경 | Vite 프로젝트에 최적 |
| HMR 지원 | 없음 | 있음 (watch 모드) |
| 타입스크립트 | ts-jest 또는 babel 필요 | 기본 지원 |
| ESM 지원 | 추가 설정 필요 | 기본 지원 |
| 커뮤니티 | 매우 큰 | 성장 중 |
| API 호환 | 기준 | Jest API 호환 |

**선택 기준:**
- Vite 기반 프로젝트 (React, Vue SPA) → **Vitest**
- Next.js, NestJS, CRA 등 → **Jest**

---

## 6. 테스트 작성 전략: AAA 패턴

```ts
it('장바구니에 상품을 추가한다', () => {
  // Arrange: 테스트 준비
  const cart = new Cart();
  const product = { id: 1, name: '노트북', price: 1000000 };

  // Act: 동작 실행
  cart.addItem(product, 2);

  // Assert: 결과 검증
  expect(cart.items).toHaveLength(1);
  expect(cart.totalPrice).toBe(2000000);
});
```

### 테스트 명명 규칙

```ts
// 패턴: [테스트 대상] [조건] [예상 결과]
it('addItem은 동일한 상품이 있을 때 수량을 합산한다', () => {});
it('login은 잘못된 비밀번호가 입력되면 에러를 반환한다', () => {});

// BDD 스타일
describe('Cart', () => {
  describe('addItem', () => {
    context('동일한 상품이 이미 있을 때', () => {
      it('수량을 합산한다', () => {});
    });
  });
});
```

---

## 7. 코드 커버리지

```bash
# Jest
npx jest --coverage

# Vitest
npx vitest --coverage
```

### 커버리지 항목

| 항목 | 설명 |
|------|------|
| Statements | 구문 실행 비율 |
| Branches | 분기(if/else) 커버 비율 |
| Functions | 함수 호출 비율 |
| Lines | 라인 실행 비율 |

> **목표**: 100%가 아닌 의미 있는 케이스를 테스트하는 것이 중요. 통상 80% 이상을 목표로 함.

---

## 8. 스냅샷 테스트

```tsx
import { render } from '@testing-library/react';
import Button from './Button';

it('Button 컴포넌트 렌더링', () => {
  const { container } = render(<Button label="클릭" variant="primary" />);
  expect(container).toMatchSnapshot();
});

// 스냅샷 업데이트
// npx jest --updateSnapshot
```

> 스냅샷 테스트는 UI 변경을 감지하는 데 유용하지만, 너무 많으면 유지보수 비용이 높아짐. 핵심 컴포넌트에만 제한적으로 사용 권장.

---

## 9. 비동기 테스트

```ts
// async/await
it('API에서 유저 목록을 가져온다', async () => {
  const users = await getUsers();
  expect(users).toHaveLength(3);
});

// Promise 반환
it('데이터를 저장한다', () => {
  return saveData({ name: '테스트' }).then(result => {
    expect(result.success).toBe(true);
  });
});

// waitFor: DOM 업데이트 대기 (Testing Library)
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';

it('버튼 클릭 후 결과가 표시된다', async () => {
  render(<AsyncComponent />);
  await userEvent.click(screen.getByRole('button'));

  await waitFor(() => {
    expect(screen.getByText('완료')).toBeInTheDocument();
  });
});
```

---

## 10. 면접 포인트

**Q. 유닛 테스트를 왜 작성하는가?**
> 코드 변경 시 회귀(regression) 버그를 조기에 발견하고, 함수의 계약(입력/출력)을 문서화하며, 리팩토링에 대한 자신감을 줍니다. 테스트가 있으면 코드 설계도 개선됩니다 — 테스트하기 어려운 코드는 결합도가 높다는 신호입니다.

**Q. jest.fn()과 jest.spyOn()의 차이는?**
> `jest.fn()`은 완전히 새로운 목 함수를 만듭니다. `jest.spyOn()`은 기존 객체의 메서드를 감시하며 원본 구현을 유지하거나(`mockImplementation`으로 교체 가능) 나중에 복원(`mockRestore()`)할 수 있습니다.

**Q. Vitest가 Jest보다 빠른 이유는?**
> Jest는 Babel 또는 ts-jest로 TypeScript를 변환하지만, Vitest는 Vite의 esbuild 기반 변환을 사용해 속도가 훨씬 빠릅니다. 또한 Vite의 ESM 지원을 그대로 활용하므로 별도 변환 설정이 적습니다.

**Q. 커버리지 100%를 목표로 해야 하는가?**
> 반드시 그렇지는 않습니다. 100% 커버리지보다 의미 있는 케이스(경계값, 에러 케이스, 핵심 비즈니스 로직)를 테스트하는 것이 중요합니다. getter, 단순 타입 등 테스트 가치가 낮은 코드에 집착하면 테스트 유지 비용만 높아집니다.
