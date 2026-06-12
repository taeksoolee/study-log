# 8. React 테스팅

## 목차
1. Jest 설정
2. React Testing Library (RTL) 핵심 API
3. 컴포넌트 테스트 전략
4. Custom Hook 테스트 (renderHook)
5. MSW (Mock Service Worker) 활용
6. 면접 포인트

---

## 1. Jest 설정

### 1.1 CRA / Vite 프로젝트 설정

```bash
# Vite 프로젝트
npm install -D jest @types/jest ts-jest jest-environment-jsdom
npm install -D @testing-library/react @testing-library/jest-dom @testing-library/user-event
```

```js
// jest.config.js
/** @type {import('jest').Config} */
module.exports = {
  testEnvironment: 'jsdom',
  setupFilesAfterFramework: ['<rootDir>/jest.setup.ts'],
  moduleNameMapper: {
    '^@/(.*)$': '<rootDir>/src/$1',  // 경로 별칭
    '\\.(css|scss)$': 'identity-obj-proxy',  // CSS 모킹
    '\\.(jpg|png|svg)$': '<rootDir>/__mocks__/fileMock.js',
  },
  transform: {
    '^.+\\.tsx?$': ['ts-jest', { tsconfig: './tsconfig.json' }],
  },
};
```

```ts
// jest.setup.ts
import '@testing-library/jest-dom';  // toBeInTheDocument 등 matcher 추가
```

### 1.2 Next.js 설정

```bash
npm install -D jest jest-environment-jsdom @testing-library/react @testing-library/jest-dom
```

```js
// jest.config.js (Next.js 13+)
const nextJest = require('next/jest');
const createJestConfig = nextJest({ dir: './' });

const config = {
  setupFilesAfterFramework: ['<rootDir>/jest.setup.ts'],
  testEnvironment: 'jest-environment-jsdom',
};

module.exports = createJestConfig(config);
```

---

## 2. React Testing Library (RTL) 핵심 API

### 2.1 render

```tsx
import { render, screen } from '@testing-library/react';

test('버튼이 렌더링된다', () => {
  render(<Button>클릭</Button>);
  // screen으로 DOM에 접근
  expect(screen.getByRole('button', { name: '클릭' })).toBeInTheDocument();
});

// Provider가 필요한 컴포넌트 — 커스텀 render 함수
function renderWithProviders(ui: React.ReactElement) {
  return render(
    <QueryClientProvider client={new QueryClient()}>
      <ThemeProvider theme={lightTheme}>
        {ui}
      </ThemeProvider>
    </QueryClientProvider>
  );
}
```

### 2.2 screen 쿼리 우선순위

RTL은 실제 사용자 경험에 가까운 쿼리를 권장한다.

```
우선순위 (높음 → 낮음)
1. getByRole          — 가장 권장. 접근성 기반
2. getByLabelText     — form label
3. getByPlaceholderText
4. getByText          — 버튼, 링크 등의 텍스트
5. getByDisplayValue  — select, input 현재 값
6. getByAltText       — img alt
7. getByTitle
8. getByTestId        — 최후 수단. data-testid 속성
```

```tsx
// 권장
screen.getByRole('button', { name: /제출/i })
screen.getByLabelText('이메일')

// 비권장 (구현 세부사항)
screen.getByClassName('submit-btn')    // 존재하지 않는 쿼리
document.querySelector('.submit-btn')  // DOM 직접 접근 지양
```

### 2.3 getBy vs queryBy vs findBy

| 쿼리 | 요소 없을 때 | 비동기 | 용도 |
|------|------------|--------|------|
| getBy | throw | X | 요소가 반드시 있어야 할 때 |
| queryBy | null 반환 | X | 요소가 없음을 검증할 때 |
| findBy | throw | O (await) | 비동기로 나타나는 요소 |

```tsx
// 요소가 없어야 할 때 — queryBy 사용
expect(screen.queryByText('에러 메시지')).not.toBeInTheDocument();

// 비동기 요소 — findBy 사용
const successMessage = await screen.findByText('저장 완료');
```

### 2.4 userEvent

실제 사용자 인터랙션을 시뮬레이션한다. `fireEvent`보다 현실적인 이벤트 흐름을 재현한다.

```tsx
import userEvent from '@testing-library/user-event';

test('폼 입력 및 제출', async () => {
  const user = userEvent.setup();  // v14+: setup() 필수
  const onSubmit = jest.fn();

  render(<LoginForm onSubmit={onSubmit} />);

  // 타이핑
  await user.type(screen.getByLabelText('이메일'), 'test@example.com');
  await user.type(screen.getByLabelText('비밀번호'), 'password123');

  // 클릭
  await user.click(screen.getByRole('button', { name: '로그인' }));

  expect(onSubmit).toHaveBeenCalledWith({
    email: 'test@example.com',
    password: 'password123',
  });
});
```

### 2.5 waitFor

비동기 상태 변화를 기다릴 때 사용한다.

```tsx
import { waitFor } from '@testing-library/react';

test('데이터 로딩 후 목록이 표시된다', async () => {
  render(<UserList />);

  // 로딩 중
  expect(screen.getByText('로딩 중...')).toBeInTheDocument();

  // 데이터 로드 완료 대기
  await waitFor(() => {
    expect(screen.queryByText('로딩 중...')).not.toBeInTheDocument();
  });

  expect(screen.getByText('홍길동')).toBeInTheDocument();
});
```

---

## 3. 컴포넌트 테스트 전략

### 3.1 모킹 (jest.fn, jest.mock)

```tsx
// props 함수 모킹
test('삭제 버튼 클릭 시 onDelete 호출', async () => {
  const user = userEvent.setup();
  const onDelete = jest.fn();

  render(<TodoItem text="할 일" onDelete={onDelete} />);
  await user.click(screen.getByRole('button', { name: '삭제' }));

  expect(onDelete).toHaveBeenCalledTimes(1);
});

// 모듈 모킹
jest.mock('next/navigation', () => ({
  useRouter: () => ({
    push: jest.fn(),
    replace: jest.fn(),
  }),
  usePathname: () => '/current-path',
}));
```

### 3.2 스냅샷 테스트

```tsx
test('Button 스냅샷 일치', () => {
  const { container } = render(<Button variant="primary">제출</Button>);
  expect(container.firstChild).toMatchSnapshot();
});
```

스냅샷은 UI 회귀를 감지하는 데 유용하지만, 세부 구현에 강하게 결합되므로 과용하지 않는 것이 좋다.

### 3.3 접근성 테스트

```tsx
import { axe, toHaveNoViolations } from 'jest-axe';
expect.extend(toHaveNoViolations);

test('LoginForm 접근성 위반 없음', async () => {
  const { container } = render(<LoginForm />);
  const results = await axe(container);
  expect(results).toHaveNoViolations();
});
```

### 3.4 통합 테스트 예제

```tsx
test('로그인 성공 시 대시보드로 이동', async () => {
  const user = userEvent.setup();
  const pushMock = jest.fn();

  jest.mocked(useRouter).mockReturnValue({ push: pushMock } as any);
  server.use(
    http.post('/api/auth/login', () => HttpResponse.json({ token: 'abc' }))
  );

  render(<LoginPage />);

  await user.type(screen.getByLabelText('이메일'), 'test@example.com');
  await user.type(screen.getByLabelText('비밀번호'), 'password');
  await user.click(screen.getByRole('button', { name: '로그인' }));

  await waitFor(() => {
    expect(pushMock).toHaveBeenCalledWith('/dashboard');
  });
});
```

---

## 4. Custom Hook 테스트 (renderHook)

### 4.1 기본 사용법

```tsx
import { renderHook, act } from '@testing-library/react';
import { useCounter } from '@/hooks/useCounter';

test('초기값이 설정된다', () => {
  const { result } = renderHook(() => useCounter(5));
  expect(result.current.count).toBe(5);
});

test('increment 호출 시 카운트 증가', () => {
  const { result } = renderHook(() => useCounter(0));

  act(() => {
    result.current.increment();
  });

  expect(result.current.count).toBe(1);
});
```

### 4.2 Context가 필요한 훅 테스트

```tsx
test('useAuth — 인증된 사용자 반환', () => {
  const wrapper = ({ children }: { children: React.ReactNode }) => (
    <AuthProvider initialUser={{ id: '1', name: '홍길동' }}>
      {children}
    </AuthProvider>
  );

  const { result } = renderHook(() => useAuth(), { wrapper });
  expect(result.current.user?.name).toBe('홍길동');
});
```

### 4.3 비동기 훅 테스트

```tsx
test('useUserData — 데이터 로딩 완료', async () => {
  server.use(
    http.get('/api/user/1', () => HttpResponse.json({ name: '홍길동' }))
  );

  const { result } = renderHook(() => useUserData('1'));

  expect(result.current.loading).toBe(true);

  await waitFor(() => {
    expect(result.current.loading).toBe(false);
  });

  expect(result.current.data?.name).toBe('홍길동');
});
```

---

## 5. MSW (Mock Service Worker) 활용

### 5.1 설치 및 설정

```bash
npm install -D msw
npx msw init public/  # 브라우저용 서비스 워커 파일 생성
```

```ts
// src/mocks/handlers.ts
import { http, HttpResponse } from 'msw';

export const handlers = [
  http.get('/api/users', () => {
    return HttpResponse.json([
      { id: '1', name: '홍길동' },
      { id: '2', name: '김철수' },
    ]);
  }),

  http.post('/api/users', async ({ request }) => {
    const body = await request.json() as { name: string };
    return HttpResponse.json({ id: '3', ...body }, { status: 201 });
  }),

  http.get('/api/users/:id', ({ params }) => {
    if (params.id === '999') {
      return new HttpResponse(null, { status: 404 });
    }
    return HttpResponse.json({ id: params.id, name: '홍길동' });
  }),
];
```

```ts
// src/mocks/server.ts (Jest 환경)
import { setupServer } from 'msw/node';
import { handlers } from './handlers';

export const server = setupServer(...handlers);
```

```ts
// jest.setup.ts
import { server } from './src/mocks/server';

beforeAll(() => server.listen({ onUnhandledRequest: 'error' }));
afterEach(() => server.resetHandlers());  // 각 테스트 후 핸들러 초기화
afterAll(() => server.close());
```

### 5.2 테스트별 핸들러 오버라이드

```tsx
import { http, HttpResponse } from 'msw';
import { server } from '@/mocks/server';

test('에러 상태 표시', async () => {
  // 이 테스트에서만 에러 응답 반환
  server.use(
    http.get('/api/users', () => {
      return new HttpResponse(null, { status: 500 });
    })
  );

  render(<UserList />);

  await waitFor(() => {
    expect(screen.getByText('서버 오류가 발생했습니다')).toBeInTheDocument();
  });
});
```

### 5.3 브라우저 환경 MSW 설정 (개발용)

```ts
// src/mocks/browser.ts
import { setupWorker } from 'msw/browser';
import { handlers } from './handlers';

export const worker = setupWorker(...handlers);
```

```ts
// src/main.tsx
async function enableMocking() {
  if (process.env.NODE_ENV !== 'development') return;
  const { worker } = await import('./mocks/browser');
  return worker.start({ onUnhandledRequest: 'bypass' });
}

enableMocking().then(() => {
  ReactDOM.createRoot(document.getElementById('root')!).render(<App />);
});
```

---

## 6. 면접 포인트

### Q1. RTL의 철학은 무엇인가요?

"테스트는 소프트웨어가 어떻게 사용되는지를 반영해야 한다"는 철학입니다. 컴포넌트 내부 구현(state, className, 컴포넌트 이름)이 아닌, 사용자가 실제로 상호작용하는 방식(역할, 텍스트, 레이블)으로 쿼리합니다. 이를 통해 리팩토링에 강한 테스트를 작성할 수 있습니다.

### Q2. getBy, queryBy, findBy의 차이는?

`getBy`는 동기 조회로, 요소가 없으면 즉시 에러를 던집니다. 요소가 반드시 존재해야 할 때 사용합니다. `queryBy`는 요소가 없을 때 null을 반환하여, 요소가 없음을 검증할 때 사용합니다. `findBy`는 비동기 조회로, 지정된 시간(기본 1000ms) 안에 요소가 나타날 때까지 기다립니다.

### Q3. MSW를 사용하는 이유는?

`jest.fn()`으로 fetch/axios를 직접 모킹하면 실제 HTTP 요청 로직을 검증하지 못합니다. MSW는 실제 네트워크 계층을 가로채 응답을 제공하므로, 브라우저와 Node.js 환경 모두에서 동일한 핸들러를 재사용할 수 있습니다. 개발 중 API 미완성 시 목업 서버로도 활용할 수 있어 프론트엔드 독립 개발이 가능합니다.

### Q4. act()는 언제 사용하나요?

React 상태 업데이트, 이벤트 핸들러, 타이머 등 React의 상태 변화를 유발하는 코드를 테스트할 때 `act()`로 감싸면 모든 상태 업데이트가 완료된 후 검증할 수 있습니다. RTL의 `render`, `fireEvent`, `userEvent` 등은 내부적으로 `act()`를 포함하므로 대부분의 경우 직접 사용할 필요는 없고, `renderHook`에서 훅의 함수를 호출할 때 명시적으로 사용합니다.
