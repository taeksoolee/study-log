# 01. 변수, 타입, 형변환

## 목차
1. [변수 선언 방식](#1-변수-선언-방식)
2. [데이터 타입](#2-데이터-타입)
3. [형변환](#3-형변환)
4. [면접 포인트](#면접-포인트)

---

## 1. 변수 선언 방식

### `var` / `let` / `const` 비교

| 구분 | `var` | `let` | `const` |
|------|-------|-------|---------|
| 스코프 | 함수 스코프 | 블록 스코프 | 블록 스코프 |
| 호이스팅 | O (undefined 초기화) | O (TDZ, 초기화 안 됨) | O (TDZ, 초기화 안 됨) |
| 재선언 | O | X | X |
| 재할당 | O | O | X |

```js
// var: 함수 스코프 - 블록을 무시함
function example() {
  if (true) {
    var x = 1;
  }
  console.log(x); // 1 (블록 밖에서도 접근 가능)
}

// let: 블록 스코프
function example2() {
  if (true) {
    let y = 1;
  }
  console.log(y); // ReferenceError: y is not defined
}
```

### TDZ (Temporal Dead Zone)
`let`/`const`는 호이스팅은 되지만, **선언 라인에 도달하기 전까지 접근하면 ReferenceError**가 발생한다.

```js
console.log(a); // ReferenceError (TDZ 구간)
let a = 1;

console.log(b); // undefined (var는 TDZ 없음, 호이스팅 후 undefined)
var b = 1;
```

> **왜 TDZ가 존재하는가?**
> 변수를 선언 전에 사용하는 것은 대부분 버그다. TDZ는 이를 에러로 잡아주는 안전장치다.

---

## 2. 데이터 타입

### 원시 타입 (Primitive)
값 자체가 저장된다. **불변(immutable)**.

| 타입 | 설명 | 예시 |
|------|------|------|
| `number` | 64bit 부동소수점 (정수/소수 구분 없음) | `42`, `3.14`, `NaN`, `Infinity` |
| `string` | UTF-16 문자열 | `'hello'`, `` `world` `` |
| `boolean` | 논리값 | `true`, `false` |
| `null` | 의도적 빈 값 | `null` |
| `undefined` | 값이 할당되지 않음 | `undefined` |
| `symbol` | 유일한 식별자 (ES6) | `Symbol('id')` |
| `bigint` | 큰 정수 (ES2020) | `9007199254740991n` |

### 참조 타입 (Reference)
값이 저장된 메모리 **주소(참조)**가 저장된다.

```js
const obj1 = { name: 'Alice' };
const obj2 = obj1; // 같은 주소를 참조

obj2.name = 'Bob';
console.log(obj1.name); // 'Bob' - 같은 객체를 가리키므로
```

```
Stack           Heap
-------         ------------------
obj1 → [주소1] → { name: 'Bob' }
obj2 → [주소1] ↗
```

### `typeof` 연산자 특이점

```js
typeof null        // 'object' ← JS 역사적 버그, null은 객체가 아님
typeof undefined   // 'undefined'
typeof function(){}// 'function' (사실 object의 하위 타입)
typeof []          // 'object' (배열도 object)
```

---

## 3. 형변환

### 명시적 형변환

```js
// → Number
Number('42')     // 42
Number('')       // 0
Number(null)     // 0
Number(undefined)// NaN
Number(true)     // 1
Number(false)    // 0
Number('abc')    // NaN

// → String
String(42)       // '42'
String(null)     // 'null'
String(undefined)// 'undefined'

// → Boolean
Boolean(0)       // false
Boolean('')      // false
Boolean(null)    // false
Boolean(undefined)// false
Boolean(NaN)     // false
// 나머지 모두 true (falsy 5개 + 0n 제외)
```

### 암묵적 형변환 (타입 강제 변환)

헷갈리는 케이스를 정확히 알아야 한다.

```js
// + 연산자: 하나라도 string이면 문자열 연결
'5' + 3       // '53'
5 + '3'       // '53'
5 + 3         // 8
true + 1      // 2
null + 1      // 1
undefined + 1 // NaN

// - * / 연산자: 숫자로 변환
'5' - 3       // 2
'5' * '3'     // 15

// 동등 연산자 (==) vs 일치 연산자 (===)
0 == false    // true  (형변환 발생)
0 === false   // false (형변환 없음)
null == undefined  // true
null === undefined // false
NaN == NaN    // false (NaN은 자기 자신과도 같지 않다)
```

### falsy 값 목록

```js
// 아래 6가지만 false로 변환됨
false, 0, -0, 0n, '', null, undefined, NaN
// 주의: '0', [], {} 는 truthy
Boolean('0') // true
Boolean([])  // true
Boolean({})  // true
```

---

## 면접 포인트

**Q. `var`, `let`, `const`의 차이는?**
> 스코프(함수/블록), 호이스팅 방식(TDZ 유무), 재선언/재할당 가능 여부의 차이. `var`는 함수 스코프라 루프 클로저 버그가 생기기 쉽고, `const`가 기본 권장이다.

**Q. `null`과 `undefined`의 차이는?**
> `undefined`는 값이 할당된 적 없는 상태. `null`은 개발자가 의도적으로 '없음'을 표현한 것. `typeof null === 'object'`는 JS의 역사적 버그.

**Q. `==`과 `===`의 차이는?**
> `==`는 타입 강제 변환 후 비교, `===`는 타입까지 일치해야 true. 예측 불가한 동작 때문에 `===` 사용 권장.

**Q. 원시 타입과 참조 타입의 차이는?**
> 원시 타입은 값 자체가 스택에 저장되고 불변. 참조 타입은 힙에 저장되고 스택에는 주소만 저장. 복사 시 원시는 깊은 복사, 참조는 얕은 복사가 기본.
