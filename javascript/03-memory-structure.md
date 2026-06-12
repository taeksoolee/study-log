# 03. 메모리 구조

## 목차
1. [메모리 영역](#1-메모리-영역)
2. [Stack vs Heap](#2-stack-vs-heap)
3. [가비지 컬렉션](#3-가비지-컬렉션)
4. [메모리 누수](#4-메모리-누수)
5. [면접 포인트](#면접-포인트)

---

## 1. 메모리 영역

JS 런타임은 크게 4가지 메모리 영역을 사용한다.

```
┌─────────────────────────────────┐
│           Code 영역              │ ← 실행 코드 (읽기 전용)
├─────────────────────────────────┤
│           Data 영역              │ ← 전역 변수, 정적 변수
├─────────────────────────────────┤
│           Stack 영역             │ ← 함수 호출, 원시 타입 값
│  (위에서 아래로 grows down)      │
├─────────────────────────────────┤
│                                 │
│           (빈 공간)              │
│                                 │
├─────────────────────────────────┤
│           Heap 영역              │ ← 객체, 배열, 함수 (동적 할당)
│  (아래에서 위로 grows up)        │
└─────────────────────────────────┘
```

---

## 2. Stack vs Heap

### Call Stack (스택)

- **LIFO(Last In, First Out)** 구조
- 함수 호출마다 **스택 프레임(Execution Context)** 이 쌓임
- 각 프레임에는: 지역 변수, 매개변수, 리턴 주소 저장
- 원시 타입 값이 직접 저장됨
- 크기 고정 → 너무 깊은 재귀 시 **Stack Overflow**

```js
function a() {
  const x = 1; // Stack에 저장
  b();
}

function b() {
  const y = 2; // Stack에 저장
}

a();
```

```
실행 순서:
│ b() 프레임  │ ← 3번째
│  y = 2     │
├────────────┤
│ a() 프레임  │ ← 2번째
│  x = 1     │
├────────────┤
│ 전역 프레임 │ ← 1번째
└────────────┘
```

### Heap (힙)

- **동적으로 크기가 결정**되는 데이터 저장
- 객체, 배열, 함수, 클로저가 여기에 저장됨
- Stack에는 힙의 **메모리 주소(참조)**만 저장

```js
const obj = { name: 'Alice' }; // obj의 값(주소)은 Stack, 실제 객체는 Heap
const arr = [1, 2, 3];          // 동일

// Stack         Heap
// obj → 0x001 → { name: 'Alice' }
// arr → 0x002 → [1, 2, 3]
```

### 원시 타입 vs 참조 타입 복사

```js
// 원시 타입: 값 복사 (Stack에 새 값 생성)
let a = 1;
let b = a;
b = 2;
console.log(a); // 1 (영향 없음)

// 참조 타입: 주소 복사 (같은 Heap 객체 가리킴)
const obj1 = { x: 1 };
const obj2 = obj1;
obj2.x = 99;
console.log(obj1.x); // 99 (같은 객체)

// 깊은 복사
const obj3 = { ...obj1 };           // 1단계 얕은 복사
const obj4 = JSON.parse(JSON.stringify(obj1)); // 깊은 복사 (함수/undefined 손실)
const obj5 = structuredClone(obj1); // 깊은 복사 (최신 API)
```

---

## 3. 가비지 컬렉션 (GC)

Heap에 할당된 메모리 중 **더 이상 참조되지 않는 객체**를 자동으로 해제한다.

### 도달 가능성(Reachability) 기반 알고리즘

V8 엔진은 **Mark-and-Sweep** 알고리즘을 사용한다.

```
1. Mark 단계: 루트(전역 객체, 스택의 변수)에서 시작해 모든 참조를 따라가며 표시
2. Sweep 단계: 표시되지 않은 객체 = 도달 불가능 → 메모리 해제
```

```js
let user = { name: 'Alice' }; // Heap에 { name: 'Alice' } 생성
user = null; // 참조 제거 → GC 대상이 됨
```

```js
// 서로 참조해도 외부에서 접근 불가 → GC 대상
function createCycle() {
  const obj1 = {};
  const obj2 = {};
  obj1.ref = obj2;
  obj2.ref = obj1;
  // 함수 종료 후 obj1, obj2 모두 GC됨 (외부 참조 없음)
}
```

### GC 세대별 전략 (Generational GC)

V8은 객체를 **Young Generation**과 **Old Generation**으로 나눈다.

```
Young Generation (New Space)
├── Nursery: 새로 생성된 객체
└── Intermediate: Nursery에서 살아남은 객체
    → 여기서도 살아남으면 Old Generation으로 승격

Old Generation (Old Space)
└── 오래된 객체, Major GC(Full GC) 대상
```

- **Minor GC (Scavenge)**: Young 영역만, 빠르고 자주 실행
- **Major GC (Mark-Sweep-Compact)**: 전체 Heap, 느리고 가끔 실행

---

## 4. 메모리 누수

GC가 있어도 **참조가 살아있으면 해제 안 됨** → 메모리 누수

### 대표적인 누수 패턴

**① 전역 변수**
```js
function leak() {
  leakedVar = 'leak'; // var/let/const 없음 → 전역에 붙음 → GC 안 됨
}
```

**② 타이머 / 이벤트 리스너 미해제**
```js
const bigData = new Array(1000000).fill('data');

setInterval(() => {
  console.log(bigData.length); // bigData를 계속 참조
}, 1000);
// clearInterval을 안 하면 bigData는 영원히 GC 안 됨

// 이벤트 리스너도 동일
element.addEventListener('click', handler);
// element가 제거되어도 handler가 클로저로 외부 객체 참조 중이면 누수
element.removeEventListener('click', handler); // 해제 필요
```

**③ 클로저가 큰 객체를 참조**
```js
function createLeak() {
  const bigArray = new Array(1000000);

  return function() {
    // bigArray를 사용하지 않아도 클로저 스코프에 남아있음
    return 'done';
  };
}

const leakFn = createLeak(); // bigArray 메모리 유지
```

**④ WeakMap/WeakSet 활용으로 누수 방지**
```js
// Map: key 객체가 삭제되어도 Map이 참조를 유지 → GC 안 됨
const cache = new Map();
let obj = {};
cache.set(obj, 'data');
obj = null; // obj는 사라지지 않음 (Map이 참조 중)

// WeakMap: key 객체가 GC 대상이 되면 자동으로 제거됨
const weakCache = new WeakMap();
let obj2 = {};
weakCache.set(obj2, 'data');
obj2 = null; // obj2 GC됨, weakCache에서도 자동 제거
```

### 메모리 누수 확인 방법
- Chrome DevTools → Memory 탭 → Heap Snapshot 비교
- `performance.memory.usedJSHeapSize` (Chrome 전용)

---

## 면접 포인트

**Q. JS에서 메모리 관리는 어떻게 이루어지나요?**
> 원시 타입은 Stack에, 참조 타입은 Heap에 저장. GC가 도달 불가능한 객체를 자동으로 해제. V8은 Young/Old 세대로 나눠 Scavenge(Minor)와 Mark-Sweep(Major) GC를 사용.

**Q. 메모리 누수가 발생하는 경우를 설명해보세요.**
> 전역 변수 오염, 해제하지 않은 타이머/이벤트 리스너, 불필요한 클로저 참조 유지, DOM이 제거된 후에도 JS에서 참조를 유지하는 경우.

**Q. `WeakMap`과 `Map`의 차이는?**
> `Map`은 키 객체에 대한 강한 참조를 가져 GC를 막지만, `WeakMap`은 약한 참조라 키 객체가 다른 곳에서 참조되지 않으면 GC되고 `WeakMap`에서도 자동 삭제. 캐시 구현에 유용.
