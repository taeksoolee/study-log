# 9. React 18 Concurrent Features

## 목차
1. Concurrent Rendering 개념
2. useTransition
3. useDeferredValue
4. Suspense for Data Fetching
5. React 18 주요 변경사항
6. 면접 포인트

---

## 1. Concurrent Rendering 개념

### 1.1 기존 렌더링의 문제점

React 17 이전의 렌더링은 **동기식(Synchronous)**이었다.
한번 렌더링이 시작되면 완료될 때까지 중단할 수 없어, 무거운 렌더링 작업이 실행되는 동안 UI가 차단(blocking)되었다.

```
[기존]  렌더링 시작 → ━━━━━━━━━━━━━━━━━━━ → 완료  (사용자 입력 차단)
[Concurrent] 렌더링 시작 → 우선순위 높은 작업 끼어들기 → 재개 → 완료
```

### 1.2 Concurrent Mode란

Concurrent Rendering은 React가 렌더링을 **일시 중단, 재개, 우선순위 조정**할 수 있는 능력이다.
React 18에서 기본으로 활성화되며, `createRoot`를 사용하면 자동으로 활성화된다.

```tsx
// React 18 — Concurrent Mode 활성화
import { createRoot } from 'react-dom/client';

const root = createRoot(document.getElementById('root')!);
root.render(<App />);

// React 17 이하 — Legacy 모드
ReactDOM.render(<App />, document.getElementById('root'));
```

### 1.3 핵심 개념

- **긴급 업데이트(Urgent Updates)**: 타이핑, 클릭 등 사용자 인터랙션 — 즉시 반응해야 함
- **전환 업데이트(Transition Updates)**: 검색 결과, 탭 전환 등 — 약간의 지연 허용
- Concurrent Features는 긴급 업데이트를 전환 업데이트보다 우선 처리한다

---

## 2. useTransition

### 2.1 개념

`useTransition`은 상태 업데이트를 "전환(Transition)"으로 표시하여, 더 긴급한 업데이트에 의해 중단될 수 있음을 React에 알린다.

```tsx
const [isPending, startTransition] = useTransition();
```

- `isPending`: 전환이 진행 중인지 여부
- `startTransition`: 내부의 상태 업데이트를 낮은 우선순위로 표시

### 2.2 예제 — 검색 필터

```tsx
import { useState, useTransition } from 'react';

const ITEMS = Array.from({ length: 10000 }, (_, i) => `아이템 ${i + 1}`);

function SearchList() {
  const [query, setQuery] = useState('');
  const [filteredItems, setFilteredItems] = useState(ITEMS);
  const [isPending, startTransition] = useTransition();

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const value = e.target.value;

    // 입력값 업데이트는 긴급 처리 (타이핑 즉시 반응)
    setQuery(value);

    // 목록 필터링은 전환으로 처리 (UI 차단 방지)
    startTransition(() => {
      const filtered = ITEMS.filter(item =>
        item.toLowerCase().includes(value.toLowerCase())
      );
      setFilteredItems(filtered);
    });
  };

  return (
    <div>
      <input value={query} onChange={handleChange} placeholder="검색..." />
      {isPending && <span>검색 중...</span>}
      <ul>
        {filteredItems.map(item => (
          <li key={item}>{item}</li>
        ))}
      </ul>
    </div>
  );
}
```

### 2.3 예제 — 탭 전환

```tsx
function TabContainer() {
  const [tab, setTab] = useState('home');
  const [isPending, startTransition] = useTransition();

  const selectTab = (nextTab: string) => {
    startTransition(() => setTab(nextTab));
  };

  return (
    <div>
      <nav style={{ opacity: isPending ? 0.7 : 1 }}>
        {['home', 'posts', 'settings'].map(t => (
          <button key={t} onClick={() => selectTab(t)}>
            {t}
          </button>
        ))}
      </nav>
      {/* tab에 따른 무거운 컴포넌트 렌더링 */}
      <TabContent tab={tab} />
    </div>
  );
}
```

---

## 3. useDeferredValue

### 3.1 개념

`useDeferredValue`는 값의 업데이트를 지연시켜, UI의 특정 부분이 더 긴급한 업데이트에 의해 뒤처지도록 허용한다.
prop이나 외부에서 오는 값을 지연할 때 사용한다 (`useTransition`은 자체 상태 업데이트에 사용).

```tsx
const deferredValue = useDeferredValue(value);
```

### 3.2 예제 — 입력과 목록 분리

```tsx
import { useState, useDeferredValue, memo } from 'react';

// memo로 감싸야 최적화 효과 있음
const SlowList = memo(function SlowList({ query }: { query: string }) {
  const items = ITEMS.filter(item => item.includes(query));
  // 의도적으로 느린 렌더링 시뮬레이션
  return <ul>{items.map(item => <li key={item}>{item}</li>)}</ul>;
});

function SearchWithDeferred() {
  const [query, setQuery] = useState('');
  const deferredQuery = useDeferredValue(query); // 지연된 값

  const isStale = query !== deferredQuery; // 목록이 뒤처진 상태

  return (
    <div>
      <input
        value={query}
        onChange={e => setQuery(e.target.value)}
        placeholder="검색..."
      />
      <div style={{ opacity: isStale ? 0.5 : 1 }}>
        <SlowList query={deferredQuery} />
      </div>
    </div>
  );
}
```

### 3.3 useTransition vs useDeferredValue 비교

| 항목 | useTransition | useDeferredValue |
|------|--------------|-----------------|
| 적용 대상 | 직접 제어하는 상태 업데이트 | prop/외부에서 오는 값 |
| 사용 위치 | 이벤트 핸들러 | 컴포넌트 본문 |
| pending 상태 | isPending 제공 | 직접 비교 필요 |
| 사용 예 | 탭 전환, 폼 제출 | 검색 결과 지연 렌더링 |

---

## 4. Suspense for Data Fetching

### 4.1 개념

React 18에서 Suspense가 데이터 페칭에 공식 지원된다.
컴포넌트가 데이터를 기다리는 동안 Promise를 throw하면, 상위 Suspense가 이를 감지해 fallback을 표시한다.

### 4.2 Next.js App Router에서 Suspense

```tsx
// app/dashboard/page.tsx
import { Suspense } from 'react';

async function UserStats() {
  const stats = await fetch('/api/stats').then(r => r.json());
  return <div>방문자: {stats.visitors}</div>;
}

async function RecentActivity() {
  const activities = await fetch('/api/activities').then(r => r.json());
  return <ul>{activities.map((a: Activity) => <li key={a.id}>{a.text}</li>)}</ul>;
}

export default function DashboardPage() {
  return (
    <div>
      {/* 각 컴포넌트가 독립적으로 스트리밍 */}
      <Suspense fallback={<StatsSkeleton />}>
        <UserStats />
      </Suspense>
      <Suspense fallback={<ActivitySkeleton />}>
        <RecentActivity />
      </Suspense>
    </div>
  );
}
```

### 4.3 React Query + Suspense

```tsx
import { useSuspenseQuery } from '@tanstack/react-query';

function UserProfile({ userId }: { userId: string }) {
  // 에러: ErrorBoundary로, 로딩: Suspense로 위임
  const { data: user } = useSuspenseQuery({
    queryKey: ['user', userId],
    queryFn: () => fetchUser(userId),
  });

  // loading/error 분기 없이 바로 데이터 사용
  return <div>{user.name}</div>;
}

// 사용
<ErrorBoundary FallbackComponent={ErrorFallback}>
  <Suspense fallback={<ProfileSkeleton />}>
    <UserProfile userId="1" />
  </Suspense>
</ErrorBoundary>
```

### 4.4 use() 훅 (React 19 preview / Canary)

```tsx
import { use, Suspense } from 'react';

// Promise를 직접 전달
function UserCard({ userPromise }: { userPromise: Promise<User> }) {
  const user = use(userPromise); // Suspense를 자동으로 트리거
  return <div>{user.name}</div>;
}

async function Page() {
  const userPromise = fetchUser('1'); // await 없이 전달
  return (
    <Suspense fallback={<Skeleton />}>
      <UserCard userPromise={userPromise} />
    </Suspense>
  );
}
```

---

## 5. React 18 주요 변경사항

### 5.1 자동 배치(Automatic Batching)

```tsx
// React 17: 이벤트 핸들러 외부에서는 배치 안 됨 (2번 렌더)
setTimeout(() => {
  setCount(c => c + 1);
  setFlag(f => !f);
}, 1000);

// React 18: 모든 상황에서 자동 배치 (1번 렌더)
// setTimeout, Promise, 네이티브 이벤트 모두 배치 처리
```

```tsx
// 배치를 원하지 않을 때 — flushSync
import { flushSync } from 'react-dom';

flushSync(() => setCount(c => c + 1));  // 즉시 렌더
flushSync(() => setFlag(f => !f));       // 즉시 렌더
```

### 5.2 새로운 훅들

```tsx
// useId — 서버/클라이언트 간 안정적인 고유 ID 생성
function FormField() {
  const id = useId();
  return (
    <div>
      <label htmlFor={id}>이름</label>
      <input id={id} />
    </div>
  );
}

// useSyncExternalStore — 외부 스토어 구독
function useWindowSize() {
  return useSyncExternalStore(
    (callback) => {
      window.addEventListener('resize', callback);
      return () => window.removeEventListener('resize', callback);
    },
    () => ({ width: window.innerWidth, height: window.innerHeight }),
    () => ({ width: 0, height: 0 }) // 서버 스냅샷
  );
}

// useInsertionEffect — CSS-in-JS 라이브러리용 (DOM 변경 전 실행)
```

### 5.3 Streaming SSR

```tsx
// React 18의 renderToPipeableStream
import { renderToPipeableStream } from 'react-server-dom-webpack/server';

// Suspense 경계를 기준으로 HTML을 스트리밍 전송
// 초기 HTML → 나머지 컴포넌트들을 청크 단위로 스트리밍
```

---

## 6. 면접 포인트

### Q1. React 18의 Concurrent Mode가 해결하는 문제는?

기존 React는 렌더링을 중단할 수 없어서 무거운 컴포넌트가 렌더링되는 동안 UI가 멈추는 문제가 있었습니다. Concurrent Mode는 렌더링 작업에 우선순위를 부여해 사용자 인터랙션(긴급)을 데이터 로딩/목록 업데이트(전환)보다 먼저 처리합니다. 이를 통해 타이핑, 클릭 등의 즉각적 응답을 유지하면서 무거운 렌더링도 처리할 수 있습니다.

### Q2. useTransition과 useDeferredValue의 차이는?

두 API 모두 업데이트 우선순위를 낮추는 역할을 하지만 사용 맥락이 다릅니다. `useTransition`은 직접 제어하는 상태 업데이트를 낮은 우선순위로 표시할 때 사용하며, `isPending`으로 진행 중 여부를 알 수 있습니다. `useDeferredValue`는 prop 등 외부에서 오는 값에 적용하며, 해당 값을 사용하는 렌더링을 지연시킵니다.

### Q3. React 18에서 자동 배치(Automatic Batching)란?

React 17에서는 이벤트 핸들러 내부에서만 여러 setState를 하나의 렌더링으로 배치했습니다. React 18에서는 `setTimeout`, Promise 콜백, 네이티브 이벤트 핸들러 등 모든 상황에서 자동으로 배치 처리됩니다. 이를 통해 불필요한 리렌더링을 줄이고 성능이 향상됩니다. 즉시 렌더가 필요한 경우 `flushSync`를 사용합니다.

### Q4. Suspense를 데이터 페칭에 사용하면 어떤 장점이 있나요?

컴포넌트에서 `loading`/`error` 분기 처리를 없앨 수 있어 컴포넌트 로직이 단순해집니다. 여러 비동기 컴포넌트를 독립적인 Suspense 경계로 나누면 각각 독립적으로 로딩/에러를 처리할 수 있고, Next.js App Router에서는 Streaming SSR과 결합해 준비된 컴포넌트부터 순차적으로 HTML을 전송할 수 있습니다.
