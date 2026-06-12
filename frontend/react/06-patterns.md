# 6. React 패턴

## 목차
1. HOC (Higher Order Component)
2. Render Props
3. Compound Components
4. Custom Hook으로 패턴 대체
5. Controlled vs Uncontrolled Component
6. 면접 포인트

---

## 1. HOC (Higher Order Component)

### 1.1 개념

HOC는 컴포넌트를 인자로 받아 새로운 컴포넌트를 반환하는 함수다.
공통 로직(인증 체크, 로딩, 로깅 등)을 여러 컴포넌트에 재사용할 때 활용했다.

```
const EnhancedComponent = withSomething(OriginalComponent);
```

### 1.2 예제 — withAuth (인증 HOC)

```tsx
import { useRouter } from 'next/navigation';
import { useAuth } from '@/hooks/useAuth';

function withAuth<P extends object>(WrappedComponent: React.ComponentType<P>) {
  return function AuthenticatedComponent(props: P) {
    const { user, loading } = useAuth();
    const router = useRouter();

    if (loading) return <div>로딩 중...</div>;
    if (!user) {
      router.push('/login');
      return null;
    }

    return <WrappedComponent {...props} />;
  };
}

// 사용
const ProtectedDashboard = withAuth(Dashboard);
```

### 1.3 예제 — withLogger (로깅 HOC)

```tsx
function withLogger<P extends object>(WrappedComponent: React.ComponentType<P>) {
  const displayName = WrappedComponent.displayName || WrappedComponent.name || 'Component';

  function LoggedComponent(props: P) {
    useEffect(() => {
      console.log(`[${displayName}] mounted`, props);
      return () => console.log(`[${displayName}] unmounted`);
    }, []);

    return <WrappedComponent {...props} />;
  }

  // DevTools에서 이름 표시
  LoggedComponent.displayName = `withLogger(${displayName})`;
  return LoggedComponent;
}
```

### 1.4 HOC의 단점

- **Props 충돌**: HOC가 동일한 prop 이름을 주입하면 덮어씌워질 수 있음
- **래퍼 지옥(Wrapper Hell)**: HOC를 여러 개 중첩하면 컴포넌트 트리가 깊어짐
- **타입 추론 어려움**: TypeScript에서 제네릭 타입 처리가 복잡함
- **출처 불명확**: 어떤 HOC에서 prop이 왔는지 파악하기 어려움

```tsx
// 래퍼 지옥 예시
export default withRouter(withAuth(withLogger(withTheme(MyComponent))));
```

---

## 2. Render Props

### 2.1 개념

render prop은 컴포넌트에 함수를 prop으로 전달하여, 해당 함수가 렌더링할 내용을 결정하는 패턴이다.
로직과 UI를 분리할 수 있다.

### 2.2 예제 — MouseTracker

```tsx
interface MousePosition {
  x: number;
  y: number;
}

interface MouseTrackerProps {
  render: (position: MousePosition) => React.ReactNode;
}

function MouseTracker({ render }: MouseTrackerProps) {
  const [position, setPosition] = useState<MousePosition>({ x: 0, y: 0 });

  const handleMouseMove = (e: React.MouseEvent) => {
    setPosition({ x: e.clientX, y: e.clientY });
  };

  return (
    <div style={{ height: '300px' }} onMouseMove={handleMouseMove}>
      {render(position)}
    </div>
  );
}

// 사용
<MouseTracker
  render={({ x, y }) => (
    <p>마우스 위치: {x}, {y}</p>
  )}
/>
```

### 2.3 children as function 패턴

```tsx
interface DataFetcherProps<T> {
  url: string;
  children: (data: T | null, loading: boolean, error: Error | null) => React.ReactNode;
}

function DataFetcher<T>({ url, children }: DataFetcherProps<T>) {
  const [data, setData] = useState<T | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  useEffect(() => {
    fetch(url)
      .then(res => res.json())
      .then(setData)
      .catch(setError)
      .finally(() => setLoading(false));
  }, [url]);

  return <>{children(data, loading, error)}</>;
}

// 사용
<DataFetcher<User[]> url="/api/users">
  {(users, loading, error) => {
    if (loading) return <Spinner />;
    if (error) return <ErrorMessage error={error} />;
    return <UserList users={users!} />;
  }}
</DataFetcher>
```

---

## 3. Compound Components

### 3.1 개념

Compound Components 패턴은 여러 컴포넌트가 암묵적으로 상태를 공유하면서 함께 동작하는 패턴이다.
Context API를 활용해 컴포넌트 간 상태를 공유한다. `<select>/<option>`, `<table>/<tr>/<td>` 같은 HTML 구조와 유사하다.

### 3.2 예제 — Tabs 컴포넌트

```tsx
interface TabsContextValue {
  activeTab: string;
  setActiveTab: (tab: string) => void;
}

const TabsContext = createContext<TabsContextValue | null>(null);

function useTabs() {
  const ctx = useContext(TabsContext);
  if (!ctx) throw new Error('Tabs 컴포넌트 내부에서만 사용 가능합니다');
  return ctx;
}

// 루트 컴포넌트
function Tabs({ children, defaultTab }: { children: React.ReactNode; defaultTab: string }) {
  const [activeTab, setActiveTab] = useState(defaultTab);
  return (
    <TabsContext.Provider value={{ activeTab, setActiveTab }}>
      <div className="tabs">{children}</div>
    </TabsContext.Provider>
  );
}

// 서브 컴포넌트
function TabList({ children }: { children: React.ReactNode }) {
  return <div role="tablist" className="tab-list">{children}</div>;
}

function Tab({ value, children }: { value: string; children: React.ReactNode }) {
  const { activeTab, setActiveTab } = useTabs();
  return (
    <button
      role="tab"
      aria-selected={activeTab === value}
      onClick={() => setActiveTab(value)}
      className={activeTab === value ? 'active' : ''}
    >
      {children}
    </button>
  );
}

function TabPanel({ value, children }: { value: string; children: React.ReactNode }) {
  const { activeTab } = useTabs();
  if (activeTab !== value) return null;
  return <div role="tabpanel">{children}</div>;
}

// 네임스페이스로 묶기
Tabs.List = TabList;
Tabs.Tab = Tab;
Tabs.Panel = TabPanel;

// 사용
<Tabs defaultTab="profile">
  <Tabs.List>
    <Tabs.Tab value="profile">프로필</Tabs.Tab>
    <Tabs.Tab value="settings">설정</Tabs.Tab>
  </Tabs.List>
  <Tabs.Panel value="profile"><ProfilePanel /></Tabs.Panel>
  <Tabs.Panel value="settings"><SettingsPanel /></Tabs.Panel>
</Tabs>
```

### 3.3 예제 — Accordion 컴포넌트

```tsx
const AccordionContext = createContext<{
  openItems: string[];
  toggle: (id: string) => void;
} | null>(null);

function Accordion({ children, multiple = false }: { children: React.ReactNode; multiple?: boolean }) {
  const [openItems, setOpenItems] = useState<string[]>([]);

  const toggle = (id: string) => {
    setOpenItems(prev =>
      prev.includes(id)
        ? prev.filter(i => i !== id)
        : multiple ? [...prev, id] : [id]
    );
  };

  return (
    <AccordionContext.Provider value={{ openItems, toggle }}>
      <div>{children}</div>
    </AccordionContext.Provider>
  );
}

function AccordionItem({ id, title, children }: { id: string; title: string; children: React.ReactNode }) {
  const ctx = useContext(AccordionContext)!;
  const isOpen = ctx.openItems.includes(id);

  return (
    <div>
      <button onClick={() => ctx.toggle(id)} aria-expanded={isOpen}>
        {title}
      </button>
      {isOpen && <div>{children}</div>}
    </div>
  );
}

Accordion.Item = AccordionItem;
```

---

## 4. Custom Hook으로 패턴 대체

### 4.1 HOC → Custom Hook

```tsx
// HOC 방식 (구식)
const ProtectedDashboard = withAuth(Dashboard);

// Custom Hook 방식 (현대적)
function useRequireAuth() {
  const { user, loading } = useAuth();
  const router = useRouter();

  useEffect(() => {
    if (!loading && !user) {
      router.push('/login');
    }
  }, [user, loading, router]);

  return { user, loading };
}

function Dashboard() {
  const { user, loading } = useRequireAuth();
  if (loading) return <Spinner />;
  return <div>안녕하세요, {user?.name}</div>;
}
```

### 4.2 Render Props → Custom Hook

```tsx
// Render Props 방식 (구식)
<MouseTracker render={({ x, y }) => <p>{x}, {y}</p>} />

// Custom Hook 방식 (현대적)
function useMousePosition() {
  const [position, setPosition] = useState({ x: 0, y: 0 });

  useEffect(() => {
    const handler = (e: MouseEvent) => setPosition({ x: e.clientX, y: e.clientY });
    window.addEventListener('mousemove', handler);
    return () => window.removeEventListener('mousemove', handler);
  }, []);

  return position;
}

function App() {
  const { x, y } = useMousePosition();
  return <p>마우스: {x}, {y}</p>;
}
```

---

## 5. Controlled vs Uncontrolled Component

### 5.1 Controlled Component

React state가 input의 값을 제어하는 방식. 값의 변경을 React가 완전히 추적한다.

```tsx
function ControlledForm() {
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    console.log({ name, email }); // 언제든 현재 값 접근 가능
  };

  return (
    <form onSubmit={handleSubmit}>
      <input value={name} onChange={e => setName(e.target.value)} />
      <input value={email} onChange={e => setEmail(e.target.value)} />
      <button type="submit">제출</button>
    </form>
  );
}
```

### 5.2 Uncontrolled Component

DOM이 값을 관리하며, `ref`를 통해 필요할 때만 값을 읽는다.

```tsx
function UncontrolledForm() {
  const nameRef = useRef<HTMLInputElement>(null);
  const emailRef = useRef<HTMLInputElement>(null);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    console.log({
      name: nameRef.current?.value,
      email: emailRef.current?.value,
    });
  };

  return (
    <form onSubmit={handleSubmit}>
      <input ref={nameRef} defaultValue="" />
      <input ref={emailRef} defaultValue="" />
      <button type="submit">제출</button>
    </form>
  );
}
```

### 5.3 비교

| 항목 | Controlled | Uncontrolled |
|------|-----------|--------------|
| 값 관리 | React state | DOM |
| 실시간 유효성 검사 | 쉬움 | 어려움 |
| 조건부 비활성화 | 쉬움 | 어려움 |
| 성능 | 리렌더링 발생 | 리렌더링 없음 |
| 파일 input | 불가 | 권장 |
| react-hook-form | Controlled/Uncontrolled 혼용 가능 | - |

---

## 6. 면접 포인트

### Q1. HOC와 Custom Hook의 차이점은?

HOC는 컴포넌트를 감싸는 함수로, 레거시 React(훅 이전)에서 로직 재사용 수단이었습니다. 래퍼 지옥, props 충돌, 타입 복잡성 문제가 있습니다.

Custom Hook은 훅을 기반으로 로직을 함수로 분리하는 방식입니다. 컴포넌트 트리를 오염시키지 않고, TypeScript 타입 추론도 자연스럽습니다. 현대 React에서는 Custom Hook을 우선 선택합니다.

### Q2. Compound Components 패턴은 언제 사용하나요?

관련된 여러 컴포넌트가 상태를 공유해야 하지만, 외부에서 유연한 구성(composition)이 필요할 때 사용합니다. 예를 들어 Tabs, Accordion, Select, Menu처럼 UI 라이브러리 컴포넌트를 만들 때 적합합니다. 사용자가 내부 구현 없이 원하는 순서로 서브 컴포넌트를 조합할 수 있다는 장점이 있습니다.

### Q3. Controlled와 Uncontrolled 중 무엇을 선택하나요?

일반적으로 **Controlled**를 권장합니다. 실시간 유효성 검사, 동적 비활성화 등 요구사항이 많기 때문입니다. 다만 성능이 중요하거나 파일 input을 다룰 때는 Uncontrolled를 사용합니다. `react-hook-form`은 내부적으로 Uncontrolled를 활용해 성능을 최적화하면서 Controlled처럼 사용할 수 있는 API를 제공합니다.

### Q4. Render Props 패턴의 단점은?

콜백 함수가 매 렌더마다 새로 생성되어 불필요한 리렌더링이 발생할 수 있습니다. 또한 중첩이 깊어지면 "콜백 지옥"과 유사한 가독성 문제가 생깁니다. React Hooks 도입 이후로는 Custom Hook이 이 역할을 대체합니다.
