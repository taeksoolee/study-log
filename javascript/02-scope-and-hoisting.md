# 02. 스코프 & 호이스팅

## 목차
1. [스코프란](#1-스코프란)
2. [렉시컬 스코프](#2-렉시컬-스코프)
3. [스코프 체인](#3-스코프-체인)
4. [호이스팅](#4-호이스팅)
5. [면접 포인트](#면접-포인트)

---

## 1. 스코프란

**스코프(Scope)** = 변수가 유효한 범위

```js
const global = '전역';

function outer() {
  const outerVar = '외부';

  function inner() {
    const innerVar = '내부';
    console.log(global);   // '전역' ✅
    console.log(outerVar); // '외부' ✅
    console.log(innerVar); // '내부' ✅
  }

  console.log(innerVar); // ReferenceError ❌ (inner 스코프 접근 불가)
}
```

### 스코프 종류

| 종류 | 범위 | 예시 |
|------|------|------|
| 전역 스코프 | 어디서든 접근 가능 | 파일 최상단의 변수 |
| 함수 스코프 | 함수 내부 | `var`, 함수 매개변수 |
| 블록 스코프 | `{}` 내부 | `let`, `const` |
| 모듈 스코프 | 파일 단위 | ESM의 최상단 변수 |

---

## 2. 렉시컬 스코프

> **함수가 어디서 호출되었느냐**가 아니라, **어디서 정의되었느냐**로 스코프가 결정된다.

```js
const x = 'global';

function foo() {
  console.log(x); // 어디서 호출되든 'global'
}

function bar() {
  const x = 'bar';
  foo(); // foo는 여기서 호출되지만...
}

bar(); // 'global' 출력 - foo는 전역에서 정의되었으므로
```

이것이 **렉시컬(정적) 스코프**. 반대인 동적 스코프는 호출 위치를 기준으로 하는데, JS는 렉시컬 스코프다.

---

## 3. 스코프 체인

함수가 중첩될 때, 내부 함수에서 변수를 찾는 방식:
**현재 스코프 → 상위 스코프 → ... → 전역 스코프**

```
전역 스코프 { x: 1 }
    ↑
outer 스코프 { y: 2 }
    ↑
inner 스코프 { z: 3 }
```

```js
const x = 1;

function outer() {
  const y = 2;

  function inner() {
    const z = 3;
    console.log(x + y + z); // 6 - 체인을 따라 x, y를 찾음
  }

  inner();
}
```

> 클로저(06장)는 이 스코프 체인이 함수 실행 후에도 유지되는 현상이다.

---

## 4. 호이스팅

JS 엔진은 코드를 실행하기 전 **컴파일 단계**에서 변수와 함수 선언을 스코프 맨 위로 끌어올린다.

### 변수 호이스팅

```js
// 실제 작성 코드
console.log(a); // undefined
var a = 1;

// JS 엔진이 처리하는 방식 (개념적)
var a;          // 선언만 위로 끌어올림
console.log(a); // undefined
a = 1;          // 할당은 제자리
```

```js
// let/const는 호이스팅되지만 TDZ에 걸림
console.log(b); // ReferenceError: Cannot access 'b' before initialization
let b = 1;
```

### 함수 호이스팅

**함수 선언식**은 통째로 호이스팅된다.

```js
greet(); // 'hello' ✅ - 선언 전에 호출 가능

function greet() {
  console.log('hello');
}
```

**함수 표현식**은 변수 호이스팅 규칙을 따른다.

```js
greet(); // TypeError: greet is not a function
// (var greet는 undefined로 호이스팅됨)

var greet = function() {
  console.log('hello');
};
```

```js
greet(); // ReferenceError (let은 TDZ)

const greet = () => {
  console.log('hello');
};
```

### 호이스팅 우선순위

같은 이름이 있을 때: **함수 선언 > 변수 선언**

```js
console.log(typeof foo); // 'function'

var foo = 1;
function foo() {}

// 호이스팅 후:
// function foo() {} ← 함수 선언이 우선
// var foo; ← 무시됨 (이미 foo가 있음)
// console.log(typeof foo); → 'function'
// foo = 1; ← 할당은 여기서
```

### `var`의 루프 클로저 문제

```js
// 문제: var는 함수 스코프라 루프마다 새 변수가 만들어지지 않음
for (var i = 0; i < 3; i++) {
  setTimeout(() => console.log(i), 100); // 3, 3, 3
}

// 해결 1: let 사용 (블록 스코프 - 매 반복마다 새 i)
for (let i = 0; i < 3; i++) {
  setTimeout(() => console.log(i), 100); // 0, 1, 2
}

// 해결 2: IIFE로 스코프 생성
for (var i = 0; i < 3; i++) {
  ((j) => setTimeout(() => console.log(j), 100))(i); // 0, 1, 2
}
```

---

## 면접 포인트

**Q. 렉시컬 스코프란?**
> 함수가 호출되는 위치가 아닌 정의된 위치를 기준으로 스코프가 결정되는 방식. JS는 렉시컬 스코프를 사용하며, 이 때문에 클로저가 가능하다.

**Q. 호이스팅이란? `let`도 호이스팅이 되나?**
> JS 엔진이 실행 전 선언을 스코프 최상단으로 끌어올리는 현상. `let`/`const`도 호이스팅은 되지만 TDZ(Temporal Dead Zone) 때문에 선언 전 접근 시 ReferenceError가 발생한다.

**Q. 함수 선언식과 함수 표현식의 호이스팅 차이는?**
> 함수 선언식은 함수 전체가 호이스팅되어 선언 전 호출 가능. 함수 표현식은 변수 호이스팅 규칙을 따라 `var`면 undefined, `let`/`const`면 TDZ 에러.
