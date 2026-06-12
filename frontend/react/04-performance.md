# 4. React 성능 최적화 (Performance)

## 목차
1. React 리렌더링 발생 조건
2. React.memo
3. useMemo vs useCallback
4. 불필요한 리렌더링 원인 분석
5. React DevTools Profiler
6. 상태 구조 최적화
7. key prop 올바른 사용법
8. Lazy Loading (React.lazy, Suspense)
9. 면접 포인트

---

## 1. React 리렌더링 발생 조건

React 컴포넌트가 리렌더링되는 조건은 4가지다.

1. **state가 변경**될 때 (`setState`, `useState`의 setter 호출)
2. **props가 변경**될 때 (부모로부터 받은 값이 달라질 때)
3. **부모 컴포넌트가 리렌더링**될 때 (props 변경 없어도 자식도 리렌더링)
4. **Context 값이 변경**될 때 (`useContext`를 구독 중인 경우)

```tsx
function Parent() {
  const [count, setCount] = useState(0);
  return (
    <div>
      <button onClick={() => setCount(c => c + 1)}>{count}</button>
      {/* count가 변경되면 Child도 리렌더링됨 (props 없어도) */}
      <Child />
    </div>
  );
}

function Child() {
  console.log('Child 리렌더링');
  return <div>나는 자식</div>;
}
```

### 1.1 리렌더링이 항상 문제인 것은 아니다

React는 Virtual DOM 비교(Reconciliation)를 통해 실제 DOM 업데이트를 최소화한다.
불필요한 최적화(memo 과도한 사용 등)는 오히려 성능을 저하시킬 수 있다.
**측정(Profiler) → 문제 확인 → 최적화** 순서를 지켜야 한다.

---

## 2. React.memo

### 2.1 개념

`React.memo`는 HOC(Higher Order Component)로, 이전 props와 현재 props를 **얕은 비교(shallow comparison)**하여 동일하면 리렌더링을 건너뛴다.

```tsx
import { memo } from 'react';

interface UserCardProps {
  name: string;
  age: number;
}

// memo로 감싸면 name, age가 변경될 때만 리렌더링
const UserCard = memo(function UserCard({ name, age }: UserCardProps) {
  console.log('UserCard 렌더링');
  return (
    <div>
      <p>{name}</p>
      <p>{age}</p>
    </div>
  );
});
```

### 2.2 얕은 비교의 함정

```tsx
function Parent() {
  const [count, setCount] = useState(0);

  // 매 렌더링마다 새 객체 생성 → memo 무효화!
  const style = { color: 'red' };
  const handleClick = () => console.log('clicked');

  return (
    <>
      <button onClick={() => setCount(c => c + 1)}>{count}</button>
      {/* style, handleClick이 매번 새 참조 → UserCard 리렌더링됨 */}
      <UserCard style={style} onClick={handleClick} />
    </>
  );
}
```

### 2.3 커스텀 비교 함수

```tsx
const UserCard = memo(
  function UserCard({ user }: { user: User }) {
    return <div>{user.name}</div>;
  },
  (prevProps, nextProps) => {
    // true 반환 시 리렌더링 건너뜀
    // false 반환 시 리렌더링 실행
    return prevProps.user.id === nextProps.user.id &&
           prevProps.user.name === nextProps.user.name;
  }
);
```

### 2.4 memo를 사용하면 좋은 경우

- 렌더링 비용이 높은 컴포넌트 (복잡한 계산, 큰 리스트 아이템)
- 부모가 자주 리렌더링되지만 해당 컴포넌트의 props는 자주 바뀌지 않는 경우
- Pure한 컴포넌트 (같은 props → 항상 같은 결과)

---

## 3. useMemo vs useCallback

### 3.1 useMemo: 값(계산 결과)을 메모이제이션

```tsx
import { useMemo, useState } from 'react';

function ProductList({ products, filter }: Props) {
  // filter나 products가 바뀔 때만 재계산
  const filteredProducts = useMemo(() => {
    console.log('필터링 실행');
    return products.filter(p => p.category === filter);
  }, [products, filter]);

  return (
    <ul>
      {filteredProducts.map(p => (
        <li key={p.id}>{p.name}</li>
      ))}
    </ul>
  );
}
```

### 3.2 useCallback: 함수를 메모이제이션

```tsx
import { useCallback, useState } from 'react';

function Parent() {
  const [count, setCount] = useState(0);
  const [text, setText] = useState('');

  // text가 바뀌어도 handleSubmit은 새 참조를 만들지 않음
  const handleSubmit = useCallback(() => {
    console.log('제출:', count);
  }, [count]); // count가 바뀔 때만 새 함수 생성

  return (
    <>
      <input value={text} onChange={e => setText(e.target.value)} />
      <button onClick={() => setCount(c => c + 1)}>{count}</button>
      {/* handleSubmit이 안정적인 참조 → MemoizedChild 리렌더링 안 됨 */}
      <MemoizedChild onSubmit={handleSubmit} />
    </>
  );
}
```

### 3.3 useMemo vs useCallback 비교

| | useMemo | useCallback |
|---|---|---|
| 반환값 | 계산된 **값** | **함수** |
| 목적 | 비싼 계산 결과 캐싱 | 함수 참조 안정화 |
| 관계 | - | `useCallback(fn, deps)` === `useMemo(() => fn, deps)` |

### 3.4 잘못된 사용 예시

```tsx
// 불필요한 useMemo: 간단한 계산에는 오버헤드
const value = useMemo(() => count * 2, [count]); // 그냥 count * 2 쓰면 됨

// 불필요한 useCallback: memo로 감싸지 않은 컴포넌트에 전달
function Parent() {
  // Child가 memo가 아니면 어차피 리렌더링됨 → useCallback 의미 없음
  const fn = useCallback(() => {}, []);
  return <Child onClick={fn} />; // Child가 memo가 아님
}
```

---

## 4. 불필요한 리렌더링 원인 분석

### 4.1 참조 동일성 문제

JavaScript에서 객체/배열/함수는 매 렌더링마다 새 참조가 생성된다.

```tsx
function Parent() {
  const [count, setCount] = useState(0);

  // 렌더링마다 새 객체/배열/함수 참조 생성
  const config = { theme: 'dark' };   // 새 객체
  const items = [1, 2, 3];            // 새 배열
  const handleClick = () => {};        // 새 함수

  return <MemoizedChild config={config} items={items} onClick={handleClick} />;
  // → MemoizedChild는 항상 리렌더링됨 (memo가 의미 없음)
}

// 해결: useMemo, useCallback, 또는 컴포넌트 외부로 이동
function ParentFixed() {
  const [count, setCount] = useState(0);

  const config = useMemo(() => ({ theme: 'dark' }), []);
  const items = useMemo(() => [1, 2, 3], []);
  const handleClick = useCallback(() => {}, []);

  return <MemoizedChild config={config} items={items} onClick={handleClick} />;
}
```

### 4.2 상태 끌어올리기 과도화 문제

```tsx
// 나쁜 패턴: input 상태를 최상위로 끌어올림 → 모든 자식 리렌더링
function App() {
  const [inputValue, setInputValue] = useState(''); // 타이핑마다 App 리렌더링

  return (
    <>
      <ExpensiveComponent />  {/* inputValue와 무관하지만 리렌더링 */}
      <input value={inputValue} onChange={e => setInputValue(e.target.value)} />
    </>
  );
}

// 좋은 패턴: 상태를 필요한 컴포넌트 안으로 내리기
function App() {
  return (
    <>
      <ExpensiveComponent />  {/* 이제 리렌더링 안 됨 */}
      <SearchInput />          {/* 상태를 자체적으로 관리 */}
    </>
  );
}

function SearchInput() {
  const [inputValue, setInputValue] = useState('');
  return <input value={inputValue} onChange={e => setInputValue(e.target.value)} />;
}
```

### 4.3 Children as Props 패턴으로 리렌더링 방지

```tsx
// count 변경 시 ExpensiveTree도 리렌더링되는 문제
function App() {
  const [count, setCount] = useState(0);
  return (
    <div>
      <button onClick={() => setCount(c => c + 1)}>{count}</button>
      <ExpensiveTree />
    </div>
  );
}

// children prop을 사용하면 ExpensiveTree는 리렌더링되지 않음
function Counter({ children }: { children: React.ReactNode }) {
  const [count, setCount] = useState(0);
  return (
    <div>
      <button onClick={() => setCount(c => c + 1)}>{count}</button>
      {children}
    </div>
  );
}

function App() {
  return (
    <Counter>
      <ExpensiveTree />  {/* count 변경 시 리렌더링 안 됨 */}
    </Counter>
  );
}
```

---

## 5. React DevTools Profiler

### 5.1 Profiler 설치 및 접근

Chrome/Firefox 확장 프로그램 "React Developer Tools"를 설치한 뒤 DevTools의 "Profiler" 탭을 사용한다.

### 5.2 사용 방법

1. Profiler 탭에서 "Record" 버튼 클릭
2. 측정하려는 동작 수행
3. "Stop" 버튼 클릭
4. Flamegraph 또는 Ranked Chart로 결과 분석

### 5.3 Profiler API (코드에서 직접 측정)

```tsx
import { Profiler } from 'react';

function onRenderCallback(
  id: string,           // Profiler의 id prop
  phase: 'mount' | 'update' | 'nested-update',
  actualDuration: number,  // 실제 렌더링 시간 (ms)
  baseDuration: number,    // memo 없을 때 예상 시간 (ms)
  startTime: number,
  commitTime: number
) {
  if (actualDuration > 16) { // 16ms = 60fps 기준
    console.warn(`${id} 렌더링이 느립니다: ${actualDuration}ms`);
  }
}

function App() {
  return (
    <Profiler id="ProductList" onRender={onRenderCallback}>
      <ProductList />
    </Profiler>
  );
}
```

### 5.4 "왜 렌더링되었나?" 확인

React DevTools Profiler 설정에서 "Record why each component rendered while profiling"을 활성화하면 각 컴포넌트의 리렌더링 원인을 확인할 수 있다.

---

## 6. 상태 구조 최적화

### 6.1 상태 분리

관련 없는 상태를 하나로 묶으면 불필요한 리렌더링이 발생한다.

```tsx
// 나쁜 패턴: 관련 없는 상태를 하나의 객체로
const [state, setState] = useState({
  username: '',
  theme: 'light',
  sidebarOpen: false,
});
// username 변경 시 theme, sidebarOpen을 사용하는 컴포넌트도 리렌더링

// 좋은 패턴: 상태 분리
const [username, setUsername] = useState('');
const [theme, setTheme] = useState('light');
const [sidebarOpen, setSidebarOpen] = useState(false);
```

### 6.2 파생 상태 피하기

```tsx
// 나쁜 패턴: 파생 상태를 별도 state로 관리
const [items, setItems] = useState([...]);
const [filteredItems, setFilteredItems] = useState([...]);
// filteredItems를 별도로 동기화해야 해서 버그 발생 가능

// 좋은 패턴: useMemo로 파생 상태 계산
const [items, setItems] = useState([...]);
const [filter, setFilter] = useState('');
const filteredItems = useMemo(
  () => items.filter(item => item.name.includes(filter)),
  [items, filter]
);
```

---

## 7. key prop 올바른 사용법

### 7.1 key의 역할

React는 `key`를 사용해 리스트 아이템의 동일성을 추적한다.

```tsx
// 나쁜 패턴: 인덱스를 key로 사용
{items.map((item, index) => (
  <Item key={index} data={item} />  // 순서 변경 시 잘못된 DOM 재사용
))}

// 좋은 패턴: 고유한 식별자를 key로 사용
{items.map(item => (
  <Item key={item.id} data={item} />
))}
```

### 7.2 key를 활용한 상태 초기화

```tsx
// key가 바뀌면 컴포넌트를 완전히 재마운트함 (상태 초기화)
function App() {
  const [userId, setUserId] = useState(1);

  return (
    // userId가 바뀌면 UserProfile이 재마운트되어 내부 상태 초기화
    <UserProfile key={userId} userId={userId} />
  );
}
```

---

## 8. Lazy Loading (React.lazy, Suspense)

### 8.1 코드 분할 (Code Splitting)

초기 번들 크기를 줄이기 위해 사용하지 않는 컴포넌트를 동적으로 로드한다.

```tsx
import { lazy, Suspense } from 'react';

// 해당 컴포넌트가 실제로 렌더링될 때 번들을 로드
const HeavyChart = lazy(() => import('./HeavyChart'));
const AdminPanel = lazy(() => import('./AdminPanel'));

function App() {
  const [showChart, setShowChart] = useState(false);

  return (
    <div>
      <button onClick={() => setShowChart(true)}>차트 보기</button>
      {showChart && (
        <Suspense fallback={<div>로딩 중...</div>}>
          <HeavyChart />
        </Suspense>
      )}
    </div>
  );
}
```

### 8.2 라우트 기반 코드 분할 (가장 일반적인 패턴)

```tsx
import { lazy, Suspense } from 'react';
import { Routes, Route } from 'react-router-dom';

const Home = lazy(() => import('./pages/Home'));
const Dashboard = lazy(() => import('./pages/Dashboard'));
const Settings = lazy(() => import('./pages/Settings'));

function App() {
  return (
    <Suspense fallback={<PageLoader />}>
      <Routes>
        <Route path="/" element={<Home />} />
        <Route path="/dashboard" element={<Dashboard />} />
        <Route path="/settings" element={<Settings />} />
      </Routes>
    </Suspense>
  );
}
```

### 8.3 React.lazy 사용 시 주의사항

- `default export`만 지원한다. Named export는 re-export 필요.
- SSR(서버 사이드 렌더링)에서는 기본적으로 지원되지 않는다 (Next.js의 `dynamic()` 사용).

```tsx
// named export를 lazy로 사용하는 방법
const MyComponent = lazy(() =>
  import('./MyComponent').then(module => ({ default: module.MyComponent }))
);
```

---

## 9. 면접 포인트

### Q1. React.memo, useMemo, useCallback의 차이를 설명해보세요.

- `React.memo`: **컴포넌트** 자체를 메모이제이션. props가 변경되지 않으면 리렌더링 건너뜀.
- `useMemo`: **값(계산 결과)**을 메모이제이션. 의존성이 바뀔 때만 재계산.
- `useCallback`: **함수**를 메모이제이션. 의존성이 바뀔 때만 새 함수 생성. `useMemo(() => fn, deps)`와 동일.

### Q2. useCallback은 언제 써야 하나요?

`useCallback`은 두 조건이 모두 만족될 때 의미가 있습니다.
1. 함수를 받는 자식 컴포넌트가 `React.memo`로 감싸져 있을 때
2. 함수가 자주 재생성되어 자식의 불필요한 리렌더링을 유발할 때

memo 없이 useCallback만 쓰면 자식은 어차피 리렌더링되므로 의미가 없습니다.

### Q3. 리스트에서 index를 key로 사용하면 안 되는 이유는?

항목이 추가/삭제/정렬될 때 index가 재할당됩니다. React는 key로 컴포넌트 동일성을 추적하므로, index를 key로 쓰면 잘못된 컴포넌트가 재사용되어 상태가 꼬이거나 불필요한 DOM 업데이트가 발생합니다. 단, 정렬/필터링이 없고 추가만 되는 경우에는 허용됩니다.

### Q4. React Profiler에서 어떤 지표를 보나요?

- `actualDuration`: 실제 렌더링 시간. 16ms 초과 시 60fps 이하로 떨어질 수 있음.
- `baseDuration`: memo 없이 렌더링했을 때의 예상 시간. actualDuration과 차이가 크면 memo가 잘 작동하고 있는 것.
- Flamegraph에서 회색(스킵된) 컴포넌트와 색칠된(렌더링된) 컴포넌트를 비교해 최적화 효과를 확인.

### Q5. 성능 최적화 시 접근 순서는?

1. **측정 먼저**: Profiler로 실제 병목을 찾는다. 추측으로 최적화하지 않는다.
2. **상태 구조 개선**: 상태를 필요한 위치에 배치하고, 관련 없는 상태는 분리.
3. **memo/useMemo/useCallback**: 참조 동일성 문제를 해결.
4. **코드 분할**: 초기 로딩 속도를 위해 라우트 단위로 lazy loading.
5. **재측정**: 최적화 후 개선 여부를 확인.
