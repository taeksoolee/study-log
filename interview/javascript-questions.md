# 1. JavaScript 핵심 면접 질문 30개

## 목차
1. [클로저(Closure)란 무엇인가요?](#1-클로저closure란-무엇인가요)
2. [프로토타입(Prototype)이란 무엇인가요?](#2-프로토타입prototype이란-무엇인가요)
3. [this 키워드는 어떻게 결정되나요?](#3-this-키워드는-어떻게-결정되나요)
4. [호이스팅(Hoisting)이란 무엇인가요?](#4-호이스팅hoisting이란-무엇인가요)
5. [var, let, const 차이는 무엇인가요?](#5-var-let-const-차이는-무엇인가요)
6. [이벤트 루프(Event Loop)를 설명해주세요](#6-이벤트-루프event-loop를-설명해주세요)
7. [Promise와 async/await의 차이는?](#7-promise와-asyncawait의-차이는)
8. [이벤트 버블링과 캡처링을 설명해주세요](#8-이벤트-버블링과-캡처링을-설명해주세요)
9. [깊은 복사와 얕은 복사의 차이는?](#9-깊은-복사와-얕은-복사의-차이는)
10. [동기와 비동기 차이는?](#10-동기synchronous와-비동기asynchronous-차이는)
11. [==와 ===의 차이는?](#11-와-의-차이는)
12. [null vs undefined vs NaN 차이는?](#12-null-vs-undefined-vs-nan-차이는)
13. [화살표 함수와 일반 함수의 차이는?](#13-화살표-함수와-일반-함수의-차이는)
14. [call, apply, bind 차이는?](#14-call-apply-bind-차이는)
15. [스코프와 스코프 체인을 설명해주세요](#15-스코프scope와-스코프-체인을-설명해주세요)
16. [제너레이터(Generator)란 무엇인가요?](#16-제너레이터generator란-무엇인가요)
17. [WeakMap과 Map의 차이는?](#17-weakmap과-map의-차이는)
18. [Symbol 타입은 언제 사용하나요?](#18-symbol-타입은-언제-사용하나요)
19. [Proxy와 Reflect란 무엇인가요?](#19-proxy와-reflect란-무엇인가요)
20. [모듈 시스템 차이는?](#20-모듈-시스템-commonjs-vs-es-modules-차이는)
21. [메모리 누수가 발생하는 경우는?](#21-메모리-누수가-발생하는-경우는)
22. [가비지 컬렉션 동작 원리는?](#22-가비지-컬렉션garbage-collection-동작-원리는)
23. [이벤트 위임(Event Delegation)이란?](#23-이벤트-위임event-delegation이란)
24. [디바운싱과 쓰로틀링의 차이는?](#24-디바운싱과-쓰로틀링의-차이는)
25. [커링(Currying)이란 무엇인가요?](#25-커링currying이란-무엇인가요)
26. [불변성(Immutability)이 중요한 이유는?](#26-불변성immutability이-중요한-이유는)
27. [Proxy를 활용한 반응형 구현 방법은?](#27-proxy를-활용한-반응형-구현-방법은)
28. [옵셔널 체이닝과 널 병합 연산자는?](#28-옵셔널-체이닝과-널-병합-연산자는)
29. [구조 분해 할당의 활용은?](#29-구조-분해-할당destructuring의-활용은)
30. [Symbol.iterator와 이터러블 프로토콜은?](#30-symboliterator와-이터러블-프로토콜은)

---

## 1. 클로저(Closure)란 무엇인가요?

**답변:**
클로저는 함수가 선언될 당시의 렉시컬 환경(Lexical Environment)을 기억하는 함수입니다. 내부 함수가 외부 함수의 스코프에 접근할 수 있는 개념으로, 외부 함수의 실행이 끝난 후에도 외부 변수에 접근할 수 있습니다.

```javascript
function makeCounter() {
  let count = 0; // 외부 함수 변수
  return function () {
    // 내부 함수(클로저)
    count++;
    return count;
  };
}

const counter = makeCounter();
counter(); // 1
counter(); // 2
counter(); // 3
```

**활용 사례:**
- 데이터 은닉 및 캡슐화
- 팩토리 함수 패턴
- 콜백 함수에서 상태 유지
- 모듈 패턴 구현

**주의점:** 클로저가 참조하는 변수는 가비지 컬렉션 대상에서 제외되므로 메모리 누수에 주의해야 합니다.

---

## 2. 프로토타입(Prototype)이란 무엇인가요?

**답변:**
JavaScript는 프로토타입 기반 언어로, 모든 객체는 자신의 부모 역할을 하는 프로토타입 객체를 가집니다. 객체에서 프로퍼티를 찾을 때 없으면 프로토타입 체인을 따라 올라가며 탐색합니다.

```javascript
function Animal(name) {
  this.name = name;
}
Animal.prototype.speak = function () {
  return `${this.name}이(가) 말합니다.`;
};

const dog = new Animal("강아지");
dog.speak(); // "강아지이(가) 말합니다."

// 체인 확인
Object.getPrototypeOf(dog) === Animal.prototype; // true
```

**프로토타입 체인:** 객체 -> 생성자의 prototype -> Object.prototype -> null 순으로 탐색됩니다. 클래스 문법은 프로토타입의 문법적 설탕(Syntactic Sugar)입니다.

---

## 3. this 키워드는 어떻게 결정되나요?

**답변:**
`this`는 함수가 호출되는 방식에 따라 동적으로 결정됩니다.

| 호출 방식 | this 값 |
|-----------|---------|
| 일반 함수 호출 | 전역 객체 (strict mode에서 undefined) |
| 메서드 호출 | 메서드를 소유한 객체 |
| 생성자 호출 (new) | 새로 생성된 인스턴스 |
| call/apply/bind | 명시적으로 지정한 객체 |
| 화살표 함수 | 상위 스코프의 this |

```javascript
const obj = {
  name: "철수",
  greet() {
    console.log(this.name); // "철수" (메서드 호출)
  },
  greetArrow: () => {
    console.log(this.name); // undefined (화살표 함수)
  },
};
```

---

## 4. 호이스팅(Hoisting)이란 무엇인가요?

**답변:**
호이스팅은 변수와 함수 선언이 코드 실행 전에 해당 스코프의 맨 위로 끌어올려지는 것처럼 동작하는 JavaScript 메커니즘입니다.

```javascript
// 실제 코드
console.log(a); // undefined (에러 아님)
var a = 10;

greet(); // "안녕하세요" (함수 선언문은 완전 호이스팅)
function greet() {
  console.log("안녕하세요");
}

// let, const는 TDZ(Temporal Dead Zone)로 인해 접근 시 ReferenceError
console.log(b); // ReferenceError
let b = 20;
```

**핵심 차이:**
- `var`: 선언 + undefined 초기화가 호이스팅됨
- `let/const`: 선언은 호이스팅되지만 초기화되지 않아 TDZ 발생
- 함수 선언문: 전체가 호이스팅됨
- 함수 표현식: 변수 선언만 호이스팅됨

---

## 5. var, let, const 차이는 무엇인가요?

**답변:**

| 구분 | var | let | const |
|------|-----|-----|-------|
| 스코프 | 함수 스코프 | 블록 스코프 | 블록 스코프 |
| 재선언 | 가능 | 불가 | 불가 |
| 재할당 | 가능 | 가능 | 불가 |
| 호이스팅 | undefined로 초기화 | TDZ | TDZ |
| 전역 객체 속성 | 등록됨 | 미등록 | 미등록 |

```javascript
for (var i = 0; i < 3; i++) {
  setTimeout(() => console.log(i), 0); // 3, 3, 3
}

for (let j = 0; j < 3; j++) {
  setTimeout(() => console.log(j), 0); // 0, 1, 2
}
```

`const`는 바인딩 자체가 불변이며, 객체/배열의 내부 값은 변경 가능합니다.

---

## 6. 이벤트 루프(Event Loop)를 설명해주세요

**답변:**
JavaScript는 싱글 스레드 언어이지만, 이벤트 루프를 통해 비동기 작업을 처리합니다.

**구성 요소:**
- **Call Stack**: 현재 실행 중인 함수들의 스택
- **Web APIs**: setTimeout, fetch 등 비동기 작업 처리 공간
- **Callback Queue (Macrotask Queue)**: setTimeout, setInterval 콜백 대기
- **Microtask Queue**: Promise, queueMicrotask 콜백 대기 (우선순위 높음)

**실행 순서:**
1. Call Stack 비워짐
2. Microtask Queue 전부 처리
3. Macrotask Queue에서 하나 처리
4. 다시 Microtask Queue 처리

```javascript
console.log("1");
setTimeout(() => console.log("2"), 0);
Promise.resolve().then(() => console.log("3"));
console.log("4");
// 출력: 1 -> 4 -> 3 -> 2
```

---

## 7. Promise와 async/await의 차이는?

**답변:**
둘 다 비동기 처리를 위한 방법이지만 문법과 에러 처리 방식이 다릅니다.

```javascript
// Promise 체이닝
fetch("/api/user")
  .then((res) => res.json())
  .then((data) => processData(data))
  .catch((err) => console.error(err));

// async/await
async function loadUser() {
  try {
    const res = await fetch("/api/user");
    const data = await res.json();
    return processData(data);
  } catch (err) {
    console.error(err);
  }
}
```

**차이점:**
- async/await은 동기 코드처럼 읽혀 가독성이 높음
- Promise 체이닝은 병렬 처리 표현이 명시적 (`Promise.all`)
- async/await도 내부적으로 Promise 기반
- 에러 처리: Promise는 `.catch()`, async/await은 `try-catch`

---

## 8. 이벤트 버블링과 캡처링을 설명해주세요

**답변:**
이벤트가 발생했을 때 DOM 트리를 통해 전파되는 두 가지 방향을 의미합니다.

- **캡처링(Capturing)**: 최상위(document)에서 이벤트 발생 요소로 내려오는 단계
- **버블링(Bubbling)**: 이벤트 발생 요소에서 최상위(document)로 올라가는 단계

```javascript
// 캡처링 단계에서 처리 (true)
element.addEventListener("click", handler, true);

// 버블링 단계에서 처리 (기본값 false)
element.addEventListener("click", handler, false);

// 전파 중단
event.stopPropagation();

// 동일 요소의 다른 핸들러도 중단
event.stopImmediatePropagation();
```

전파 순서: 캡처링 -> 타겟 -> 버블링

---

## 9. 깊은 복사와 얕은 복사의 차이는?

**답변:**
- **얕은 복사(Shallow Copy)**: 객체의 1단계 프로퍼티만 복사, 중첩 객체는 참조 공유
- **깊은 복사(Deep Copy)**: 중첩된 모든 객체를 재귀적으로 복사

```javascript
const original = { a: 1, b: { c: 2 } };

// 얕은 복사
const shallow = { ...original };
shallow.b.c = 99;
console.log(original.b.c); // 99 (영향 받음)

// 깊은 복사 방법들
const deep1 = JSON.parse(JSON.stringify(original)); // 단순하나 함수/undefined 손실
const deep2 = structuredClone(original); // 최신 API, 권장
```

**얕은 복사 방법:** `Object.assign()`, 스프레드 연산자(`...`), `Array.slice()`

---

## 10. 동기(Synchronous)와 비동기(Asynchronous) 차이는?

**답변:**
- **동기**: 작업이 순서대로 실행되며 이전 작업이 완료될 때까지 대기
- **비동기**: 작업 완료를 기다리지 않고 다음 작업을 실행, 완료 시 콜백/Promise로 결과 처리

```javascript
// 동기
console.log("시작");
const result = heavyComputation(); // 완료까지 블로킹
console.log("완료");

// 비동기
console.log("시작");
fetch("/api/data").then((data) => {
  console.log("데이터 수신"); // 나중에 실행
});
console.log("이 코드가 먼저 실행됨");
```

JavaScript는 싱글 스레드이므로 I/O, 네트워크 요청 등은 비동기로 처리하여 블로킹을 방지합니다.

---

## 11. ==와 ===의 차이는?

**답변:**
- `==` (동등 연산자): 타입 변환(Type Coercion) 후 값 비교
- `===` (일치 연산자): 타입 변환 없이 타입과 값 모두 비교

```javascript
0 == false;   // true  (false -> 0으로 변환)
0 === false;  // false (타입 다름: number vs boolean)
null == undefined;  // true
null === undefined; // false
"1" == 1;   // true
"1" === 1;  // false
```

일반적으로 예측 불가능한 동작을 방지하기 위해 `===` 사용을 권장합니다.

---

## 12. null vs undefined vs NaN 차이는?

**답변:**
- **undefined**: 변수가 선언되었지만 값이 할당되지 않은 상태, 함수의 기본 반환값
- **null**: 의도적으로 값이 없음을 나타내는 명시적 할당값
- **NaN**: Not a Number, 숫자 연산의 결과가 유효한 숫자가 아님을 나타냄

```javascript
let a;
console.log(a); // undefined

let b = null;
console.log(b); // null

console.log(parseInt("abc")); // NaN
console.log(NaN === NaN); // false (NaN은 자기 자신과 같지 않음)
console.log(Number.isNaN(NaN)); // true (올바른 NaN 체크 방법)

typeof undefined; // "undefined"
typeof null;      // "object" (역사적 버그)
typeof NaN;       // "number"
```

---

## 13. 화살표 함수와 일반 함수의 차이는?

**답변:**

| 구분 | 일반 함수 | 화살표 함수 |
|------|----------|------------|
| this | 호출 방식에 따라 동적 결정 | 선언 시 상위 스코프의 this |
| arguments 객체 | 있음 | 없음 |
| 생성자 | new 사용 가능 | 사용 불가 |
| prototype | 있음 | 없음 |
| yield | 사용 가능 | 사용 불가 |

```javascript
const obj = {
  value: 10,
  regular: function () {
    setTimeout(function () {
      console.log(this.value); // undefined (this가 window/undefined)
    }, 100);
  },
  arrow: function () {
    setTimeout(() => {
      console.log(this.value); // 10 (상위 스코프 this 유지)
    }, 100);
  },
};
```

---

## 14. call, apply, bind 차이는?

**답변:**
세 메서드 모두 함수의 `this`를 명시적으로 지정하는 방법입니다.

```javascript
function greet(greeting, punctuation) {
  return `${greeting}, ${this.name}${punctuation}`;
}

const person = { name: "철수" };

// call: 인수를 개별적으로 전달, 즉시 실행
greet.call(person, "안녕", "!"); // "안녕, 철수!"

// apply: 인수를 배열로 전달, 즉시 실행
greet.apply(person, ["안녕", "!"]); // "안녕, 철수!"

// bind: 새 함수를 반환, 나중에 실행
const boundGreet = greet.bind(person, "안녕");
boundGreet("!"); // "안녕, 철수!"
```

**사용 사례:** `apply`는 배열을 인수로 넘길 때 유용 (`Math.max.apply(null, arr)`), `bind`는 이벤트 핸들러 등록 시 유용합니다.

---

## 15. 스코프(Scope)와 스코프 체인을 설명해주세요

**답변:**
스코프는 변수가 유효한 범위를 의미합니다. JavaScript는 렉시컬 스코프(정적 스코프)를 따르며, 함수가 정의된 위치에 따라 스코프가 결정됩니다.

**스코프 종류:**
- 전역 스코프(Global Scope)
- 함수 스코프(Function Scope)
- 블록 스코프(Block Scope, ES6+)

**스코프 체인:** 변수를 찾을 때 현재 스코프에서 시작해 상위 스코프로 순서대로 탐색하는 메커니즘

```javascript
const globalVar = "전역";

function outer() {
  const outerVar = "외부";

  function inner() {
    const innerVar = "내부";
    // 스코프 체인: inner -> outer -> global
    console.log(globalVar); // "전역" (체인으로 접근)
    console.log(outerVar);  // "외부"
    console.log(innerVar);  // "내부"
  }
  inner();
}
```

---

## 16. 제너레이터(Generator)란 무엇인가요?

**답변:**
제너레이터는 실행을 중간에 멈추고 재개할 수 있는 특별한 함수입니다. `function*` 문법으로 정의하며, `yield` 키워드로 값을 반환하고 실행을 일시 중지합니다.

```javascript
function* counter() {
  let i = 0;
  while (true) {
    yield i++;
  }
}

const gen = counter();
gen.next(); // { value: 0, done: false }
gen.next(); // { value: 1, done: false }
gen.next(); // { value: 2, done: false }
```

**활용 사례:**
- 무한 시퀀스 생성
- 이터러블 프로토콜 구현
- 비동기 흐름 제어 (Redux-Saga)
- 지연 평가(Lazy Evaluation)

---

## 17. WeakMap과 Map의 차이는?

**답변:**

| 구분 | Map | WeakMap |
|------|-----|---------|
| 키 타입 | 모든 값 | 객체만 가능 |
| 가비지 컬렉션 | 참조 유지 | 키 객체가 GC되면 자동 제거 |
| 이터러블 | O | X |
| size 프로퍼티 | O | X |

```javascript
let obj = { name: "철수" };

const weakMap = new WeakMap();
weakMap.set(obj, "데이터");

obj = null; // 참조 제거 시 WeakMap 항목도 GC 대상이 됨
```

**사용 사례:** DOM 노드에 메타데이터 연결, 비공개 데이터 저장, 캐시 구현 시 메모리 누수 방지

---

## 18. Symbol 타입은 언제 사용하나요?

**답변:**
Symbol은 ES6에서 추가된 유일하고 변경 불가능한 원시 타입입니다. 주로 프로퍼티 키의 충돌을 방지하기 위해 사용합니다.

```javascript
const id = Symbol("id");
const id2 = Symbol("id");
id === id2; // false (항상 고유)

const user = {
  name: "철수",
  [id]: 12345, // Symbol을 키로 사용
};

// Symbol 키는 일반 열거에서 제외
Object.keys(user); // ["name"]
Object.getOwnPropertySymbols(user); // [Symbol(id)]
```

**주요 활용:**
- 잘 알려진 심볼(Well-known Symbols): `Symbol.iterator`, `Symbol.toPrimitive`
- 라이브러리 간 프로퍼티 충돌 방지
- 열거형(Enum) 대체

---

## 19. Proxy와 Reflect란 무엇인가요?

**답변:**
- **Proxy**: 객체에 대한 기본 작업(읽기, 쓰기, 삭제 등)을 가로채고 커스텀 동작을 정의하는 객체
- **Reflect**: 객체의 기본 동작을 수행하는 메서드를 제공하는 내장 객체 (Proxy handler와 함께 사용)

```javascript
const handler = {
  get(target, prop) {
    console.log(`${prop} 속성 읽기`);
    return Reflect.get(target, prop);
  },
  set(target, prop, value) {
    if (typeof value !== "number") throw new TypeError("숫자만 허용");
    return Reflect.set(target, prop, value);
  },
};

const obj = new Proxy({}, handler);
obj.age = 25; // 정상
obj.age = "스물다섯"; // TypeError
```

**활용 사례:** Vue 3의 반응형 시스템, 유효성 검사, 로깅, 접근 제어

---

## 20. 모듈 시스템 (CommonJS vs ES Modules) 차이는?

**답변:**

| 구분 | CommonJS (CJS) | ES Modules (ESM) |
|------|---------------|-----------------|
| 환경 | Node.js | 브라우저/Node.js |
| 문법 | require/module.exports | import/export |
| 로딩 | 동기, 런타임 | 비동기, 컴파일 타임 |
| 트리 쉐이킹 | 어려움 | 가능 |
| this | module 객체 | undefined |

```javascript
// CommonJS
const fs = require("fs");
module.exports = { foo };

// ES Modules
import fs from "fs";
export const foo = () => {};
export default class Bar {}
```

ESM은 정적 분석이 가능해 번들러의 트리 쉐이킹 최적화가 유리합니다.

---

## 21. 메모리 누수가 발생하는 경우는?

**답변:**
메모리 누수는 더 이상 사용하지 않는 메모리가 해제되지 않아 계속 쌓이는 현상입니다.

**주요 원인:**
1. **전역 변수 남용**: 의도치 않은 전역 변수 생성
2. **클로저 남용**: 큰 객체를 참조하는 클로저
3. **이벤트 리스너 미제거**: 제거된 DOM에 이벤트 리스너가 남아있는 경우
4. **setInterval 미정리**: clearInterval 없이 남아있는 타이머
5. **순환 참조**: 객체가 서로 참조하는 경우

```javascript
// 메모리 누수 예시
function addListener() {
  const data = new Array(1000000).fill("*");
  document.addEventListener("click", function () {
    console.log(data.length); // data를 클로저로 계속 참조
  });
}

// 해결책: 이벤트 리스너 제거
const handler = () => console.log("클릭");
document.addEventListener("click", handler);
document.removeEventListener("click", handler); // 필요 없어지면 제거
```

---

## 22. 가비지 컬렉션(Garbage Collection) 동작 원리는?

**답변:**
가비지 컬렉션은 더 이상 참조되지 않는 메모리를 자동으로 해제하는 메커니즘입니다.

**주요 알고리즘:**

1. **참조 카운팅(Reference Counting)**: 각 객체를 참조하는 수를 추적. 0이 되면 해제. 순환 참조 문제가 있음.

2. **Mark-and-Sweep (현대 JS 엔진)**: 루트(전역 객체 등)에서 시작해 도달 가능한 객체를 마킹, 마킹되지 않은 객체를 해제.

```javascript
let a = { name: "철수" }; // 참조 1개
let b = a; // 참조 2개
a = null; // 참조 1개 (b가 아직 참조)
b = null; // 참조 0개 -> GC 대상
```

**V8 엔진:** Young Generation(짧게 사는 객체)과 Old Generation(오래 사는 객체)으로 분리해 관리하는 세대별 GC 사용

---

## 23. 이벤트 위임(Event Delegation)이란?

**답변:**
이벤트 위임은 여러 자식 요소에 개별적으로 이벤트를 붙이는 대신, 공통 부모 요소에 하나의 이벤트 리스너를 등록하여 자식 이벤트를 처리하는 패턴입니다. 이벤트 버블링 원리를 활용합니다.

```javascript
// 비효율적: 각 항목에 리스너 등록
document.querySelectorAll("li").forEach((li) => {
  li.addEventListener("click", handleClick);
});

// 효율적: 이벤트 위임
document.querySelector("ul").addEventListener("click", function (e) {
  if (e.target.tagName === "LI") {
    handleClick(e.target);
  }
});
```

**장점:**
- 메모리 절약 (리스너 수 감소)
- 동적으로 추가된 요소도 자동 처리
- 코드 관리 용이

---

## 24. 디바운싱과 쓰로틀링의 차이는?

**답변:**
둘 다 함수 호출 빈도를 제어하는 기술이지만 동작 방식이 다릅니다.

- **디바운싱(Debouncing)**: 마지막 호출로부터 일정 시간이 지난 후 함수 실행 (연속 호출 중 마지막만 처리)
- **쓰로틀링(Throttling)**: 일정 시간 간격으로 최대 한 번만 실행 (일정 주기로 처리)

```javascript
// 디바운싱 - 검색 입력에 적합
function debounce(fn, delay) {
  let timer;
  return (...args) => {
    clearTimeout(timer);
    timer = setTimeout(() => fn(...args), delay);
  };
}

// 쓰로틀링 - 스크롤, 리사이즈에 적합
function throttle(fn, interval) {
  let lastTime = 0;
  return (...args) => {
    const now = Date.now();
    if (now - lastTime >= interval) {
      lastTime = now;
      fn(...args);
    }
  };
}
```

---

## 25. 커링(Currying)이란 무엇인가요?

**답변:**
커링은 다수의 인수를 받는 함수를 단일 인수를 받는 함수들의 체인으로 변환하는 함수형 프로그래밍 기법입니다.

```javascript
// 일반 함수
const add = (a, b, c) => a + b + c;
add(1, 2, 3); // 6

// 커링된 함수
const curriedAdd = (a) => (b) => (c) => a + b + c;
curriedAdd(1)(2)(3); // 6

// 실용적인 예시: 설정 재사용
const multiply = (factor) => (number) => number * factor;
const double = multiply(2);
const triple = multiply(3);

double(5); // 10
triple(5); // 15
[1, 2, 3].map(double); // [2, 4, 6]
```

**활용:** 부분 적용(Partial Application), 함수 합성, 재사용 가능한 유틸리티 함수 생성

---

## 26. 불변성(Immutability)이 중요한 이유는?

**답변:**
불변성은 데이터가 생성된 후 변경되지 않는 성질입니다.

**중요한 이유:**
1. **예측 가능성**: 데이터 변경 추적이 쉬워짐
2. **버그 감소**: 의도치 않은 사이드 이펙트 방지
3. **React 최적화**: 참조 비교로 변경 감지 (`===`)
4. **시간 여행 디버깅**: Redux DevTools처럼 상태 이력 관리 가능

```javascript
// 가변적 방식 (문제 있음)
const state = { count: 0 };
state.count = 1; // 원본 변경

// 불변적 방식 (권장)
const newState = { ...state, count: state.count + 1 };

// 배열도 마찬가지
const arr = [1, 2, 3];
const newArr = [...arr, 4]; // 원본 유지
```

**라이브러리:** Immer.js를 사용하면 불변성을 유지하면서 직관적인 코드 작성 가능

---

## 27. Proxy를 활용한 반응형 구현 방법은?

**답변:**
Proxy의 `get`과 `set` 트랩을 이용해 데이터 변경을 감지하고 자동으로 UI를 업데이트하는 반응형 시스템을 구현할 수 있습니다. Vue 3의 반응형 시스템이 이 방식을 사용합니다.

```javascript
function reactive(obj) {
  const subscribers = new Map();

  return new Proxy(obj, {
    get(target, prop) {
      // 의존성 추적
      if (!subscribers.has(prop)) subscribers.set(prop, new Set());
      if (currentEffect) subscribers.get(prop).add(currentEffect);
      return Reflect.get(target, prop);
    },
    set(target, prop, value) {
      const result = Reflect.set(target, prop, value);
      // 구독자에게 알림
      subscribers.get(prop)?.forEach((fn) => fn());
      return result;
    },
  });
}

let currentEffect = null;

function effect(fn) {
  currentEffect = fn;
  fn(); // 즉시 실행으로 의존성 수집
  currentEffect = null;
}

const state = reactive({ count: 0 });
effect(() => console.log(`count: ${state.count}`)); // "count: 0"
state.count++; // "count: 1" 자동 출력
```

---

## 28. 옵셔널 체이닝과 널 병합 연산자는?

**답변:**
- **옵셔널 체이닝(`?.`)**: 체인 중간에 null/undefined가 있어도 에러 없이 undefined 반환
- **널 병합 연산자(`??`)**: 좌변이 null/undefined일 때만 우변을 반환 (`||`는 falsy 모두 포함)

```javascript
const user = {
  profile: {
    address: null,
  },
};

// 옵셔널 체이닝
user?.profile?.address?.city; // undefined (에러 없음)
user?.getName?.(); // undefined (메서드도 사용 가능)
user?.hobbies?.[0]; // undefined (배열 인덱스도 사용 가능)

// 널 병합 연산자
const name = user?.name ?? "익명"; // "익명"
const count = 0 ?? 10; // 0 (0은 null/undefined가 아님)
const count2 = 0 || 10; // 10 (0은 falsy)
```

---

## 29. 구조 분해 할당(Destructuring)의 활용은?

**답변:**
구조 분해 할당은 배열이나 객체의 값을 손쉽게 변수에 추출하는 ES6 문법입니다.

```javascript
// 객체 구조 분해
const { name, age, address: { city } = {} } = user;

// 기본값 설정
const { role = "user", theme = "light" } = settings;

// 이름 변경
const { firstName: first, lastName: last } = person;

// 배열 구조 분해
const [head, ...tail] = [1, 2, 3, 4];
const [, second, , fourth] = array; // 건너뛰기

// 함수 매개변수
function renderUser({ name, age, role = "user" }) {
  return `${name} (${age}세) - ${role}`;
}

// 스왑
let a = 1, b = 2;
[a, b] = [b, a];
```

---

## 30. Symbol.iterator와 이터러블 프로토콜은?

**답변:**
이터러블 프로토콜은 객체가 `for...of`, 스프레드, 구조 분해 등에서 순회 가능하도록 `Symbol.iterator` 메서드를 구현하는 규약입니다.

```javascript
// 커스텀 이터러블 구현
const range = {
  from: 1,
  to: 5,
  [Symbol.iterator]() {
    let current = this.from;
    const last = this.to;
    return {
      next() {
        if (current <= last) {
          return { value: current++, done: false };
        }
        return { value: undefined, done: true };
      },
    };
  },
};

for (const num of range) {
  console.log(num); // 1, 2, 3, 4, 5
}

[...range]; // [1, 2, 3, 4, 5]
```

**내장 이터러블:** Array, String, Map, Set, NodeList, arguments 객체, 제너레이터 객체
