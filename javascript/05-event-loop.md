# 05. 이벤트 루프

## 목차
1. [JS는 싱글 스레드](#1-js는-싱글-스레드)
2. [구성 요소](#2-구성-요소)
3. [이벤트 루프 동작 방식](#3-이벤트-루프-동작-방식)
4. [Macrotask vs Microtask](#4-macrotask-vs-microtask)
5. [실행 순서 예제](#5-실행-순서-예제)
6. [면접 포인트](#면접-포인트)

---

## 1. JS는 싱글 스레드

JS 엔진은 **한 번에 하나의 코드**만 실행한다. 그런데 어떻게 네트워크 요청, 타이머, 이벤트 처리를 동시에 하는 것처럼 보이는가?

→ **이벤트 루프 + Web APIs + 큐** 덕분이다.

---

## 2. 구성 요소

```
┌──────────────────────────────────────────────────────┐
│                    JS 엔진 (V8)                        │
│  ┌──────────────┐   ┌─────────────────────────────┐  │
│  │  Call Stack  │   │         Heap                │  │
│  │  (실행 중인  │   │  (객체, 클로저 저장)          │  │
│  │   함수들)    │   │                             │  │
│  └──────────────┘   └─────────────────────────────┘  │
└──────────────────────────────────────────────────────┘
         ↑ 꺼내서 실행
┌────────────────────┐     ┌─────────────────────────┐
│   Event Loop       │     │       Web APIs           │
│  (큐를 감시하고    │     │  - setTimeout/setInterval│
│   스택이 비면      │     │  - fetch / XHR           │
│   큐에서 꺼냄)     │     │  - DOM Events            │
└────────────────────┘     │  - requestAnimationFrame │
                           └─────────────────────────┘
         ↑                          ↓ 완료 시 콜백을 큐에 넣음
┌────────────────────┐   ┌──────────────────────────┐
│   Microtask Queue  │   │      Macrotask Queue      │
│  - Promise .then   │   │  - setTimeout             │
│  - queueMicrotask  │   │  - setInterval            │
│  - MutationObserver│   │  - I/O 콜백               │
│                    │   │  - UI rendering           │
└────────────────────┘   └──────────────────────────┘
```

---

## 3. 이벤트 루프 동작 방식

```
while (true) {
  // 1. 현재 실행 중인 스크립트/태스크 완료까지 실행
  // 2. Microtask 큐가 빌 때까지 모두 실행
  //    (Microtask 실행 중 새 Microtask 추가 → 그것도 실행)
  // 3. 브라우저 렌더링 (필요 시)
  // 4. Macrotask 큐에서 태스크 하나 꺼내 실행
  // 5. 2번으로 돌아감
}
```

핵심 규칙:
> **Macrotask 하나 → Microtask 전부 비우기 → 렌더링 → Macrotask 하나 → ...**

---

## 4. Macrotask vs Microtask

| 구분 | 해당하는 것들 | 실행 시점 |
|------|-------------|----------|
| **Macrotask** | `setTimeout`, `setInterval`, `setImmediate`, I/O, UI 이벤트 | Macrotask 큐에서 하나씩 |
| **Microtask** | `Promise.then/catch/finally`, `queueMicrotask`, `MutationObserver` | Macrotask 하나 끝날 때마다 전부 |

```js
console.log('1');                          // 동기

setTimeout(() => console.log('2'), 0);     // Macrotask

Promise.resolve().then(() => console.log('3')); // Microtask

console.log('4');                          // 동기

// 출력: 1 → 4 → 3 → 2
```

**왜 3이 2보다 먼저인가?**
1. `1` 출력 (동기)
2. `setTimeout` 등록 (Web API가 처리, 0ms 후 Macrotask 큐에 추가)
3. `Promise.then` 등록 (Microtask 큐에 추가)
4. `4` 출력 (동기)
5. 콜스택 비어짐 → Microtask 큐 확인 → `3` 출력
6. Microtask 큐 비어짐 → Macrotask 큐 확인 → `2` 출력

---

## 5. 실행 순서 예제

### 예제 1: 기본

```js
console.log('start');

setTimeout(() => console.log('timeout 1'), 0);
setTimeout(() => console.log('timeout 2'), 0);

Promise.resolve()
  .then(() => console.log('promise 1'))
  .then(() => console.log('promise 2'));

console.log('end');

// start → end → promise 1 → promise 2 → timeout 1 → timeout 2
```

### 예제 2: 중첩 Promise

```js
Promise.resolve()
  .then(() => {
    console.log('A');
    Promise.resolve().then(() => console.log('B')); // 새 Microtask 추가
  })
  .then(() => console.log('C'));

// A → B → C  or  A → C → B ?
// 정답: A → B → C
// 이유: 
// 1. 첫 .then → 'A' 출력, 'B'를 microtask 큐에 추가
// 2. 두 번째 .then('C')도 큐에 있음
// 큐 상태: [B, C]
// 3. B 실행
// 4. C 실행
```

### 예제 3: async/await

```js
async function foo() {
  console.log('foo start');         // 동기
  await Promise.resolve();          // 여기서 일시 중단, Microtask에 등록
  console.log('foo after await');   // Microtask로 실행
}

console.log('before');
foo();
console.log('after');

// before → foo start → after → foo after await
```

`await` 뒤의 코드는 Promise `.then` 콜백과 동일하게 Microtask로 처리된다.

### 예제 4: 스택 오버플로우 vs 큐

```js
// 재귀: 스택 오버플로우 발생
function recursion() {
  recursion(); // 콜스택 계속 쌓임 → RangeError
}

// 큐를 이용한 재귀: 스택 비우면서 실행
function safeRecursion() {
  setTimeout(safeRecursion, 0); // 매번 Macrotask로 등록
}
```

---

## 면접 포인트

**Q. JS가 싱글 스레드인데 비동기 처리를 어떻게 하나요?**
> JS 엔진 자체는 싱글 스레드지만, 브라우저/Node.js가 제공하는 Web APIs(멀티스레드)가 타이머, 네트워크 등을 처리. 완료 시 콜백을 큐에 넣고, 이벤트 루프가 스택이 비면 큐에서 꺼내 실행한다.

**Q. `setTimeout(fn, 0)`이 즉시 실행되지 않는 이유는?**
> Web API가 0ms를 기다린 후 콜백을 Macrotask 큐에 넣지만, 이벤트 루프는 현재 실행 중인 스크립트와 Microtask 큐를 먼저 소비한 뒤에야 Macrotask를 꺼낸다.

**Q. Promise와 setTimeout 중 어느 것이 먼저 실행되나요?**
> Promise `.then`은 Microtask, `setTimeout`은 Macrotask. Microtask가 항상 먼저 실행된다. 현재 실행 단위가 끝나면 Microtask 큐를 전부 비운 후 Macrotask를 하나 처리한다.

**Q. `async/await`와 Promise의 관계는?**
> `async/await`는 Promise의 문법적 설탕(syntactic sugar). `await`는 해당 Promise가 resolve될 때까지 함수 실행을 일시 중단하고, 이후 코드를 Microtask로 등록한다.
