# 06. 클로저 (Closure)

## 목차
1. [클로저 정의](#1-클로저-정의)
2. [렉시컬 환경과 클로저의 동작 원리](#2-렉시컬-환경과-클로저의-동작-원리)
3. [클로저 활용 패턴](#3-클로저-활용-패턴)
4. [주의사항](#4-주의사항)
5. [면접 포인트](#면접-포인트)

---

## 1. 클로저 정의

> **클로저(Closure)**: 함수가 선언될 당시의 렉시컬 환경(Lexical Environment)을 기억하여, 자신이 선언된 스코프 밖에서 호출되더라도 그 환경에 접근할 수 있는 함수.

MDN 정의:
> "A closure is the combination of a function and the lexical environment within which that function was declared."

```js
function outer() {
  const message = 'Hello';

  function inner() {
    console.log(message); // outer의 변수에 접근
  }

  return inner;
}

const greet = outer(); // outer 실행 종료
greet();               // 'Hello' - outer가 끝났어도 message에 접근 가능
```

`outer()`가 실행을 마쳤지만, `inner` 함수는 `message` 변수를 참조하는 클로저를 형성하고 있기 때문에 `message`는 가비지 컬렉션되지 않는다.

---

## 2. 렉시컬 환경과 클로저의 동작 원리

### 렉시컬 환경 (Lexical Environment)

실행 컨텍스트가 생성될 때 두 가지 컴포넌트를 가진다.

```
Lexical Environment
├── Environment Record   : 현재 스코프의 변수/함수 바인딩
└── Outer Reference      : 상위 렉시컬 환경에 대한 참조 (스코프 체인)
```

함수는 **정의될 때**(호출 시가 아님) 자신의 `[[Environment]]` 내부 슬롯에 현재 렉시컬 환경을 저장한다.

```js
function makeCounter() {
  let count = 0;             // makeCounter의 Environment Record에 저장

  return {
    increment() { count++; },
    decrement() { count--; },
    getCount() { return count; }
  };
}

const counter = makeCounter();
counter.increment();
counter.increment();
counter.increment();
counter.decrement();
console.log(counter.getCount()); // 2

// increment, decrement, getCount 모두 동일한 count를 공유
```

```
makeCounter 실행 컨텍스트
└── Lexical Environment
    ├── count: 0  ← 세 메서드가 모두 이 변수를 참조
    └── Outer: 전역 렉시컬 환경

increment[[Environment]] → 위 렉시컬 환경
decrement[[Environment]] → 위 렉시컬 환경
getCount[[Environment]]  → 위 렉시컬 환경
```

---

## 3. 클로저 활용 패턴

### 3-1. 모듈 패턴 (Module Pattern)

외부에서 접근하지 못하는 **비공개(private) 상태**를 구현할 수 있다.

```js
const bankAccount = (() => {
  let balance = 0; // private 변수

  function validate(amount) {
    if (amount <= 0) throw new Error('금액은 0보다 커야 합니다.');
  }

  return {
    deposit(amount) {
      validate(amount);
      balance += amount;
      console.log(`입금: ${amount}원 / 잔액: ${balance}원`);
    },
    withdraw(amount) {
      validate(amount);
      if (amount > balance) throw new Error('잔액 부족');
      balance -= amount;
      console.log(`출금: ${amount}원 / 잔액: ${balance}원`);
    },
    getBalance() {
      return balance;
    }
  };
})(); // IIFE(즉시 실행 함수)로 감쌈

bankAccount.deposit(10000);  // 입금: 10000원 / 잔액: 10000원
bankAccount.withdraw(3000);  // 출금: 3000원 / 잔액: 7000원
console.log(bankAccount.balance); // undefined - 외부 접근 불가
```

### 3-2. 함수 팩토리 (Function Factory)

특정 설정을 **고정(캡처)** 한 채 새로운 함수를 만든다.

```js
function makeMultiplier(factor) {
  return (number) => number * factor; // factor를 클로저로 캡처
}

const double = makeMultiplier(2);
const triple = makeMultiplier(3);
const tenTimes = makeMultiplier(10);

console.log(double(5));   // 10
console.log(triple(5));   // 15
console.log(tenTimes(5)); // 50

// 실용 예: 로거 팩토리
function makeLogger(prefix) {
  return (message) => console.log(`[${prefix}] ${message}`);
}

const errorLog = makeLogger('ERROR');
const infoLog  = makeLogger('INFO');

errorLog('파일을 찾을 수 없습니다.'); // [ERROR] 파일을 찾을 수 없습니다.
infoLog('서버가 시작되었습니다.');    // [INFO] 서버가 시작되었습니다.
```

### 3-3. 메모이제이션 (Memoization)

클로저로 **캐시(cache)** 를 유지해서 중복 계산을 방지한다.

```js
function memoize(fn) {
  const cache = new Map(); // 클로저로 캐시 유지

  return function(...args) {
    const key = JSON.stringify(args);

    if (cache.has(key)) {
      console.log(`캐시 히트: ${key}`);
      return cache.get(key);
    }

    const result = fn.apply(this, args);
    cache.set(key, result);
    return result;
  };
}

// 느린 함수 예시
function slowFibonacci(n) {
  if (n <= 1) return n;
  return slowFibonacci(n - 1) + slowFibonacci(n - 2);
}

const fastFibonacci = memoize(slowFibonacci);

console.time('first');
fastFibonacci(40); // 첫 번째: 실제 계산
console.timeEnd('first');

console.time('second');
fastFibonacci(40); // 두 번째: 캐시에서 즉시 반환
console.timeEnd('second');
```

### 3-4. 부분 적용 (Partial Application)

함수의 일부 인자를 미리 고정한 새 함수를 반환한다.

```js
function partial(fn, ...presetArgs) {
  return function(...laterArgs) {
    return fn(...presetArgs, ...laterArgs);
  };
}

function add(a, b, c) {
  return a + b + c;
}

const add10 = partial(add, 10);
const add10and20 = partial(add, 10, 20);

console.log(add10(5, 3));     // 18  (10 + 5 + 3)
console.log(add10and20(7));   // 37  (10 + 20 + 7)
```

---

## 4. 주의사항

### 4-1. 루프에서의 클로저 (고전적 버그)

```js
// 문제: var는 함수 스코프 → 모든 콜백이 같은 i를 공유
for (var i = 0; i < 3; i++) {
  setTimeout(() => console.log(i), 0); // 3, 3, 3 출력
}
// 루프 종료 시 i = 3, 모든 콜백은 동일한 i 참조
```

**해결 방법 1: `let` 사용 (블록 스코프로 반복마다 새로운 i)**

```js
for (let i = 0; i < 3; i++) {
  setTimeout(() => console.log(i), 0); // 0, 1, 2 출력
}
// let은 반복마다 새로운 바인딩을 만들어 각 콜백이 독립된 i를 캡처
```

**해결 방법 2: IIFE로 스코프 격리**

```js
for (var i = 0; i < 3; i++) {
  ((j) => {
    setTimeout(() => console.log(j), 0); // 0, 1, 2 출력
  })(i); // i를 j로 복사해서 새 스코프에 가둠
}
```

**해결 방법 3: `bind` 또는 추가 인자**

```js
for (var i = 0; i < 3; i++) {
  setTimeout(console.log.bind(null, i), 0); // 0, 1, 2 출력
}
```

### 4-2. 메모리 누수 주의

클로저는 참조된 렉시컬 환경 전체를 메모리에 유지한다. 더 이상 필요 없을 때 참조를 해제해야 한다.

```js
function createHeavyProcess() {
  const largeData = new Array(1000000).fill('data'); // 대용량 데이터

  return function process() {
    // largeData를 사용하지 않아도 클로저가 유지되면 GC 불가
    console.log('processing');
  };
}

let process = createHeavyProcess();
process();

// 사용 후 명시적으로 참조 해제
process = null; // 이제 클로저와 largeData 모두 GC 대상
```

```js
// 이벤트 리스너에서의 메모리 누수
function setupButton() {
  const heavyData = loadHeavyData();

  const handler = () => {
    console.log(heavyData); // heavyData를 캡처
  };

  document.getElementById('btn').addEventListener('click', handler);

  // 버튼이 DOM에서 제거될 때 리스너도 제거해야 함
  return () => {
    document.getElementById('btn').removeEventListener('click', handler);
  };
}

const cleanup = setupButton();
// 나중에 cleanup() 호출로 리스너 제거 → 메모리 해제
```

---

## 면접 포인트

**Q. 클로저란 무엇인가요?**
> 함수가 선언된 렉시컬 환경을 기억하여, 스코프 밖에서 호출되더라도 그 환경의 변수에 접근할 수 있는 함수와 환경의 조합. 모든 함수는 기술적으로 클로저를 형성하지만, 보통 외부 스코프 변수를 참조하는 내부 함수를 가리킨다.

**Q. 클로저를 사용하는 이유는?**
> (1) 데이터 은닉(private 변수 구현), (2) 상태 유지(함수 호출 간 상태 보존), (3) 함수 팩토리(설정을 캡처한 함수 생성), (4) 메모이제이션(캐시 유지). React의 `useState` 훅도 내부적으로 클로저를 활용한다.

**Q. 루프에서 `var`로 클로저를 만들면 왜 문제가 생기나요?**
> `var`는 함수 스코프이므로 루프의 모든 반복이 동일한 변수 i를 공유한다. 비동기 콜백이 실행될 때는 이미 루프가 끝나 i가 최종값이다. `let`은 블록 스코프라 반복마다 새로운 바인딩이 생겨 각 콜백이 독립된 값을 캡처한다.

**Q. 클로저와 메모리 누수의 관계는?**
> 클로저는 참조한 렉시컬 환경 전체를 살아있게 한다. 더 이상 필요 없는 클로저를 변수에 계속 담아두면 GC가 해당 환경을 수거하지 못해 메모리 누수가 발생한다. 특히 이벤트 리스너, 타이머에서 대용량 데이터를 캡처할 때 주의해야 한다.

**Q. React의 `useState`와 클로저의 관계는?**
> `useState`가 반환하는 setter 함수는 내부 상태 저장소(fiber)를 클로저로 참조한다. 오래된 클로저(stale closure) 문제가 발생할 수 있는데, 예를 들어 `useEffect` 내에서 이전 렌더링의 state 값을 캡처하는 경우다. 의존성 배열을 올바르게 설정하거나 함수형 업데이트(`setState(prev => prev + 1)`)로 해결한다.
