# 2. React Hooks

## 목차
1. [useState](#1-usestate)
2. [useEffect](#2-useeffect)
3. [useRef](#3-useref)
4. [useMemo](#4-usememo)
5. [useCallback](#5-usecallback)
6. [useContext](#6-usecontext)
7. [useReducer](#7-usereducer)
8. [커스텀 훅](#8-커스텀-훅)
9. [면접 포인트](#9-면접-포인트)

---

## 1. useState

`useState`는 함수형 컴포넌트에서 상태를 선언하고 관리하는 기본 훅입니다.

### 기본 사용법

```jsx
import { useState } from 'react';

function Counter() {
  const [count, setCount] = useState(0); // 초기값: 0

  return (
    <div>
      <p>현재 카운트: {count}</p>
      <button onClick={() => setCount(count + 1)}>증가</button>
    </div>
  );
}
```

### 함수형 업데이트

이전 상태를 기반으로 업데이트할 때는 함수형 업데이트를 사용해야 합니다. 클로저로 인해 오래된 상태값을 참조하는 문제를 방지합니다.

```jsx
function Counter() {
  const [count, setCount] = useState(0);

  // 잘못된 방식: count가 클로저로 캡처된 오래된 값일 수 있음
  const handleClickBad = () => {
    setCount(count + 1);
    setCount(count + 1); // 두 번 호출해도 1만 증가
  };

  // 올바른 방식: 항상 최신 상태를 prev로 받아서 처리
  const handleClickGood = () => {
    setCount(prev => prev + 1);
    setCount(prev => prev + 1); // 2 증가
  };

  return <button onClick={handleClickGood}>{count}</button>;
}
```

### 초기값으로 함수 전달 (Lazy Initialization)

초기값 계산이 무거운 경우, 함수를 전달하면 최초 렌더링 시에만 실행됩니다.

```jsx
// 매 렌더링마다 expensiveCalculation() 실행됨 (비효율)
const [value, setValue] = useState(expensiveCalculation());

// 최초 렌더링 시에만 실행됨 (권장)
const [value, setValue] = useState(() => expensiveCalculation());
```

### 배치 업데이트

React 18부터 모든 환경(이벤트 핸들러, setTimeout, Promise 등)에서 자동 배치(Automatic Batching)가 적용됩니다.

```jsx
// React 18: 아래 두 setState는 배치 처리되어 렌더링 1회만 발생
setTimeout(() => {
  setCount(c => c + 1);
  setFlag(f => !f);
  // 렌더링은 1회
}, 1000);

// 배치를 원하지 않을 때: flushSync 사용
import { flushSync } from 'react-dom';

flushSync(() => setCount(c => c + 1)); // 즉시 렌더링
flushSync(() => setFlag(f => !f));     // 즉시 렌더링
```

---

## 2. useEffect

`useEffect`는 컴포넌트 외부의 시스템과 동기화하기 위한 훅입니다. 데이터 페칭, 구독, DOM 수동 조작 등에 사용합니다.

### 의존성 배열 패턴

```jsx
import { useState, useEffect } from 'react';

function UserProfile({ userId }) {
  const [user, setUser] = useState(null);

  // 1. 배열 생략: 매 렌더링 후 실행
  useEffect(() => {
    document.title = `User: ${userId}`;
  });

  // 2. 빈 배열: 마운트 시 1회만 실행
  useEffect(() => {
    console.log('컴포넌트 마운트');
    return () => console.log('컴포넌트 언마운트');
  }, []);

  // 3. 의존성 지정: 해당 값 변경 시마다 실행
  useEffect(() => {
    let cancelled = false;

    async function fetchUser() {
      const data = await getUserById(userId);
      if (!cancelled) {
        setUser(data);
      }
    }

    fetchUser();

    // 클린업: 다음 effect 실행 전 또는 언마운트 시 호출
    return () => {
      cancelled = true;
    };
  }, [userId]); // userId 변경 시마다 실행

  return <div>{user?.name}</div>;
}
```

### 클린업 함수가 필요한 경우

```jsx
function ChatRoom({ roomId }) {
  useEffect(() => {
    // 구독 설정
    const subscription = chatAPI.subscribe(roomId, handleMessage);

    // 이벤트 리스너 등록
    window.addEventListener('resize', handleResize);

    // 타이머 설정
    const timerId = setInterval(pollUpdates, 5000);

    return () => {
      // 클린업: 구독 해제, 리스너 제거, 타이머 정리
      subscription.unsubscribe();
      window.removeEventListener('resize', handleResize);
      clearInterval(timerId);
    };
  }, [roomId]);
}
```

### 무한루프 주의사항

```jsx
// 무한루프 발생: data가 매 렌더링마다 새 객체 참조 생성
function Bad() {
  const [data, setData] = useState([]);

  useEffect(() => {
    setData([...data, 'new']); // setData → 렌더링 → useEffect 반복
  }, [data]); // data가 매번 새로운 참조
}

// 해결: 함수형 업데이트로 의존성 제거
function Good() {
  const [data, setData] = useState([]);

  useEffect(() => {
    setData(prev => [...prev, 'new']); // data를 의존성에서 제거
  }, []); // 마운트 시 1회만
}

// 객체/배열을 의존성으로 쓸 때는 useMemo 또는 useRef로 안정화
```

---

## 3. useRef

`useRef`는 렌더링 간에 값을 유지하되, 값 변경 시 리렌더링을 유발하지 않는 훅입니다.

### DOM 요소 참조

```jsx
import { useRef, useEffect } from 'react';

function TextInput() {
  const inputRef = useRef(null);

  useEffect(() => {
    // 마운트 후 input에 포커스
    inputRef.current.focus();
  }, []);

  function handleSubmit() {
    console.log('입력값:', inputRef.current.value);
  }

  return (
    <div>
      <input ref={inputRef} type="text" />
      <button onClick={handleSubmit}>제출</button>
    </div>
  );
}
```

### 값 저장 용도 (리렌더링 없이 값 유지)

```jsx
function Timer() {
  const [seconds, setSeconds] = useState(0);
  const intervalRef = useRef(null); // interval ID 저장 (리렌더링 불필요)
  const renderCountRef = useRef(0); // 렌더링 횟수 추적

  renderCountRef.current += 1; // 렌더링 횟수 증가 (리렌더링 유발 안 함)

  function start() {
    intervalRef.current = setInterval(() => {
      setSeconds(s => s + 1);
    }, 1000);
  }

  function stop() {
    clearInterval(intervalRef.current);
  }

  return (
    <div>
      <p>{seconds}초 (렌더링: {renderCountRef.current}회)</p>
      <button onClick={start}>시작</button>
      <button onClick={stop}>정지</button>
    </div>
  );
}
```

### useRef vs useState 비교

| 구분 | useRef | useState |
|------|--------|----------|
| 값 변경 시 리렌더링 | 없음 | 있음 |
| 렌더링 간 값 유지 | 유지 | 유지 |
| 주요 용도 | DOM 참조, 인스턴스 변수 | UI에 표시되는 상태 |
| 접근 방법 | `.current` 프로퍼티 | 상태값 직접 참조 |

---

## 4. useMemo

`useMemo`는 연산 결과를 캐싱(메모이제이션)하여 불필요한 재계산을 방지합니다.

### 기본 사용법

```jsx
import { useMemo, useState } from 'react';

function ProductList({ products, filterText }) {
  // filterText나 products가 변경될 때만 재계산
  const filteredProducts = useMemo(() => {
    console.log('필터링 계산 실행');
    return products.filter(p =>
      p.name.toLowerCase().includes(filterText.toLowerCase())
    );
  }, [products, filterText]);

  return (
    <ul>
      {filteredProducts.map(p => <li key={p.id}>{p.name}</li>)}
    </ul>
  );
}
```

### 언제 사용해야 하는가

```jsx
// 사용 기준: 계산이 실제로 무겁거나, 참조 동일성이 필요한 경우

// 1. 무거운 계산 캐싱
const sortedData = useMemo(() => {
  return hugeDataset.sort(complexCompareFn); // O(n log n), 수천 건
}, [hugeDataset]);

// 2. 자식 컴포넌트에 전달하는 객체/배열 안정화 (React.memo와 함께)
const config = useMemo(() => ({
  theme: 'dark',
  locale: userLocale,
}), [userLocale]);

// 불필요한 경우: 단순 계산은 오히려 오버헤드
// useMemo 자체도 비용이 있으므로 성능 측정 후 도입할 것
const double = useMemo(() => count * 2, [count]); // 이런 건 그냥 계산
```

---

## 5. useCallback

`useCallback`은 함수를 메모이제이션하여 매 렌더링마다 새로운 함수 참조가 생성되는 것을 방지합니다.

### 기본 사용법

```jsx
import { useCallback, useState, memo } from 'react';

// React.memo로 감싼 자식 컴포넌트
const Button = memo(({ onClick, label }) => {
  console.log(`${label} 버튼 렌더링`);
  return <button onClick={onClick}>{label}</button>;
});

function Parent() {
  const [count, setCount] = useState(0);
  const [text, setText] = useState('');

  // useCallback 없이: text 변경 시에도 새 함수 참조 → Button 리렌더링
  // useCallback 사용: count 변경 시에만 새 함수 생성
  const handleIncrement = useCallback(() => {
    setCount(prev => prev + 1);
  }, []); // setCount는 안정적이므로 의존성 불필요

  return (
    <div>
      <input value={text} onChange={e => setText(e.target.value)} />
      <Button onClick={handleIncrement} label="증가" />
      <p>카운트: {count}</p>
    </div>
  );
}
```

### useCallback과 useEffect 조합

```jsx
function SearchResults({ query }) {
  const [results, setResults] = useState([]);

  // 함수를 useEffect 의존성으로 사용할 때 useCallback으로 안정화
  const fetchResults = useCallback(async () => {
    const data = await searchAPI(query);
    setResults(data);
  }, [query]); // query 변경 시에만 새 함수 생성

  useEffect(() => {
    fetchResults();
  }, [fetchResults]); // fetchResults가 안정적이므로 query 변경 시에만 실행

  return <ResultList items={results} />;
}
```

### useMemo vs useCallback

```javascript
// useCallback(fn, deps) 는 아래와 동일
// useMemo(() => fn, deps)

const memoizedFn = useCallback(() => doSomething(a, b), [a, b]);
const memoizedFn2 = useMemo(() => () => doSomething(a, b), [a, b]);
// 위 두 줄은 동일한 결과
```

---

## 6. useContext

`useContext`는 Props 드릴링 없이 컴포넌트 트리 전반에 데이터를 전달할 때 사용합니다.

### Context 생성과 사용

```jsx
import { createContext, useContext, useState } from 'react';

// 1. Context 생성 (기본값 설정)
const ThemeContext = createContext('light');

// 2. Provider 컴포넌트로 값 제공
function App() {
  const [theme, setTheme] = useState('light');

  return (
    <ThemeContext.Provider value={{ theme, setTheme }}>
      <Header />
      <Main />
    </ThemeContext.Provider>
  );
}

// 3. 깊이 중첩된 컴포넌트에서 값 소비
function ThemeToggle() {
  const { theme, setTheme } = useContext(ThemeContext);

  return (
    <button onClick={() => setTheme(t => t === 'light' ? 'dark' : 'light')}>
      현재 테마: {theme}
    </button>
  );
}
```

### 리렌더링 주의사항

```jsx
// 주의: Context 값이 변경되면 해당 Context를 소비하는
// 모든 컴포넌트가 리렌더링됨

// 문제: value에 매 렌더링마다 새 객체 전달
function BadProvider({ children }) {
  const [user, setUser] = useState(null);

  // 렌더링마다 새 객체 생성 → 모든 소비자 리렌더링
  return (
    <UserContext.Provider value={{ user, setUser }}>
      {children}
    </UserContext.Provider>
  );
}

// 해결 1: useMemo로 값 안정화
function GoodProvider({ children }) {
  const [user, setUser] = useState(null);

  const value = useMemo(() => ({ user, setUser }), [user]);

  return (
    <UserContext.Provider value={value}>
      {children}
    </UserContext.Provider>
  );
}

// 해결 2: 자주 변경되는 값과 안정적인 값을 Context 분리
const UserContext = createContext(null);      // 자주 변경
const UserDispatchContext = createContext(null); // 안정적 (dispatch)
```

---

## 7. useReducer

`useReducer`는 복잡한 상태 로직을 컴포넌트 외부의 순수 함수(reducer)로 분리할 때 사용합니다.

### 기본 사용법

```jsx
import { useReducer } from 'react';

// 1. 초기 상태 정의
const initialState = {
  count: 0,
  step: 1,
};

// 2. Reducer 함수 (순수 함수: 동일 입력 → 동일 출력)
function reducer(state, action) {
  switch (action.type) {
    case 'INCREMENT':
      return { ...state, count: state.count + state.step };
    case 'DECREMENT':
      return { ...state, count: state.count - state.step };
    case 'RESET':
      return initialState;
    case 'SET_STEP':
      return { ...state, step: action.payload };
    default:
      throw new Error(`알 수 없는 액션: ${action.type}`);
  }
}

// 3. 컴포넌트에서 사용
function Counter() {
  const [state, dispatch] = useReducer(reducer, initialState);

  return (
    <div>
      <p>카운트: {state.count} (스텝: {state.step})</p>
      <button onClick={() => dispatch({ type: 'INCREMENT' })}>+</button>
      <button onClick={() => dispatch({ type: 'DECREMENT' })}>-</button>
      <button onClick={() => dispatch({ type: 'RESET' })}>초기화</button>
      <input
        type="number"
        value={state.step}
        onChange={e => dispatch({ type: 'SET_STEP', payload: Number(e.target.value) })}
      />
    </div>
  );
}
```

### useReducer + useContext 패턴 (전역 상태 관리)

```jsx
import { createContext, useContext, useReducer } from 'react';

const StoreContext = createContext(null);
const DispatchContext = createContext(null);

function StoreProvider({ children }) {
  const [state, dispatch] = useReducer(appReducer, initialAppState);

  return (
    <StoreContext.Provider value={state}>
      {/* dispatch는 안정적이므로 분리하여 불필요한 리렌더링 방지 */}
      <DispatchContext.Provider value={dispatch}>
        {children}
      </DispatchContext.Provider>
    </StoreContext.Provider>
  );
}

// 커스텀 훅으로 편의 제공
function useStore() {
  return useContext(StoreContext);
}

function useDispatch() {
  return useContext(DispatchContext);
}
```

### useState vs useReducer 선택 기준

| 상황 | 권장 |
|------|------|
| 단순한 단일 값 상태 | `useState` |
| 독립적인 여러 상태 | `useState` 여러 개 |
| 서로 연관된 복잡한 상태 | `useReducer` |
| 다음 상태가 이전 상태에 의존 | `useReducer` |
| 상태 로직을 테스트하고 싶음 | `useReducer` (reducer만 단독 테스트 가능) |

---

## 8. 커스텀 훅

커스텀 훅은 `use`로 시작하는 함수로, 여러 컴포넌트에서 반복되는 상태 로직을 재사용 가능하게 추출합니다.

### 예제 1: useFetch - 데이터 페칭 훅

```jsx
import { useState, useEffect } from 'react';

function useFetch(url) {
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    if (!url) return;

    let cancelled = false;
    setLoading(true);
    setError(null);

    fetch(url)
      .then(res => {
        if (!res.ok) throw new Error(`HTTP error: ${res.status}`);
        return res.json();
      })
      .then(json => {
        if (!cancelled) {
          setData(json);
          setLoading(false);
        }
      })
      .catch(err => {
        if (!cancelled) {
          setError(err.message);
          setLoading(false);
        }
      });

    return () => { cancelled = true; };
  }, [url]);

  return { data, loading, error };
}

// 사용
function UserProfile({ userId }) {
  const { data: user, loading, error } = useFetch(`/api/users/${userId}`);

  if (loading) return <Spinner />;
  if (error) return <ErrorMessage message={error} />;
  return <div>{user.name}</div>;
}
```

### 예제 2: useLocalStorage - 로컬스토리지 동기화 훅

```jsx
import { useState, useEffect } from 'react';

function useLocalStorage(key, initialValue) {
  const [storedValue, setStoredValue] = useState(() => {
    try {
      const item = window.localStorage.getItem(key);
      return item ? JSON.parse(item) : initialValue;
    } catch {
      return initialValue;
    }
  });

  const setValue = (value) => {
    try {
      const valueToStore = value instanceof Function
        ? value(storedValue)
        : value;
      setStoredValue(valueToStore);
      window.localStorage.setItem(key, JSON.stringify(valueToStore));
    } catch (error) {
      console.error('localStorage 저장 실패:', error);
    }
  };

  return [storedValue, setValue];
}

// 사용
function Settings() {
  const [theme, setTheme] = useLocalStorage('theme', 'light');

  return (
    <button onClick={() => setTheme(t => t === 'light' ? 'dark' : 'light')}>
      현재 테마: {theme}
    </button>
  );
}
```

### 예제 3: useDebounce - 디바운스 훅

```jsx
import { useState, useEffect } from 'react';

function useDebounce(value, delay = 300) {
  const [debouncedValue, setDebouncedValue] = useState(value);

  useEffect(() => {
    const timer = setTimeout(() => {
      setDebouncedValue(value);
    }, delay);

    return () => clearTimeout(timer); // 클린업으로 이전 타이머 취소
  }, [value, delay]);

  return debouncedValue;
}

// 사용: 사용자 입력 300ms 후 검색 실행
function SearchInput() {
  const [query, setQuery] = useState('');
  const debouncedQuery = useDebounce(query, 300);

  useEffect(() => {
    if (debouncedQuery) {
      performSearch(debouncedQuery);
    }
  }, [debouncedQuery]);

  return <input value={query} onChange={e => setQuery(e.target.value)} />;
}
```

---

## 9. 면접 포인트

### Q1. useEffect의 의존성 배열을 빈 배열로 두면 항상 안전한가요?

아닙니다. 빈 배열은 "이 effect는 외부 값에 의존하지 않는다"는 의미입니다. effect 내부에서 컴포넌트의 props나 state를 사용하면서 의존성 배열에 포함시키지 않으면 오래된 클로저(stale closure) 문제가 발생합니다. `eslint-plugin-react-hooks`의 `exhaustive-deps` 규칙을 사용하여 누락된 의존성을 검사하는 것이 권장됩니다.

### Q2. useCallback과 useMemo는 항상 사용해야 하나요?

아닙니다. 메모이제이션 자체도 비용이 있습니다. 이전 의존성 값을 저장하고 비교하는 오버헤드가 존재하므로, 단순한 연산이나 자주 변경되는 의존성이 있는 경우 오히려 성능이 나빠질 수 있습니다. 성능 프로파일러로 실제 병목을 확인한 후 도입하는 것이 좋습니다. `React.memo`와 함께 참조 동일성이 중요할 때, 또는 계산이 명확히 무거울 때 사용하세요.

### Q3. useState와 useReducer 중 어떤 것을 선택해야 하나요?

상태가 단순한 원시값이거나 독립적이라면 `useState`가 간결합니다. 여러 상태가 서로 연관되어 함께 업데이트되거나, 다음 상태가 이전 상태의 여러 필드에 의존하거나, 상태 로직을 컴포넌트 외부에서 테스트하고 싶다면 `useReducer`가 적합합니다. Redux를 쓰지 않더라도 `useReducer + useContext` 조합으로 경량 전역 상태 관리를 구현할 수 있습니다.

### Q4. 커스텀 훅과 일반 함수의 차이는 무엇인가요?

커스텀 훅은 이름이 `use`로 시작하며 내부에서 다른 훅을 호출할 수 있습니다. 일반 함수는 훅을 호출할 수 없습니다. React의 훅 규칙(최상위에서만 호출, React 함수 내에서만 호출)은 커스텀 훅에도 동일하게 적용됩니다. `use` 접두사는 React에게 "이 함수는 훅 규칙을 따른다"는 신호를 줍니다.

### Q5. useRef와 useState의 차이는 무엇이며, 언제 useRef를 써야 하나요?

`useState`는 값이 변경되면 리렌더링을 트리거하지만, `useRef`는 `.current` 값을 변경해도 리렌더링이 발생하지 않습니다. UI에 표시되어야 하는 값은 `useState`, UI에는 표시되지 않지만 렌더링 간에 유지되어야 하는 값(타이머 ID, 이전 값 추적, DOM 참조 등)은 `useRef`를 사용합니다.

### Q6. useContext를 사용할 때 성능 이슈를 어떻게 방지하나요?

Context 값이 변경되면 해당 Context를 구독하는 모든 컴포넌트가 리렌더링됩니다. 이를 방지하는 방법으로는: (1) 자주 변경되는 값과 그렇지 않은 값을 별도 Context로 분리, (2) `useMemo`로 Context value 안정화, (3) 소비 컴포넌트를 `React.memo`로 감싸기, (4) 필요한 값만 소비하도록 Context를 세분화하는 방법이 있습니다.
