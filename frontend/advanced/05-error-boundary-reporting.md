# 에러 바운더리 & 에러 리포팅 체계

## 개요

에러는 반드시 발생한다. 문제는 **"감지 → 격리 → 복구 → 보고"** 체인을 얼마나 잘 구축했는가이다.

프로덕션 환경에서 에러를 방치하면:
- 사용자는 흰 화면(White Screen of Death)을 보고 이탈한다
- 개발팀은 문제를 인지하지 못해 대응이 늦어진다
- 같은 에러가 반복되며 신뢰도가 하락한다

이 문서에서는 React Error Boundary를 중심으로 에러를 격리·복구하고, Sentry를 통해 체계적으로 보고·추적하는 전체 파이프라인을 다룬다.

---

## React Error Boundary

### 기본 원리

Error Boundary는 **하위 컴포넌트 트리에서 발생한 렌더링 에러를 잡아** 앱 전체가 크래시하는 것을 방지하는 React 패턴이다.

```jsx
class ErrorBoundary extends React.Component {
  state = { hasError: false, error: null };

  // 렌더링 중 에러 발생 시 호출 → state 업데이트
  static getDerivedStateFromError(error) {
    return { hasError: true, error };
  }

  // 에러 정보 + 컴포넌트 스택을 받아 부수효과 처리 (로깅 등)
  componentDidCatch(error, errorInfo) {
    console.error('Caught by ErrorBoundary:', error);
    console.error('Component stack:', errorInfo.componentStack);
    // Sentry 등 외부 서비스로 보고
    reportToSentry(error, errorInfo);
  }

  render() {
    if (this.state.hasError) {
      return <FallbackUI error={this.state.error} />;
    }
    return this.props.children;
  }
}
```

**왜 함수형 컴포넌트로 만들 수 없는가?**

- `getDerivedStateFromError`와 `componentDidCatch`는 클래스 생명주기 메서드
- React 팀이 아직 함수형 대응 Hook(`useCatch` 등)을 제공하지 않음
- 내부적으로 Fiber의 `flags`를 통해 에러를 전파하는데, 이 메커니즘이 클래스 기반으로 설계됨
- **실무 해결책**: `react-error-boundary` 라이브러리 사용

### react-error-boundary 라이브러리

```bash
npm install react-error-boundary
```

```tsx
import { ErrorBoundary } from 'react-error-boundary';

function ErrorFallback({ error, resetErrorBoundary }) {
  return (
    <div role="alert" className="error-fallback">
      <h2>문제가 발생했습니다</h2>
      <pre>{error.message}</pre>
      <button onClick={resetErrorBoundary}>다시 시도</button>
    </div>
  );
}

function App() {
  return (
    <ErrorBoundary
      FallbackComponent={ErrorFallback}
      onError={(error, errorInfo) => {
        // Sentry 등으로 보고
        Sentry.captureException(error, { extra: errorInfo });
      }}
      onReset={() => {
        // 에러 복구 시 상태 초기화 로직
      }}
    >
      <MainContent />
    </ErrorBoundary>
  );
}
```

---

### 경계(Boundary) 설계 전략

에러 바운더리를 **어디에 배치하느냐**가 UX를 결정한다.

#### 1. 페이지 레벨 바운더리 (전체 fallback)

```tsx
// 최상위: 앱 전체를 감싸는 최후 방어선
<ErrorBoundary FallbackComponent={FullPageError}>
  <Router>
    <Routes />
  </Router>
</ErrorBoundary>
```

- 어떤 에러든 흰 화면 대신 에러 페이지를 보여줌
- 사용자에게 "새로고침" 또는 "홈으로" 옵션 제공

#### 2. 위젯/섹션 레벨 바운더리 (부분 격리)

```tsx
// 대시보드: 각 위젯을 독립적으로 격리
function Dashboard() {
  return (
    <div className="grid">
      <ErrorBoundary FallbackComponent={WidgetError}>
        <RevenueChart />
      </ErrorBoundary>
      <ErrorBoundary FallbackComponent={WidgetError}>
        <UserTable />
      </ErrorBoundary>
      <ErrorBoundary FallbackComponent={WidgetError}>
        <NotificationFeed />
      </ErrorBoundary>
    </div>
  );
}
```

- 하나의 위젯이 깨져도 나머지는 정상 동작
- 사용자 경험 손실을 최소화

#### 3. 크리티컬 vs 논크리티컬 에러 구분

| 구분 | 예시 | 처리 |
|------|------|------|
| 크리티컬 | 결제 폼 렌더링 실패 | 전체 fallback + 즉시 보고 |
| 논크리티컬 | 추천 위젯 실패 | 해당 영역만 숨김 |

#### 4. Suspense + ErrorBoundary 조합

```tsx
// data fetching 에러를 선언적으로 처리
<ErrorBoundary FallbackComponent={DataError}>
  <Suspense fallback={<Skeleton />}>
    <UserProfile /> {/* 내부에서 use() 또는 suspend */}
  </Suspense>
</ErrorBoundary>
```

- Suspense는 로딩 상태를, ErrorBoundary는 에러 상태를 담당
- React 19의 `use()` Hook과 자연스럽게 연동

---

### 복구 패턴

#### resetErrorBoundary로 재시도

```tsx
function QueryErrorFallback({ error, resetErrorBoundary }) {
  return (
    <div>
      <p>데이터를 불러오지 못했습니다: {error.message}</p>
      <button onClick={resetErrorBoundary}>재시도</button>
    </div>
  );
}
```

#### resetKeys로 상태 변경 시 자동 복구

```tsx
// userId가 바뀌면 에러 상태를 자동으로 리셋
<ErrorBoundary
  FallbackComponent={ErrorFallback}
  resetKeys={[userId]}
  onResetKeysChange={() => {
    // 새로운 사용자 데이터 로드 준비
  }}
>
  <UserProfile userId={userId} />
</ErrorBoundary>
```

#### Fallback UI 설계 원칙

좋은 에러 UI는 세 가지를 제공한다:

1. **무엇이 잘못됐는지** (사용자 친화적 메시지)
2. **어떻게 해결할 수 있는지** (재시도, 새로고침 버튼)
3. **도움을 받을 수 있는 경로** (고객센터 링크, 에러 코드)

```tsx
function RobustFallback({ error, resetErrorBoundary }) {
  const errorId = useMemo(() => generateErrorId(), []);

  return (
    <div role="alert" className="error-container">
      <h2>일시적인 문제가 발생했습니다</h2>
      <p>잠시 후 다시 시도해주세요.</p>
      <div className="error-actions">
        <button onClick={resetErrorBoundary}>다시 시도</button>
        <button onClick={() => window.location.reload()}>
          페이지 새로고침
        </button>
      </div>
      <details>
        <summary>기술 정보</summary>
        <p>에러 ID: {errorId}</p>
        <pre>{error.message}</pre>
      </details>
      <a href="/support">고객센터 문의</a>
    </div>
  );
}
```

---

## 에러 분류 체계

모든 에러를 동일하게 처리하면 안 된다. **심각도에 따라 대응 전략을 분리**해야 한다.

### Recoverable (복구 가능)

사용자 개입 없이 또는 최소 개입으로 정상 상태로 돌아갈 수 있는 에러.

| 에러 | 복구 전략 |
|------|-----------|
| 네트워크 일시 오류 (5xx, timeout) | 지수 백오프(exponential backoff) 재시도 |
| 인증 만료 (401) | refresh token으로 자동 갱신 후 원래 요청 재시도 |
| 낙관적 업데이트 실패 | 이전 상태로 롤백 + 사용자 알림 |
| Rate Limit (429) | Retry-After 헤더 기반 대기 후 재시도 |

```tsx
// 재시도 유틸
async function withRetry<T>(
  fn: () => Promise<T>,
  maxRetries = 3,
  baseDelay = 1000
): Promise<T> {
  for (let attempt = 0; attempt < maxRetries; attempt++) {
    try {
      return await fn();
    } catch (error) {
      if (attempt === maxRetries - 1) throw error;
      const delay = baseDelay * Math.pow(2, attempt);
      await new Promise(resolve => setTimeout(resolve, delay));
    }
  }
  throw new Error('Unreachable');
}
```

### Fatal (치명적)

자동 복구가 불가능하며, 사용자에게 명확한 안내가 필요한 에러.

| 에러 | 대응 |
|------|------|
| ChunkLoadError (코드 스플릿 파일 로드 실패) | 새로고침 유도 (배포 후 구버전 청크 삭제됨) |
| 렌더링 무한 루프 | Error Boundary 포착 + Sentry 보고 |
| 치명적 상태 불일치 | 로컬 스토리지 클리어 + 전체 리셋 |
| Critical API 장애 (결제, 인증 서버 다운) | 점검 페이지 표시 |

### Silent (무시 가능)

사용자에게 노출하지 않고, 로깅만 하는 에러.

| 에러 | 처리 |
|------|------|
| Analytics/추적 전송 실패 | console.warn + 무시 |
| 비필수 기능 에러 (추천, 배너) | 해당 UI 숨김 |
| 브라우저 확장 프로그램 충돌 | 필터링 후 무시 |

```tsx
// 에러 심각도 판단 유틸
type ErrorSeverity = 'fatal' | 'recoverable' | 'silent';

function classifyError(error: Error): ErrorSeverity {
  if (error.name === 'ChunkLoadError') return 'fatal';
  if (error.message.includes('Network Error')) return 'recoverable';
  if (error.message.includes('ResizeObserver')) return 'silent';
  return 'recoverable'; // 기본값: 복구 시도
}
```

---

## Sentry 연동 실전

### 기본 설정

```bash
# Next.js 프로젝트
npx @sentry/wizard@latest -i nextjs

# React SPA
npm install @sentry/react @sentry/browser
```

```tsx
// sentry.client.config.ts
import * as Sentry from '@sentry/nextjs';

Sentry.init({
  dsn: process.env.NEXT_PUBLIC_SENTRY_DSN,
  environment: process.env.NODE_ENV,     // 'production' | 'staging' | 'development'
  release: process.env.NEXT_PUBLIC_APP_VERSION,  // git SHA 또는 버전 태그

  // 프로덕션에서만 100% 샘플링, 개발 시 줄임
  tracesSampleRate: process.env.NODE_ENV === 'production' ? 0.2 : 1.0,

  // Session Replay: 에러 발생 세션만 100% 캡처
  replaysSessionSampleRate: 0.1,    // 일반 세션 10%
  replaysOnErrorSampleRate: 1.0,    // 에러 세션 100%

  integrations: [
    Sentry.browserTracingIntegration(),
    Sentry.replayIntegration({
      maskAllText: false,
      blockAllMedia: false,
    }),
  ],
});
```

**소스맵 업로드 (빌드 시)**

```js
// next.config.js
const { withSentryConfig } = require('@sentry/nextjs');

module.exports = withSentryConfig(nextConfig, {
  org: 'my-org',
  project: 'my-frontend',
  silent: true,
  // 빌드 시 소스맵을 Sentry에 업로드하고 번들에서는 제거
  hideSourceMaps: true,
});
```

### 고급 활용

#### Breadcrumbs (사용자 행동 추적)

Sentry는 에러 발생 직전의 사용자 행동을 자동 기록한다:
- 클릭 이벤트, 네비게이션, 콘솔 로그, XHR 요청

```tsx
// 커스텀 breadcrumb 추가
Sentry.addBreadcrumb({
  category: 'user-action',
  message: '결제 버튼 클릭',
  level: 'info',
  data: { orderId: '12345', amount: 50000 },
});
```

#### Custom Context (유저 정보, 페이지 상태)

```tsx
// 로그인 시 유저 정보 설정
Sentry.setUser({
  id: user.id,
  email: user.email,  // PII 주의: beforeSend에서 필터링 가능
  subscription: user.plan,
});

// 페이지별 추가 컨텍스트
Sentry.setContext('page', {
  route: '/dashboard',
  filters: { dateRange: '7d', status: 'active' },
});
```

#### beforeSend로 PII 필터링 & 노이즈 제거

```tsx
Sentry.init({
  beforeSend(event) {
    // PII 제거
    if (event.user) {
      delete event.user.email;
      delete event.user.ip_address;
    }

    // 브라우저 확장 에러 무시
    const frames = event.exception?.values?.[0]?.stacktrace?.frames || [];
    if (frames.some(f => f.filename?.includes('chrome-extension://'))) {
      return null; // 이벤트 삭제
    }

    // ResizeObserver 에러 무시 (브라우저 버그)
    if (event.message?.includes('ResizeObserver loop')) {
      return null;
    }

    return event;
  },
});
```

#### Release 태깅 & 커밋 연결

```bash
# CI/CD에서 릴리스 생성
sentry-cli releases new $VERSION
sentry-cli releases set-commits $VERSION --auto
sentry-cli releases finalize $VERSION
sentry-cli releases deploys $VERSION new -e production
```

이렇게 하면 Sentry UI에서:
- 어떤 릴리스에서 에러가 처음 발생했는지
- 어떤 커밋이 에러를 유발했는지
- 릴리스 간 에러율 비교

를 확인할 수 있다.

### 알림 & 대응

#### Issue Grouping

Sentry는 fingerprint 기반으로 같은 에러를 자동 그룹핑한다. 커스텀 그룹핑:

```tsx
Sentry.withScope(scope => {
  scope.setFingerprint(['payment-failure', String(errorCode)]);
  Sentry.captureException(error);
});
```

#### Alert Rules 설정

- **에러율 급증**: 5분 내 같은 에러 10회 이상 → Slack 알림
- **새 에러 발생**: 이전에 없던 에러 유형 → 즉시 알림
- **P0 에러**: 결제/인증 관련 → PagerDuty 연동

#### Resolve / Ignore 워크플로

1. 새 이슈 → 담당자 배정 (Assign)
2. 수정 완료 → Resolve (다음 릴리스에서 자동 확인)
3. 재발 시 → 자동 Reopen + 알림
4. 의도된 동작 → Ignore (조건부: 특정 버전 이하만)

---

## 전역 에러 핸들링

### window.onerror & window.onunhandledrejection

```tsx
// 전역 JS 에러 캐치 (동기 에러, 스크립트 로드 실패 등)
window.onerror = (message, source, lineno, colno, error) => {
  Sentry.captureException(error || new Error(String(message)), {
    extra: { source, lineno, colno },
  });
  return false; // 브라우저 기본 에러 로깅 유지
};

// Promise rejection 미처리 캐치
window.onunhandledrejection = (event) => {
  Sentry.captureException(event.reason, {
    tags: { type: 'unhandled_rejection' },
  });
};
```

### React의 에러 경계에 잡히지 않는 에러들

Error Boundary는 **렌더링 과정(render, lifecycle, constructor)** 의 에러만 잡는다. 다음은 잡히지 않는다:

| 잡히지 않는 에러 | 이유 |
|-----------------|------|
| 이벤트 핸들러 내부 에러 | 렌더링이 아닌 사용자 상호작용 시점 |
| 비동기 코드 (setTimeout, Promise) | 콜스택이 React 외부에서 실행 |
| SSR 에러 | 서버에서는 Error Boundary 미동작 |
| Error Boundary 자체의 에러 | 자기 자신은 못 잡음 |

**해결: try-catch + 전역 핸들러 조합**

```tsx
// 이벤트 핸들러는 try-catch로 직접 감싸기
function PaymentButton() {
  const handleClick = async () => {
    try {
      await processPayment();
    } catch (error) {
      Sentry.captureException(error);
      toast.error('결제 처리 중 오류가 발생했습니다');
    }
  };

  return <button onClick={handleClick}>결제하기</button>;
}
```

---

## 실전 코드 예제

### ErrorBoundary + Sentry 통합 컴포넌트

```tsx
import { ErrorBoundary } from 'react-error-boundary';
import * as Sentry from '@sentry/react';

interface AppErrorBoundaryProps {
  children: React.ReactNode;
  level?: 'page' | 'widget';
  name?: string;  // 어떤 바운더리에서 잡혔는지 식별
}

export function AppErrorBoundary({
  children,
  level = 'widget',
  name = 'unknown',
}: AppErrorBoundaryProps) {
  const handleError = (error: Error, errorInfo: React.ErrorInfo) => {
    Sentry.withScope(scope => {
      scope.setTag('error_boundary', name);
      scope.setTag('boundary_level', level);
      scope.setExtra('componentStack', errorInfo.componentStack);
      Sentry.captureException(error);
    });
  };

  const FallbackComponent = level === 'page' ? PageFallback : WidgetFallback;

  return (
    <ErrorBoundary
      FallbackComponent={FallbackComponent}
      onError={handleError}
      onReset={() => {
        // 캐시 무효화 등 정리 작업
      }}
    >
      {children}
    </ErrorBoundary>
  );
}

function PageFallback({ error, resetErrorBoundary }) {
  return (
    <div className="full-page-error">
      <h1>페이지를 표시할 수 없습니다</h1>
      <p>잠시 후 다시 시도해주세요.</p>
      <button onClick={resetErrorBoundary}>다시 시도</button>
      <button onClick={() => (window.location.href = '/')}>홈으로</button>
    </div>
  );
}

function WidgetFallback({ resetErrorBoundary }) {
  return (
    <div className="widget-error">
      <p>이 영역을 불러올 수 없습니다</p>
      <button onClick={resetErrorBoundary}>재시도</button>
    </div>
  );
}
```

### API 에러 핸들링 유틸 (axios interceptor)

```tsx
import axios, { AxiosError } from 'axios';
import * as Sentry from '@sentry/react';

const api = axios.create({ baseURL: '/api' });

// 요청 인터셉터: breadcrumb 추가
api.interceptors.request.use(config => {
  Sentry.addBreadcrumb({
    category: 'api',
    message: `${config.method?.toUpperCase()} ${config.url}`,
    level: 'info',
  });
  return config;
});

// 응답 인터셉터: 에러 분류 및 처리
api.interceptors.response.use(
  response => response,
  async (error: AxiosError) => {
    const status = error.response?.status;

    // 401: 토큰 갱신 시도
    if (status === 401) {
      try {
        await refreshToken();
        return api.request(error.config!);  // 원래 요청 재시도
      } catch {
        // 갱신 실패 → 로그아웃
        redirectToLogin();
      }
    }

    // 5xx: Sentry에 보고
    if (status && status >= 500) {
      Sentry.captureException(error, {
        tags: { api_status: status },
        extra: {
          url: error.config?.url,
          method: error.config?.method,
        },
      });
    }

    return Promise.reject(error);
  }
);

export default api;
```

### ChunkLoadError 자동 복구

코드 스플릿된 청크가 배포 후 삭제되어 로드 실패하는 경우:

```tsx
// lazy 로드 시 ChunkLoadError 감지 및 자동 새로고침
function lazyWithRetry(componentImport: () => Promise<any>) {
  return React.lazy(() =>
    componentImport().catch((error) => {
      if (
        error.name === 'ChunkLoadError' ||
        error.message.includes('Loading chunk')
      ) {
        // 무한 새로고침 방지: sessionStorage로 1회만
        const reloaded = sessionStorage.getItem('chunk_reload');
        if (!reloaded) {
          sessionStorage.setItem('chunk_reload', 'true');
          window.location.reload();
          return { default: () => null }; // 새로고침 전 빈 컴포넌트
        }
        sessionStorage.removeItem('chunk_reload');
      }
      throw error; // 다른 에러는 ErrorBoundary로 전파
    })
  );
}

// 사용
const Dashboard = lazyWithRetry(() => import('./pages/Dashboard'));
```

### 에러 리포팅 추상화 레이어

Sentry에 직접 의존하지 않고 추상화하면, 나중에 도구 교체가 쉽다:

```tsx
// lib/error-reporter.ts
interface ErrorReporter {
  captureException(error: Error, context?: Record<string, any>): void;
  captureMessage(message: string, level?: 'info' | 'warning' | 'error'): void;
  setUser(user: { id: string; email?: string } | null): void;
  addBreadcrumb(breadcrumb: { category: string; message: string }): void;
}

class SentryReporter implements ErrorReporter {
  captureException(error: Error, context?: Record<string, any>) {
    Sentry.captureException(error, { extra: context });
  }

  captureMessage(message: string, level = 'error') {
    Sentry.captureMessage(message, level);
  }

  setUser(user: { id: string; email?: string } | null) {
    Sentry.setUser(user);
  }

  addBreadcrumb(breadcrumb: { category: string; message: string }) {
    Sentry.addBreadcrumb({ ...breadcrumb, level: 'info' });
  }
}

// 싱글턴으로 export
export const errorReporter: ErrorReporter = new SentryReporter();
```

---

## 프로덕션 디버깅 워크플로

에러가 발생했을 때 **빠르게 원인을 찾고 수정하는 흐름**:

```
1. Sentry Alert 수신 (Slack/이메일)
   ↓
2. Breadcrumb으로 재현 경로 파악
   - 사용자가 어떤 페이지에서 어떤 동작을 했는지
   - 직전 API 호출 결과는?
   ↓
3. 소스맵으로 원본 코드 위치 확인
   - 난독화된 번들이 아닌 원본 파일명 + 라인 번호
   - "src/components/PaymentForm.tsx:142"
   ↓
4. Session Replay로 시각적 확인
   - 에러 발생 전후 30초 화면 녹화
   - 정확한 재현 없이도 상황 파악 가능
   ↓
5. 핫픽스 → 배포 → Resolve
   - 수정 커밋 → 릴리스에 연결
   - Sentry에서 이슈 Resolve
   - 재발 시 자동 Reopen
```

**소스맵이 없으면?**

```
// 난독화된 에러 (디버깅 불가)
TypeError: Cannot read property 'a' of undefined
    at e.value (main.3f2a1b.js:1:28394)

// 소스맵 적용 후 (즉시 위치 파악)
TypeError: Cannot read property 'name' of undefined
    at UserProfile.render (src/components/UserProfile.tsx:42:18)
```

---

## 면접 포인트

### Q. Error Boundary의 동작 원리를 설명하시오

> 하위 컴포넌트 트리에서 렌더링 중 에러가 throw되면, React는 Fiber 트리를 거슬러 올라가며 가장 가까운 Error Boundary를 찾는다. `getDerivedStateFromError`로 상태를 업데이트하여 fallback UI를 렌더링하고, `componentDidCatch`에서 에러 정보를 외부로 보고한다.

### Q. 에러 바운더리에 잡히지 않는 에러는? 어떻게 처리하는가?

> 이벤트 핸들러, 비동기 코드(setTimeout, Promise), SSR, Error Boundary 자체의 에러. 이벤트 핸들러는 try-catch로 감싸고, 미처리 Promise는 `window.onunhandledrejection`으로 전역 캐치한다.

### Q. 프로덕션 에러를 어떻게 모니터링하는가?

> Sentry 같은 에러 추적 도구를 통해 에러를 수집하고, Breadcrumb으로 재현 경로를, Session Replay로 시각적 맥락을 확인한다. Alert Rules로 에러율 급증 시 즉시 알림을 받고, Release 태깅으로 어떤 배포에서 문제가 발생했는지 추적한다.

### Q. Sentry에서 소스맵은 왜 필요한가?

> 프로덕션 번들은 minify/uglify되어 에러 스택트레이스가 읽을 수 없다. 소스맵을 업로드하면 Sentry가 원본 파일명과 라인 번호로 변환해주어 즉시 디버깅이 가능하다. 단, 소스맵을 클라이언트에 노출하면 코드가 공개되므로 Sentry에만 업로드하고 번들에서는 제거한다.

### Q. ChunkLoadError의 원인과 해결 방법은?

> 코드 스플릿된 JS 청크의 해시가 배포마다 달라지는데, 사용자가 구버전 HTML을 캐시한 상태에서 새 배포 후 청크를 요청하면 404가 발생한다. 해결: ① 에러 감지 시 자동 새로고침, ② 서비스 워커로 HTML 캐시 무효화, ③ CDN에서 구버전 청크를 일정 기간 유지.

### Q. 에러를 사용자에게 어떻게 보여줘야 하는가?

> 기술적 에러 메시지를 그대로 노출하지 않는다. ① 사용자 친화적 메시지 ("일시적인 문제가 발생했습니다"), ② 해결 방법 (재시도, 새로고침 버튼), ③ 도움 경로 (고객센터 링크, 에러 ID)를 제공한다. 크리티컬 에러는 전체 fallback, 논크리티컬은 해당 영역만 숨긴다.

---

## 참고 자료

- [React 공식 문서 - Error Boundaries](https://react.dev/reference/react/Component#catching-rendering-errors-with-an-error-boundary)
- [react-error-boundary GitHub](https://github.com/bvaughn/react-error-boundary)
- [Sentry React SDK 문서](https://docs.sentry.io/platforms/javascript/guides/react/)
- [Sentry Next.js SDK 문서](https://docs.sentry.io/platforms/javascript/guides/nextjs/)
- [Kent C. Dodds - Use react-error-boundary](https://kentcdodds.com/blog/use-react-error-boundary-to-handle-errors-in-react)
- [Web.dev - Monitor your web application with Reporting API](https://web.dev/reporting-api/)
