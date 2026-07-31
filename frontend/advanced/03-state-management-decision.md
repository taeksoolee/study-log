# 상태관리 실전 판단 기준

## 개요

"어떤 상태관리 라이브러리를 쓸까?"는 잘못된 질문이다.  
진짜 질문은 **"이 상태를 어디에 둘까?"**다.

상태관리 라이브러리를 먼저 고르고 모든 상태를 거기에 넣는 것이 아니라,  
**상태의 성격을 먼저 파악**하고 그에 맞는 도구를 선택해야 한다.

현대 React 앱에서 상태는 단일 저장소에 모이지 않는다.  
서버 상태, 클라이언트 상태, URL 상태, 파생 상태 — 각각 최적의 위치가 다르다.

---

## 상태의 분류

### 1. 서버 상태 (Server State)

**특징:**
- 비동기적으로 가져옴
- 여러 사용자/탭 간에 공유될 수 있음
- 시간이 지나면 stale(오래된 상태)해짐
- 소유권이 클라이언트에 없음 (서버가 원본)

**도구:** TanStack Query, SWR, RTK Query

**핵심 개념:**

| 개념 | 설명 |
|------|------|
| staleTime | 데이터를 fresh로 간주하는 시간 |
| gcTime | 비활성 쿼리를 메모리에 유지하는 시간 |
| 캐시 무효화 | mutation 후 관련 쿼리를 refetch |
| Optimistic Update | 서버 응답 전에 UI를 먼저 업데이트 |
| Background Refetch | 포커스/재연결 시 자동 갱신 |

```typescript
// 서버 상태 예시: TanStack Query
const { data, isLoading, error } = useQuery({
  queryKey: ['todos', filters],
  queryFn: () => fetchTodos(filters),
  staleTime: 5 * 60 * 1000, // 5분간 fresh
});
```

**판단 기준:** 데이터의 원본이 서버에 있는가? → 서버 상태

---

### 2. 클라이언트 상태 (Client State)

서버와 무관하게 클라이언트에서만 존재하는 상태.

#### UI 상태
- 모달 열림/닫힘
- 사이드바 토글
- 탭 인덱스
- 드롭다운 활성 상태

```typescript
// 대부분 로컬로 충분
const [isOpen, setIsOpen] = useState(false);
```

#### 폼 상태
- 입력값, 유효성 검증, 제출 상태
- 도구: React Hook Form, Formik, 또는 직접 관리

```typescript
// React Hook Form
const { register, handleSubmit, formState: { errors } } = useForm();
```

#### 전역 상태
- 테마 (다크/라이트)
- 언어 설정
- 사용자 인증 정보
- 여러 컴포넌트가 공유하는 UI 설정

```typescript
// Zustand 전역 상태
const useThemeStore = create((set) => ({
  theme: 'light',
  toggleTheme: () => set((s) => ({ 
    theme: s.theme === 'light' ? 'dark' : 'light' 
  })),
}));
```

---

### 3. URL 상태

**URL에 반영되어야 하는 것:**
- 검색어, 필터, 정렬 기준
- 페이지네이션 (현재 페이지)
- 선택된 탭이나 뷰 모드

**이유:**
- 새로고침해도 상태 유지
- 공유/북마크 가능
- 브라우저 뒤로가기 동작

```typescript
// URL 상태 관리
const [searchParams, setSearchParams] = useSearchParams();
const page = Number(searchParams.get('page')) || 1;
const sort = searchParams.get('sort') || 'newest';
```

**판단 기준:** 이 상태를 다른 사람에게 링크로 공유할 수 있어야 하는가? → URL 상태

---

### 4. 파생 상태 (Derived State)

다른 상태에서 **계산 가능한** 값은 별도로 저장하지 않는다.

```typescript
// ❌ 안티패턴: 파생 가능한 상태를 별도 저장
const [todos, setTodos] = useState([]);
const [completedCount, setCompletedCount] = useState(0); // 불필요

// ✅ 파생 상태로 처리
const todos = useTodos();
const completedCount = useMemo(
  () => todos.filter(t => t.completed).length,
  [todos]
);
```

**도구:**
- `useMemo` — React 컴포넌트 내
- Zustand `selector` — 스토어에서 파생
- Jotai `derived atom` — atom 조합
- Reselect — Redux selector 메모이제이션

---

## 판단 플로우차트

```
이 데이터가 서버에서 오는가?
│
├─ Yes → TanStack Query / SWR
│         (캐시, 무효화, refetch 자동 관리)
│
└─ No → 여러 컴포넌트가 공유하는가?
         │
         ├─ No → useState / useReducer
         │       (로컬 상태로 충분)
         │
         └─ Yes → URL에 반영되어야 하는가?
                  │
                  ├─ Yes → URL 상태 (searchParams)
                  │         (공유/북마크/뒤로가기)
                  │
                  └─ No → 전역 상태 (Zustand / Jotai)
                           (최소한의 전역만)
```

### 추가 판단 질문

- 이 상태가 다른 상태에서 계산 가능한가? → **파생 상태** (별도 저장 X)
- 이 상태가 폼 입력과 관련인가? → **폼 라이브러리** (React Hook Form)
- 이 상태가 페이지 이동 후에도 유지되어야 하는가? → **영속화** 고려 (localStorage + hydration)

---

## 라이브러리 비교 (실전 관점)

### Zustand

| 항목 | 내용 |
|------|------|
| 번들 크기 | ~1KB (gzip) |
| 보일러플레이트 | 최소 |
| 학습 곡선 | 낮음 |
| DevTools | Redux DevTools 연동 가능 (제한적) |
| SSR | 지원 (hydration 필요) |

**장점:**
- 설정 코드가 거의 없음 — `create()` 하나로 끝
- React 외부에서도 `getState()` / `subscribe()`로 접근 가능
- TypeScript 추론 우수
- Immer middleware로 불변성 간편 처리

**단점:**
- 복잡한 비동기 흐름은 직접 구현 필요
- Middleware 조합이 많아지면 타입 복잡도 증가
- 대규모 앱에서 스토어 구조 설계는 개발자 몫

**적합한 경우:** 중소규모 앱, 간단한 전역 상태, 빠른 프로토타이핑

```typescript
import { create } from 'zustand';

interface AuthStore {
  user: User | null;
  login: (user: User) => void;
  logout: () => void;
}

const useAuthStore = create<AuthStore>((set) => ({
  user: null,
  login: (user) => set({ user }),
  logout: () => set({ user: null }),
}));
```

---

### Jotai

| 항목 | 내용 |
|------|------|
| 번들 크기 | ~3KB (gzip) |
| 모델 | Atomic (bottom-up) |
| 학습 곡선 | 중간 |
| Suspense | 네이티브 지원 |
| DevTools | jotai-devtools 패키지 |

**장점:**
- Atom 단위로 구독 → 불필요한 리렌더링 최소화
- 파생 상태(derived atom)가 자연스러움
- Suspense와 통합으로 비동기 처리 간결
- Provider 없이도 동작 (Provider-less mode)

**단점:**
- Atom이 수십 개 이상 늘어나면 추적 어려움
- 디버깅 시 "어떤 atom이 변경됐는지" 파악 난이도
- 팀 컨벤션 없으면 atom 파일 구조 혼란

**적합한 경우:** 복잡한 파생 상태가 많은 대시보드, 필터 조합 UI

```typescript
import { atom, useAtom } from 'jotai';

// 기본 atom
const filterAtom = atom({ status: 'all', priority: 'all' });

// 파생 atom
const filteredTodosAtom = atom((get) => {
  const filter = get(filterAtom);
  const todos = get(todosAtom);
  return todos.filter(todo => {
    if (filter.status !== 'all' && todo.status !== filter.status) return false;
    if (filter.priority !== 'all' && todo.priority !== filter.priority) return false;
    return true;
  });
});
```

---

### Redux Toolkit (RTK)

| 항목 | 내용 |
|------|------|
| 번들 크기 | ~11KB (gzip, redux + toolkit) |
| 보일러플레이트 | 중간 (vanilla Redux 대비 감소) |
| 학습 곡선 | 높음 |
| DevTools | 최강 (time-travel, action log) |
| 미들웨어 | thunk 내장, saga/observable 선택 |

**장점:**
- 10년 이상 검증된 아키텍처
- Redux DevTools — time-travel debugging, action 재생
- 대규모 팀에서 표준화된 패턴 강제
- RTK Query로 서버 상태까지 통합 가능

**단점:**
- 작은 앱에서는 과도한 구조
- slice + action + selector + thunk = 파일 수 증가
- 초기 학습 비용 높음

**적합한 경우:** 대규모 엔터프라이즈 앱, 10명 이상 팀, 복잡한 비동기 워크플로

```typescript
import { createSlice, configureStore } from '@reduxjs/toolkit';

const todosSlice = createSlice({
  name: 'todos',
  initialState: { items: [], loading: false },
  reducers: {
    addTodo: (state, action) => {
      state.items.push(action.payload); // Immer 내장
    },
    toggleTodo: (state, action) => {
      const todo = state.items.find(t => t.id === action.payload);
      if (todo) todo.completed = !todo.completed;
    },
  },
});
```

---

### Signals (Preact Signals, Angular Signals)

| 항목 | 내용 |
|------|------|
| 반응성 | 초미세 (fine-grained reactivity) |
| 리렌더링 | 컴포넌트 단위가 아닌 DOM 노드 단위 |
| React 지원 | 실험적 (@preact/signals-react) |

**장점:**
- 불필요한 리렌더링이 원천적으로 없음
- 구독 그래프가 자동 추적됨
- 간결한 API: `signal()`, `computed()`, `effect()`

**React에서의 현황 및 한계:**
- React의 렌더링 모델(top-down, immutable)과 근본적으로 충돌
- `@preact/signals-react`는 React 내부 API에 의존 → 버전 호환 불안정
- React 팀의 공식 방향은 컴파일러 기반 최적화 (React Compiler)
- 프로덕션에서 사용하기엔 아직 이른 단계

```typescript
// Preact Signals 예시 (참고용)
import { signal, computed } from '@preact/signals';

const count = signal(0);
const doubled = computed(() => count.value * 2);

// DOM을 직접 업데이트 — React 리렌더링 없음
count.value++; // doubled.value === 2
```

---

### 비교 요약표

| 기준 | Zustand | Jotai | RTK | Signals |
|------|---------|-------|-----|---------|
| 번들 크기 | ~1KB | ~3KB | ~11KB | ~2KB |
| 보일러플레이트 | 최소 | 적음 | 중간 | 최소 |
| 파생 상태 | selector | derived atom | reselect | computed |
| DevTools | 제한적 | 별도 패키지 | 최강 | 없음 |
| 학습 곡선 | 낮음 | 중간 | 높음 | 낮음 |
| React 외 사용 | ✅ | ❌ | ✅ | ✅ |
| SSR | ✅ | ✅ | ✅ | ⚠️ |

---

## 실전 코드 예제

### 패턴 1: 서버 상태 + 클라이언트 상태 분리

TanStack Query로 서버 데이터를 관리하고, Zustand로 UI 상태만 관리하는 패턴.

```typescript
// stores/uiStore.ts — 클라이언트 UI 상태
import { create } from 'zustand';

interface UIStore {
  sidebarOpen: boolean;
  selectedView: 'grid' | 'list';
  toggleSidebar: () => void;
  setView: (view: 'grid' | 'list') => void;
}

export const useUIStore = create<UIStore>((set) => ({
  sidebarOpen: true,
  selectedView: 'grid',
  toggleSidebar: () => set((s) => ({ sidebarOpen: !s.sidebarOpen })),
  setView: (view) => set({ selectedView: view }),
}));
```

```typescript
// hooks/useTodos.ts — 서버 상태
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';

export function useTodos(filters: TodoFilters) {
  return useQuery({
    queryKey: ['todos', filters],
    queryFn: () => api.getTodos(filters),
    staleTime: 30_000,
  });
}

export function useCreateTodo() {
  const queryClient = useQueryClient();
  
  return useMutation({
    mutationFn: api.createTodo,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['todos'] });
    },
  });
}
```

```typescript
// components/TodoPage.tsx — 조합
function TodoPage() {
  const { sidebarOpen, selectedView } = useUIStore();
  const { data: todos, isLoading } = useTodos(filters);
  
  // 서버 상태와 클라이언트 상태가 명확히 분리됨
  return (
    <Layout sidebar={sidebarOpen}>
      {isLoading ? <Skeleton /> : <TodoList todos={todos} view={selectedView} />}
    </Layout>
  );
}
```

---

### 패턴 2: URL 상태 동기화

검색/필터를 URL로 관리하는 커스텀 훅.

```typescript
// hooks/useUrlState.ts
import { useSearchParams } from 'react-router-dom';
import { useCallback, useMemo } from 'react';

interface TableParams {
  page: number;
  pageSize: number;
  sort: string;
  order: 'asc' | 'desc';
  search: string;
}

const DEFAULTS: TableParams = {
  page: 1,
  pageSize: 20,
  sort: 'createdAt',
  order: 'desc',
  search: '',
};

export function useTableParams(): [TableParams, (patch: Partial<TableParams>) => void] {
  const [searchParams, setSearchParams] = useSearchParams();

  const params = useMemo<TableParams>(() => ({
    page: Number(searchParams.get('page')) || DEFAULTS.page,
    pageSize: Number(searchParams.get('pageSize')) || DEFAULTS.pageSize,
    sort: searchParams.get('sort') || DEFAULTS.sort,
    order: (searchParams.get('order') as 'asc' | 'desc') || DEFAULTS.order,
    search: searchParams.get('search') || DEFAULTS.search,
  }), [searchParams]);

  const setParams = useCallback((patch: Partial<TableParams>) => {
    setSearchParams((prev) => {
      const next = new URLSearchParams(prev);
      Object.entries(patch).forEach(([key, value]) => {
        if (value === DEFAULTS[key as keyof TableParams] || value === '') {
          next.delete(key); // 기본값이면 URL에서 제거
        } else {
          next.set(key, String(value));
        }
      });
      // 필터 변경 시 페이지 리셋
      if ('search' in patch || 'sort' in patch) {
        next.delete('page');
      }
      return next;
    });
  }, [setSearchParams]);

  return [params, setParams];
}
```

```typescript
// 사용 예시
function UserListPage() {
  const [params, setParams] = useTableParams();
  const { data } = useUsers(params); // TanStack Query와 조합

  return (
    <>
      <SearchInput 
        value={params.search} 
        onChange={(search) => setParams({ search })} 
      />
      <DataTable 
        data={data?.items} 
        sort={params.sort}
        onSort={(sort) => setParams({ sort })}
      />
      <Pagination 
        page={params.page} 
        onChange={(page) => setParams({ page })} 
      />
    </>
  );
}
```

---

### 패턴 3: Zustand 슬라이스 패턴

대규모 상태를 모듈별로 분리하여 관리.

```typescript
// stores/slices/authSlice.ts
import { StateCreator } from 'zustand';

export interface AuthSlice {
  user: User | null;
  token: string | null;
  login: (credentials: Credentials) => Promise<void>;
  logout: () => void;
}

export const createAuthSlice: StateCreator<
  AuthSlice & UISlice, // 전체 스토어 타입
  [],
  [],
  AuthSlice
> = (set) => ({
  user: null,
  token: null,
  login: async (credentials) => {
    const { user, token } = await api.login(credentials);
    set({ user, token });
  },
  logout: () => set({ user: null, token: null }),
});
```

```typescript
// stores/slices/uiSlice.ts
export interface UISlice {
  theme: 'light' | 'dark';
  language: string;
  setTheme: (theme: 'light' | 'dark') => void;
  setLanguage: (lang: string) => void;
}

export const createUISlice: StateCreator<
  AuthSlice & UISlice,
  [],
  [],
  UISlice
> = (set) => ({
  theme: 'light',
  language: 'ko',
  setTheme: (theme) => set({ theme }),
  setLanguage: (language) => set({ language }),
});
```

```typescript
// stores/index.ts — 슬라이스 조합
import { create } from 'zustand';
import { devtools, persist } from 'zustand/middleware';
import { createAuthSlice, AuthSlice } from './slices/authSlice';
import { createUISlice, UISlice } from './slices/uiSlice';

type AppStore = AuthSlice & UISlice;

export const useAppStore = create<AppStore>()(
  devtools(
    persist(
      (...args) => ({
        ...createAuthSlice(...args),
        ...createUISlice(...args),
      }),
      { name: 'app-store', partialize: (state) => ({ theme: state.theme, language: state.language }) }
    )
  )
);

// 선택적 selector로 리렌더링 최소화
export const useTheme = () => useAppStore((s) => s.theme);
export const useUser = () => useAppStore((s) => s.user);
```

---

### 패턴 4: Jotai atoms + derived atoms

복잡한 필터 조합을 atom으로 관리.

```typescript
// atoms/filterAtoms.ts
import { atom } from 'jotai';

// 기본 atoms
export const searchQueryAtom = atom('');
export const categoryAtom = atom<string[]>([]);
export const priceRangeAtom = atom<[number, number]>([0, 100000]);
export const sortAtom = atom<'price' | 'rating' | 'newest'>('newest');

// 파생 atom: 활성 필터 개수
export const activeFilterCountAtom = atom((get) => {
  let count = 0;
  if (get(searchQueryAtom)) count++;
  if (get(categoryAtom).length > 0) count++;
  const [min, max] = get(priceRangeAtom);
  if (min > 0 || max < 100000) count++;
  return count;
});

// 파생 atom: API 요청 파라미터 조합
export const apiParamsAtom = atom((get) => ({
  q: get(searchQueryAtom),
  categories: get(categoryAtom),
  minPrice: get(priceRangeAtom)[0],
  maxPrice: get(priceRangeAtom)[1],
  sort: get(sortAtom),
}));

// 비동기 파생 atom: 검색 결과
export const searchResultsAtom = atom(async (get) => {
  const params = get(apiParamsAtom);
  const response = await fetch(`/api/products?${new URLSearchParams(params as any)}`);
  return response.json();
});

// 리셋 atom (write-only)
export const resetFiltersAtom = atom(null, (get, set) => {
  set(searchQueryAtom, '');
  set(categoryAtom, []);
  set(priceRangeAtom, [0, 100000]);
  set(sortAtom, 'newest');
});
```

```typescript
// components/FilterPanel.tsx
import { useAtom, useAtomValue, useSetAtom } from 'jotai';

function FilterPanel() {
  const [search, setSearch] = useAtom(searchQueryAtom);
  const [categories, setCategories] = useAtom(categoryAtom);
  const activeCount = useAtomValue(activeFilterCountAtom);
  const resetFilters = useSetAtom(resetFiltersAtom);

  return (
    <aside>
      <h3>필터 ({activeCount}개 활성)</h3>
      <input value={search} onChange={(e) => setSearch(e.target.value)} />
      <CategorySelect value={categories} onChange={setCategories} />
      <button onClick={() => resetFilters()}>초기화</button>
    </aside>
  );
}
```

---

## 흔한 안티패턴

### 1. 모든 것을 전역에 넣기 (Prop Drilling 공포증)

```typescript
// ❌ 모달의 열림 상태를 전역 스토어에 넣음
const useStore = create((set) => ({
  isDeleteModalOpen: false,
  isEditModalOpen: false,
  isConfirmModalOpen: false,
  // ... 수십 개의 모달 상태
}));

// ✅ 모달 상태는 해당 컴포넌트에서 로컬로 관리
function UserCard() {
  const [showDeleteModal, setShowDeleteModal] = useState(false);
  return (
    <>
      <button onClick={() => setShowDeleteModal(true)}>삭제</button>
      {showDeleteModal && <DeleteModal onClose={() => setShowDeleteModal(false)} />}
    </>
  );
}
```

**규칙:** 2~3 레벨의 prop drilling은 정상이다. Composition 패턴으로 해결할 수도 있다.

---

### 2. 서버 상태를 Redux에 직접 넣기

```typescript
// ❌ Redux에서 직접 fetch + 저장
const todosSlice = createSlice({
  name: 'todos',
  initialState: { items: [], loading: false, error: null },
  extraReducers: (builder) => {
    builder
      .addCase(fetchTodos.pending, (state) => { state.loading = true; })
      .addCase(fetchTodos.fulfilled, (state, action) => {
        state.loading = false;
        state.items = action.payload;
      });
    // stale 관리? background refetch? 캐시? 전부 수동 구현...
  },
});

// ✅ 서버 상태는 TanStack Query에 위임
const { data, isLoading } = useQuery({
  queryKey: ['todos'],
  queryFn: fetchTodos,
  // stale, cache, refetch, retry — 모두 자동
});
```

---

### 3. 파생 가능한 상태를 별도 저장하기

```typescript
// ❌ 동기화 버그 발생 가능
const [items, setItems] = useState([]);
const [totalPrice, setTotalPrice] = useState(0);

const addItem = (item) => {
  setItems([...items, item]);
  setTotalPrice(totalPrice + item.price); // 동기화 깨질 수 있음
};

// ✅ 파생 상태로 계산
const [items, setItems] = useState([]);
const totalPrice = useMemo(
  () => items.reduce((sum, item) => sum + item.price, 0),
  [items]
);
```

---

### 4. Context를 전역 상태관리로 남용하기

```typescript
// ❌ Context value가 바뀌면 모든 Consumer가 리렌더링
const AppContext = createContext({
  user: null,
  theme: 'light',
  notifications: [],
  sidebarOpen: true,
  // ... 모든 것을 하나의 Context에
});

// 문제: sidebarOpen만 바뀌어도 notifications를 사용하는 컴포넌트도 리렌더링

// ✅ Context는 변경 빈도가 낮은 값에만 사용
// (테마, 언어 등 앱 수명 동안 거의 안 바뀌는 것)
// 자주 바뀌는 상태는 Zustand/Jotai 사용
```

**Context의 적절한 용도:**
- DI (Dependency Injection) 컨테이너
- 테마/언어 같은 저빈도 변경 값
- 컴포넌트 트리의 특정 구간에만 필요한 설정

---

## 면접 포인트

### Q1. 서버 상태와 클라이언트 상태의 차이를 설명하시오

> **서버 상태**는 원본이 서버에 있고, 비동기적이며, 다른 사용자와 공유될 수 있고, 시간이 지나면 stale해집니다. **클라이언트 상태**는 원본이 브라우저에 있고, 동기적이며, 현재 세션에만 존재합니다. 이 둘을 구분하면 서버 상태는 TanStack Query 같은 캐싱 라이브러리로, 클라이언트 상태는 Zustand/useState로 관리하여 각각의 특성에 맞는 최적 도구를 사용할 수 있습니다.

### Q2. 언제 전역 상태관리를 도입하는가?

> 전역 상태관리는 **여러 비인접 컴포넌트가 동일한 상태를 공유**하고, **prop drilling이나 composition으로 해결하기 어려운 경우**에 도입합니다. 먼저 서버 상태를 분리하고(TanStack Query), URL 상태를 분리한 후, 남은 공유 상태가 있을 때만 도입합니다. 대부분의 앱에서 순수 전역 상태는 생각보다 적습니다.

### Q3. Context API를 상태관리로 쓸 때의 문제점은?

> Context는 **값이 변경되면 해당 Context를 구독하는 모든 컴포넌트가 리렌더링**됩니다. selector 개념이 없어서 부분 구독이 불가능합니다. 따라서 자주 변경되는 상태에 사용하면 성능 문제가 발생합니다. Context를 분리하거나 `useMemo`로 value를 감싸는 워크어라운드가 있지만, 근본적으로 빈번한 업데이트에는 부적합합니다.

### Q4. Zustand와 Redux의 차이, 선택 기준은?

> **Zustand**: 보일러플레이트 최소, 번들 1KB, 설정 없이 바로 사용. 소규모~중규모 앱에 적합.  
> **Redux**: 엄격한 단방향 흐름, 최강 DevTools, 팀 표준화 용이. 대규모 엔터프라이즈에 적합.  
> 선택 기준: 팀 규모, 디버깅 요구사항, 기존 코드베이스, 비동기 복잡도.  
> 5명 이하 팀이고 상태가 단순하면 Zustand, 10명 이상이고 복잡한 비동기 워크플로가 있으면 RTK.

### Q5. URL 상태와 React 상태를 언제 구분하는가?

> **"이 상태를 링크로 공유할 수 있어야 하는가?"**가 판단 기준입니다. 검색어, 필터, 정렬, 페이지네이션처럼 사용자가 공유/북마크/뒤로가기 할 수 있어야 하는 상태는 URL에 둡니다. 모달 열림, 로딩 상태, 입력 중인 폼 값처럼 일시적인 상태는 React 상태에 둡니다.

---

## 참고 자료

- [TanStack Query 공식 문서](https://tanstack.com/query/latest)
- [Zustand GitHub](https://github.com/pmndrs/zustand)
- [Jotai 공식 문서](https://jotai.org/)
- [Redux Toolkit 공식 문서](https://redux-toolkit.js.org/)
- [Kent C. Dodds — Application State Management with React](https://kentcdodds.com/blog/application-state-management-with-react)
- [TkDodo — Practical React Query](https://tkdodo.eu/blog/practical-react-query)
- [Mark Erikson — Blogged Answers: A (Mostly) Complete Guide to React Rendering Behavior](https://blog.isquaredsoftware.com/2020/05/blogged-answers-a-mostly-complete-guide-to-react-rendering-behavior/)
- Case Study 01: [TanStack Query 캐시 무효화 & 로그아웃 세션 정리](../../case-studies/01-tanstack-query-cache.md)
- Case Study 09: [URL을 상태의 원천으로](../../case-studies/09-url-as-state.md)
