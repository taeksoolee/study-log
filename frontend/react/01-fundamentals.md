# 1. React 기본 개념 (Virtual DOM, Fiber)

## 목차
1. [Virtual DOM이란](#1-virtual-dom이란)
2. [Reconciliation (재조정)](#2-reconciliation-재조정)
3. [Diffing 알고리즘](#3-diffing-알고리즘)
4. [React Fiber 아키텍처](#4-react-fiber-아키텍처)
5. [JSX 변환](#5-jsx-변환)
6. [React 17 이후 새로운 JSX 변환](#6-react-17-이후-새로운-jsx-변환)
7. [컴포넌트 생명주기 (함수형 관점)](#7-컴포넌트-생명주기-함수형-관점)
8. [면접 포인트](#8-면접-포인트)

---

## 1. Virtual DOM이란

Virtual DOM은 실제 DOM(Document Object Model)을 JavaScript 객체 트리로 추상화한 개념입니다. React는 UI 상태 변경 시 실제 DOM을 직접 조작하는 대신, 메모리 상의 Virtual DOM을 먼저 갱신하고 이전 Virtual DOM과 비교하여 변경된 부분만 실제 DOM에 반영합니다.

### 실제 DOM vs Virtual DOM

| 구분 | 실제 DOM | Virtual DOM |
|------|----------|-------------|
| 위치 | 브라우저 메모리 | JavaScript 힙 메모리 |
| 조작 비용 | 높음 (레이아웃/페인트 유발) | 낮음 (순수 JS 연산) |
| 동기화 | 즉시 반영 | 배치(batch) 처리 후 반영 |
| 목적 | 실제 화면 렌더링 | 변경 최소화를 위한 중간 표현 |

```javascript
// 실제 DOM 조작 (비용이 큼)
document.getElementById('count').textContent = newCount;

// React Virtual DOM 방식
// 1. 새로운 Virtual DOM 트리 생성
// 2. 이전 트리와 비교 (Diffing)
// 3. 변경된 부분만 실제 DOM에 반영 (Reconciliation)
function Counter() {
  const [count, setCount] = React.useState(0);
  return <div id="count">{count}</div>;
}
```

### Virtual DOM 객체 구조

React 엘리먼트는 내부적으로 다음과 같은 평범한 JavaScript 객체입니다.

```javascript
// JSX: <div className="container"><span>Hello</span></div>
// 위 JSX가 변환된 React 엘리먼트 객체
{
  type: 'div',
  props: {
    className: 'container',
    children: {
      type: 'span',
      props: {
        children: 'Hello'
      },
      key: null,
      ref: null
    }
  },
  key: null,
  ref: null
}
```

---

## 2. Reconciliation (재조정)

Reconciliation은 React가 Virtual DOM 트리의 변경 사항을 파악하고 실제 DOM에 효율적으로 반영하는 전체 과정을 말합니다.

### 동작 흐름

```
상태/Props 변경
      ↓
새로운 Virtual DOM 트리 생성
      ↓
이전 Virtual DOM 트리와 비교 (Diffing)
      ↓
변경된 노드 파악 (Patch 목록 생성)
      ↓
실제 DOM 업데이트 (Commit Phase)
```

### Render Phase vs Commit Phase

```
Render Phase (순수 계산, 중단 가능)
  - 컴포넌트 함수 실행
  - 새로운 React 엘리먼트 트리 생성
  - 이전 트리와 비교하여 변경 사항 계산

Commit Phase (DOM 조작, 중단 불가)
  - 실제 DOM에 변경 사항 반영
  - useLayoutEffect 실행
  - useEffect 스케줄링
```

---

## 3. Diffing 알고리즘

React는 두 트리를 비교할 때 O(n³) 복잡도의 완전 비교 대신, 두 가지 가정을 통해 O(n) 복잡도로 최적화합니다.

- **가정 1**: 서로 다른 타입의 엘리먼트는 서로 다른 트리를 생성한다.
- **가정 2**: `key` prop을 통해 자식 엘리먼트의 안정성을 힌트로 제공할 수 있다.

### 같은 타입의 엘리먼트

같은 DOM 타입이면 노드를 유지하고 변경된 속성만 업데이트합니다.

```jsx
// 이전
<div className="before" style={{ color: 'red' }} />

// 이후
<div className="after" style={{ color: 'blue' }} />

// React 동작: div 노드는 유지, className과 style 속성만 업데이트
```

### 다른 타입의 엘리먼트

타입이 다르면 이전 트리를 완전히 제거하고 새 트리를 처음부터 구축합니다.

```jsx
// 이전
<div>
  <Counter />
</div>

// 이후: div → section 으로 변경
<section>
  <Counter />
</section>

// React 동작: 기존 div와 그 자식(Counter)을 모두 언마운트,
//            새로운 section과 Counter를 마운트
// 주의: Counter의 상태도 초기화됨
```

### key prop을 이용한 자식 목록 비교

```jsx
// key 없는 경우 - 목록 앞에 추가 시 모든 아이템 업데이트 발생
// 이전: [<li>B</li>, <li>C</li>]
// 이후: [<li>A</li>, <li>B</li>, <li>C</li>]
// React: B, C가 변경된 것으로 인식하여 전체 재렌더링

// key 있는 경우 - React가 어떤 아이템이 이동/추가/삭제됐는지 정확히 파악
const items = ['B', 'C'];
items.unshift('A'); // ['A', 'B', 'C']

// 올바른 key 사용 (고유하고 안정적인 값)
items.map(item => <li key={item.id}>{item.name}</li>)

// 잘못된 key 사용 - index를 key로 쓰면 순서 변경 시 비효율적
items.map((item, index) => <li key={index}>{item}</li>)
```

---

## 4. React Fiber 아키텍처

React 16에서 도입된 Fiber는 기존 Stack Reconciler를 대체하는 새로운 재조정 엔진입니다. 렌더링 작업을 작은 단위로 분할하여 우선순위에 따라 중단하고 재개할 수 있게 해줍니다.

### 기존 Stack Reconciler의 문제점

기존 방식은 컴포넌트 트리 전체를 재귀적으로 순회하여 동기적으로 처리했습니다. 트리가 깊을수록 메인 스레드를 오래 점유하여 사용자 입력이나 애니메이션이 끊기는 현상이 발생했습니다.

```
기존 Stack Reconciler:
App → Header → Nav → ... (깊은 재귀, 중단 불가)
메인 스레드 블로킹 → 사용자 입력 지연, 애니메이션 끊김
```

### Fiber 노드 구조

각 React 컴포넌트는 하나의 Fiber 노드로 표현됩니다.

```javascript
// Fiber 노드의 핵심 필드 (단순화)
{
  // 컴포넌트 타입 (함수, 클래스, DOM 태그 등)
  type: MyComponent,

  // 현재 상태 및 props
  stateNode: instance,
  pendingProps: { ... },
  memoizedProps: { ... },
  memoizedState: { ... },

  // 트리 연결
  return: parentFiber,    // 부모
  child: firstChildFiber, // 첫 번째 자식
  sibling: nextFiber,     // 다음 형제

  // 우선순위 및 작업 상태
  lanes: Lanes,
  flags: Flags,           // 삽입/업데이트/삭제 등
}
```

### Concurrent Mode와 작업 우선순위

Fiber를 통해 React는 작업에 우선순위를 부여하고 높은 우선순위 작업이 먼저 처리되도록 스케줄링합니다.

```javascript
import { startTransition, useTransition } from 'react';

function SearchComponent() {
  const [query, setQuery] = React.useState('');
  const [results, setResults] = React.useState([]);
  const [isPending, startTransition] = useTransition();

  function handleChange(e) {
    // 우선순위 높음: 사용자 입력 즉시 반영
    setQuery(e.target.value);

    // 우선순위 낮음: 검색 결과 업데이트는 지연 가능
    startTransition(() => {
      setResults(searchItems(e.target.value));
    });
  }

  return (
    <div>
      <input value={query} onChange={handleChange} />
      {isPending ? <Spinner /> : <ResultList items={results} />}
    </div>
  );
}
```

### 우선순위 레인 (Lanes)

```
Sync Lane          - 동기 업데이트 (가장 높음)
Input Continuous   - 연속 입력 이벤트 (마우스 이동 등)
Default            - 일반 업데이트
Transition         - startTransition으로 감싼 업데이트
Idle               - 유휴 시간에 처리 (가장 낮음)
```

---

## 5. JSX 변환

JSX는 JavaScript의 문법 확장으로, 빌드 타임에 JavaScript 함수 호출로 변환됩니다.

### React 16 이하: React.createElement

```jsx
// 작성한 JSX
function Greeting({ name }) {
  return (
    <div className="greeting">
      <h1>Hello, {name}!</h1>
      <p>Welcome to React.</p>
    </div>
  );
}

// Babel이 변환한 결과 (React 16 이하)
function Greeting({ name }) {
  return React.createElement(
    'div',
    { className: 'greeting' },
    React.createElement('h1', null, 'Hello, ', name, '!'),
    React.createElement('p', null, 'Welcome to React.')
  );
}
```

이 방식에서는 JSX를 사용하는 파일 최상단에 반드시 `import React from 'react'`가 필요했습니다. JSX가 `React.createElement` 호출로 변환되기 때문입니다.

---

## 6. React 17 이후 새로운 JSX 변환

React 17부터 새로운 JSX 변환 방식이 도입되어 `React`를 직접 임포트하지 않아도 됩니다. Babel이나 TypeScript가 자동으로 필요한 함수를 삽입합니다.

```jsx
// 작성한 JSX (import React 없음)
function Greeting({ name }) {
  return (
    <div className="greeting">
      <h1>Hello, {name}!</h1>
    </div>
  );
}

// 새로운 변환 결과 (React 17+)
import { jsx as _jsx, jsxs as _jsxs } from 'react/jsx-runtime';

function Greeting({ name }) {
  return _jsxs('div', {
    className: 'greeting',
    children: [
      _jsx('h1', { children: ['Hello, ', name, '!'] })
    ]
  });
}
```

### 변환 비교 요약

| 구분 | React 16 이하 | React 17+ |
|------|--------------|-----------|
| 임포트 | `import React from 'react'` 필수 | 자동 삽입, 불필요 |
| 변환 함수 | `React.createElement` | `jsx`, `jsxs` (react/jsx-runtime) |
| 번들 크기 | 조금 더 큼 | 소폭 개선 |

---

## 7. 컴포넌트 생명주기 (함수형 관점)

함수형 컴포넌트에서는 `useEffect` 훅으로 생명주기를 표현합니다.

```jsx
import { useState, useEffect, useRef } from 'react';

function LifecycleDemo({ userId }) {
  const [user, setUser] = useState(null);
  const prevUserIdRef = useRef(userId);

  // componentDidMount와 동일 (마운트 시 1회 실행)
  useEffect(() => {
    console.log('컴포넌트 마운트됨');

    return () => {
      // componentWillUnmount와 동일 (언마운트 시 실행)
      console.log('컴포넌트 언마운트됨');
    };
  }, []); // 빈 배열: 마운트/언마운트 시에만

  // componentDidUpdate와 동일 (특정 값 변경 시 실행)
  useEffect(() => {
    if (prevUserIdRef.current !== userId) {
      console.log('userId가 변경됨:', userId);
      prevUserIdRef.current = userId;
    }

    fetchUser(userId).then(setUser);

    return () => {
      // 이전 effect 클린업 (다음 effect 실행 전, 또는 언마운트 시)
      cancelFetch();
    };
  }, [userId]); // userId 변경 시마다 실행

  return <div>{user?.name}</div>;
}
```

### 생명주기 대응 표

| 클래스형 생명주기 | 함수형 훅 |
|----------------|-----------|
| `constructor` | `useState` 초기값 |
| `componentDidMount` | `useEffect(() => {}, [])` |
| `componentDidUpdate` | `useEffect(() => {}, [deps])` |
| `componentWillUnmount` | `useEffect(() => { return cleanup }, [])` |
| `shouldComponentUpdate` | `React.memo`, `useMemo` |
| `getDerivedStateFromProps` | 렌더링 중 `setState` 호출 패턴 |

---

## 8. 면접 포인트

### Q1. Virtual DOM이 항상 실제 DOM보다 빠른가요?

아닙니다. Virtual DOM 자체는 추가적인 추상화 레이어이므로 단순한 작업에서는 실제 DOM 직접 조작보다 느릴 수 있습니다. Virtual DOM의 장점은 **대규모 UI에서 변경 최소화를 자동으로 처리**해 준다는 점입니다. 개발자가 직접 최적화하지 않아도 합리적인 성능을 보장하는 추상화입니다.

### Q2. React Fiber가 도입된 이유는 무엇인가요?

기존 Stack Reconciler는 컴포넌트 트리를 동기적으로 재귀 순회하여 렌더링 작업 도중 중단이 불가능했습니다. 그 결과 복잡한 UI에서 메인 스레드가 블로킹되어 사용자 인터랙션이 지연되는 문제가 있었습니다. Fiber는 렌더링 작업을 작은 단위로 분할하고 우선순위에 따라 중단/재개할 수 있게 하여 Concurrent Mode를 가능하게 했습니다.

### Q3. key prop을 index로 사용하면 안 되는 이유는?

리스트의 순서가 변경될 때 index를 key로 사용하면 React가 잘못된 비교를 합니다. 예를 들어 앞에 새 아이템이 추가되면 기존 아이템의 index가 모두 바뀌어, React는 모든 아이템이 변경되었다고 판단하여 불필요한 재렌더링이 발생합니다. 또한 컴포넌트 내부 상태가 잘못된 아이템에 연결될 수 있습니다. 고유하고 안정적인 ID를 key로 사용해야 합니다.

### Q4. Reconciliation의 두 단계(Render, Commit)의 차이점은?

- **Render Phase**: 순수한 계산 단계로 컴포넌트 함수를 실행하고 변경 사항을 파악합니다. 부수 효과가 없으며 Concurrent Mode에서 중단되거나 여러 번 실행될 수 있습니다.
- **Commit Phase**: 실제 DOM 조작이 일어나는 단계로 중단 없이 동기적으로 실행됩니다. `useLayoutEffect`, `useEffect` 실행도 이 단계 이후에 이루어집니다.

### Q5. React 17의 새로운 JSX 변환이 가져온 이점은?

`import React from 'react'`를 각 파일마다 작성할 필요가 없어져 코드가 간결해집니다. 번들 크기도 소폭 줄어들며, 향후 React가 제공하는 최적화를 더 쉽게 적용할 수 있는 토대가 됩니다.
