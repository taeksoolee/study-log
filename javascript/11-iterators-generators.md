# 11. 이터레이터와 제너레이터 (Iterators & Generators)

## 목차
1. [Iterable / Iterator 프로토콜](#1-iterable--iterator-프로토콜)
2. [Symbol.iterator 직접 구현](#2-symboliterator-직접-구현)
3. [Generator 함수](#3-generator-함수)
4. [제너레이터 활용](#4-제너레이터-활용)
5. [면접 포인트](#면접-포인트)

---

## 1. Iterable / Iterator 프로토콜

### 프로토콜 정의

**Iterable 프로토콜**: `Symbol.iterator` 메서드를 가진 객체. `for...of`, 스프레드 연산자(`...`), 구조 분해 등에서 사용 가능.

**Iterator 프로토콜**: `{ value, done }` 형태의 객체를 반환하는 `next()` 메서드를 가진 객체.

```
Iterable 객체
└── [Symbol.iterator]() → Iterator 객체
                          └── next() → { value: any, done: boolean }
```

### 내장 Iterable

```js
// 배열: Iterable
const arr = [1, 2, 3];
for (const v of arr) console.log(v); // 1, 2, 3

// 문자열: Iterable
for (const char of 'hello') console.log(char); // h, e, l, l, o

// Map, Set: Iterable
const map = new Map([['a', 1], ['b', 2]]);
for (const [key, val] of map) console.log(key, val); // a 1, b 2

const set = new Set([1, 2, 3]);
for (const v of set) console.log(v); // 1, 2, 3

// 스프레드 + 구조 분해도 Iterable 프로토콜 사용
const [first, ...rest] = arr; // first: 1, rest: [2, 3]
const copy = [...arr];         // [1, 2, 3]
```

### Iterator 직접 다루기

```js
const arr = [10, 20, 30];

// Symbol.iterator로 Iterator 가져오기
const iterator = arr[Symbol.iterator]();

console.log(iterator.next()); // { value: 10, done: false }
console.log(iterator.next()); // { value: 20, done: false }
console.log(iterator.next()); // { value: 30, done: false }
console.log(iterator.next()); // { value: undefined, done: true }
console.log(iterator.next()); // { value: undefined, done: true } (이후 계속 done: true)
```

---

## 2. Symbol.iterator 직접 구현

### 객체를 Iterable로 만들기

```js
// 범위(Range) Iterable
function range(start, end, step = 1) {
  return {
    [Symbol.iterator]() {
      let current = start;
      return {
        next() {
          if (current <= end) {
            const value = current;
            current += step;
            return { value, done: false };
          }
          return { value: undefined, done: true };
        }
      };
    }
  };
}

for (const n of range(1, 10, 2)) {
  console.log(n); // 1, 3, 5, 7, 9
}

console.log([...range(1, 5)]); // [1, 2, 3, 4, 5]

// 구조 분해도 가능
const [a, b, c] = range(10, 30, 10);
console.log(a, b, c); // 10 20 30
```

### 클래스에 Iterable 구현

```js
class LinkedList {
  constructor() {
    this.head = null;
    this.size = 0;
  }

  push(value) {
    const node = { value, next: null };
    if (!this.head) {
      this.head = node;
    } else {
      let current = this.head;
      while (current.next) current = current.next;
      current.next = node;
    }
    this.size++;
    return this;
  }

  // Iterable 프로토콜 구현
  [Symbol.iterator]() {
    let current = this.head;
    return {
      next() {
        if (current) {
          const value = current.value;
          current = current.next;
          return { value, done: false };
        }
        return { value: undefined, done: true };
      }
    };
  }
}

const list = new LinkedList();
list.push(1).push(2).push(3);

for (const val of list) {
  console.log(val); // 1, 2, 3
}

console.log([...list]); // [1, 2, 3]
```

### Iterable이면서 Iterator인 객체

`next()`가 있으면서 `[Symbol.iterator]`가 자기 자신을 반환하면 두 역할을 동시에 한다.

```js
function counter(start = 0) {
  let current = start;
  return {
    next() {
      return { value: current++, done: false }; // 무한 Iterator
    },
    [Symbol.iterator]() {
      return this; // 자기 자신 반환 → Iterable이기도 함
    }
  };
}

const c = counter(1);
console.log(c.next().value); // 1
console.log(c.next().value); // 2

// for...of와 함께 사용 (무한이므로 break 필수)
for (const n of counter(1)) {
  if (n > 5) break;
  console.log(n); // 1, 2, 3, 4, 5
}
```

---

## 3. Generator 함수

제너레이터는 Iterable/Iterator를 쉽게 만들 수 있는 특별한 함수다.

`function*` 키워드를 사용하며, `yield`로 값을 하나씩 내보낸다.

### 기본 문법

```js
function* simpleGenerator() {
  console.log('1단계');
  yield 1;           // 여기서 일시 중단, { value: 1, done: false } 반환
  console.log('2단계');
  yield 2;           // 여기서 일시 중단, { value: 2, done: false } 반환
  console.log('3단계');
  return 3;          // { value: 3, done: true } 반환 후 종료
}

const gen = simpleGenerator(); // 실행 안 됨, Generator 객체 반환

console.log(gen.next()); // '1단계' 출력, { value: 1, done: false }
console.log(gen.next()); // '2단계' 출력, { value: 2, done: false }
console.log(gen.next()); // '3단계' 출력, { value: 3, done: true }
console.log(gen.next()); // { value: undefined, done: true }

// Generator는 Iterable: for...of는 done:true인 값(return값)은 무시
for (const v of simpleGenerator()) {
  console.log(v); // 1, 2 (3은 출력 안 됨)
}
```

### `yield`로 값 주고받기

```js
function* twoWayCommunication() {
  const x = yield '첫 번째 질문: x는?'; // next()에 전달한 값이 yield의 결과
  const y = yield `두 번째 질문: y는? (현재 x = ${x})`;
  return `x + y = ${x + y}`;
}

const gen = twoWayCommunication();

// 첫 번째 next(): 인자가 있어도 무시됨 (시작 전이므로)
console.log(gen.next());       // { value: '첫 번째 질문: x는?', done: false }
// 두 번째 next(10): 10이 yield의 반환값 → x = 10
console.log(gen.next(10));     // { value: '두 번째 질문: y는? (현재 x = 10)', done: false }
// 세 번째 next(20): 20이 yield의 반환값 → y = 20
console.log(gen.next(20));     // { value: 'x + y = 30', done: true }
```

### `yield*` - 다른 Iterable 위임

```js
function* inner() {
  yield 'a';
  yield 'b';
}

function* outer() {
  yield 1;
  yield* inner();  // inner 제너레이터에 위임
  yield* [3, 4];   // 배열도 위임 가능
  yield 5;
}

console.log([...outer()]); // [1, 'a', 'b', 3, 4, 5]
```

### `return()`과 `throw()`

```js
function* gen() {
  try {
    yield 1;
    yield 2;
    yield 3;
  } catch (err) {
    console.log('에러 잡힘:', err.message);
    yield 99;
  } finally {
    console.log('finally 실행');
  }
}

const g = gen();
console.log(g.next());          // { value: 1, done: false }
console.log(g.throw(new Error('주입된 에러'))); // '에러 잡힘: 주입된 에러', { value: 99, done: false }
console.log(g.return('조기 종료')); // 'finally 실행', { value: '조기 종료', done: true }
```

---

## 4. 제너레이터 활용

### 4-1. 무한 시퀀스

```js
// 무한 피보나치 수열
function* fibonacci() {
  let [a, b] = [0, 1];
  while (true) {
    yield a;
    [a, b] = [b, a + b];
  }
}

// 처음 10개만 가져오기
function take(iterable, n) {
  const result = [];
  for (const val of iterable) {
    result.push(val);
    if (result.length >= n) break;
  }
  return result;
}

console.log(take(fibonacci(), 10));
// [0, 1, 1, 2, 3, 5, 8, 13, 21, 34]

// 무한 ID 생성기
function* idGenerator(prefix = 'id') {
  let n = 1;
  while (true) {
    yield `${prefix}_${n++}`;
  }
}

const genId = idGenerator('user');
console.log(genId.next().value); // 'user_1'
console.log(genId.next().value); // 'user_2'
console.log(genId.next().value); // 'user_3'
```

### 4-2. 지연 평가 (Lazy Evaluation)

```js
// 일반 함수: 즉시 모든 데이터를 처리
function* lazyMap(iterable, transform) {
  for (const value of iterable) {
    yield transform(value); // 하나씩 변환
  }
}

function* lazyFilter(iterable, predicate) {
  for (const value of iterable) {
    if (predicate(value)) yield value; // 조건 만족하는 것만
  }
}

function* lazyTake(iterable, n) {
  let count = 0;
  for (const value of iterable) {
    if (count >= n) return;
    yield value;
    count++;
  }
}

// 파이프라인: 1~100만 중에서 짝수만, 2배로, 처음 5개
const pipeline = lazyTake(
  lazyMap(
    lazyFilter(range(1, 1_000_000), n => n % 2 === 0),
    n => n * 2
  ),
  5
);

console.log([...pipeline]); // [4, 8, 12, 16, 20]
// 실제로는 처음 5개를 찾는 순간 나머지 연산을 멈춤
```

### 4-3. 비동기 제어 흐름

```js
// 제너레이터로 async/await 직접 구현 (원리 이해용)
function run(generatorFn) {
  const gen = generatorFn();

  function step(value) {
    const result = gen.next(value);
    if (result.done) return Promise.resolve(result.value);

    return Promise.resolve(result.value).then(
      val => step(val),
      err => gen.throw(err)
    );
  }

  return step();
}

// 제너레이터로 작성한 "async" 함수
run(function* () {
  const user  = yield fetch('/api/user').then(r => r.json());
  const posts = yield fetch(`/api/posts/${user.id}`).then(r => r.json());
  console.log(posts);
});
// → async/await와 동일한 동작
```

### 4-4. 상태 머신 (State Machine)

```js
function* trafficLight() {
  while (true) {
    yield '빨강';  // 정지
    yield '초록';  // 진행
    yield '노랑';  // 주의
  }
}

const light = trafficLight();
const next = () => light.next().value;

console.log(next()); // '빨강'
console.log(next()); // '초록'
console.log(next()); // '노랑'
console.log(next()); // '빨강' (다시 반복)
```

---

## 면접 포인트

**Q. Iterable과 Iterator의 차이는?**
> Iterable은 `[Symbol.iterator]()` 메서드를 가진 객체로 `for...of` 등에서 순회 가능하다. Iterator는 `next()` 메서드를 가져 `{ value, done }` 형태의 결과를 반환하는 객체다. Iterable의 `[Symbol.iterator]()`를 호출하면 Iterator가 반환된다.

**Q. 제너레이터 함수의 실행 흐름은?**
> `function*`으로 선언한 함수를 호출하면 즉시 실행되지 않고 Generator 객체가 반환된다. `next()`를 호출할 때마다 다음 `yield`까지 실행하고 일시 중단한다. `next(value)`로 값을 주입하면 현재 중단된 `yield` 표현식의 반환값이 된다. 이 일시 중단/재개 특성이 핵심이다.

**Q. 제너레이터의 실용적인 사용 사례는?**
> (1) 무한 시퀀스 (피보나치, ID 생성), (2) 지연 평가 파이프라인(대용량 데이터 처리 최적화), (3) 비동기 흐름 제어(co 라이브러리, async/await의 원형), (4) 상태 머신 구현, (5) Redux-Saga에서 비동기 사이드 이펙트 관리.

**Q. `yield*`와 `yield`의 차이는?**
> `yield`는 단일 값을 내보낸다. `yield*`는 다른 Iterable(배열, 다른 제너레이터 등)에 순회를 위임하여 해당 Iterable의 모든 값을 하나씩 내보낸다. `yield* [1,2,3]`은 `yield 1; yield 2; yield 3;`과 동일하다.

**Q. 일반 함수와 제너레이터 함수의 차이는?**
> 일반 함수는 호출 시 즉시 실행되고 하나의 값을 반환 후 종료된다. 제너레이터 함수는 호출 시 Generator 객체를 반환하고, `next()` 호출마다 `yield` 지점에서 일시 중단/재개되며 여러 값을 순차적으로 내보낼 수 있다. 실행 컨텍스트가 유지되어 지역 변수 상태가 보존된다.
