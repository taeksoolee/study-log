# 2. 테스트 더블 · 모킹 · MSW

## 목차
1. [테스트 더블 5종](#1-테스트-더블-5종)
2. [언제 모킹하고 언제 하지 말까](#2-언제-모킹하고-언제-하지-말까)
3. [모듈/함수 모킹 (Vitest/Jest)](#3-모듈함수-모킹-vitestjest)
4. [네트워크 모킹 — MSW](#4-네트워크-모킹--msw)
5. [타이머·시간·랜덤 제어](#5-타이머시간랜덤-제어)
6. [모킹 안티패턴](#6-모킹-안티패턴)
7. [면접 포인트](#7-면접-포인트)

---

## 1. 테스트 더블 5종

"테스트 더블"은 실제 의존성을 대체하는 가짜의 총칭. 다섯으로 나뉜다.

| 종류 | 역할 |
|------|------|
| **Dummy** | 자리만 채움(실제로 안 쓰임) |
| **Stub** | 미리 정해진 값을 반환(상태 검증용) |
| **Spy** | 실제 동작 + 호출 기록(어떻게 불렸나 관찰) |
| **Mock** | 기대한 호출을 검증(행위 검증용, 미충족 시 실패) |
| **Fake** | 가벼운 실제 구현(인메모리 DB 등) |

> 핵심 구분: **Stub은 "무엇을 돌려주나"(상태)**, **Mock은 "어떻게 불렸나"(행위)**를 본다. Spy는 실제를 감싸 기록만 한다.

---

## 2. 언제 모킹하고 언제 하지 말까

**모킹할 것:**
- 네트워크/HTTP(느림·불안정), 시간·랜덤(비결정성), 외부 서비스(결제·이메일), 파일/DB.
- 즉, **느리거나·비결정적이거나·부작용이 있는** 경계.

**모킹하지 말 것:**
- 테스트 대상 자신, 단순 순수 함수, 내가 검증하려는 핵심 협업 로직.
- 과도한 모킹은 "모킹이 실제와 다를" 위험(거짓 안심)을 키운다.

> 원칙: **시스템 경계(boundary)에서 모킹**하라. 내부를 잘게 모킹할수록 통합 버그를 놓친다.

---

## 3. 모듈/함수 모킹 (Vitest/Jest)

```js
import { vi } from 'vitest';

// 함수 스텁/스파이
const fn = vi.fn().mockReturnValue(42);
fn(1, 2);
expect(fn).toHaveBeenCalledWith(1, 2);   // 행위 검증
expect(fn).toHaveBeenCalledTimes(1);

// 모듈 전체 모킹
vi.mock('./api', () => ({
  fetchUser: vi.fn().mockResolvedValue({ id: 1, name: 'A' }),
}));

// 부분 모킹: 실제 모듈 유지하고 일부만 교체
vi.mock('./utils', async (importOriginal) => ({
  ...(await importOriginal()),
  now: vi.fn(() => 0),
}));
```

> 모듈 모킹은 강력하지만 결합도가 높다(경로·내부 구조에 의존). 가능하면 **네트워크 레벨 모킹(MSW)**으로 한 단계 바깥에서 막는 게 더 견고하다.

---

## 4. 네트워크 모킹 — MSW

**MSW(Mock Service Worker)**는 `fetch`/`XHR`를 **네트워크 계층에서 가로채** 가짜 응답을 준다. 앱 코드는 진짜 HTTP를 호출한다고 믿어, `fetch`를 직접 모킹할 때보다 현실적이다.

```js
import { setupServer } from 'msw/node';
import { http, HttpResponse } from 'msw';

const server = setupServer(
  http.get('/api/user/:id', ({ params }) =>
    HttpResponse.json({ id: params.id, name: '홍길동' })
  )
);

beforeAll(() => server.listen());
afterEach(() => server.resetHandlers());  // 테스트 간 격리
afterAll(() => server.close());

// 특정 테스트에서 에러 응답 오버라이드
test('서버 에러 처리', async () => {
  server.use(http.get('/api/user/:id', () => new HttpResponse(null, { status: 500 })));
  // ... 에러 UI 검증
});
```

장점:
- **같은 핸들러를 테스트·개발·Storybook에서 재사용**(브라우저에선 실제 Service Worker로 가로챔).
- `fetch` 구현 세부를 모르고도 동작 검증 → 라이브러리 교체(axios↔fetch)에 강함.

---

## 5. 타이머·시간·랜덤 제어

비결정성 제거는 신뢰성의 핵심.

```js
// 가짜 타이머: setTimeout/디바운스 즉시 진행
vi.useFakeTimers();
doDebouncedThing();
vi.advanceTimersByTime(300);   // 300ms 흐른 것처럼
vi.useRealTimers();

// 시간 고정
vi.setSystemTime(new Date('2024-01-01T00:00:00Z'));

// 랜덤 고정
vi.spyOn(Math, 'random').mockReturnValue(0.5);
```

---

## 6. 모킹 안티패턴

- **과잉 모킹**: 거의 모든 것을 모킹 → 테스트가 "모킹이 맞다"만 검증, 실제는 깨져도 통과.
- **구현 결합 모킹**: 내부 함수 호출 순서·횟수를 과하게 단언 → 리팩터링마다 깨짐.
- **모킹 누수**: `resetHandlers`/`restoreAllMocks` 누락 → 테스트 간 오염(순서 의존).
- **상태가 아닌 행위만 검증**: "A를 호출했다"만 보고 결과를 안 봄 → 잘못된 결과도 통과.

```js
afterEach(() => { vi.restoreAllMocks(); });  // 스파이/모킹 정리 습관화
```

---

## 7. 면접 포인트

**Q. Stub과 Mock의 차이는?**
> Stub은 미리 정한 값을 반환해 **상태(결과)**를 검증하게 돕고, Mock은 **기대한 호출이 일어났는지(행위)**를 검증하며 미충족 시 실패한다. Spy는 실제 동작을 감싸 호출 기록만 남긴다.

**Q. 무엇을 모킹하고 무엇은 하지 말아야 하나요?**
> 느리거나 비결정적이거나 부작용이 있는 시스템 경계(네트워크·시간·외부 서비스·DB)를 모킹한다. 테스트 대상 자신이나 검증하려는 핵심 협업 로직은 모킹하지 않는다. 내부를 잘게 모킹할수록 통합 버그를 놓친다.

**Q. MSW가 `fetch`를 직접 모킹하는 것보다 나은 이유는?**
> 네트워크 계층에서 요청을 가로채 앱이 실제 HTTP를 호출한다고 믿게 한다. 그래서 fetch/axios 구현 세부에 결합되지 않고, 같은 핸들러를 테스트·개발·Storybook에서 재사용할 수 있어 더 현실적이고 견고하다.

**Q. 테스트의 비결정성(flakiness)을 어떻게 제거하나요?**
> 시간은 `setSystemTime`/fake timers로 고정, 랜덤은 `Math.random` 스파이로 고정, 네트워크는 MSW로 모킹, 테스트 간에는 핸들러·모킹을 reset해 격리한다.

**Q. 과잉 모킹의 위험은?**
> 거의 모든 의존성을 모킹하면 테스트가 "모킹이 약속대로 동작한다"만 검증하게 되어, 실제 통합이 깨져도 통과하는 거짓 안심을 준다. 경계에서만 모킹하고 내부 협업은 실제로 돌려야 한다.
