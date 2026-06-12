# 7. Error Boundary & 에러 처리

## 목차
1. Error Boundary 개념
2. Class 컴포넌트로 직접 구현
3. react-error-boundary 라이브러리
4. Suspense + Error Boundary 조합
5. 비동기 에러 처리
6. 면접 포인트

---

## 1. Error Boundary 개념

### 1.1 정의

Error Boundary는 하위 컴포넌트 트리에서 발생한 JavaScript 에러를 캐치하여 fallback UI를 렌더링하는 컴포넌트다.
React 16에서 도입되었으며, **반드시 Class 컴포넌트**로 구현해야 한다(현재 기준).

### 1.2 캐치할 수 있는 에러 vs 없는 에러

| 캐치 가능 | 캐치 불가 |
|----------|----------|
| 렌더링 중 발생한 에러 | 이벤트 핸들러 에러 |
| 생명주기 메서드 에러 | 비동기 코드 (setTimeout, Promise) |
| 하위 컴포넌트 생성자 에러 | SSR 에러 |
| | Error Boundary 자체 에러 |

---

## 2. Class 컴포넌트로 직접 구현

### 2.1 기본 구현

```tsx
import React, { Component, ErrorInfo } from 'react';

interface Props {
  fallback: React.ReactNode;
  children: React.ReactNode;
}

interface State {
  hasError: boolean;
  error: Error | null;
}

class ErrorBoundary extends Component<Props, State> {
  constructor(props: Props) {
    super(props);
    this.state = { hasError: false, error: null };
  }

  // 에러 발생 시 state 업데이트 (렌더링 단계)
  static getDerivedStateFromError(error: Error): State {
    return { hasError: true, error };
  }

  // 에러 로깅 (커밋 단계)
  componentDidCatch(error: Error, errorInfo: ErrorInfo) {
    console.error('에러 발생:', error);
    console.error('컴포넌트 스택:', errorInfo.componentStack);
    // Sentry.captureException(error, { extra: errorInfo });
  }

  render() {
    if (this.state.hasError) {
      return this.props.fallback;
    }
    return this.props.children;
  }
}

// 사용
<ErrorBoundary fallback={<div>문제가 발생했습니다.</div>}>
  <UserProfile />
</ErrorBoundary>
```

### 2.2 에러 초기화 기능 추가

```tsx
class ErrorBoundary extends Component<Props, State> {
  // ...

  resetError = () => {
    this.setState({ hasError: false, error: null });
  };

  render() {
    if (this.state.hasError) {
      return (
        <div role="alert">
          <p>예기치 못한 오류가 발생했습니다.</p>
          <p>{this.state.error?.message}</p>
          <button onClick={this.resetError}>다시 시도</button>
        </div>
      );
    }
    return this.props.children;
  }
}
```

---

## 3. react-error-boundary 라이브러리

### 3.1 설치 및 기본 사용

```bash
npm install react-error-boundary
```

```tsx
import { ErrorBoundary } from 'react-error-boundary';

function ErrorFallback({
  error,
  resetErrorBoundary,
}: {
  error: Error;
  resetErrorBoundary: () => void;
}) {
  return (
    <div role="alert">
      <h2>오류가 발생했습니다</h2>
      <pre>{error.message}</pre>
      <button onClick={resetErrorBoundary}>다시 시도</button>
    </div>
  );
}

function App() {
  return (
    <ErrorBoundary
      FallbackComponent={ErrorFallback}
      onError={(error, info) => {
        // 에러 로깅 서비스에 전송
        logError(error, info.componentStack);
      }}
      onReset={() => {
        // 에러 초기화 시 추가 작업
      }}
    >
      <UserDashboard />
    </ErrorBoundary>
  );
}
```

### 3.2 useErrorBoundary 훅

```tsx
import { useErrorBoundary } from 'react-error-boundary';

function UserProfile({ userId }: { userId: string }) {
  const { showBoundary } = useErrorBoundary();

  const handleClick = async () => {
    try {
      await updateUserData(userId);
    } catch (error) {
      // 이벤트 핸들러에서 발생한 에러를 ErrorBoundary로 전달
      showBoundary(error);
    }
  };

  return <button onClick={handleClick}>업데이트</button>;
}
```

### 3.3 resetKeys — 특정 prop 변경 시 자동 초기화

```tsx
function App() {
  const [userId, setUserId] = useState('user-1');

  return (
    <ErrorBoundary
      FallbackComponent={ErrorFallback}
      resetKeys={[userId]} // userId가 변경되면 에러 상태 초기화
    >
      <UserProfile userId={userId} />
    </ErrorBoundary>
  );
}
```

---

## 4. Suspense + Error Boundary 조합

### 4.1 패턴 개요

```
<ErrorBoundary>       ← 에러 처리 (아래에서 throw된 Promise reject)
  <Suspense>          ← 로딩 처리 (아래에서 throw된 Promise pending)
    <AsyncComponent /> ← 데이터 페칭 컴포넌트
  </Suspense>
</ErrorBoundary>
```

### 4.2 Next.js App Router에서 활용

```tsx
// app/posts/page.tsx
import { Suspense } from 'react';
import { ErrorBoundary } from 'react-error-boundary';

export default function PostsPage() {
  return (
    <ErrorBoundary FallbackComponent={ErrorFallback}>
      <Suspense fallback={<PostsSkeleton />}>
        <PostList />  {/* async 서버 컴포넌트 */}
      </Suspense>
    </ErrorBoundary>
  );
}

// app/posts/error.tsx — App Router 내장 에러 처리
'use client';

export default function Error({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  return (
    <div>
      <h2>포스트를 불러오는 중 오류가 발생했습니다</h2>
      <button onClick={reset}>다시 시도</button>
    </div>
  );
}
```

### 4.3 병렬 Suspense로 독립적 에러 처리

```tsx
export default function Dashboard() {
  return (
    <div className="grid">
      {/* 각 섹션이 독립적으로 에러/로딩 처리 */}
      <ErrorBoundary FallbackComponent={SectionError}>
        <Suspense fallback={<Skeleton />}>
          <RevenueChart />
        </Suspense>
      </ErrorBoundary>

      <ErrorBoundary FallbackComponent={SectionError}>
        <Suspense fallback={<Skeleton />}>
          <RecentOrders />
        </Suspense>
      </ErrorBoundary>
    </div>
  );
}
```

---

## 5. 비동기 에러 처리

### 5.1 이벤트 핸들러 — try/catch

Error Boundary는 이벤트 핸들러의 에러를 캐치하지 못한다. 직접 처리해야 한다.

```tsx
function SubmitButton() {
  const [error, setError] = useState<Error | null>(null);

  const handleSubmit = async () => {
    try {
      await submitForm(data);
    } catch (e) {
      if (e instanceof Error) {
        setError(e);
      }
    }
  };

  return (
    <>
      {error && <p className="error">{error.message}</p>}
      <button onClick={handleSubmit}>제출</button>
    </>
  );
}
```

### 5.2 React Query와 ErrorBoundary 통합

```tsx
import { QueryErrorResetBoundary } from '@tanstack/react-query';
import { ErrorBoundary } from 'react-error-boundary';

function App() {
  return (
    <QueryErrorResetBoundary>
      {({ reset }) => (
        <ErrorBoundary
          FallbackComponent={ErrorFallback}
          onReset={reset} // 쿼리 에러도 함께 초기화
        >
          <Suspense fallback={<Spinner />}>
            <UserList />
          </Suspense>
        </ErrorBoundary>
      )}
    </QueryErrorResetBoundary>
  );
}

// useQuery에서 throwOnError 옵션으로 ErrorBoundary에 위임
function UserList() {
  const { data } = useQuery({
    queryKey: ['users'],
    queryFn: fetchUsers,
    throwOnError: true, // 에러를 ErrorBoundary로 전파
  });

  return <ul>{data?.map(u => <li key={u.id}>{u.name}</li>)}</ul>;
}
```

### 5.3 전역 에러 처리 (window.onerror)

```tsx
// app/layout.tsx 또는 _app.tsx
useEffect(() => {
  const handler = (event: ErrorEvent) => {
    // 처리되지 않은 에러 수집
    reportError(event.error);
  };

  const rejectionHandler = (event: PromiseRejectionEvent) => {
    // 처리되지 않은 Promise rejection 수집
    reportError(event.reason);
  };

  window.addEventListener('error', handler);
  window.addEventListener('unhandledrejection', rejectionHandler);

  return () => {
    window.removeEventListener('error', handler);
    window.removeEventListener('unhandledrejection', rejectionHandler);
  };
}, []);
```

---

## 6. 면접 포인트

### Q1. Error Boundary가 캐치하지 못하는 에러는?

이벤트 핸들러, 비동기 코드(setTimeout, Promise), SSR, Error Boundary 자체에서 발생한 에러는 캐치하지 못합니다. 이벤트 핸들러 에러는 try/catch로, Promise 에러는 `.catch()`나 `async/await + try/catch`로 처리해야 합니다. `react-error-boundary`의 `useErrorBoundary` 훅을 사용하면 이벤트 핸들러 에러도 Error Boundary로 위임할 수 있습니다.

### Q2. Error Boundary를 함수형 컴포넌트로 구현할 수 없는 이유는?

`getDerivedStateFromError`와 `componentDidCatch`는 React의 클래스 생명주기 메서드입니다. 현재 React는 이에 대응하는 훅을 제공하지 않습니다. React 팀이 향후 훅 기반 Error Boundary를 지원할 계획이 있지만, 현재(2025년 기준)까지 클래스 컴포넌트로만 구현 가능합니다. 실무에서는 `react-error-boundary` 라이브러리로 함수형 컴포넌트처럼 사용합니다.

### Q3. getDerivedStateFromError와 componentDidCatch의 차이는?

`getDerivedStateFromError`는 렌더링 단계에서 실행되며 state를 업데이트해 fallback UI를 표시하는 용도입니다. 사이드 이펙트가 없어야 합니다.

`componentDidCatch`는 커밋 단계(DOM 반영 후)에서 실행되며 에러 로깅, 외부 서비스 전송 등 사이드 이펙트를 처리하는 용도입니다.

### Q4. Next.js App Router에서 Error Boundary 사용 방법은?

App Router는 각 라우트 세그먼트에 `error.tsx` 파일을 두면 자동으로 Error Boundary로 감쌉니다. `error.tsx`는 반드시 `'use client'` 지시어가 필요하고, `error`와 `reset` props를 받습니다. `global-error.tsx`는 루트 레이아웃 수준의 에러를 처리합니다.
