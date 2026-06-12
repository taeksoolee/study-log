# 3. 상태 관리 (State Management)

## 목차
1. Context API 특징과 한계
2. Redux 핵심 원리
3. Redux Toolkit 코드 예제
4. Zustand
5. Jotai
6. 상태 관리 라이브러리 비교
7. 라이브러리 선택 가이드
8. 면접 포인트

---

## 1. Context API 특징과 한계

### 1.1 Context API 개요

React 내장 기능으로, prop drilling 없이 컴포넌트 트리에 데이터를 전달할 수 있다.

```tsx
// ThemeContext.tsx
import { createContext, useContext, useState } from 'react';

interface ThemeContextType {
  theme: 'light' | 'dark';
  toggleTheme: () => void;
}

const ThemeContext = createContext<ThemeContextType | null>(null);

export function ThemeProvider({ children }: { children: React.ReactNode }) {
  const [theme, setTheme] = useState<'light' | 'dark'>('light');

  const toggleTheme = () => {
    setTheme(prev => (prev === 'light' ? 'dark' : 'light'));
  };

  return (
    <ThemeContext.Provider value={{ theme, toggleTheme }}>
      {children}
    </ThemeContext.Provider>
  );
}

export function useTheme() {
  const ctx = useContext(ThemeContext);
  if (!ctx) throw new Error('ThemeProvider 내부에서 사용해야 합니다.');
  return ctx;
}
```

### 1.2 Context API의 한계: 리렌더링 문제

Context 값이 변경되면 해당 Context를 구독하는 **모든** 컴포넌트가 리렌더링된다.
부분 구독(특정 슬라이스만 구독)이 불가능하다.

```tsx
// 문제 상황: UserContext에 name과 settings가 함께 있을 때
const UserContext = createContext({ name: '', settings: {} });

// name만 필요한 컴포넌트도 settings가 바뀌면 리렌더링됨
function UserName() {
  const { name } = useContext(UserContext); // settings 변경 시에도 리렌더링!
  return <span>{name}</span>;
}
```

### 1.3 리렌더링 문제 완화 방법

Context를 역할별로 분리하여 영향 범위를 줄인다.

```tsx
// 개선: Context 분리
const UserNameContext = createContext('');
const UserSettingsContext = createContext({});

function UserName() {
  const name = useContext(UserNameContext); // settings 변경 시 리렌더링 없음
  return <span>{name}</span>;
}
```

### 1.4 Context API가 적합한 경우

- 변경 빈도가 낮은 전역 상태 (테마, 언어, 인증 정보)
- 컴포넌트 수가 많지 않은 소규모 앱
- 외부 라이브러리 의존을 최소화해야 하는 경우

---

## 2. Redux 핵심 원리

### 2.1 세 가지 원칙

1. **단일 진실의 원천 (Single Source of Truth)**: 전체 앱 상태를 하나의 스토어에 저장
2. **읽기 전용 상태 (State is Read-Only)**: 상태 변경은 반드시 액션 객체를 통해서만
3. **순수 함수 리듀서 (Changes via Pure Functions)**: 리듀서는 부작용 없는 순수 함수

### 2.2 단방향 데이터 흐름

```
View → dispatch(Action) → Reducer → Store → View
```

```
Action:  { type: 'counter/increment', payload: 1 }
Reducer: (prevState, action) => newState  // 순수 함수, 이전 상태 변경 금지
Store:   { counter: 1 }
```

### 2.3 순수 함수 리듀서 규칙

```tsx
// 올바른 리듀서: 새 객체 반환
function counterReducer(state = 0, action) {
  switch (action.type) {
    case 'increment':
      return state + 1; // 기존 상태를 변경하지 않고 새 값 반환
    default:
      return state;
  }
}

// 잘못된 리듀서: 직접 변경 (금지)
function badReducer(state = [], action) {
  if (action.type === 'addItem') {
    state.push(action.payload); // 직접 변이 - 금지!
    return state;
  }
  return state;
}
```

---

## 3. Redux Toolkit 코드 예제

### 3.1 createSlice

Redux Toolkit은 보일러플레이트를 대폭 줄여준다. Immer 라이브러리가 내장되어 있어 불변성을 자동으로 처리한다.

```tsx
// features/counter/counterSlice.ts
import { createSlice, PayloadAction } from '@reduxjs/toolkit';

interface CounterState {
  value: number;
  status: 'idle' | 'loading';
}

const initialState: CounterState = {
  value: 0,
  status: 'idle',
};

const counterSlice = createSlice({
  name: 'counter',
  initialState,
  reducers: {
    increment(state) {
      state.value += 1; // Immer 덕분에 직접 변이처럼 작성 가능
    },
    decrement(state) {
      state.value -= 1;
    },
    incrementByAmount(state, action: PayloadAction<number>) {
      state.value += action.payload;
    },
  },
});

export const { increment, decrement, incrementByAmount } = counterSlice.actions;
export default counterSlice.reducer;
```

### 3.2 configureStore

```tsx
// app/store.ts
import { configureStore } from '@reduxjs/toolkit';
import counterReducer from '../features/counter/counterSlice';
import userReducer from '../features/user/userSlice';

export const store = configureStore({
  reducer: {
    counter: counterReducer,
    user: userReducer,
  },
  // Redux DevTools Extension 자동 연결
  // 미들웨어: redux-thunk 기본 포함
});

// 타입 추출
export type RootState = ReturnType<typeof store.getState>;
export type AppDispatch = typeof store.dispatch;
```

### 3.3 컴포넌트에서 사용

```tsx
// features/counter/Counter.tsx
import { useSelector, useDispatch } from 'react-redux';
import { RootState, AppDispatch } from '../../app/store';
import { increment, decrement, incrementByAmount } from './counterSlice';

// 타입 안전 훅
const useAppSelector = useSelector.withTypes<RootState>();
const useAppDispatch = useDispatch.withTypes<AppDispatch>();

export function Counter() {
  const count = useAppSelector(state => state.counter.value);
  const dispatch = useAppDispatch();

  return (
    <div>
      <button onClick={() => dispatch(decrement())}>-</button>
      <span>{count}</span>
      <button onClick={() => dispatch(increment())}>+</button>
      <button onClick={() => dispatch(incrementByAmount(5))}>+5</button>
    </div>
  );
}
```

### 3.4 createAsyncThunk (비동기 처리)

```tsx
// features/user/userSlice.ts
import { createSlice, createAsyncThunk } from '@reduxjs/toolkit';

export const fetchUser = createAsyncThunk(
  'user/fetchById',
  async (userId: string) => {
    const response = await fetch(`/api/users/${userId}`);
    return response.json();
  }
);

const userSlice = createSlice({
  name: 'user',
  initialState: { data: null, loading: false, error: null as string | null },
  reducers: {},
  extraReducers: builder => {
    builder
      .addCase(fetchUser.pending, state => {
        state.loading = true;
        state.error = null;
      })
      .addCase(fetchUser.fulfilled, (state, action) => {
        state.loading = false;
        state.data = action.payload;
      })
      .addCase(fetchUser.rejected, (state, action) => {
        state.loading = false;
        state.error = action.error.message ?? '오류 발생';
      });
  },
});

export default userSlice.reducer;
```

---

## 4. Zustand

### 4.1 Zustand 개념

- 보일러플레이트 없는 간결한 API
- React 외부에서도 사용 가능 (스토어가 React에 종속되지 않음)
- 부분 구독(selector)으로 불필요한 리렌더링 방지
- Context Provider 불필요

```bash
npm install zustand
```

### 4.2 기본 사용법

```tsx
// store/useCounterStore.ts
import { create } from 'zustand';

interface CounterState {
  count: number;
  increment: () => void;
  decrement: () => void;
  reset: () => void;
}

const useCounterStore = create<CounterState>(set => ({
  count: 0,
  increment: () => set(state => ({ count: state.count + 1 })),
  decrement: () => set(state => ({ count: state.count - 1 })),
  reset: () => set({ count: 0 }),
}));

export default useCounterStore;
```

```tsx
// Counter.tsx
import useCounterStore from '../store/useCounterStore';

function Counter() {
  // 부분 구독: count만 변경될 때만 리렌더링
  const count = useCounterStore(state => state.count);
  const increment = useCounterStore(state => state.increment);

  return (
    <div>
      <span>{count}</span>
      <button onClick={increment}>+</button>
    </div>
  );
}
```

### 4.3 미들웨어 (devtools, persist)

```tsx
import { create } from 'zustand';
import { devtools, persist } from 'zustand/middleware';

const useStore = create<CounterState>()(
  devtools(
    persist(
      set => ({
        count: 0,
        increment: () => set(state => ({ count: state.count + 1 })),
      }),
      { name: 'counter-storage' } // localStorage 키
    )
  )
);
```

---

## 5. Jotai

### 5.1 Jotai 개념

- 원자(Atom) 단위로 상태를 관리
- Recoil에서 영감을 받은 bottom-up 방식
- 파생 상태(derived atom)를 선언적으로 정의
- 컴포넌트가 사용하는 atom만 구독 → 세밀한 리렌더링 제어

```bash
npm install jotai
```

### 5.2 기본 사용법

```tsx
// atoms/counterAtom.ts
import { atom } from 'jotai';

export const countAtom = atom(0);

// 파생 atom (읽기 전용)
export const doubleCountAtom = atom(get => get(countAtom) * 2);

// 읽기/쓰기 파생 atom
export const countWithLogAtom = atom(
  get => get(countAtom),
  (get, set, newValue: number) => {
    console.log('count 변경:', newValue);
    set(countAtom, newValue);
  }
);
```

```tsx
// Counter.tsx
import { useAtom, useAtomValue, useSetAtom } from 'jotai';
import { countAtom, doubleCountAtom } from '../atoms/counterAtom';

function Counter() {
  const [count, setCount] = useAtom(countAtom);
  const double = useAtomValue(doubleCountAtom); // 읽기만 할 때

  return (
    <div>
      <p>count: {count}</p>
      <p>double: {double}</p>
      <button onClick={() => setCount(c => c + 1)}>+</button>
    </div>
  );
}

// setCount만 필요할 때: useSetAtom으로 리렌더링 방지
function IncrementButton() {
  const setCount = useSetAtom(countAtom); // count 변경 시 리렌더링 없음
  return <button onClick={() => setCount(c => c + 1)}>+</button>;
}
```

### 5.3 atomWithStorage (영속성)

```tsx
import { atomWithStorage } from 'jotai/utils';

export const themeAtom = atomWithStorage<'light' | 'dark'>('theme', 'light');
```

---

## 6. 상태 관리 라이브러리 비교

| 항목 | Context API | Redux Toolkit | Zustand | Jotai |
|------|------------|---------------|---------|-------|
| 번들 크기 | 0 (내장) | ~11kb | ~1kb | ~3kb |
| 보일러플레이트 | 낮음 | 중간 | 매우 낮음 | 낮음 |
| 리렌더링 제어 | 어려움 | 가능 (selector) | 쉬움 (selector) | 매우 세밀함 (atom) |
| 비동기 처리 | 수동 | createAsyncThunk | 직접 작성 | jotai-tanstack-query |
| DevTools | 없음 | Redux DevTools | Zustand DevTools | Jotai DevTools |
| 학습 곡선 | 낮음 | 중간 | 매우 낮음 | 낮음 |
| 서버 상태 | 별도 구현 필요 | 별도 구현 필요 | 별도 구현 필요 | 별도 구현 필요 |
| 사용 패턴 | top-down | top-down | 혼합 | bottom-up |

---

## 7. 라이브러리 선택 가이드

### Context API를 선택할 때

- 테마, 언어, 인증 정보처럼 변경이 드문 전역 상태
- 외부 라이브러리 의존을 최소화해야 하는 경우
- 소규모 팀 / 단순한 앱

### Redux Toolkit을 선택할 때

- 대규모 팀, 엄격한 상태 흐름 추적이 필요한 경우
- 복잡한 비동기 흐름 (여러 액션 연계)
- 디버깅, 시간 여행 디버깅이 중요한 경우
- 이미 Redux를 사용 중인 레거시 프로젝트

### Zustand를 선택할 때

- 빠른 개발이 필요하고 Redux가 과하다고 느껴질 때
- 전역 상태가 필요하지만 설정이 간단해야 할 때
- React 외부(유틸리티 함수 등)에서도 상태 접근이 필요할 때

### Jotai를 선택할 때

- 상태 간 의존 관계가 복잡한 경우 (파생 상태가 많을 때)
- 컴포넌트별로 세밀한 리렌더링 최적화가 필요할 때
- Recoil 대안을 찾는 경우

### 참고: 서버 상태는 별도로

전역 상태 관리 라이브러리와 서버 상태 관리 라이브러리를 분리하는 것이 현재 트렌드다.

```
서버 상태 (캐싱, 동기화): TanStack Query, SWR
클라이언트 전역 상태: Zustand, Jotai, Redux Toolkit
```

---

## 8. 면접 포인트

### Q1. Context API의 리렌더링 문제를 설명하고 해결 방법을 말해보세요.

Context 값이 변경되면 해당 Context를 `useContext`로 구독하는 모든 컴포넌트가 리렌더링됩니다. 해결 방법으로는 (1) Context를 역할별로 분리하거나, (2) `React.memo`와 함께 사용하거나, (3) 변경 빈도가 높은 상태는 Zustand 같은 외부 라이브러리를 사용하는 방법이 있습니다.

### Q2. Redux의 리듀서가 순수 함수여야 하는 이유는?

리듀서가 순수 함수여야 하는 이유는 다음과 같습니다.
- **예측 가능성**: 같은 입력에 항상 같은 출력을 보장해 상태 변화를 추적하기 쉽습니다.
- **시간 여행 디버깅**: 순수 함수이기 때문에 이전 상태를 재현할 수 있습니다.
- **테스트 용이성**: 부작용이 없으므로 단위 테스트 작성이 간단합니다.

### Q3. Redux Toolkit에서 Immer를 사용하는 이유는?

Redux는 불변성을 지켜야 하므로 원래는 스프레드 연산자 등으로 새 객체를 반환해야 합니다. Immer는 내부적으로 Proxy를 사용해 변이처럼 보이는 코드를 작성해도 실제로는 새 불변 객체를 생성해줍니다. 코드 가독성과 생산성을 높여줍니다.

### Q4. Zustand와 Redux의 차이점은?

| | Zustand | Redux |
|---|---|---|
| 설정 | Provider 불필요, 스토어 바로 사용 | Provider + configureStore 필요 |
| 보일러플레이트 | 매우 적음 | 비교적 많음 (RTK로 줄었지만) |
| 적합한 규모 | 소~중규모 | 중~대규모 |
| 디버깅 | Zustand DevTools | Redux DevTools (강력) |

### Q5. 상태 관리 라이브러리를 선택할 때 어떤 기준으로 판단하나요?

(1) **상태의 복잡도**: 단순하면 Context/Zustand, 복잡한 비동기 흐름이 많으면 Redux Toolkit
(2) **팀 규모와 컨벤션**: 대규모 팀은 엄격한 패턴의 Redux가 유리
(3) **성능 요구사항**: 세밀한 리렌더링 제어가 필요하면 Jotai
(4) **서버 상태 분리**: TanStack Query로 서버 상태를 분리하면 클라이언트 상태 관리 라이브러리의 부담이 줄어들어 Zustand만으로도 충분한 경우가 많음
